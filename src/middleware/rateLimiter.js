const rateLimit = require('express-rate-limit');
const { logger } = require('../utils/logger');

const GENERATION_WINDOW_MS = 15 * 60 * 1000;
const GENERATION_MAX_PER_IP = 5;
const STATUS_WINDOW_MS = 60 * 1000;
const STATUS_MAX_PER_IP = 100;

/** Strict flood shield for expensive video generation uploads. */
const videoGenerationLimiter = rateLimit({
  windowMs: GENERATION_WINDOW_MS,
  max: GENERATION_MAX_PER_IP,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res, _next, options) => {
    logger.warn('Video generation rate limit exceeded', {
      ip: req.ip,
      path: req.originalUrl,
      windowMs: options.windowMs,
      max: options.max,
    });

    res.status(429).json({
      error: 'Too many generations initiated. Please slow down and wait a few minutes.',
    });
  },
});

/** Balanced flood shield for Flutter status polling (3s cadence). */
const statusPollingLimiter = rateLimit({
  windowMs: STATUS_WINDOW_MS,
  max: STATUS_MAX_PER_IP,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res, _next, options) => {
    logger.warn('Status polling rate limit exceeded', {
      ip: req.ip,
      path: req.originalUrl,
      windowMs: options.windowMs,
      max: options.max,
    });

    res.status(429).json({
      error: 'Too many status checks. Please slow down polling.',
    });
  },
});

module.exports = {
  videoGenerationLimiter,
  statusPollingLimiter,
};
