import 'package:cloud_firestore/cloud_firestore.dart';

/// Token costs for each feature — single source of truth.
abstract final class InkTokenCost {
  static const int animateMyInk = 10;
  static const int coverupStudio = 3;
  static const int aiConcept = 1;
}

/// The user's wallet document, deserialized from Firestore.
class InkWallet {
  final int subscriptionTokens; // expires at renewalDate
  final int purchasedTokens; // never expires
  final bool freeVideoUsed;
  final bool freeCoverUpUsed;
  final String? lastFreeConceptDate; // "YYYY-MM-DD"
  final String? subscriptionTier; // "starter"|"plus"|"pro"|"studio"|null
  final DateTime? subscriptionRenewalDate;
  final int totalRendersCompleted;
  final String referralCode;
  final DateTime createdAt;

  const InkWallet({
    required this.subscriptionTokens,
    required this.purchasedTokens,
    required this.freeVideoUsed,
    required this.freeCoverUpUsed,
    required this.lastFreeConceptDate,
    required this.subscriptionTier,
    required this.subscriptionRenewalDate,
    required this.totalRendersCompleted,
    required this.referralCode,
    required this.createdAt,
  });

  /// Total spendable balance — subscription first, then purchased.
  int get totalBalance => subscriptionTokens + purchasedTokens;

  /// Today's date string in YYYY-MM-DD format (UTC).
  static String get todayString {
    final now = DateTime.now().toUtc();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Whether the user has their free daily concept available today.
  bool get hasFreeDailyConcept => lastFreeConceptDate != todayString;

  factory InkWallet.fromMap(Map<String, dynamic> map) {
    return InkWallet(
      subscriptionTokens: (map['subscriptionTokens'] as num?)?.toInt() ?? 0,
      purchasedTokens: (map['purchasedTokens'] as num?)?.toInt() ?? 0,
      freeVideoUsed: (map['freeVideoUsed'] as bool?) ?? false,
      freeCoverUpUsed: (map['freeCoverUpUsed'] as bool?) ?? false,
      lastFreeConceptDate: map['lastFreeConceptDate'] as String?,
      subscriptionTier: map['subscriptionTier'] as String?,
      subscriptionRenewalDate: map['subscriptionRenewalDate'] != null
          ? (map['subscriptionRenewalDate'] as Timestamp).toDate()
          : null,
      totalRendersCompleted:
          (map['totalRendersCompleted'] as num?)?.toInt() ?? 0,
      referralCode: (map['referralCode'] as String?) ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'subscriptionTokens': subscriptionTokens,
        'purchasedTokens': purchasedTokens,
        'freeVideoUsed': freeVideoUsed,
        'freeCoverUpUsed': freeCoverUpUsed,
        'lastFreeConceptDate': lastFreeConceptDate,
        'subscriptionTier': subscriptionTier,
        'subscriptionRenewalDate': subscriptionRenewalDate != null
            ? Timestamp.fromDate(subscriptionRenewalDate!)
            : null,
        'totalRendersCompleted': totalRendersCompleted,
        'referralCode': referralCode,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

/// All Firestore wallet operations for Ink-N-Motion.
class FirestoreWalletService {
  FirestoreWalletService._();
  static final FirestoreWalletService instance = FirestoreWalletService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _walletRef(String uid) =>
      _db.collection('users').doc(uid).collection('wallet').doc('balance');

  // ─── READ ────────────────────────────────────────────────────────────────

  /// Fetch the wallet once. Returns null if it doesn't exist yet.
  Future<InkWallet?> getWallet(String uid) async {
    final snap = await _walletRef(uid).get();
    if (!snap.exists || snap.data() == null) return null;
    return InkWallet.fromMap(snap.data()!);
  }

  /// Stream the wallet in real time — use this to drive the UI.
  Stream<InkWallet?> watchWallet(String uid) {
    return _walletRef(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return InkWallet.fromMap(snap.data()!);
    });
  }

  // ─── CREATE ──────────────────────────────────────────────────────────────

  /// Called once on first sign-in. Creates wallet with 10 purchased tokens.
  /// Uses set with merge:true so it's safe to call multiple times.
  Future<void> initializeWallet(String uid) async {
    final ref = _walletRef(uid);
    final snap = await ref.get();
    if (snap.exists) return; // already exists, do nothing

    final referralCode = _generateReferralCode(uid);

    await ref.set({
      'subscriptionTokens': 0,
      'purchasedTokens': 10, // welcome gift — covers first free animation
      'freeVideoUsed': false,
      'freeCoverUpUsed': false,
      'lastFreeConceptDate': null,
      'subscriptionTier': null,
      'subscriptionRenewalDate': null,
      'totalRendersCompleted': 0,
      'referralCode': referralCode,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── DEDUCT ──────────────────────────────────────────────────────────────

  /// Deduct tokens for a render. Burns subscription tokens first,
  /// then purchased tokens. Returns false if insufficient balance.
  Future<bool> deductTokens(String uid, int amount) async {
    final wallet = await getWallet(uid);
    if (wallet == null) return false;
    if (wallet.totalBalance < amount) return false;

    int subDeduct = 0;
    int purchDeduct = 0;

    if (wallet.subscriptionTokens >= amount) {
      subDeduct = amount;
    } else {
      subDeduct = wallet.subscriptionTokens;
      purchDeduct = amount - subDeduct;
    }

    await _walletRef(uid).update({
      'subscriptionTokens': FieldValue.increment(-subDeduct),
      'purchasedTokens': FieldValue.increment(-purchDeduct),
      'totalRendersCompleted': FieldValue.increment(1),
    });

    return true;
  }

  // ─── FREE USAGE CHECKS & CLAIMS ─────────────────────────────────────────

  /// Check + claim the free daily concept. Returns true if free render
  /// is available and marks it used for today.
  Future<bool> claimFreeDailyConcept(String uid) async {
    final wallet = await getWallet(uid);
    if (wallet == null) return false;
    if (!wallet.hasFreeDailyConcept) return false;

    await _walletRef(uid).update({
      'lastFreeConceptDate': InkWallet.todayString,
    });
    return true;
  }

  /// Check + claim the lifetime free video. Returns true if not yet used.
  Future<bool> claimFreeVideo(String uid) async {
    final wallet = await getWallet(uid);
    if (wallet == null) return false;
    if (wallet.freeVideoUsed) return false;

    await _walletRef(uid).update({'freeVideoUsed': true});
    return true;
  }

  /// Check + claim the lifetime free coverup. Returns true if not yet used.
  Future<bool> claimFreeCoverUp(String uid) async {
    final wallet = await getWallet(uid);
    if (wallet == null) return false;
    if (wallet.freeCoverUpUsed) return false;

    await _walletRef(uid).update({'freeCoverUpUsed': true});
    return true;
  }

  // ─── ADD TOKENS ──────────────────────────────────────────────────────────

  /// Add purchased tokens (never expire). Used after IAP purchase.
  Future<void> addPurchasedTokens(String uid, int amount) async {
    await _walletRef(uid).update({
      'purchasedTokens': FieldValue.increment(amount),
    });
  }

  /// Add subscription tokens (expire at renewal). Used after sub purchase.
  Future<void> addSubscriptionTokens(String uid, int amount) async {
    await _walletRef(uid).update({
      'subscriptionTokens': FieldValue.increment(amount),
    });
  }

  /// Add referral bonus tokens (treated as purchased — never expire).
  Future<void> addReferralBonus(String uid) async {
    await _walletRef(uid).update({
      'purchasedTokens': FieldValue.increment(10),
    });
  }

  /// Add social share bonus (one time — 5 tokens).
  Future<void> addSocialShareBonus(String uid) async {
    await _walletRef(uid).update({
      'purchasedTokens': FieldValue.increment(5),
    });
  }

  // ─── SUBSCRIPTION EXPIRY ─────────────────────────────────────────────────

  /// Called when a subscription renews or expires.
  /// If expired: zero out subscription tokens.
  /// If renewed: grant new monthly tokens based on tier.
  Future<void> handleSubscriptionRenewal(String uid, {
    required String? tier,
    required DateTime? renewalDate,
  }) async {
    final int newTokens = _tokensForTier(tier);
    await _walletRef(uid).update({
      'subscriptionTier': tier,
      'subscriptionTokens': newTokens,
      'subscriptionRenewalDate': renewalDate != null
          ? Timestamp.fromDate(renewalDate)
          : null,
    });
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────

  String _generateReferralCode(String uid) {
    final suffix = uid.length >= 6
        ? uid.substring(uid.length - 6).toUpperCase()
        : uid.toUpperCase();
    return 'INK$suffix';
  }

  int _tokensForTier(String? tier) {
    switch (tier) {
      case 'starter':
        return 50;
      case 'plus':
        return 120;
      case 'pro':
        return 250;
      case 'studio':
        return 1200;
      default:
        return 0;
    }
  }
}
