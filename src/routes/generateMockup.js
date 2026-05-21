const express = require('express');
const { mockupGenerationLimiter } = require('../middleware/rateLimiter');
const {
  extractDiscoverySummary,
  summaryHasDesignFields,
  generateMockupImage,
} = require('../services/openAiMockupService');
const { logger } = require('../utils/logger');

const router = express.Router();

/**
 * POST /generate-mockup
 * Accepts `{ discovery_summary: { style, size, location, reasoning, estimated_time } }`
 * and returns `{ imageUrl, image_url }` from DALL-E 3.
 */
router.post('/', mockupGenerationLimiter, async (req, res) => {
  const requestStartedAt = Date.now();

  try {
    const discoverySummary = extractDiscoverySummary(req.body);

    if (!discoverySummary) {
      logger.warn('Rejected generate-mockup: missing discovery_summary');
      return res.status(400).json({
        error: 'bad_request',
        message: 'Missing or invalid discovery_summary payload.',
      });
    }

    if (!summaryHasDesignFields(discoverySummary)) {
      logger.warn('Rejected generate-mockup: empty discovery_summary');
      return res.status(400).json({
        error: 'bad_request',
        message:
          'discovery_summary must include at least one design field (style, size, location, reasoning, or estimated_time).',
      });
    }

    logger.info('Incoming generate-mockup request', {
      style: discoverySummary.style || null,
      location: discoverySummary.location || null,
      size: discoverySummary.size || null,
    });

    const { imageUrl } = await generateMockupImage(discoverySummary);

    logger.info('generate-mockup completed', {
      durationMs: Date.now() - requestStartedAt,
    });

    return res.status(200).json({
      imageUrl,
      image_url: imageUrl,
    });
  } catch (error) {
    logger.error('generate-mockup failed', {
      code: error.code || 'mockup_generation_failed',
      message: error.message,
      durationMs: Date.now() - requestStartedAt,
    });

    const statusCode = Number.isInteger(error.statusCode)
      ? error.statusCode
      : 500;

    return res.status(statusCode).json({
      error: error.code || 'mockup_generation_failed',
      message: error.message || 'Unable to generate mockup image.',
    });
  }
});

module.exports = router;
