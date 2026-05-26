/// Outcome of attempting to start premium video generation.
enum PremiumGenerationStartResult {
  started,
  insufficientCredits,
  monthlyLimitReached,
}

/// Outcome of attempting to start easy video generation.
enum EasyGenerationStartResult {
  started,
  dailyLimitReached,
}

/// Outcome of a refund request against rolling window rules.
enum RefundRequestResult {
  approved,
  rejectedEmptyTag,
  limitReached,
}
