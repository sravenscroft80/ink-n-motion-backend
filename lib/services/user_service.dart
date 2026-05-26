import 'package:firebase_auth/firebase_auth.dart';
import 'package:ink_n_motion/models/user_profile.dart';
import 'package:ink_n_motion/services/firebase_auth_service.dart';
import 'package:ink_n_motion/utils/token_constants.dart';

/// Tier identifiers — match RevenueCat product IDs exactly
enum InkTier {
  free,
  starter,
  plus,
  pro,
  studio,
}

/// Wallet holds token balance + tier + rollover state
class InkWallet {
  final int tokenBalance;
  final int rolloverTokens;
  final InkTier tier;
  final int lifetimeFreeRendersUsed;
  final int lifetimeFreeConceptsUsed;
  final int monthlyConceptsUsed;
  final DateTime? tierRenewDate;
  final bool isSubscriber;

  const InkWallet({
    this.tokenBalance = 0,
    this.rolloverTokens = 0,
    this.tier = InkTier.free,
    this.lifetimeFreeRendersUsed = 0,
    this.lifetimeFreeConceptsUsed = 0,
    this.monthlyConceptsUsed = 0,
    this.tierRenewDate,
    this.isSubscriber = false,
  });

  /// Total spendable tokens = balance + rollover
  int get spendable => tokenBalance + rolloverTokens;

  /// Free renders remaining (lifetime)
  int get freeRendersRemaining =>
      (kFreeLifetime5sRenders - lifetimeFreeRendersUsed).clamp(0, kFreeLifetime5sRenders);

  /// Free concepts remaining (lifetime)
  int get freeConceptsRemaining =>
      (kFreeLifetime2dConcepts - lifetimeFreeConceptsUsed).clamp(0, kFreeLifetime2dConcepts);

  /// Whether user can do a free 5s render
  bool get hasFreeRenderAvailable => freeRendersRemaining > 0;

  /// Whether user can do a free concept
  bool get hasFreeConceptAvailable => freeConceptsRemaining > 0;

  /// Can afford a 5s paid render
  bool get canAfford5sRender => spendable >= kTokenCost5sRender;

  /// Can afford a 10s paid render
  bool get canAfford10sRender => spendable >= kTokenCost10sRender;

  /// Can afford a 2D concept
  bool get canAffordConcept => spendable >= kTokenCost2dConcept;

  /// Rollover cap for current tier
  int get rolloverCap {
    switch (tier) {
      case InkTier.starter: return kSubStarterRolloverCap;
      case InkTier.plus:    return kSubPlusRolloverCap;
      case InkTier.pro:     return kSubProRolloverCap;
      case InkTier.studio:  return kSubStudioRolloverCap;
      case InkTier.free:    return 0;
    }
  }

  /// Monthly concept soft cap for current tier
  int get conceptSoftCap {
    switch (tier) {
      case InkTier.starter: return kSubStarterConceptSoftCap;
      case InkTier.plus:    return kSubPlusConceptSoftCap;
      case InkTier.pro:     return kSubProConceptSoftCap;
      case InkTier.studio:  return kSubStudioConceptSoftCap;
      case InkTier.free:    return kFreeLifetime2dConcepts;
    }
  }

  /// Monthly concept hard cap for current tier
  int get conceptHardCap {
    switch (tier) {
      case InkTier.starter: return kSubStarterConceptHardCap;
      case InkTier.plus:    return kSubPlusConceptHardCap;
      case InkTier.pro:     return kSubProConceptHardCap;
      case InkTier.studio:  return kSubStudioConceptHardCap;
      case InkTier.free:    return kFreeLifetime2dConcepts;
    }
  }

  /// Whether to show soft cap warning
  bool get showConceptWarning =>
      isSubscriber &&
      conceptSoftCap > 0 &&
      monthlyConceptsUsed >= (conceptSoftCap * kConceptSoftCapWarningPercent).floor();

  /// Whether concept hard cap is reached
  bool get conceptHardCapReached =>
      isSubscriber && monthlyConceptsUsed >= conceptHardCap;

  /// Display label for tier
  String get tierLabel {
    switch (tier) {
      case InkTier.free:    return 'Free';
      case InkTier.starter: return 'Ink Starter';
      case InkTier.plus:    return 'Ink Plus';
      case InkTier.pro:     return 'Ink Pro';
      case InkTier.studio:  return 'Studio Pro';
    }
  }

  InkWallet copyWith({
    int? tokenBalance,
    int? rolloverTokens,
    InkTier? tier,
    int? lifetimeFreeRendersUsed,
    int? lifetimeFreeConceptsUsed,
    int? monthlyConceptsUsed,
    DateTime? tierRenewDate,
    bool? isSubscriber,
  }) {
    return InkWallet(
      tokenBalance: tokenBalance ?? this.tokenBalance,
      rolloverTokens: rolloverTokens ?? this.rolloverTokens,
      tier: tier ?? this.tier,
      lifetimeFreeRendersUsed: lifetimeFreeRendersUsed ?? this.lifetimeFreeRendersUsed,
      lifetimeFreeConceptsUsed: lifetimeFreeConceptsUsed ?? this.lifetimeFreeConceptsUsed,
      monthlyConceptsUsed: monthlyConceptsUsed ?? this.monthlyConceptsUsed,
      tierRenewDate: tierRenewDate ?? this.tierRenewDate,
      isSubscriber: isSubscriber ?? this.isSubscriber,
    );
  }
}

class UserService {
  UserService({required FirebaseAuthService authService})
      : _authService = authService;

  // ignore: unused_field
  final FirebaseAuthService _authService;

  bool get isAvailable {
    try {
      FirebaseAuth.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  // Local wallet state (will be replaced by Firestore once Firebase auth is wired)
  InkWallet _wallet = const InkWallet();
  InkWallet get wallet => _wallet;

  Future<UserProfile?> loadProfile() async => null;

  Future<String> ensureAnonymousAuth() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
    return auth.currentUser!.uid;
  }

  String? getCurrentUid() {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  /// Deduct tokens for a 5s render (or use free lifetime render)
  /// Returns true if render is allowed, false if insufficient balance
  bool consumeRender5s() {
    if (_wallet.hasFreeRenderAvailable) {
      _wallet = _wallet.copyWith(
        lifetimeFreeRendersUsed: _wallet.lifetimeFreeRendersUsed + 1,
      );
      return true;
    }
    if (_wallet.canAfford5sRender) {
      _wallet = _wallet.copyWith(
        tokenBalance: _wallet.tokenBalance - kTokenCost5sRender,
      );
      return true;
    }
    return false;
  }

  /// Deduct tokens for a 10s render
  /// Returns true if render is allowed, false if insufficient balance
  bool consumeRender10s() {
    if (_wallet.canAfford10sRender) {
      _wallet = _wallet.copyWith(
        tokenBalance: _wallet.tokenBalance - kTokenCost10sRender,
      );
      return true;
    }
    return false;
  }

  /// Deduct tokens for a 2D concept (or use free lifetime concept)
  /// Returns true if allowed, false if hard cap reached or insufficient balance
  bool consumeConcept() {
    if (_wallet.conceptHardCapReached) return false;
    if (_wallet.hasFreeConceptAvailable) {
      _wallet = _wallet.copyWith(
        lifetimeFreeConceptsUsed: _wallet.lifetimeFreeConceptsUsed + 1,
        monthlyConceptsUsed: _wallet.monthlyConceptsUsed + 1,
      );
      return true;
    }
    if (_wallet.canAffordConcept) {
      _wallet = _wallet.copyWith(
        tokenBalance: _wallet.tokenBalance - kTokenCost2dConcept,
        monthlyConceptsUsed: _wallet.monthlyConceptsUsed + 1,
      );
      return true;
    }
    return false;
  }

  /// Add tokens (PPV purchase or referral reward)
  void addTokens(int amount) {
    _wallet = _wallet.copyWith(
      tokenBalance: _wallet.tokenBalance + amount,
    );
  }

  /// Called on monthly renewal — reset monthly usage, apply rollover
  void applyMonthlyRenewal(int newTokenAllocation) {
    final unused = _wallet.tokenBalance;
    final rollover = unused.clamp(0, _wallet.rolloverCap);
    _wallet = _wallet.copyWith(
      tokenBalance: newTokenAllocation,
      rolloverTokens: rollover,
      monthlyConceptsUsed: 0,
    );
  }

  /// Legacy sync method — kept for compatibility, will be replaced by Firestore
  Future<void> syncWallet({
    required int creditBalance,
    required bool isPremium,
    int premiumRendersThisMonth = 0,
    DateTime? premiumRenderResetDate,
    int easyRendersToday = 0,
    DateTime? easyRenderResetDate,
  }) async {
    _wallet = _wallet.copyWith(
      tokenBalance: creditBalance,
      tier: isPremium ? InkTier.plus : InkTier.free,
      isSubscriber: isPremium,
    );
  }
}
