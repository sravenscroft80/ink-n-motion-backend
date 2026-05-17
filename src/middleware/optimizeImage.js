const fs = require('fs');
const path = require('path');
const sharp = require('sharp');
const { logger } = require('../utils/logger');

const MAX_EDGE_PX = 1024;
const JPEG_QUALITY = 85;

/**
 * Sharp pipeline — EXIF orient, resize (max edge 1024), JPEG @ 85% quality.
 * Sets `req.file.optimizedPath` for downstream Replicate relay.
 */
async function optimizeImage(req, res, next) {
  if (!req.file?.path) {
    return next();
  }

  const originalPath = req.file.path;
  let originalBytes = 0;

  try {
    originalBytes = fs.statSync(originalPath).size;
  } catch (statError) {
    logger.warn('Image optimization: unable to stat upload', {
      path: originalPath,
      message: statError.message,
    });
    return res.status(400).json({
      error: 'image_processing_failed',
      message: 'Uploaded image could not be read. Please try a different file.',
    });
  }

  const parsed = path.parse(originalPath);
  const optimizedPath = path.join(
    parsed.dir,
    `${parsed.name}-optimized.jpg`,
  );

  try {
    await sharp(originalPath)
      .rotate()
      .resize(MAX_EDGE_PX, MAX_EDGE_PX, {
        fit: 'inside',
        withoutEnlargement: true,
      })
      .jpeg({ quality: JPEG_QUALITY, mozjpeg: true })
      .toFile(optimizedPath);

    const optimizedBytes = fs.statSync(optimizedPath).size;
    const reductionPct =
      originalBytes > 0
        ? Number((((originalBytes - optimizedBytes) / originalBytes) * 100).toFixed(1))
        : 0;

    req.file.optimizedPath = optimizedPath;
    req.file.mimetype = 'image/jpeg';

    logger.info('Image optimization complete', {
      originalPath,
      optimizedPath,
      originalBytes,
      optimizedBytes,
      reductionPct,
      maxEdgePx: MAX_EDGE_PX,
    });

    console.log(
      `[ink-api] Image optimized: ${originalBytes} bytes → ${optimizedBytes} bytes ` +
        `(${reductionPct}% reduction) · ${optimizedPath}`,
    );

    return next();
  } catch (error) {
    logger.error('Image optimization failed', {
      originalPath,
      message: error.message,
    });

    if (fs.existsSync(optimizedPath)) {
      fs.unlink(optimizedPath, () => {});
    }

    return res.status(400).json({
      error: 'image_processing_failed',
      message:
        'The uploaded image appears corrupted or unsupported. Please export as JPEG or PNG and retry.',
    });
  }
}

module.exports = { optimizeImage };
