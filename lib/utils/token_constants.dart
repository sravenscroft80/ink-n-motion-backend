// ─── TOKEN COSTS ─────────────────────────────────────────────────────────────
// 1 token = $0.10 user value reference
// 5s render costs owner ~$0.40 Kling → earns $0.50 → 80% margin
// 10s render costs owner ~$0.60 Kling → earns $1.00 → 83% margin
// 2D AI concept costs owner ~$0.05 OpenAI → earns $0.30 → 83% margin

const int kTokenCost5sRender = 5;
const int kTokenCost10sRender = 10;
const int kTokenCost2dConcept = 3;

// ─── FREE LIFETIME TIER ──────────────────────────────────────────────────────
const int kFreeLifetime5sRenders = 3;
const int kFreeLifetime2dConcepts = 3;
const int kReferralRewardTokens = 10;
const int kSocialShareRewardTokens = 5;

// ─── PPV PACKS (never expire) ────────────────────────────────────────────────
const String kPpvSparkId = 'ink_ppv_spark_399';
const double kPpvSparkPrice = 3.99;
const int kPpvSparkTokens = 25;

const String kPpvBlazeId = 'ink_ppv_blaze_799';
const double kPpvBlazePrice = 7.99;
const int kPpvBlazeTokens = 55;

const String kPpvInfernoId = 'ink_ppv_inferno_1599';
const double kPpvInfernoPrice = 15.99;
const int kPpvInfernoTokens = 120;

// ─── MONTHLY SUBSCRIPTION TIERS ──────────────────────────────────────────────
const String kSubStarterId = 'ink_starter_monthly_999';
const double kSubStarterPrice = 9.99;
const int kSubStarterTokens = 80;
const int kSubStarterRolloverCap = 30;
const int kSubStarterConceptSoftCap = 20;
const int kSubStarterConceptHardCap = 26;

const String kSubPlusId = 'ink_plus_monthly_1999';
const double kSubPlusPrice = 19.99;
const int kSubPlusTokens = 200;
const int kSubPlusRolloverCap = 40;
const int kSubPlusConceptSoftCap = 40;
const int kSubPlusConceptHardCap = 50;
const int kSubPlusArtistPacksIncluded = 1;

const String kSubProId = 'ink_pro_monthly_3499';
const double kSubProPrice = 34.99;
const int kSubProTokens = 450;
const int kSubProRolloverCap = 60;
const int kSubProConceptSoftCap = 80;
const int kSubProConceptHardCap = 100;
const int kSubProArtistPacksIncluded = 3;

const String kSubStudioId = 'ink_studio_monthly_14900';
const double kSubStudioPrice = 149.00;
const int kSubStudioTokens = 2000;
const int kSubStudioRolloverCap = 100;
const int kSubStudioConceptSoftCap = 180;
const int kSubStudioConceptHardCap = 200;
const bool kSubStudioAllArtistPacksIncluded = true;

// ─── ARTIST PACK PRICING ─────────────────────────────────────────────────────
const double kArtistPackIndividualPrice = 4.99;
const int kArtistPackReferralUnlockCount = 2;

// ─── SOFT CAP WARNING THRESHOLD ──────────────────────────────────────────────
// Show warning when user hits this % of their monthly concept allowance
const double kConceptSoftCapWarningPercent = 0.80;

// ─── RENDER DURATION OPTIONS ─────────────────────────────────────────────────
// Kling API ONLY accepts "5" or "10" — no other values
const int kRenderDuration5s = 5;
const int kRenderDuration10s = 10;
const int kVideoLoopCount5s = 3;  // 5s loops 3x on playback = ~15s feel
const int kVideoLoopCount10s = 2; // 10s loops 2x on playback = ~20s feel
