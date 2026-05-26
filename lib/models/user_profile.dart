import 'package:ink_n_motion/services/user_service.dart';

/// Legacy profile model — retained for Firebase sync compatibility.
/// New token/wallet logic lives in InkWallet inside user_service.dart.
class UserProfile {
  const UserProfile({
    required this.creditBalance,
    required this.isPremium,
    this.tier = InkTier.free,
    this.tokenBalance = 0,
    this.rolloverTokens = 0,
    this.lifetimeFreeRendersUsed = 0,
    this.lifetimeFreeConceptsUsed = 0,
    this.monthlyConceptsUsed = 0,
    this.premiumRendersThisMonth = 0,
    this.premiumRenderResetDate,
    this.easyRendersToday = 0,
    this.easyRenderResetDate,
    this.tierRenewDate,
  });

  // Legacy fields — kept for backward compat
  final int creditBalance;
  final bool isPremium;
  final int premiumRendersThisMonth;
  final DateTime? premiumRenderResetDate;
  final int easyRendersToday;
  final DateTime? easyRenderResetDate;

  // New token fields
  final InkTier tier;
  final int tokenBalance;
  final int rolloverTokens;
  final int lifetimeFreeRendersUsed;
  final int lifetimeFreeConceptsUsed;
  final int monthlyConceptsUsed;
  final DateTime? tierRenewDate;

  /// Convert profile into an InkWallet for use in UserService
  InkWallet toWallet() => InkWallet(
        tokenBalance: tokenBalance,
        rolloverTokens: rolloverTokens,
        tier: tier,
        lifetimeFreeRendersUsed: lifetimeFreeRendersUsed,
        lifetimeFreeConceptsUsed: lifetimeFreeConceptsUsed,
        monthlyConceptsUsed: monthlyConceptsUsed,
        tierRenewDate: tierRenewDate,
        isSubscriber: isPremium,
      );
}
