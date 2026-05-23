const admin = require('firebase-admin');
const { logger } = require('../utils/logger');

let initAttempted = false;

function isFirebaseAdminConfigured() {
  return Boolean(
    process.env.FIREBASE_SERVICE_ACCOUNT_JSON ||
      process.env.GOOGLE_APPLICATION_CREDENTIALS,
  );
}

function initializeFirebaseAdmin() {
  if (initAttempted) return admin.apps.length > 0;
  initAttempted = true;

  if (admin.apps.length > 0) {
    return true;
  }

  if (!isFirebaseAdminConfigured()) {
    logger.warn('Firebase Admin SDK not configured — Studio auth verification disabled');
    return false;
  }

  try {
    if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
    } else {
      admin.initializeApp({
        credential: admin.credential.applicationDefault(),
      });
    }

    logger.info('Firebase Admin SDK initialized', {
      projectId: admin.app().options.projectId,
    });
    return true;
  } catch (error) {
    logger.error('Firebase Admin SDK initialization failed', {
      message: error.message,
    });
    return false;
  }
}

/**
 * Verifies a Firebase ID token from the Authorization Bearer header.
 *
 * @param {string} idToken
 * @returns {Promise<import('firebase-admin/auth').DecodedIdToken>}
 */
async function verifyFirebaseIdToken(idToken) {
  if (!initializeFirebaseAdmin()) {
    throw new Error('firebase_admin_not_configured');
  }

  return admin.auth().verifyIdToken(idToken);
}

module.exports = {
  initializeFirebaseAdmin,
  isFirebaseAdminConfigured,
  verifyFirebaseIdToken,
};
