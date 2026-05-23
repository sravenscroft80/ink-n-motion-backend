// src/studio/klingProvider.js
// Kling AI v1 image-to-video provider (JWT auth, submit + poll)

const crypto = require('crypto');
const https = require('https');
const { logger } = require('../utils/logger');

const KLING_BASE = 'https://api.klingai.com';

// ─── JWT Builder ────────────────────────────────────────────────────────────
function buildKlingJwt() {
  const accessKey = process.env.KLING_ACCESS_KEY;
  const secretKey = process.env.KLING_SECRET_KEY;

  if (!accessKey || !secretKey) {
    throw new Error('KLING_ACCESS_KEY or KLING_SECRET_KEY env var missing');
  }

  const header = Buffer.from(JSON.stringify({ alg: 'HS256', typ: 'JWT' }))
    .toString('base64url');
  const now = Math.floor(Date.now() / 1000);
  const payload = Buffer.from(
    JSON.stringify({ iss: accessKey, exp: now + 1800, nbf: now - 5 })
  ).toString('base64url');

  const sig = crypto
    .createHmac('sha256', secretKey)
    .update(`${header}.${payload}`)
    .digest('base64url');

  return `${header}.${payload}.${sig}`;
}

// ─── HTTP helper ────────────────────────────────────────────────────────────
function klingRequest(method, path, body = null) {
  return new Promise((resolve, reject) => {
    const token = buildKlingJwt();
    const data = body ? JSON.stringify(body) : null;

    const options = {
      hostname: 'api.klingai.com',
      path,
      method,
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
        ...(data ? { 'Content-Length': Buffer.byteLength(data) } : {}),
      },
    };

    const req = https.request(options, (res) => {
      let raw = '';
      res.on('data', (chunk) => { raw += chunk; });
      res.on('end', () => {
        try {
          const parsed = JSON.parse(raw);
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve(parsed);
          } else {
            reject(Object.assign(new Error(`Kling ${res.statusCode}`), { response: { status: res.statusCode }, body: parsed }));
          }
        } catch {
          reject(new Error(`Kling non-JSON response: ${raw.slice(0, 200)}`));
        }
      });
    });

    req.on('error', reject);
    if (data) req.write(data);
    req.end();
  });
}

// ─── Submit image-to-video job ───────────────────────────────────────────────
// imageUrl: publicly accessible URL of the tattoo image
// durationSeconds: 5 or 10
// stylePrompt: style-specific prompt text
async function submitKlingJob({ imageUrl, durationSeconds = 5, stylePrompt = '' }) {
  const body = {
    model_name: 'kling-v1',
    image: imageUrl,
    prompt: stylePrompt || 'cinematic tattoo animation, flowing ink movement',
    duration: String(durationSeconds),
    cfg_scale: 0.5,
    mode: 'std',
  };

  logger.info('Submitting Kling i2v job', { durationSeconds, hasPrompt: Boolean(stylePrompt) });

  const result = await klingRequest('POST', '/v1/videos/image2video', body);

  const taskId = result?.data?.task_id;
  if (!taskId) {
    throw new Error(`Kling submit: no task_id in response — ${JSON.stringify(result).slice(0, 300)}`);
  }

  logger.info('Kling job submitted', { taskId });
  return taskId;
}

// ─── Poll job status ─────────────────────────────────────────────────────────
// Returns: { status: 'processing'|'succeed'|'failed', videoUrl: string|null }
async function pollKlingJob(taskId) {
  const result = await klingRequest('GET', `/v1/videos/image2video/${taskId}`);

  const taskStatus = result?.data?.task_status; // 'submitted' | 'processing' | 'succeed' | 'failed'
  const videoUrl =
    result?.data?.task_result?.videos?.[0]?.url ?? null;

  logger.info('Kling poll result', { taskId, taskStatus, hasVideo: Boolean(videoUrl) });

  return {
    status: taskStatus === 'succeed'
      ? 'succeed'
      : taskStatus === 'failed'
      ? 'failed'
      : 'processing',
    videoUrl,
    raw: result?.data,
  };
}

module.exports = { submitKlingJob, pollKlingJob };
