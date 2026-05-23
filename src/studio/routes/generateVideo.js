const fs = require('fs');
const express = require('express');
const { tattooImageUpload } = require('../../middleware/upload');
const { optimizeImage } = require('../../middleware/optimizeImage');
const {
  videoGenerationLimiter,
  statusPollingLimiter,
} = require('../../middleware/rateLimiter');
const { prepare } = require('../prep/prep_engine');
const { composeRenderSpec } = require('../render/style_engine');
const { KlingProvider } = require('../render/providers/kling_provider');
const {
  createJob,
  getJob,
  updateJob,
  toStatusPayload,
} = require('../render/render_job_store');
const { logger } = require('../../utils/logger');

const router = express.Router();
const klingProvider = new KlingProvider();

function resolveStyleId(body) {
  return (body.style_id || body.styleId || '').trim();
}

function resolveSubjectType(body) {
  return (body.subject_type || body.subjectType || '').trim();
}

function resolveMotionPreset(body) {
  return (body.motion_preset || body.motionPreset || 'default').trim() || 'default';
}

function resolveDiscoverySummary(body) {
  return body.discovery_summary ?? body.discoverySummary ?? null;
}

function safeUnlink(filePath) {
  if (!filePath) return;
  fs.unlink(filePath, () => {});
}

function cleanupUploadFiles(file) {
  if (!file) return;
  safeUnlink(file.path);
  if (file.optimizedPath && file.optimizedPath !== file.path) {
    safeUnlink(file.optimizedPath);
  }
}

router.get('/health', (_req, res) => {
  res.status(200).json({
    status: 'ok',
    module: 'studio-generate',
    klingConfigured: klingProvider.isConfigured(),
  });
});

router.post('/spec-preview', express.json(), (req, res) => {
  const styleId = resolveStyleId(req.body);
  const subjectType = resolveSubjectType(req.body) || 'default';
  const motionPreset = resolveMotionPreset(req.body);

  if (!styleId) {
    return res.status(400).json({
      error: 'bad_request',
      message: 'Missing required field: style_id',
    });
  }

  const spec = composeRenderSpec({ subjectType, styleId, motionPreset });

  logger.info('Studio render spec preview', {
    styleId: spec.styleId,
    subjectType: spec.subjectType,
    motionFamily: spec.metadata.motionFamily,
  });

  return res.status(200).json({
    status: 'ok',
    spec,
  });
});

/**
 * POST /v1/studio/generate/animate
 * Multipart: image, styleId/style_id, subjectType/subject_type
 */
router.post(
  '/animate',
  videoGenerationLimiter,
  tattooImageUpload,
  optimizeImage,
  async (req, res) => {
    const requestStartedAt = Date.now();
    const styleId = resolveStyleId(req.body);
    const clientSubjectType = resolveSubjectType(req.body);
    const motionPreset = resolveMotionPreset(req.body);
    const discoverySummary = resolveDiscoverySummary(req.body);

    logger.info('Studio animate request', {
      styleId: styleId || null,
      subjectType: clientSubjectType || null,
      hasFile: Boolean(req.file),
    });

    if (!req.file) {
      return res.status(400).json({
        error: 'bad_request',
        message: 'Missing required multipart field: image',
      });
    }

    if (!styleId) {
      cleanupUploadFiles(req.file);
      return res.status(400).json({
        error: 'bad_request',
        message: 'Missing required field: styleId',
      });
    }

    if (!klingProvider.isConfigured()) {
      cleanupUploadFiles(req.file);
      return res.status(503).json({
        error: 'kling_not_configured',
        message: 'Kling API credentials are not configured on the server.',
      });
    }

    try {
      const prepResult = await prepare({
        file: req.file,
        styleId,
        subjectType: clientSubjectType,
        motionPreset,
        discoverySummary,
      });

      const renderSpec = composeRenderSpec({
        subjectType: prepResult.subjectType,
        styleId: prepResult.styleId,
        motionPreset: prepResult.motionPreset,
      });

      const klingResult = await klingProvider.submitGeneration({
        prompt: renderSpec.prompt,
        image: prepResult.imageBase64,
        duration: renderSpec.motion.duration_seconds,
        extra: {
          style_id: renderSpec.styleId,
          subject_type: renderSpec.subjectType,
          motion_label: renderSpec.motion.label,
          motion_family: renderSpec.metadata.motionFamily,
        },
      });

      const job = createJob({
        taskId: klingResult.taskId,
        vendor: klingResult.vendor,
        styleId: renderSpec.styleId,
        subjectType: renderSpec.subjectType,
        renderSpec,
        status: 'queued',
      });

      logger.info('Studio animate job queued', {
        jobId: job.jobId,
        taskId: job.taskId,
        styleId: renderSpec.styleId,
        subjectType: renderSpec.subjectType,
        totalDurationMs: Date.now() - requestStartedAt,
      });

      return res.status(202).json({
        status: 'queued',
        job_id: job.jobId,
        task_id: job.taskId,
        message: 'Studio animation task registered.',
        render_engine: 'kling',
        style_id: renderSpec.styleId,
        subject_type: renderSpec.subjectType,
      });
    } catch (error) {
      logger.error('Studio animate pipeline failed', {
        styleId,
        message: error.message,
        durationMs: Date.now() - requestStartedAt,
      });

      const isUpstream = error.message?.startsWith('kling_');
      return res.status(isUpstream ? 502 : 500).json({
        error: isUpstream ? 'render_submit_failed' : 'studio_animate_failed',
        message: error.message || 'Unable to start Studio animation.',
      });
    } finally {
      cleanupUploadFiles(req.file);
    }
  },
);

/**
 * GET /v1/studio/generate/status/:job_id
 * Polls in-memory registry and refreshes from Kling when needed.
 */
router.get('/status/:job_id', statusPollingLimiter, async (req, res) => {
  const jobId = (req.params.job_id || '').trim();

  if (!jobId) {
    return res.status(400).json({
      error: 'bad_request',
      message: 'job_id path parameter is required',
    });
  }

  const job = getJob(jobId);
  if (!job) {
    return res.status(404).json({
      status: 'failed',
      job_id: jobId,
      error: 'Unknown or expired job_id',
    });
  }

  if (job.status === 'succeeded' || job.status === 'failed') {
    return res.status(200).json(toStatusPayload(job));
  }

  if (!klingProvider.isConfigured()) {
    return res.status(503).json({
      status: 'failed',
      job_id: jobId,
      error: 'Kling API credentials are not configured on the server.',
    });
  }

  try {
    const klingStatus = await klingProvider.getTaskStatus(job.taskId);

    updateJob(jobId, {
      status: klingStatus.status,
      videoUrl: klingStatus.video_url ?? null,
      error: klingStatus.error ?? null,
    });

    const refreshed = getJob(jobId);
    return res.status(200).json(toStatusPayload(refreshed));
  } catch (error) {
    logger.error('Studio status checkpoint failed', {
      jobId,
      taskId: job.taskId,
      message: error.message,
    });

    return res.status(502).json({
      status: 'failed',
      job_id: jobId,
      task_id: job.taskId,
      error: 'Unable to verify job status with Kling.',
    });
  }
});

module.exports = router;
