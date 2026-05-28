const express = require('express');
const multer = require('multer');
const { submitKlingJob, pollKlingJob } = require('../studio/klingProvider');
const {
  generateConceptImage,
  generateCoverupImage,
} = require('../services/openAiMockupService');
const { logger } = require('../utils/logger');

const router = express.Router();

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 20 * 1024 * 1024 },
});

const STYLE_PROMPTS = {
  ember_glow:
    'Animate only the tattoo art on the skin. Warm golden and amber light pulses gently from within the linework and shading. The ink glows like embers breathing in the dark. The body and background remain completely still. Cinematic, 10 seconds, seamless loop.',
  fluid_flow:
    'Animate only the tattoo art on the skin. The ink flows with slow organic liquid motion, rippling and breathing as if alive beneath the surface. Shadows and highlights shift fluidly. The body and background remain completely still. Cinematic, 10 seconds, seamless loop.',
  mystic_drift:
    'Animate only the tattoo art on the skin. Ink elements drift and swirl with an ethereal energy, like dark smoke curling in slow motion. Fine details shimmer faintly. The body and background remain completely still. Cinematic, 10 seconds, seamless loop.',
  electric_storm:
    'Animate only the tattoo art on the skin. Bright neon electricity and energy arcs trace along the linework, crackling between details like a tesla coil. The ink pulses with electric blue and white light. The body and background remain completely still. Cinematic, 10 seconds, seamless loop.',
  watercolor_bloom:
    'Animate only the tattoo art on the skin. Ink pigment blooms and bleeds outward from the tattoo lines like watercolor on wet paper, expanding then retreating in slow waves. Colors deepen and soften rhythmically. The body and background remain completely still. Cinematic, 10 seconds, seamless loop.',
  shadow_reaper:
    'Animate only the tattoo art on the skin. Deep shadows emerge and recede within the tattoo, dark gothic forms shifting and breathing with a haunting energy. Black ink deepens to near void then releases. The body and background remain completely still. Cinematic, 10 seconds, seamless loop.',
  japanese_wave:
    'Animate only the tattoo art on the skin. The linework flows like traditional Japanese brush strokes, ink moves like Hokusai waves rising and receding, bold forms breathe with ancient energy. Wind bars flutter, water churns within the design. The body and background remain completely still. Cinematic, 10 seconds, seamless loop.',
  alex_grey:
    'Animate only the tattoo art on the skin. Sacred geometry patterns pulse and activate within the linework, visionary light grids emerge, inter-dimensional energy flows through the design like Alex Grey artwork coming alive. Chakra light radiates from focal points. The body and background remain completely still. Cinematic, 10 seconds, seamless loop.',
  steampunk:
    'Animate only the tattoo art on the skin. Intricate gears rotate within the linework, copper and brass tones catch warm light, delicate steam wisps rise from the ink. Mechanical energy pulses through every detail. The body and background remain completely still. Cinematic, 10 seconds, seamless loop.',
  horror:
    'Animate only the tattoo art on the skin. Dark ink drips and bleeds slowly from the linework, veins pulse beneath the design, sinister shadows breathe and shift. A haunting malevolent energy radiates from within. The body and background remain completely still. Cinematic, 10 seconds, seamless loop.',
  default:
    'Animate only the tattoo art on the skin. Cinematic flowing ink movement, dynamic artistic energy transforming the design. The body and background remain completely still. 10 seconds, seamless loop.',
};

function mapStyleToStyleId(style) {
  const styleId = (style || '').trim().toLowerCase();
  return Object.prototype.hasOwnProperty.call(STYLE_PROMPTS, styleId) && styleId !== 'default'
    ? styleId
    : 'default';
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

  try {
    const { imageUrl } = await generateConceptImage({ prompt, style });
    return res.status(200).json({ imageUrl });
  } catch (error) {
    logger.error('API generate-concept failed', {
      code: error.code || 'concept_generation_failed',
      message: error.message,
    });

    const statusCode = Number.isInteger(error.statusCode) ? error.statusCode : 502;
    return res.status(statusCode).json({
      error: error.code || 'concept_generation_failed',
      message: error.message || 'Unable to generate concept image.',
    });
  }
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

  try {
    const { imageUrl } = await generateCoverupImage({
      imageBuffer: req.file.buffer,
      prompt,
    });
    return res.status(200).json({ imageUrl });
  } catch (error) {
    logger.error('API generate-coverup failed', {
      code: error.code || 'coverup_generation_failed',
      message: error.message,
    });

    const statusCode = Number.isInteger(error.statusCode) ? error.statusCode : 502;
    return res.status(statusCode).json({
      error: error.code || 'coverup_generation_failed',
      message: error.message || 'Unable to generate coverup image.',
    });
  }
});

module.exports = router;
