require('dotenv').config();

const http = require('http');
const app = require('./src/app');
const { logger } = require('./src/utils/logger');
const { validateProductionEnvironment } = require('./src/config/validateEnvironment');

const deploymentEnv = validateProductionEnvironment();

const PORT = Number(process.env.PORT) || 5001;
const REQUEST_TIMEOUT_MS = 120_000;

const server = http.createServer(app);
server.setTimeout(REQUEST_TIMEOUT_MS);
server.headersTimeout = REQUEST_TIMEOUT_MS + 5_000;

server.listen(PORT, () => {
  logger.info('Ink-N-Motion API listening', {
    port: PORT,
    nodeEnv: process.env.NODE_ENV || 'development',
    basePath: '/v1',
    generateEndpoint: 'POST /v1/generate/video',
    mockupEndpoint: 'POST /generate-mockup',
    healthEndpoint: 'GET /health',
    timeoutMs: REQUEST_TIMEOUT_MS,
    replicateLiveRelayEnabled: deploymentEnv.replicateLiveRelayEnabled,
    deploymentWarnings: deploymentEnv.warnings,
  });
});

server.on('error', (error) => {
  logger.error('Server failed to start', { message: error.message });
  process.exit(1);
});

process.on('SIGINT', () => {
  logger.info('Shutting down gracefully (SIGINT)');
  server.close(() => process.exit(0));
});

process.on('SIGTERM', () => {
  logger.info('Shutting down gracefully (SIGTERM)');
  server.close(() => process.exit(0));
});
