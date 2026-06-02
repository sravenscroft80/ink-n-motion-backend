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
    'Animate only the tattoo art on the skin. Warm golden and amber light surges and pulses through the linework with subtle 3D depth, embers flicker and glow brighter then dim like living fire breathing, faint sparks drift just off the ink and fade. The art appears to rise slightly off the skin with soft volumetric glow. Rich, vibrant, cinematic. The body and background remain completely still. 10 seconds, seamless loop.',
  fluid_flow:
    'Animate only the tattoo art on the skin. The ink flows with rich organic liquid motion and subtle dimensional depth, rippling and swirling as if alive beneath the surface, highlights and shadows sliding fluidly to give the design soft 3D relief. Vivid and hypnotic. The body and background remain completely still. 10 seconds, seamless loop.',
  mystic_drift:
    'Animate only the tattoo art on the skin. Ethereal dark energy swirls through the ink with layered depth and parallax, wisps of mystical smoke curl and drift just beyond the lines, fine details shimmer with an otherworldly glow as the art floats slightly above the skin. Trippy, dreamlike, cinematic. The body and background remain completely still. 10 seconds, seamless loop.',
  electric_storm:
    'Animate only the tattoo art on the skin. Brilliant neon electricity races along every line with glowing dimensional depth, vivid blue and white energy arcs crackle between details and snap just off the ink like a tesla coil, the design pulses with charged power and soft volumetric light. High energy, cinematic. The body and background remain completely still. 10 seconds, seamless loop.',
  watercolor_bloom:
    'Animate only the tattoo art on the skin. Vivid pigment blooms and bleeds outward from the lines like watercolor on wet paper with soft layered depth, rich colors swell then retreat in slow rhythmic waves, gentle halos of color pulse just past the edges giving a subtle 3D bloom. Lush and beautiful. The body and background remain completely still. 10 seconds, seamless loop.',
  shadow_reaper:
    'Animate only the tattoo art on the skin. Deep shadows surge and recede within the ink with dramatic dimensional depth, dark gothic forms shift and breathe with haunting menace, tendrils of darkness creep just beyond the lines then withdraw, the design appears to rise in ominous relief. Cinematic. The body and background remain completely still. 10 seconds, seamless loop.',
  japanese_wave:
    'Animate only the tattoo art on the skin. The linework moves like living Hokusai brushwork, bold waves rise and curl and crash within the design, wind bars flutter and water churns with powerful ancient energy, all contained inside the tattoo lines. Dynamic and majestic. The body and background remain completely still. 10 seconds, seamless loop.',
  alex_grey:
    'Animate only the tattoo art on the skin. Glowing sacred geometry ignites and pulses through the linework with luminous depth, radiant visionary light grids activate, psychedelic chakra energy and inter-dimensional patterns surge through the design like Alex Grey\'s art coming alive, all held within the tattoo lines. Trippy, vibrant, transcendent. The body and background remain completely still. 10 seconds, seamless loop.',
  steampunk:
    'Animate only the tattoo art on the skin. Intricate brass and copper gears turn and mesh within the linework, polished metal catches glints of warm light, delicate wisps of steam hiss and curl up from the mechanism, every cog and rivet alive with motion, all contained inside the tattoo lines. Rich, detailed, cinematic. The body and background remain completely still. 10 seconds, seamless loop.',
  horror:
    'Animate only the tattoo art on the skin. Dark ink drips and bleeds slowly through the design with eerie depth, veins throb and pulse beneath the lines, sinister shadows breathe and twist, a faint malevolent mist seeps just past the edges. Disturbing, intense, cinematic. The body and background remain completely still. 10 seconds, seamless loop.',
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
