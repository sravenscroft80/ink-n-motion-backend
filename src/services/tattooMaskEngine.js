const fs = require('fs');
const path = require('path');
const sharp = require('sharp');
const { logger } = require('../utils/logger');

const MASK_DIR = path.join(__dirname, '..', '..', 'uploads', 'masks');
const MASK_THRESHOLD = 132;
const CONTRAST_LINEAR_A = 1.5;
const CONTRAST_LINEAR_B = -55;

const SPARKLE_STYLE_IDS = new Set(['animated_pop_3d', 'make_it_sparkle']);

if (!fs.existsSync(MASK_DIR)) {
  fs.mkdirSync(MASK_DIR, { recursive: true });
}

function isSparkleTrackStyle(styleId) {
  return SPARKLE_STYLE_IDS.has((styleId || '').trim());
}

/**
 * "Make it Sparkle" line mask — dark ink → solid black, skin → transparent PNG.
 */
async function generateTattooMask(optimizedImagePath) {
  const startedAt = Date.now();
  const inputBytes = fs.statSync(optimizedImagePath).size;

  const { data, info } = await sharp(optimizedImagePath)
    .rotate()
    .greyscale()
    .normalize()
    .linear(CONTRAST_LINEAR_A, CONTRAST_LINEAR_B)
    .raw()
    .toBuffer({ resolveWithObject: true });

  const { width, height, channels } = info;
  const pixelCount = width * height;
  const rgba = Buffer.alloc(pixelCount * 4);

  for (let i = 0; i < pixelCount; i += 1) {
    const lum = data[i * channels];
    const isInk = lum < MASK_THRESHOLD;

    rgba[i * 4] = 0;
    rgba[i * 4 + 1] = 0;
    rgba[i * 4 + 2] = 0;
    rgba[i * 4 + 3] = isInk ? 255 : 0;
  }

  const maskFileName = `mask-${Date.now()}-${Math.random().toString(36).slice(2, 10)}.png`;
  const maskPath = path.join(MASK_DIR, maskFileName);

  await sharp(rgba, {
    raw: {
      width,
      height,
      channels: 4,
    },
  })
    .png({ compressionLevel: 9, adaptiveFiltering: true })
    .toFile(maskPath);

  const outputBytes = fs.statSync(maskPath).size;
  const durationMs = Date.now() - startedAt;

  logger.info('Tattoo line mask generated', {
    optimizedImagePath,
    maskPath,
    inputBytes,
    outputBytes,
    durationMs,
    width,
    height,
  });

  console.log(
    `[ink-api] Line mask: ${inputBytes} bytes → ${outputBytes} bytes ` +
      `in ${durationMs}ms · ${maskPath}`,
  );

  return {
    maskPath,
    maskFileName,
    inputBytes,
    outputBytes,
    durationMs,
  };
}

module.exports = {
  generateTattooMask,
  isSparkleTrackStyle,
  MASK_DIR,
  SPARKLE_STYLE_IDS,
};
