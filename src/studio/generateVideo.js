// src/studio/generateVideo.js
// POST /v1/studio/generate/animate  — submit Kling i2v job
// GET  /v1/studio/generate/status/:task_id — poll Kling job

const express = require('express');
const { videoGenerationLimiter, statusPollingLimiter } = require('../middleware/rateLimiter');
const { submitKlingJob, pollKlingJob } = require('./klingProvider');
const { logger } = require('../utils/logger');

const router = express.Router();

// Style ID → Kling prompt map
const STYLE_PROMPTS = {
  cyberpunk_neon_glow: 'cyberpunk tattoo animation, electric neon lines pulsing, glowing circuitry flowing, futuristic energy radiating',
  traditional_japanese_ink_flow: 'traditional Japanese ink wash animation, flowing brushstrokes, koi fish movement, cherry blossom petals drifting',
  animated_pop_3d: 'bold pop art tattoo animation, vivid colors popping, 3D depth pulsing, dynamic comic energy bursting',
  monochrome_shadow: 'monochrome tattoo animation, deep shadows flowing, bold contrast shifting, dramatic light and dark dance',
  traditional_japanese:
    'traditional Japanese ink wash animation, flowing brushstrokes, koi fish movement, cherry blossom petals drifting',
  neo_traditional:
    'neo-traditional tattoo animation, bold lines flowing, vibrant colors pulsing, ornate details shimmering',
  blackwork:
    'blackwork tattoo animation, bold geometric patterns shifting, deep shadows flowing, intricate linework alive',
  watercolor:
    'watercolor tattoo animation, ink bleeds blooming outward, soft pigment clouds drifting, fluid color washes',
  tribal:
    'tribal tattoo animation, ancient patterns awakening, bold strokes undulating, primal energy radiating',
  realism:
    'photorealistic tattoo animation, lifelike subject breathing, subtle movement, cinematic depth of field',
  geometric:
    'geometric tattoo animation, precise lines rotating, sacred geometry transforming, symmetrical patterns shifting',
  biomechanical:
    'biomechanical tattoo animation, mechanical parts moving, gears turning, organic-machine fusion pulsing',
  dark_art:
    'dark art tattoo animation, shadowy forms emerging, gothic details alive, ethereal dark energy flowing',
  illustrative:
    'illustrative tattoo animation, storybook characters moving, bold outlines dancing, whimsical scene unfolding',
  // fallback
  default:
    'cinematic tattoo animation, flowing ink movement, dynamic energy, artistic transformation',
};

function getStylePrompt(styleId) {
  return STYLE_PROMPTS[styleId] || STYLE_PROMPTS.default;
}

// ─── POST /v1/studio/generate/animate ────────────────────────────────────────
router.post(
  '/animate',
  videoGenerationLimiter,
  async (req, res) => {
    const imageBase64 = req.body.image_base64;
    const styleId = (req.body.style_id || '').trim();
    const durationRaw = parseInt(req.body.duration_seconds || '5', 10);
    const durationSeconds = [5, 10].includes(durationRaw) ? durationRaw : 5;

    logger.info('Studio animate request', {
      styleId,
      durationSeconds,
      hasImageBase64: Boolean(imageBase64),
      imageBase64Length: imageBase64 ? imageBase64.length : 0,
    });

    if (!imageBase64 || imageBase64.length < 100) {
      return res.status(400).json({ error: 'bad_request', message: 'Missing image file' });
    }
    if (!styleId) {
      return res.status(400).json({ error: 'bad_request', message: 'Missing style_id' });
    }

    try {
      const taskId = await submitKlingJob({
        imageUrl: imageBase64,
        durationSeconds,
        stylePrompt: getStylePrompt(styleId),
      });

      return res.status(202).json({
        status: 'queued',
        task_id: taskId,
        message: 'Kling animation job submitted successfully.',
      });
    } catch (error) {
      logger.error('Studio animate failed', { styleId, message: error.message });
      return res.status(502).json({
        error: 'kling_submit_failed',
        message: 'Unable to submit animation job to Kling.',
      });
    }
  }
);

// ─── GET /v1/studio/generate/status/:task_id ─────────────────────────────────
router.get('/status/:task_id', statusPollingLimiter, async (req, res) => {
  const taskId = (req.params.task_id || '').trim();

  if (!taskId) {
    return res.status(400).json({ error: 'bad_request', message: 'task_id required' });
  }

  try {
    const result = await pollKlingJob(taskId);
    return res.status(200).json({
      status: result.status,
      video_url: result.videoUrl ?? null,
      videoUrl: result.videoUrl ?? null,
      task_result: result.raw
        ? { videos: result.raw.task_result?.videos ?? [] }
        : null,
    });
  } catch (error) {
    logger.error('Studio poll failed', { taskId, message: error.message });
    return res.status(502).json({
      status: 'failed',
      error: 'Unable to poll Kling job status.',
    });
  }
});

module.exports = router;
