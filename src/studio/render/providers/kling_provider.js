const crypto = require('crypto');
const axios = require('axios');
const { logger } = require('../../../utils/logger');

const DEFAULT_KLING_BASE_URL = 'https://api.klingai.com/v1';
const JWT_TTL_SECONDS = 1800;

function isPlaceholderSecret(value) {
  if (!value || typeof value !== 'string') return true;
  const normalized = value.trim().toLowerCase();
  return (
    normalized.includes('placeholder') ||
    normalized.includes('your_kling') ||
    normalized.includes('your_secret') ||
    normalized === 'your_kling_access_key_here' ||
    normalized === 'your_kling_secret_key_here'
  );
}

function base64UrlEncode(input) {
  return Buffer.from(input)
    .toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

function signJwt(payload, secret) {
  const header = { alg: 'HS256', typ: 'JWT' };
  const encodedHeader = base64UrlEncode(JSON.stringify(header));
  const encodedPayload = base64UrlEncode(JSON.stringify(payload));
  const signature = crypto
    .createHmac('sha256', secret)
    .update(`${encodedHeader}.${encodedPayload}`)
    .digest('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');

  return `${encodedHeader}.${encodedPayload}.${signature}`;
}

function extractTaskId(responseData) {
  return (
    responseData?.data?.task_id ??
    responseData?.task_id ??
    responseData?.data?.id ??
    responseData?.id ??
    null
  );
}

function extractTaskStatus(responseData) {
  return (
    responseData?.data?.task_status ??
    responseData?.task_status ??
    responseData?.data?.status ??
    responseData?.status ??
    'unknown'
  );
}

function extractVideoUrl(responseData) {
  const taskResult = responseData?.data?.task_result ?? responseData?.task_result ?? {};
  const videos = taskResult?.videos ?? responseData?.data?.videos ?? responseData?.videos;

  if (Array.isArray(videos) && videos.length > 0) {
    const first = videos[0];
    if (typeof first === 'string') return first;
    if (first && typeof first.url === 'string') return first.url;
    if (first && typeof first.video_url === 'string') return first.video_url;
  }

  if (typeof taskResult?.video_url === 'string') return taskResult.video_url;
  if (typeof responseData?.data?.video_url === 'string') return responseData.data.video_url;

  return null;
}

function mapKlingStatus(rawStatus) {
  const normalized = (rawStatus || '').toLowerCase();

  if (['succeed', 'succeeded', 'success', 'completed', 'done'].includes(normalized)) {
    return 'succeeded';
  }
  if (['failed', 'error', 'canceled', 'cancelled'].includes(normalized)) {
    return 'failed';
  }
  if (['processing', 'running', 'in_progress', 'pending', 'submitted', 'queued'].includes(normalized)) {
    return 'processing';
  }

  return normalized || 'unknown';
}

/**
 * Kling 3.0 provider — async job pattern:
 *   POST /v1/videos/generations
 *   GET  /v1/tasks/{task_id}
 */
class KlingProvider {
  constructor(options = {}) {
    this.accessKey = options.accessKey ?? process.env.KLING_ACCESS_KEY;
    this.secretKey = options.secretKey ?? process.env.KLING_SECRET_KEY;
    this.baseUrl = (options.baseUrl ?? process.env.KLING_API_BASE_URL ?? DEFAULT_KLING_BASE_URL).replace(
      /\/$/,
      '',
    );
    this.timeoutMs = options.timeoutMs ?? 30_000;
  }

  isConfigured() {
    return !isPlaceholderSecret(this.accessKey) && !isPlaceholderSecret(this.secretKey);
  }

  buildAuthHeaders() {
    if (!this.isConfigured()) {
      throw new Error('kling_not_configured');
    }

    const now = Math.floor(Date.now() / 1000);
    const token = signJwt(
      {
        iss: this.accessKey,
        exp: now + JWT_TTL_SECONDS,
        nbf: now - 5,
      },
      this.secretKey,
    );

    return {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    };
  }

  /**
   * Submits an image-to-video generation job.
   *
   * @param {{
   *   prompt: string,
   *   image?: string,
   *   imageUrl?: string,
   *   duration?: number|string,
   *   mode?: string,
   *   modelName?: string,
   *   aspectRatio?: string,
   *   extra?: object
   * }} payload
   */
  async submitGeneration(payload) {
    const headers = this.buildAuthHeaders();
    const body = {
      model_name: payload.modelName ?? process.env.KLING_MODEL_NAME ?? 'kling-v3',
      prompt: payload.prompt,
      duration: String(payload.duration ?? '5'),
      mode: payload.mode ?? 'std',
      aspect_ratio: payload.aspectRatio ?? '16:9',
      ...(payload.image ? { image: payload.image } : {}),
      ...(payload.imageUrl ? { image_url: payload.imageUrl } : {}),
      ...(payload.extra ?? {}),
    };

    logger.info('Kling generation submit', {
      model: body.model_name,
      mode: body.mode,
      duration: body.duration,
      hasImage: Boolean(body.image || body.image_url),
    });

    const response = await axios.post(`${this.baseUrl}/videos/generations`, body, {
      headers,
      timeout: this.timeoutMs,
      validateStatus: (status) => status >= 200 && status < 500,
    });

    if (response.status >= 400) {
      const message =
        response.data?.message ??
        response.data?.error ??
        `Kling submit failed with HTTP ${response.status}`;
      throw new Error(`kling_submit_failed: ${message}`);
    }

    const taskId = extractTaskId(response.data);
    if (!taskId) {
      throw new Error('kling_bad_response: missing task_id');
    }

    logger.info('Kling generation queued', { taskId, status: extractTaskStatus(response.data) });

    return {
      taskId,
      vendor: 'kling',
      rawStatus: extractTaskStatus(response.data),
      raw: response.data,
    };
  }

  /**
   * Polls a Kling task by id.
   *
   * @param {string} taskId
   */
  async getTaskStatus(taskId) {
    if (!taskId || typeof taskId !== 'string') {
      throw new Error('task_id is required');
    }

    const headers = this.buildAuthHeaders();

    const response = await axios.get(`${this.baseUrl}/tasks/${encodeURIComponent(taskId)}`, {
      headers,
      timeout: this.timeoutMs,
      validateStatus: (status) => status >= 200 && status < 500,
    });

    if (response.status >= 400) {
      const message =
        response.data?.message ??
        response.data?.error ??
        `Kling status failed with HTTP ${response.status}`;
      throw new Error(`kling_status_failed: ${message}`);
    }

    const rawStatus = extractTaskStatus(response.data);
    const status = mapKlingStatus(rawStatus);
    const videoUrl = extractVideoUrl(response.data);

    const payload = {
      status,
      rawStatus,
      task_id: taskId,
      vendor: 'kling',
    };

    if (status === 'succeeded') {
      payload.video_url = videoUrl;
      if (!videoUrl) {
        payload.status = 'failed';
        payload.error = 'Kling succeeded but video URL is missing';
      }
    }

    if (status === 'failed') {
      payload.error =
        response.data?.data?.task_status_msg ??
        response.data?.message ??
        rawStatus ??
        'Kling task failed';
    }

    return payload;
  }
}

module.exports = {
  KlingProvider,
  isPlaceholderSecret,
};
