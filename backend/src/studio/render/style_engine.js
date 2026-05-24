/**
 * Style Engine — maps styleId → cinematic prompts and subjectType → motion presets.
 */

const PROMPT_TEMPLATES = {
  alex_grey: {
    adjectives: [
      'ethereal',
      'anatomical',
      'translucent layers',
      'cosmic gradient',
      'meditative glow',
    ],
    basePrompt:
      'Cinematic tattoo animation, {adjectives}, subtle camera drift, sacred anatomy lighting',
  },
  cyberpunk: {
    adjectives: ['neon-drenched', 'electric haze', 'rain-slick reflections', 'holographic'],
    basePrompt: 'Cyberpunk tattoo reveal, {adjectives}, pulsing grid energy',
  },
  cyberpunk_neon_glow: {
    adjectives: ['neon-drenched', 'electric haze', 'rain-slick reflections', 'holographic'],
    basePrompt: 'Cyberpunk tattoo reveal, {adjectives}, pulsing grid energy',
  },
  traditional_japanese: {
    adjectives: ['ink wash', 'flowing sumi-e', 'misty depth', 'hand-brushed texture'],
    basePrompt: 'Japanese irezumi motion, {adjectives}, organic fluid movement',
  },
  traditional_japanese_ink_flow: {
    adjectives: ['ink wash', 'flowing sumi-e', 'misty depth', 'hand-brushed texture'],
    basePrompt: 'Japanese irezumi motion, {adjectives}, organic fluid movement',
  },
  animated_pop_3d: {
    adjectives: ['sparkling particles', 'pop-art contrast', 'playful depth'],
    basePrompt: 'Animated tattoo sparkle effect, {adjectives}, light burst motion',
  },
  monochrome_shadow: {
    adjectives: ['high contrast', 'chiaroscuro', 'slow shadow play'],
    basePrompt: 'Monochrome tattoo study, {adjectives}, dramatic studio lighting',
  },
  alex_grey_visionary: {
    adjectives: [],
    basePrompt:
      'visionary psychedelic tattoo animation, sacred geometry fractals flowing, alex grey inspired neural tapestry, bioluminescent patterns breathing, consciousness expanding motion',
  },
  steampunk_clockwork: {
    adjectives: [],
    basePrompt:
      'steampunk tattoo animation, brass gears rotating, copper pipe steam venting, clockwork mechanisms ticking, Victorian industrial motion, warm sepia tones',
  },
  anime_cel_shaded: {
    adjectives: [],
    basePrompt:
      'anime cel-shaded tattoo animation, bold ink outlines pulsing, vibrant flat colours, manga speed lines radiating, Japanese animation style motion',
  },
  gothic_horror: {
    adjectives: [],
    basePrompt:
      'gothic horror tattoo animation, dark shadows crawling, moonlit fog drifting, ravens circling, candlelight flickering, dramatic chiaroscuro motion',
  },
  default: {
    adjectives: ['cinematic', 'high contrast', 'studio lighting'],
    basePrompt: 'Premium tattoo motion study, {adjectives}',
  },
};

const LifeMotion = {
  default: {
    motion_bucket_id: 145,
    fps: 6,
    cond_aug: 0.03,
    duration_seconds: 5,
    label: 'breathing_life',
  },
  subtle: {
    motion_bucket_id: 110,
    fps: 5,
    cond_aug: 0.02,
    duration_seconds: 5,
    label: 'gentle_breath',
  },
  vivid: {
    motion_bucket_id: 185,
    fps: 7,
    cond_aug: 0.04,
    duration_seconds: 5,
    label: 'living_pulse',
  },
};

const PulseMotion = {
  default: {
    motion_bucket_id: 200,
    fps: 8,
    cond_aug: 0.01,
    duration_seconds: 5,
    label: 'geometric_pulse',
  },
  slow: {
    motion_bucket_id: 160,
    fps: 6,
    cond_aug: 0.01,
    duration_seconds: 5,
    label: 'slow_rhythm',
  },
  strobe: {
    motion_bucket_id: 230,
    fps: 10,
    cond_aug: 0.005,
    duration_seconds: 5,
    label: 'sharp_strobe',
  },
};

const NeutralMotion = {
  default: {
    motion_bucket_id: 127,
    fps: 6,
    cond_aug: 0.02,
    duration_seconds: 5,
    label: 'balanced',
  },
};

const MOTION_BY_SUBJECT = {
  animal: LifeMotion,
  portrait: LifeMotion,
  organic: LifeMotion,
  geometric: PulseMotion,
  abstract: PulseMotion,
  symbol: PulseMotion,
  default: NeutralMotion,
};

const VALID_SUBJECT_TYPES = new Set([
  'animal',
  'portrait',
  'organic',
  'geometric',
  'abstract',
  'symbol',
  'default',
]);

function normalizeSubjectType(subjectType) {
  const normalized = (subjectType || 'default').trim().toLowerCase();
  return VALID_SUBJECT_TYPES.has(normalized) ? normalized : 'default';
}

function resolvePromptTemplate(styleId) {
  const key = (styleId || '').trim();
  return PROMPT_TEMPLATES[key] ?? PROMPT_TEMPLATES.default;
}

function resolveMotionPreset(subjectType, motionPreset) {
  const family = MOTION_BY_SUBJECT[subjectType] ?? MOTION_BY_SUBJECT.default;
  const presetKey = (motionPreset || 'default').trim().toLowerCase();
  return family[presetKey] ?? family.default;
}

function resolveMotionFamily(subjectType) {
  if (subjectType === 'geometric' || subjectType === 'abstract' || subjectType === 'symbol') {
    return 'PulseMotion';
  }
  if (subjectType === 'animal' || subjectType === 'portrait' || subjectType === 'organic') {
    return 'LifeMotion';
  }
  return 'NeutralMotion';
}

/**
 * Builds the render specification consumed by RenderEngine providers.
 *
 * @param {{ subjectType?: string, styleId: string, motionPreset?: string }} params
 * @returns {{
 *   styleId: string,
 *   subjectType: string,
 *   motionPreset: string,
 *   prompt: string,
 *   motion: object,
 *   metadata: { motionFamily: string, templateKey: string }
 * }}
 */
function composeRenderSpec({ subjectType, styleId, motionPreset }) {
  const normalizedStyleId = (styleId || '').trim() || 'default';
  const normalizedSubject = normalizeSubjectType(subjectType);
  const normalizedPreset = (motionPreset || 'default').trim().toLowerCase() || 'default';

  const template = resolvePromptTemplate(normalizedStyleId);
  const motion = resolveMotionPreset(normalizedSubject, normalizedPreset);
  const adjectivePhrase = template.adjectives.join(', ');
  const prompt = template.basePrompt.replace('{adjectives}', adjectivePhrase);

  const templateKey = PROMPT_TEMPLATES[normalizedStyleId] ? normalizedStyleId : 'default';

  return {
    styleId: normalizedStyleId,
    subjectType: normalizedSubject,
    motionPreset: normalizedPreset,
    prompt,
    motion,
    metadata: {
      motionFamily: resolveMotionFamily(normalizedSubject),
      templateKey,
    },
  };
}

module.exports = {
  composeRenderSpec,
  normalizeSubjectType,
  PROMPT_TEMPLATES,
  LifeMotion,
  PulseMotion,
  NeutralMotion,
};
