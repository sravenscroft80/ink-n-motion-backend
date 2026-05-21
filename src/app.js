const express = require('express');
const multer = require('multer');
const generateVideoRouter = require('./routes/generateVideo');
const generateMockupRouter = require('./routes/generateMockup');
const { MASK_DIR } = require('./services/tattooMaskEngine');
const { logger } = require('./utils/logger');

const app = express();
app.set('trust proxy', 1);
/** CORS — allows Flutter mobile / web clients during development. */
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  if (req.method === 'OPTIONS') { return res.sendStatus(204); }
  next();
});

app.use((req, res, next) => {
  const started = Date.now();
  res.on('finish', () => {
    logger.info('HTTP request completed', { method: req.method, path: req.originalUrl, status: res.statusCode, durationMs: Date.now() - started });
  });
  next();
});

app.use(express.json({ limit: '64kb' }));

app.get('/health', (_req, res) => {
  res.status(200).json({ status: 'ok', service: 'ink-n-motion-api' });
});

/** Routes */
app.use('/generate-mockup', generateMockupRouter);
app.use('/v1/generate', generateVideoRouter);
app.use('/uploads/masks', express.static(MASK_DIR));

app.use((err, req, res, _next) => {
  if (err instanceof multer.MulterError) {
    logger.warn('Multer error', { code: err.code, message: err.message });
    return res.status(400).json({ error: 'upload_error', message: err.message });
  }
  if (err.message?.includes('Unsupported image type')) {
    return res.status(400).json({ error: 'bad_request', message: err.message });
  }
  logger.error('Unhandled server error', { message: err.message });
  return res.status(500).json({ error: 'internal_error', message: 'An unexpected server error occurred.' });
});

module.exports = app;
