const axios = require('axios');
const sharp = require('sharp');
const { logger } = require('../utils/logger');

const OPENAI_IMAGES_URL = 'https://api.openai.com/v1/images/generations';
const OPENAI_EDITS_URL = 'https://api.openai.com/v1/images/edits';
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

function buildImageGenerationRequest(model, prompt, qualityOverride) {
  const body = {
    model,
    prompt,
    n: 1,
    size: DEFAULT_SIZE,
  };

  if (isGptImageModel(model)) {
    body.quality = normalizeQualityForModel(model, qualityOverride ?? DEFAULT_QUALITY);
    body.output_format = DEFAULT_OUTPUT_FORMAT;
  } else {
    body.response_format = 'url';
    body.quality = qualityOverride ?? 'standard';
  }

  return body;
}

function normalizeQualityForModel(model, quality) {
  if (isGptImageModel(model)) {
    if (quality === 'standard') {
      return 'medium';
    }
    return quality || DEFAULT_QUALITY;
  }
  return quality || 'standard';
}

function getOpenAiApiKey() {
  const apiKey = process.env.OPENAI_API_KEY;

  if (!apiKey || !apiKey.trim() || isPlaceholderSecret(apiKey)) {
    const error = new Error(
      'OpenAI API key is not configured. Set OPENAI_API_KEY in the server environment.',
    );
    error.code = 'missing_openai_key';
    error.statusCode = 503;
    throw error;
  }

  return apiKey.trim();
}

function wrapOpenAiAxiosError(error, fallbackMessage) {
  if (error.code) {
    return error;
  }

  const upstreamStatus = error.response?.status;
  const upstreamMessage =
    error.response?.data?.error?.message ||
    error.message ||
    fallbackMessage;

  logger.error(fallbackMessage, {
    status: upstreamStatus ?? null,
    message: upstreamMessage,
  });

  const wrapped = new Error(upstreamMessage);
  wrapped.code = 'openai_upstream_error';
  wrapped.statusCode = upstreamStatus === 429 ? 429 : 502;
  return wrapped;
}

async function requestOpenAiImageGeneration(prompt, options = {}) {
  const apiKey = getOpenAiApiKey();
  const model = resolveImageModel();
  const requestBody = buildImageGenerationRequest(
    model,
    prompt,
    options.quality,
  );

  logger.info('OpenAI image generation starting', {
    operation: options.operation || 'generation',
    model,
    size: DEFAULT_SIZE,
    quality: requestBody.quality ?? null,
    outputFormat: requestBody.output_format ?? null,
    promptLength: prompt.length,
  });

  try {
    const response = await axios.post(OPENAI_IMAGES_URL, requestBody, {
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      timeout: OPENAI_TIMEOUT_MS,
      validateStatus: (status) => status != null && status < 600,
    });

    const status = response.status ?? 0;
    if (status < 200 || status >= 300) {
      const upstreamMessage =
        response.data?.error?.message || `OpenAI returned HTTP ${status}`;

      const error = new Error(upstreamMessage);
      error.code = 'openai_upstream_error';
      error.statusCode = status === 429 ? 429 : 502;
      throw error;
    }

    const resolved = resolveImageFromOpenAiResponse(response.data);
    if (!resolved) {
      logger.error('OpenAI image generation returned unexpected payload', {
        operation: options.operation || 'generation',
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

    logger.info('OpenAI image generation succeeded', {
      operation: options.operation || 'generation',
      model,
      delivery: resolved.imageBase64 ? 'base64' : 'url',
    });

    return {
      imageUrl: resolved.imageUrl,
      imageBase64: resolved.imageBase64,
      prompt,
    };
  } catch (error) {
    throw wrapOpenAiAxiosError(error, 'OpenAI image generation failed');
  }
}

function buildConceptPrompt(userPrompt, style) {
  const parts = [
    'Create a high-quality 2D tattoo design concept illustration.',
    'Professional tattoo flash sheet style on a clean neutral background.',
    'No skin, no body parts, no watermark, no text overlay.',
  ];

  const trimmedPrompt = typeof userPrompt === 'string' ? userPrompt.trim() : '';
  if (trimmedPrompt) {
    parts.push(`Design description: ${trimmedPrompt}.`);
  }

  const trimmedStyle = typeof style === 'string' ? style.trim() : '';
  if (trimmedStyle) {
    parts.push(`Style context: ${trimmedStyle}.`);
  }

  return parts.join(' ');
}

async function generateConceptImage({ prompt, style }) {
  const trimmedPrompt = typeof prompt === 'string' ? prompt.trim() : '';
  if (!trimmedPrompt) {
    const error = new Error('prompt is required');
    error.code = 'bad_request';
    error.statusCode = 400;
    throw error;
  }

  const imagePrompt = buildConceptPrompt(trimmedPrompt, style);
  return requestOpenAiImageGeneration(imagePrompt, {
    operation: 'generate-concept',
    quality: 'standard',
  });
}

async function prepareImageBufferForEdit(imageBuffer) {
  return sharp(imageBuffer)
    .rotate()
    .resize(1024, 1024, {
      fit: 'contain',
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    })
    .png()
    .toBuffer();
}

function resolveCoverupEditModel() {
  const fromEnv = process.env.OPENAI_IMAGE_EDIT_MODEL;
  if (typeof fromEnv === 'string' && fromEnv.trim().length > 0) {
    return fromEnv.trim();
  }
  return resolveImageModel();
}

async function requestOpenAiImageEdit(imageBuffer, prompt, options = {}) {
  const apiKey = getOpenAiApiKey();
  const primaryModel = options.model || resolveCoverupEditModel();
  const editPrompt = `Tattoo coverup design: ${prompt}`;
  const pngBuffer = await prepareImageBufferForEdit(imageBuffer);

  const attemptEdit = async (model) => {
    const form = new FormData();
    form.append(
      'image',
      new Blob([pngBuffer], { type: 'image/png' }),
      'image.png',
    );
    form.append('prompt', editPrompt);
    form.append('model', model);
    form.append('size', DEFAULT_SIZE);
    form.append('n', '1');

    if (!isGptImageModel(model)) {
      form.append('response_format', 'b64_json');
    }

    logger.info('OpenAI image edit starting', {
      operation: options.operation || 'edit',
      model,
      size: DEFAULT_SIZE,
      promptLength: editPrompt.length,
      imageBytes: pngBuffer.length,
    });

    const response = await axios.post(OPENAI_EDITS_URL, form, {
      headers: {
        Authorization: `Bearer ${apiKey}`,
      },
      timeout: OPENAI_TIMEOUT_MS,
      validateStatus: (status) => status != null && status < 600,
    });

    const status = response.status ?? 0;
    if (status < 200 || status >= 300) {
      const upstreamMessage =
        response.data?.error?.message || `OpenAI returned HTTP ${status}`;

      const error = new Error(upstreamMessage);
      error.code = 'openai_upstream_error';
      error.statusCode = status === 429 ? 429 : 502;
      throw error;
    }

    const resolved = resolveImageFromOpenAiResponse(response.data);
    if (!resolved) {
      const error = new Error(
        'OpenAI response missing image data (expected url or b64_json).',
      );
      error.code = 'openai_bad_response';
      error.statusCode = 502;
      throw error;
    }

    logger.info('OpenAI image edit succeeded', {
      operation: options.operation || 'edit',
      model,
      delivery: resolved.imageBase64 ? 'base64' : 'url',
    });

    return resolved;
  };

  try {
    try {
      return await attemptEdit(primaryModel);
    } catch (error) {
      if (
        primaryModel !== 'dall-e-2' &&
        error.code === 'openai_upstream_error'
      ) {
        logger.warn('OpenAI image edit failed on primary model, retrying dall-e-2', {
          primaryModel,
          message: error.message,
        });
        return await attemptEdit('dall-e-2');
      }
      throw error;
    }
  } catch (error) {
    throw wrapOpenAiAxiosError(error, 'OpenAI image edit failed');
  }
}

async function generateCoverupImage({ imageBuffer, prompt }) {
  const trimmedPrompt = typeof prompt === 'string' ? prompt.trim() : '';
  if (!trimmedPrompt) {
    const error = new Error('prompt is required');
    error.code = 'bad_request';
    error.statusCode = 400;
    throw error;
  }

  if (!imageBuffer || !Buffer.isBuffer(imageBuffer) || imageBuffer.length === 0) {
    const error = new Error('image is required');
    error.code = 'bad_request';
    error.statusCode = 400;
    throw error;
  }

  const resolved = await requestOpenAiImageEdit(imageBuffer, trimmedPrompt, {
    operation: 'generate-coverup',
  });

  return {
    imageUrl: resolved.imageUrl,
    imageBase64: resolved.imageBase64,
    prompt: `Tattoo coverup design: ${trimmedPrompt}`,
  };
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
  const prompt = buildMockupPrompt(discoverySummary);
  return requestOpenAiImageGeneration(prompt, { operation: 'generate-mockup' });
}

module.exports = {
  extractDiscoverySummary,
  summaryHasDesignFields,
  buildMockupPrompt,
  buildConceptPrompt,
  generateMockupImage,
  generateConceptImage,
  generateCoverupImage,
};
