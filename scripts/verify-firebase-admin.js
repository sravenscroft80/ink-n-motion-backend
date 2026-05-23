#!/usr/bin/env node
/**
 * Verifies Firebase Admin wiring for Studio auth.
 * Usage (local): FIREBASE_SERVICE_ACCOUNT_JSON='{"type":"service_account",...}' node scripts/verify-firebase-admin.js
 */
require('dotenv').config();

const {
  initializeFirebaseAdmin,
  isFirebaseAdminConfigured,
  verifyFirebaseIdToken,
} = require('../src/services/firebase_admin');
const { requireFirebaseAuth } = require('../src/middleware/token_auth');

function assert(condition, message) {
  if (!condition) {
    console.error(`FAIL: ${message}`);
    process.exit(1);
  }
}

async function main() {
  console.log('Firebase Admin integration check');
  console.log('─'.repeat(48));

  const configured = isFirebaseAdminConfigured();
  console.log(`FIREBASE_SERVICE_ACCOUNT_JSON set: ${Boolean(process.env.FIREBASE_SERVICE_ACCOUNT_JSON)}`);
  console.log(`GOOGLE_APPLICATION_CREDENTIALS set: ${Boolean(process.env.GOOGLE_APPLICATION_CREDENTIALS)}`);
  console.log(`Admin configured: ${configured}`);

  if (!configured) {
    console.warn(
      'WARN: No Admin credentials in this environment. Render must set FIREBASE_SERVICE_ACCOUNT_JSON.',
    );
    process.exit(0);
  }

  if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    const parsed = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
    assert(parsed.project_id, 'service account JSON missing project_id');
    assert(parsed.client_email, 'service account JSON missing client_email');
    assert(parsed.private_key, 'service account JSON missing private_key');
    console.log(`Service account project_id: ${parsed.project_id}`);
    console.log(`Service account client_email: ${parsed.client_email}`);
  }

  const initialized = initializeFirebaseAdmin();
  assert(initialized, 'Firebase Admin SDK failed to initialize');

  let missingTokenStatus;
  const fakeReq = { headers: {}, originalUrl: '/v1/studio/generate/health' };
  const fakeRes = {
    status(code) {
      missingTokenStatus = code;
      return this;
    },
    json(body) {
      console.log(`requireFirebaseAuth without token -> HTTP ${missingTokenStatus}`, body);
      return this;
    },
  };

  await requireFirebaseAuth(fakeReq, fakeRes, () => {});
  assert(missingTokenStatus === 401, 'Expected 401 when Bearer token is missing');

  try {
    await verifyFirebaseIdToken('not-a-real-token');
    assert(false, 'Expected invalid token verification to throw');
  } catch (error) {
    console.log(`Invalid token rejected as expected: ${error.code || error.message}`);
  }

  console.log('PASS: Firebase Admin + requireFirebaseAuth middleware are wired correctly.');
}

main().catch((error) => {
  console.error('FAIL:', error.message);
  process.exit(1);
});
