const { logger } = require('../utils/logger');

function isPlaceholderSecret(value) {
  if (!value || typeof value !== 'string') return true;
  const normalized = value.trim().toLowerCase();
  return (
    normalized.includes('placeholder') ||
    normalized.includes('your_secret') ||
    normalized.includes('your_runway') ||
    normalized === 'your_secret_ai_key_here' ||
    normalized === 'your_runway_key_here'
  );
}

/**
 * Validates deployment credentials before the HTTP listener binds.
 * In production, missing Replicate tokens log a critical warning and fall back to mock relay.
 */
function validateProductionEnvironment() {
  const isProduction = process.env.NODE_ENV === 'production';

  if (!isProduction) {
    logger.info('Environment validation skipped (NODE_ENV is not production)', {
      nodeEnv: process.env.NODE_ENV || 'development',
    });
    return {
      isProduction: false,
      replicateLiveRelayEnabled: false,
      warnings: [],
    };
  }

  const warnings = [];
  const replicateToken = process.env.REPLICATE_API_TOKEN;

  if (!replicateToken || !replicateToken.trim()) {
    const criticalMessage =
      '[ink-api-critical] Missing REPLICATE_API_TOKEN in production environment variables!';
    console.error(criticalMessage);
    logger.error(criticalMessage);
    warnings.push('missing_replicate_api_token');
  } else if (isPlaceholderSecret(replicateToken)) {
    const criticalMessage =
      '[ink-api-critical] REPLICATE_API_TOKEN is unset or still a placeholder in production!';
    console.error(criticalMessage);
    logger.error(criticalMessage);
    warnings.push('placeholder_replicate_api_token');
  }

  const replicateLiveRelayEnabled = warnings.length === 0;

  if (!replicateLiveRelayEnabled) {
    const fallbackMessage =
      '[ink-api-warning] Production will serve mock video URLs until REPLICATE_API_TOKEN is configured.';
    console.warn(fallbackMessage);
    logger.warn(fallbackMessage, { warnings });
  } else {
    logger.info('Production environment validation passed', {
      replicateConfigured: true,
    });
  }

  return {
    isProduction: true,
    replicateLiveRelayEnabled,
    warnings,
  };
}

module.exports = { validateProductionEnvironment };
