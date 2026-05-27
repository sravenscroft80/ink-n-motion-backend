const express = require('express');
const multer = require('multer');
const { submitKlingJob, pollKlingJob } = require('../studio/klingProvider');
const { logger } = require('../utils/logger');

const router = express.Router();

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 20 * 1024 * 1024 },
});

const STYLE_ID_MAP = {
  fluid: 'watercolor',
  sparkle: 'animated_pop_3d',
  'neon pulse': 'cyberpunk_neon_glow',
  cyberpunk: 'cyberpunk_neon_glow',
  watercolor: 'watercolor',
  'dark energy': 'dark_art',
};

const STYLE_PROMPTS = {
  cyberpunk_neon_glow:
    'cyberpunk tattoo animation, electric neon lines pulsing, glowing circuitry flowing, futuristic energy radiating',
  animated_pop_3d:
    'bold pop art tattoo animation, vivid colors popping, 3D depth pulsing, dynamic comic energy bursting',
  watercolor:
    'watercolor tattoo animation, ink bleeds blooming outward, soft pigment clouds drifting, fluid color washes',
  dark_art:
    'dark art tattoo animation, shadowy forms emerging, gothic details alive, ethereal dark energy flowing',
  default:
    'cinematic tattoo animation, flowing ink movement, dynamic energy, artistic transformation',
};

function mapStyleToStyleId(style) {
  const key = (style || '').trim().toLowerCase();
  return STYLE_ID_MAP[key] || 'default';
}

function getStylePrompt(styleId) {
  return STYLE_PROMPTS[styleId] || STYLE_PROMPTS.default;
}

function parseDurationSeconds(raw) {
  const parsed = parseInt(raw || '10', 10);
  return parsed === 10 ? 10 : 5;
}

// ─── POST /api/generate-video ───────────────────────────────────────────────
router.post('/generate-video', upload.single('image'), async (req, res) => {
  try {
    if (!req.file?.buffer) {
      return res.status(400).json({ error: 'bad_request', message: 'Missing image file' });
    }

    const style = req.body.style || '';
    const styleId = mapStyleToStyleId(style);
    const durationSeconds = parseDurationSeconds(req.body.duration);
    const imageBase64 = req.file.buffer.toString('base64');

    logger.info('API generate-video request', {
      style,
      styleId,
      durationSeconds,
      imageBytes: req.file.buffer.length,
    });

    const taskId = await submitKlingJob({
      imageUrl: imageBase64,
      durationSeconds,
      stylePrompt: getStylePrompt(styleId),
    });

    return res.status(202).json({
      taskId,
      status: 'queued',
    });
  } catch (error) {
    logger.error('API generate-video failed', { message: error.message });
    return res.status(502).json({
      error: 'kling_submit_failed',
      message: 'Unable to submit animation job.',
    });
  }
});

// ─── GET /api/generate-video-status/:taskId ─────────────────────────────────
router.get('/generate-video-status/:taskId', async (req, res) => {
  const taskId = (req.params.taskId || '').trim();

  if (!taskId) {
    return res.status(400).json({ error: 'bad_request', message: 'taskId required' });
  }

  try {
    const result = await pollKlingJob(taskId);
    return res.status(200).json({
      status: result.status,
      videoUrl: result.videoUrl ?? null,
    });
  } catch (error) {
    logger.error('API generate-video-status failed', { taskId, message: error.message });
    return res.status(502).json({
      status: 'failed',
      error: 'Unable to poll Kling job status.',
    });
  }
});

// ─── POST /api/generate-concept ─────────────────────────────────────────────
router.post('/generate-concept', async (req, res) => {
  const { prompt, style } = req.body || {};

  logger.info('API generate-concept request', {
    hasPrompt: Boolean(prompt),
    style: style || null,
  });

  // TODO: wire to DALL-E or Stability AI
  return res.status(200).json({
    imageUrl: `https://picsum.photos/seed/${Date.now()}/400/400`,
  });
});

// ─── POST /api/generate-coverup ─────────────────────────────────────────────
router.post('/generate-coverup', upload.single('image'), async (req, res) => {
  const prompt = req.body.prompt || '';

  logger.info('API generate-coverup request', {
    hasImage: Boolean(req.file?.buffer),
    hasPrompt: Boolean(prompt),
  });

  if (!req.file?.buffer) {
    return res.status(400).json({ error: 'bad_request', message: 'Missing image file' });
  }

  // TODO: wire to inpainting API
  return res.status(200).json({
    imageUrl: `https://picsum.photos/seed/${Date.now() + 1}/400/400`,
  });
});

module.exports = router;
