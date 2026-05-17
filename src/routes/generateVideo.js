const fs = require('fs');
const path = require('path');
const express = require('express');
const { tattooImageUpload } = require('../middleware/upload');
const { optimizeImage } = require('../middleware/optimizeImage');
const {
  videoGenerationLimiter,
  statusPollingLimiter,
} = require('../middleware/rateLimiter');
const {
  queueGenerativeVideoJob,
  getGenerativeJobStatus,
} = require('../services/generativeAiRelay');
const {
  generateTattooMask,
  isSparkleTrackStyle,
} = require('../services/tattooMaskEngine');
const { logger } = require('../utils/logger');

const router = express.Router();

function resolveStyleId(body) {
  return (body.style_id || body.styleId || '').trim();
}

function safeUnlink(filePath) {
  if (!filePath) return;
  fs.unlink(filePath, () => {});
}

function cleanupUploadFiles(file, { preserveMask = false } = {}) {
  if (!file) return;
  safeUnlink(file.path);
  if (file.optimizedPath && file.optimizedPath !== file.path) {
    safeUnlink(file.optimizedPath);
  }
  if (!preserveMask) {
    safeUnlink(file.maskPath);
  }
}

function buildMaskPublicUrl(req, maskFileName) {
  const protocol = req.headers['x-forwarded-proto'] || req.protocol || 'http';
  const host = req.get('host') || `localhost:${process.env.PORT || 5001}`;
  return `${protocol}://${host}/uploads/masks/${maskFileName}`;
}

/**
 * POST /v1/generate/video
 * Sparkle track → instant 200 + mask_url; premium styles → 202 async queue.
 */
router.post(
  '/video',
  videoGenerationLimiter,
  tattooImageUpload,
  optimizeImage,
  async (req, res) => {
    const requestStartedAt = Date.now();
    const styleId = resolveStyleId(req.body);

    logger.info('Incoming generate/video queue request', {
      styleId: styleId || null,
      hasFile: Boolean(req.file),
      contentType: req.headers['content-type'],
    });

    if (!req.file) {
      logger.warn('Rejected request: missing image file');
      return res.status(400).json({
        error: 'bad_request',
        message: 'Missing required multipart field: image',
      });
    }

    if (!styleId) {
      cleanupUploadFiles(req.file);
      logger.warn('Rejected request: missing style_id');
      return res.status(400).json({
        error: 'bad_request',
        message: 'Missing required field: style_id',
      });
    }

    const optimizedPath = req.file.optimizedPath || req.file.path;
    const isSparkleTrack = isSparkleTrackStyle(styleId);

    try {
      if (isSparkleTrack) {
        const maskResult = await generateTattooMask(optimizedPath);
        req.file.maskPath = maskResult.maskPath;

        const maskUrl = buildMaskPublicUrl(req, maskResult.maskFileName);
        const totalDurationMs = Date.now() - requestStartedAt;

        logger.info('Sparkle line mask served instantly (local_overlay)', {
          styleId,
          maskUrl,
          maskDurationMs: maskResult.durationMs,
          totalDurationMs,
          inputBytes: maskResult.inputBytes,
          outputBytes: maskResult.outputBytes,
        });

        console.log(
          `[ink-api] Sparkle track completed in ${totalDurationMs}ms ` +
            `(mask engine ${maskResult.durationMs}ms) · ${maskUrl}`,
        );

        return res.status(200).json({
          status: 'success',
          engine: 'local_overlay',
          mask_url: maskUrl,
          message: 'Line mask generated instantly.',
        });
      }

      const queueResult = await queueGenerativeVideoJob({
        imagePath: optimizedPath,
        optimizedImagePath: req.file.optimizedPath,
        styleId,
        mimeType: req.file.optimizedPath ? 'image/jpeg' : req.file.mimetype,
      });

      logger.info('Animation task registered in cloud queue', {
        jobId: queueResult.jobId,
        styleId,
        vendor: queueResult.vendor,
        mock: queueResult.mock,
        totalDurationMs: Date.now() - requestStartedAt,
      });

      return res.status(202).json({
        status: 'queued',
        job_id: queueResult.jobId,
        message: 'Animation task safely registered in cloud queue.',
      });
    } catch (error) {
      logger.error('Generate/video pipeline failed', {
        styleId,
        sparkleTrack: isSparkleTrack,
        message: error.message,
        durationMs: Date.now() - requestStartedAt,
      });

      const status = error.response?.status === 429 ? 503 : 502;
      return res.status(status).json({
        error: isSparkleTrack ? 'mask_generation_failed' : 'queue_failed',
        message: isSparkleTrack
          ? 'Unable to generate line mask for this upload.'
          : 'Unable to register animation task with upstream provider.',
      });
    } finally {
      cleanupUploadFiles(req.file, { preserveMask: isSparkleTrack });
    }
  },
);

/**
 * GET /v1/generate/status/:job_id
 * Polls upstream Replicate (or mock registry) for render progress.
 */
router.get('/status/:job_id', statusPollingLimiter, async (req, res) => {
  const jobId = (req.params.job_id || '').trim();

  logger.info('Status checkpoint request', { jobId });

  if (!jobId) {
    return res.status(400).json({
      error: 'bad_request',
      message: 'job_id path parameter is required',
    });
  }

  try {
    const statusPayload = await getGenerativeJobStatus(jobId);
    return res.status(200).json(statusPayload);
  } catch (error) {
    logger.error('Status checkpoint failed', {
      jobId,
      message: error.message,
    });

    const httpStatus = error.response?.status === 429 ? 503 : 502;
    return res.status(httpStatus).json({
      status: 'failed',
      job_id: jobId,
      error: 'Unable to verify job status with upstream provider.',
    });
  }
});

module.exports = router;
