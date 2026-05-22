const axios = require('axios');
const { logger } = require('../utils/logger');

const OPENAI_IMAGES_URL = 'https://api.openai.com/v1/images/generations';
const DEFAULT_IMAGE_MODEL = 'gpt-image-1';
const DEFAULT_SIZE = '1024x1024';
const DEFAULT_QUALITY = 'medium';
const DEFAULT_OUTPUT_FORMAT = 'png';
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

function isGptImageModel(model) {
  return typeof model === 'string' && model.startsWith('gpt-image');
}

function buildImageGenerationRequest(model, prompt) {
  const body = {
    model,
    prompt,
    n: 1,
    size: DEFAULT_SIZE,
  };

  if (isGptImageModel(model)) {
    body.quality = DEFAULT_QUALITY;
    body.output_format = DEFAULT_OUTPUT_FORMAT;
  } else {
    body.response_format = 'url';
    body.quality = 'standard';
  }

  return body;
}

function resolveImageFromOpenAiResponse(responseData) {
  const item = responseData?.data?.[0];
  if (!item || typeof item !== 'object') {
    return null;
  }

  if (typeof item.url === 'string' && item.url.trim().length > 0) {
    return { imageUrl: item.url.trim(), imageBase64: null };
  }

  if (typeof item.b64_json === 'string' && item.b64_json.trim().length > 0) {
    const imageBase64 = item.b64_json.trim();
    return {
      imageUrl: `data:image/png;base64,${imageBase64}`,
      imageBase64,
    };
  }

  return null;
}

/**
 * Calls OpenAI Images API and returns a display URL (hosted or data URI).
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
  const requestBody = buildImageGenerationRequest(model, prompt);

  logger.info('OpenAI mockup generation starting', {
    model,
    size: DEFAULT_SIZE,
    quality: requestBody.quality ?? null,
    outputFormat: requestBody.output_format ?? null,
    promptLength: prompt.length,
  });

  try {
    const response = await axios.post(OPENAI_IMAGES_URL, requestBody, {
      headers: {
        Authorization: `Bearer ${apiKey.trim()}`,
        'Content-Type': 'application/json',
      },
      timeout: OPENAI_TIMEOUT_MS,
      validateStatus: (status) => status != null && status < 600,
    });

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

    const resolved = resolveImageFromOpenAiResponse(response.data);
    if (!resolved) {
      logger.error('OpenAI mockup generation returned unexpected payload', {
        model,
        dataKeys: Object.keys(response.data ?? {}),
        firstItemKeys: Object.keys(response.data?.data?.[0] ?? {}),
      });
      const error = new Error(
        'OpenAI response missing image data (expected url or b64_json).',
      );
      error.code = 'openai_bad_response';
      error.statusCode = 502;
      throw error;
    }

    logger.info('OpenAI mockup generation succeeded', {
      model,
      delivery: resolved.imageBase64 ? 'base64' : 'url',
    });

    return {
      imageUrl: resolved.imageUrl,
      imageBase64: resolved.imageBase64,
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
