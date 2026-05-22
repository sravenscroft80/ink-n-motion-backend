const axios = require('axios');
const { logger } = require('../utils/logger');

const OPENAI_IMAGES_URL = 'https://api.openai.com/v1/images/generations';
const DEFAULT_IMAGE_MODEL = 'gpt-image-1';
const DEFAULT_SIZE = '1024x1024';
const OPENAI_TIMEOUT_MS = 120_000;

function resolveImageModel() {
  const fromEnv = process.env.OPENAI_IMAGE_MODEL;
  if (typeof fromEnv === 'string' && fromEnv.trim().length > 0) {
    return fromEnv.trim();
  }
  return DEFAULT_IMAGE_MODEL;
}

function isPlaceholderSecret(value) {
  if (!value || typeof value !== 'string') return true;
  const normalized = value.trim().toLowerCase();
  return (
    normalized.includes('placeholder') ||
    normalized.includes('your_secret') ||
    normalized.includes('your_openai') ||
    normalized === 'your_secret_ai_key_here' ||
    normalized === 'sk-your_openai_key_here'
  );
}

function normalizeDiscoverySummary(raw) {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) {
    return null;
  }

  const readString = (value) =>
    typeof value === 'string' ? value.trim() : '';

  return {
    style: readString(raw.style),
    size: readString(raw.size),
    location: readString(raw.location),
    reasoning: readString(raw.reasoning),
    estimatedTime: readString(raw.estimated_time ?? raw.estimatedTime),
  };
}

/**
 * Accepts `{ discovery_summary: {...} }` or `{ discoverySummary: {...} }`.
 */
function extractDiscoverySummary(body) {
  if (!body || typeof body !== 'object') {
    return null;
  }

  const nested = body.discovery_summary ?? body.discoverySummary;
  if (nested) {
    return normalizeDiscoverySummary(nested);
  }

  if (body.style || body.reasoning || body.location || body.size) {
    return normalizeDiscoverySummary(body);
  }

  return null;
}

function summaryHasDesignFields(summary) {
  return Boolean(
    summary.style ||
      summary.size ||
      summary.location ||
      summary.reasoning ||
      summary.estimatedTime,
  );
}

function buildMockupPrompt(summary) {
  const parts = [
    'Create a high-quality 2D tattoo design concept illustration.',
    'Professional tattoo flash sheet style on a clean neutral background.',
    'No skin, no body parts, no watermark, no text overlay.',
  ];

  if (summary.style) {
    parts.push(`Tattoo style: ${summary.style}.`);
  }
  if (summary.size) {
    parts.push(`Approximate size: ${summary.size}.`);
  }
  if (summary.location) {
    parts.push(`Intended body placement: ${summary.location}.`);
  }
  if (summary.reasoning) {
    parts.push(`Creative vision: ${summary.reasoning}.`);
  }
  if (summary.estimatedTime) {
    parts.push(`Session context: ${summary.estimatedTime}.`);
  }

  return parts.join(' ');
}

/**
 * Calls OpenAI DALL-E 3 and returns a hosted image URL.
 */
async function generateMockupImage(discoverySummary) {
  const apiKey = process.env.OPENAI_API_KEY;

  if (!apiKey || !apiKey.trim() || isPlaceholderSecret(apiKey)) {
    const error = new Error(
      'OpenAI API key is not configured. Set OPENAI_API_KEY in the server environment.',
    );
    error.code = 'missing_openai_key';
    error.statusCode = 503;
    throw error;
  }

  const prompt = buildMockupPrompt(discoverySummary);
  const model = resolveImageModel();

  logger.info('OpenAI mockup generation starting', {
    model,
    size: DEFAULT_SIZE,
    promptLength: prompt.length,
  });

  try {
    const response = await axios.post(
      OPENAI_IMAGES_URL,
      {
        model,
        prompt,
        n: 1,
        size: DEFAULT_SIZE,
      },
      {
        headers: {
          Authorization: `Bearer ${apiKey.trim()}`,
          'Content-Type': 'application/json',
        },
        timeout: OPENAI_TIMEOUT_MS,
        validateStatus: (status) => status != null && status < 600,
      },
    );

    const status = response.status ?? 0;
    if (status < 200 || status >= 300) {
      const upstreamMessage =
        response.data?.error?.message ||
        `OpenAI returned HTTP ${status}`;

      const error = new Error(upstreamMessage);
      error.code = 'openai_upstream_error';
      error.statusCode = status === 429 ? 429 : 502;
      throw error;
    }

    const imageUrl = response.data?.data?.[0]?.url;
    if (typeof imageUrl !== 'string' || imageUrl.trim().length === 0) {
      const error = new Error('OpenAI response missing image URL.');
      error.code = 'openai_bad_response';
      error.statusCode = 502;
      throw error;
    }

    return {
      imageUrl: imageUrl.trim(),
      prompt,
    };
  } catch (error) {
    if (error.code) {
      throw error;
    }

    const upstreamStatus = error.response?.status;
    const upstreamMessage =
      error.response?.data?.error?.message ||
      error.message ||
      'OpenAI image generation failed.';

    logger.error('OpenAI mockup generation failed', {
      status: upstreamStatus ?? null,
      message: upstreamMessage,
    });

    const wrapped = new Error(upstreamMessage);
    wrapped.code = 'openai_upstream_error';
    wrapped.statusCode = upstreamStatus === 429 ? 429 : 502;
    throw wrapped;
  }
}

module.exports = {
  extractDiscoverySummary,
  summaryHasDesignFields,
  buildMockupPrompt,
  generateMockupImage,
};
