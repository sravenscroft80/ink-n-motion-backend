const fs = require('fs');
const path = require('path');
const sharp = require('sharp');
const { normalizeSubjectType } = require('../render/style_engine');
const { logger } = require('../../utils/logger');

const MAX_EDGE_PX = 1024;
const JPEG_QUALITY = 85;

function parseDiscoverySummary(raw) {
  if (!raw) return null;
  if (typeof raw === 'object') return raw;

  if (typeof raw === 'string' && raw.trim()) {
    try {
      return JSON.parse(raw);
    } catch {
      return null;
    }
  }

  return null;
}

function inferSubjectFromDiscoverySummary(summary) {
  if (!summary || typeof summary !== 'object') return null;

  const blob = [summary.style, summary.reasoning, summary.location]
    .filter(Boolean)
    .join(' ')
    .toLowerCase();

  if (!blob) return null;

  if (/\b(wolf|lion|snake|bird|dragon|animal|pet|koi|tiger|bear)\b/.test(blob)) {
    return 'animal';
  }
  if (/\b(mandala|geometry|hexagon|grid|dotwork|sacred geometry|symmetry)\b/.test(blob)) {
    return 'geometric';
  }
  if (/\b(portrait|face|realism)\b/.test(blob)) {
    return 'portrait';
  }

  return null;
}

function resolveSubjectType({ clientSubjectType, discoverySummary }) {
  const normalizedClient = normalizeSubjectType(clientSubjectType);
  if (clientSubjectType && normalizedClient !== 'default') {
    return {
      subjectType: normalizedClient,
      subjectSource: 'client',
      subjectConfidence: 1,
    };
  }

  const inferred = inferSubjectFromDiscoverySummary(discoverySummary);
  if (inferred) {
    return {
      subjectType: inferred,
      subjectSource: 'text',
      subjectConfidence: 0.75,
    };
  }

  return {
    subjectType: 'default',
    subjectSource: 'default',
    subjectConfidence: 0.5,
  };
}

async function normalizeUploadedImage(file) {
  if (!file?.path) {
    throw new Error('prep_missing_file');
  }

  if (file.optimizedPath && fs.existsSync(file.optimizedPath)) {
    const optimizedBytes = fs.statSync(file.optimizedPath).size;
    const metadata = await sharp(file.optimizedPath).metadata();

    return {
      optimizedPath: file.optimizedPath,
      mimeType: 'image/jpeg',
      originalPath: file.path,
      optimizedBytes,
      width: metadata.width ?? null,
      height: metadata.height ?? null,
      reusedOptimization: true,
    };
  }

  const originalPath = file.path;
  const parsed = path.parse(originalPath);
  const optimizedPath = path.join(parsed.dir, `${parsed.name}-studio-prep.jpg`);

  await sharp(originalPath)
    .rotate()
    .resize(MAX_EDGE_PX, MAX_EDGE_PX, {
      fit: 'inside',
      withoutEnlargement: true,
    })
    .jpeg({ quality: JPEG_QUALITY, mozjpeg: true })
    .toFile(optimizedPath);

  const metadata = await sharp(optimizedPath).metadata();
  const optimizedBytes = fs.statSync(optimizedPath).size;

  file.optimizedPath = optimizedPath;
  file.mimetype = 'image/jpeg';

  return {
    optimizedPath,
    mimeType: 'image/jpeg',
    originalPath,
    optimizedBytes,
    width: metadata.width ?? null,
    height: metadata.height ?? null,
    reusedOptimization: false,
  };
}

function readImageBase64(optimizedPath) {
  return fs.readFileSync(optimizedPath).toString('base64');
}

/**
 * Normalizes an uploaded tattoo image and resolves subject metadata for render.
 *
 * @param {{
 *   file: Express.Multer.File,
 *   styleId: string,
 *   subjectType?: string,
 *   motionPreset?: string,
 *   discoverySummary?: object|string|null
 * }} input
 */
async function prepare({
  file,
  styleId,
  subjectType,
  motionPreset,
  discoverySummary,
}) {
  const startedAt = Date.now();
  const normalizedStyleId = (styleId || '').trim();
  if (!normalizedStyleId) {
    throw new Error('prep_missing_style_id');
  }

  const parsedSummary = parseDiscoverySummary(discoverySummary);
  const subjectResolution = resolveSubjectType({
    clientSubjectType: subjectType,
    discoverySummary: parsedSummary,
  });

  const image = await normalizeUploadedImage(file);
  const imageBase64 = readImageBase64(image.optimizedPath);

  const result = {
    styleId: normalizedStyleId,
    subjectType: subjectResolution.subjectType,
    subjectSource: subjectResolution.subjectSource,
    subjectConfidence: subjectResolution.subjectConfidence,
    motionPreset: (motionPreset || 'default').trim().toLowerCase() || 'default',
    optimizedPath: image.optimizedPath,
    originalPath: image.originalPath,
    mimeType: image.mimeType,
    imageBase64,
    width: image.width,
    height: image.height,
    optimizedBytes: image.optimizedBytes,
    discoverySummary: parsedSummary,
    prepDurationMs: Date.now() - startedAt,
  };

  logger.info('PrepEngine complete', {
    styleId: result.styleId,
    subjectType: result.subjectType,
    subjectSource: result.subjectSource,
    optimizedBytes: result.optimizedBytes,
    prepDurationMs: result.prepDurationMs,
  });

  return result;
}

module.exports = {
  prepare,
  normalizeUploadedImage,
  resolveSubjectType,
};
