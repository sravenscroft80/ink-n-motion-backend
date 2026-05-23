const { logger } = require('../utils/logger');
const {
  initializeFirebaseAdmin,
  isFirebaseAdminConfigured,
  verifyFirebaseIdToken,
} = require('../services/firebase_admin');

function extractBearerToken(req) {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) return null;
  return authHeader.slice('Bearer '.length).trim();
}

/**
 * Optional auth — attaches decoded Firebase user when a valid token is present.
 */
async function optionalTokenAuth(req, res, next) {
  const token = extractBearerToken(req);
  if (!token) {
    return next();
  }

  if (!isFirebaseAdminConfigured()) {
    req.authToken = token;
    return next();
  }

  try {
    const decoded = await verifyFirebaseIdToken(token);
    req.authToken = token;
    req.firebaseUser = decoded;
    req.userId = decoded.uid;
    return next();
  } catch (error) {
    logger.warn('Optional Firebase auth rejected token', {
      path: req.originalUrl,
      message: error.message,
    });
    return res.status(401).json({
      error: 'unauthorized',
      message: 'Invalid Firebase ID token.',
    });
  }
}

/**
 * Requires a valid Firebase ID token for Studio render endpoints.
 */
async function requireFirebaseAuth(req, res, next) {
  const token = extractBearerToken(req);

  if (!token) {
    logger.warn('Rejected request: missing Firebase ID token', {
      path: req.originalUrl,
    });
    return res.status(401).json({
      error: 'unauthorized',
      message: 'Authorization Bearer Firebase ID token is required.',
    });
  }

  if (!initializeFirebaseAdmin()) {
    logger.error('Studio auth blocked: Firebase Admin SDK is not configured');
    return res.status(503).json({
      error: 'auth_not_configured',
      message: 'Firebase Admin credentials are not configured on the server.',
    });
  }

  try {
    const decoded = await verifyFirebaseIdToken(token);
    req.authToken = token;
    req.firebaseUser = decoded;
    req.userId = decoded.uid;

    logger.info('Firebase auth verified', {
      uid: decoded.uid,
      path: req.originalUrl,
    });

    return next();
  } catch (error) {
    logger.warn('Firebase auth verification failed', {
      path: req.originalUrl,
      message: error.message,
    });

    return res.status(401).json({
      error: 'unauthorized',
      message: 'Invalid or expired Firebase ID token.',
    });
  }
}

module.exports = {
  optionalTokenAuth,
  requireFirebaseAuth,
};
