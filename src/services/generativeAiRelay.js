const fs = require('fs');
const axios = require('axios');
const { logger } = require('../utils/logger');

const REPLICATE_PREDICTIONS_URL = 'https://api.replicate.com/v1/predictions';
const MOCK_JOB_TTL_MS = 60 * 60 * 1000;
const MAX_MOCK_JOBS = 500;

/**
 * stability-ai/stable-video-diffusion-img2vid — override via REPLICATE_MODEL_VERSION.
 * @see https://replicate.com/stability-ai/stable-video-diffusion
 */
const DEFAULT_SVD_MODEL_VERSION =
  '3f0457e4619daac51203dedb472816fd4a51f94f6345a385c5268f6dbf029ed';

/** In-memory mock queue registry (placeholder API keys only). */
const mockJobRegistry = new Map();

/** Placeholder tokens from .env.example — triggers mock queue flow. */
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

function buildMockVideoUrl(styleId) {
  const stamp = Date.now();
  return `https://cdn.inknmotion.com/renders/mock/${styleId}/${stamp}.mp4`;
}

/**
 * Builds a data URI from the Sharp-optimized JPEG (or raw upload fallback).
 */
function readImageAsDataUri(imagePath, mimeType, optimizedImagePath) {
  const relayPath = optimizedImagePath || imagePath;
  const relayMime = optimizedImagePath ? 'image/jpeg' : mimeType || 'image/jpeg';
  const imageBuffer = fs.readFileSync(relayPath);
  const base64 = imageBuffer.toString('base64');
  return `data:${relayMime};base64,${base64}`;
}

/**
 * Maps Ink-N-Motion style_id values to SVD motion / pacing weights.
 */
function buildModelInput(styleId, inputImageDataUri) {
  const motionBucketByStyle = {
    cyberpunk_neon_glow: 200,
    traditional_japanese_ink_flow: 95,
    animated_pop_3d: 165,
    monochrome_shadow: 75,
  };

  const motion_bucket_id = motionBucketByStyle[styleId] ?? 127;

  return {
    input_image: inputImageDataUri,
    video_length: '25_frames_with_svd_xt',
    sizing_strategy: 'maintain_aspect_ratio',
    motion_bucket_id,
    frames_per_second: 6,
    cond_aug: 0.02,
    decoding_t: 7,
    style_id: styleId,
  };
}

function replicateHeaders(token) {
  return {
    Authorization: `Bearer ${token}`,
    'Content-Type': 'application/json',
  };
}

function pruneMockJobRegistry() {
  const now = Date.now();

  for (const [jobId, meta] of mockJobRegistry.entries()) {
    if (now - meta.createdAt > MOCK_JOB_TTL_MS) {
      mockJobRegistry.delete(jobId);
    }
  }

  if (mockJobRegistry.size <= MAX_MOCK_JOBS) {
    return;
  }

  const sorted = [...mockJobRegistry.entries()].sort(
    (a, b) => a[1].createdAt - b[1].createdAt,
  );
  const overflow = mockJobRegistry.size - MAX_MOCK_JOBS;
  for (let i = 0; i < overflow; i += 1) {
    mockJobRegistry.delete(sorted[i][0]);
  }
}

function registerMockJob(styleId) {
  const jobId = `mock-${Date.now()}-${styleId}`;
  mockJobRegistry.set(jobId, { styleId, createdAt: Date.now() });
  pruneMockJobRegistry();
  return jobId;
}

async function createReplicatePrediction(token, modelInput) {
  const version = process.env.REPLICATE_MODEL_VERSION || DEFAULT_SVD_MODEL_VERSION;

  const response = await axios.post(
    REPLICATE_PREDICTIONS_URL,
    {
      version,
      input: modelInput,
    },
    {
      headers: replicateHeaders(token),
      timeout: 30_000,
    },
  );

  const predictionId = response.data?.id;
  if (!predictionId) {
    throw new Error('Replicate create response missing prediction id');
  }

  logger.info('Replicate prediction queued upstream', {
    predictionId,
    status: response.data?.status,
  });

  return predictionId;
}

async function fetchReplicatePrediction(token, predictionId) {
  const response = await axios.get(`${REPLICATE_PREDICTIONS_URL}/${predictionId}`, {
    headers: {
      Authorization: `Bearer ${token}`,
    },
    timeout: 15_000,
  });

  return response.data;
}

function extractVideoUrlFromOutput(output) {
  if (typeof output === 'string' && output.length > 0) {
    return output;
  }
  if (Array.isArray(output) && output.length > 0 && typeof output[0] === 'string') {
    return output[0];
  }
  return null;
}

/**
 * Registers a generative job and returns a tracking id (no render polling).
 */
async function queueGenerativeVideoJob({
  imagePath,
  optimizedImagePath,
  styleId,
  mimeType,
}) {
  const replicateToken = process.env.REPLICATE_API_TOKEN;
  const relayImagePath = optimizedImagePath || imagePath;

  if (isPlaceholderSecret(replicateToken)) {
    const jobId = registerMockJob(styleId);
    logger.info('Queue registration (mock)', {
      jobId,
      styleId,
      optimized: Boolean(optimizedImagePath),
    });
    return {
      jobId,
      vendor: 'mock',
      mock: true,
    };
  }

  logger.info('AI relay: encoding optimized image for Replicate', {
    styleId,
    relayImagePath,
    optimized: Boolean(optimizedImagePath),
  });

  const inputImageDataUri = readImageAsDataUri(
    imagePath,
    mimeType,
    optimizedImagePath,
  );
  const modelInput = buildModelInput(styleId, inputImageDataUri);
  const jobId = await createReplicatePrediction(replicateToken, modelInput);

  logger.info('Queue registration (replicate)', { jobId, styleId });

  return {
    jobId,
    vendor: 'replicate',
    mock: false,
  };
}

/**
 * Status checkpoint — proxies Replicate prediction state to the mobile client.
 */
async function getGenerativeJobStatus(jobId) {
  if (!jobId || typeof jobId !== 'string') {
    throw new Error('job_id is required');
  }

  if (jobId.startsWith('mock-')) {
    pruneMockJobRegistry();
    const meta = mockJobRegistry.get(jobId);
    if (!meta) {
      return {
        status: 'failed',
        error: 'Unknown or expired mock job_id',
      };
    }

    return {
      status: 'succeeded',
      video_url: buildMockVideoUrl(meta.styleId),
      vendor: 'mock',
    };
  }

  const replicateToken = process.env.REPLICATE_API_TOKEN;
  if (isPlaceholderSecret(replicateToken)) {
    return {
      status: 'failed',
      error: 'Replicate API token is not configured',
    };
  }

  const prediction = await fetchReplicatePrediction(replicateToken, jobId);
  const status = prediction?.status ?? 'unknown';

  logger.info('Status checkpoint', { jobId, status });

  const payload = {
    status,
    job_id: jobId,
    vendor: 'replicate',
  };

  if (status === 'succeeded') {
    payload.video_url = extractVideoUrlFromOutput(prediction.output);
    if (!payload.video_url) {
      payload.status = 'failed';
      payload.error = 'Replicate succeeded but output MP4 URL is missing';
    }
  }

  if (status === 'failed' || status === 'canceled') {
    payload.error =
      typeof prediction?.error === 'string'
        ? prediction.error
        : JSON.stringify(prediction?.error ?? status);
  }

  return payload;
}

async function relayToRunway({ imagePath, styleId }) {
  const runwayKey = process.env.RUNWAY_API_KEY;
  if (isPlaceholderSecret(runwayKey)) {
    return null;
  }

  logger.info('AI relay: Runway path reserved', { styleId, imagePath });
  return null;
}

module.exports = {
  queueGenerativeVideoJob,
  getGenerativeJobStatus,
  relayToRunway,
  buildMockVideoUrl,
  DEFAULT_SVD_MODEL_VERSION,
};
