/**
 * Minimal structured request logging for production debugging.
 */
const logger = {
  info(message, meta = {}) {
    const payload = Object.keys(meta).length ? ` ${JSON.stringify(meta)}` : '';
    console.log(`[ink-api] INFO  ${message}${payload}`);
  },
  warn(message, meta = {}) {
    const payload = Object.keys(meta).length ? ` ${JSON.stringify(meta)}` : '';
    console.warn(`[ink-api] WARN  ${message}${payload}`);
  },
  error(message, meta = {}) {
    const payload = Object.keys(meta).length ? ` ${JSON.stringify(meta)}` : '';
    console.error(`[ink-api] ERROR ${message}${payload}`);
  },
};

module.exports = { logger };
