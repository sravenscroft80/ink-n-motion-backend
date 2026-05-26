import 'package:ink_n_motion/models/video_generation_status.dart';

import 'package:ink_n_motion/state/app_state.dart';

import 'package:shared_preferences/shared_preferences.dart';



/// Local persistence for durable [AppState] fields via SharedPreferences.

class StorageService {

  StorageService({SharedPreferences? preferences})

      : _preferences = preferences;



  SharedPreferences? _preferences;



  static const String _keyCredits = 'ink_credits_balance';

  static const String _keyIsPremium = 'ink_is_premium_subscriber';

  static const String _keyRefundTimestamps = 'ink_refund_timestamps';

  static const String _keyGeneratedVideoPaths = 'ink_generated_video_paths';

  static const String _keyTotalVideosGenerated = 'ink_total_videos_generated';

  static const String _keyTotalRefundsRequested = 'ink_total_refunds_requested';

  static const String _keyAccountFlagged = 'ink_is_account_flagged_for_review';

  static const String _keyHasCompletedOnboarding = 'ink_has_completed_onboarding';

  static const String _keyAiCoachLastGenerationDay =

      'ink_ai_coach_last_generation_day';

  static const String _keyPremiumRendersThisMonth = 'ink_premium_renders_month';

  static const String _keyPremiumRenderResetDate = 'ink_premium_render_reset';

  static const String _keyEasyRendersToday = 'ink_easy_renders_today';

  static const String _keyEasyRenderResetDate = 'ink_easy_render_reset';

  static const String _keyShareUnlockUsedToday = 'ink_share_unlock_used_today';
  static const String _keyHomeTourViewCount = 'home_tour_view_count';



  String _todayDayKey() {

    final now = DateTime.now();

    final month = now.month.toString().padLeft(2, '0');

    final day = now.day.toString().padLeft(2, '0');

    return '${now.year}-$month-$day';

  }



  /// Free users get one AI Coach generation per calendar day.

  Future<bool> canGenerateAiCoachToday({required bool isPremium}) async {

    if (isPremium) return true;

    final prefs = await _prefs;

    final lastDay = prefs.getString(_keyAiCoachLastGenerationDay);

    return lastDay != _todayDayKey();

  }



  Future<void> recordAiCoachGeneration() async {

    final prefs = await _prefs;

    await prefs.setString(_keyAiCoachLastGenerationDay, _todayDayKey());

  }



  /// Share-to-unlock may grant bonus credits once per calendar day.

  Future<bool> canUseShareUnlockToday() async {

    final prefs = await _prefs;

    final lastDay = prefs.getString(_keyShareUnlockUsedToday);

    return lastDay != _todayDayKey();

  }



  Future<void> recordShareUnlockUsedToday() async {

    final prefs = await _prefs;

    await prefs.setString(_keyShareUnlockUsedToday, _todayDayKey());

  }

  /// How It Works modal — shown on the first two Home tab visits.
  Future<int> loadHomeTourViewCount() async {
    final prefs = await _prefs;
    return prefs.getInt(_keyHomeTourViewCount) ?? 0;
  }

  Future<void> incrementHomeTourViewCount() async {
    final prefs = await _prefs;
    final count = prefs.getInt(_keyHomeTourViewCount) ?? 0;
    await prefs.setInt(_keyHomeTourViewCount, count + 1);
  }



  Future<SharedPreferences> get _prefs async {

    return _preferences ??= await SharedPreferences.getInstance();

  }



  /// Local wallet fallback when Firebase/Firestore is unavailable.

  Future<({int creditBalance, bool isPremium})> loadWallet() async {

    final prefs = await _prefs;

    return (

      creditBalance: prefs.getInt(_keyCredits) ?? 10,

      isPremium: prefs.getBool(_keyIsPremium) ?? false,

    );

  }



  Future<void> saveWallet({

    required int creditBalance,

    required bool isPremium,

  }) async {

    final prefs = await _prefs;

    await Future.wait([

      prefs.setInt(_keyCredits, creditBalance),

      prefs.setBool(_keyIsPremium, isPremium),

    ]);

  }



  /// Preloads the platform preference store (optional boot optimization).

  Future<void> ensureInitialized() async {

    await _prefs;

  }



  /// Hydrates persisted fields; transient session fields use safe defaults.

  Future<AppState> loadPersistedState() async {

    final prefs = await _prefs;



    final timestampStrings = prefs.getStringList(_keyRefundTimestamps) ?? const [];

    final refundTimestamps = timestampStrings

        .map(DateTime.tryParse)

        .whereType<DateTime>()

        .toList(growable: false);



    return AppState(

      refundTimestamps: refundTimestamps,

      generatedVideoPaths:

          prefs.getStringList(_keyGeneratedVideoPaths) ?? const [],

      totalVideosGenerated: prefs.getInt(_keyTotalVideosGenerated) ?? 0,

      totalRefundsRequested: prefs.getInt(_keyTotalRefundsRequested) ?? 0,

      isAccountFlaggedForReview: prefs.getBool(_keyAccountFlagged) ?? false,

      hasCompletedOnboarding: prefs.getBool(_keyHasCompletedOnboarding) ?? false,

      premiumRendersThisMonth: prefs.getInt(_keyPremiumRendersThisMonth) ?? 0,

      premiumRenderResetDate:

          DateTime.tryParse(prefs.getString(_keyPremiumRenderResetDate) ?? ''),

      easyRendersToday: prefs.getInt(_keyEasyRendersToday) ?? 0,

      easyRenderResetDate:

          DateTime.tryParse(prefs.getString(_keyEasyRenderResetDate) ?? ''),

      videoGenerationStatus: VideoGenerationStatus.idle,

      navigateToPaywall: false,

    );

  }



  /// Writes all durable fields from [state] to disk.

  Future<void> savePersistedState(AppState state) async {

    final prefs = await _prefs;



    final timestampStrings = state.refundTimestamps

        .map((timestamp) => timestamp.toIso8601String())

        .toList(growable: false);



    final writes = <Future<bool>>[

      prefs.setStringList(_keyRefundTimestamps, timestampStrings),

      prefs.setStringList(_keyGeneratedVideoPaths, state.generatedVideoPaths),

      prefs.setInt(_keyTotalVideosGenerated, state.totalVideosGenerated),

      prefs.setInt(_keyTotalRefundsRequested, state.totalRefundsRequested),

      prefs.setBool(_keyAccountFlagged, state.isAccountFlaggedForReview),

      prefs.setBool(_keyHasCompletedOnboarding, state.hasCompletedOnboarding),

      prefs.setInt(_keyPremiumRendersThisMonth, state.premiumRendersThisMonth),

      prefs.setInt(_keyEasyRendersToday, state.easyRendersToday),

    ];



    final premiumReset = state.premiumRenderResetDate;

    if (premiumReset != null) {

      writes.add(

        prefs.setString(_keyPremiumRenderResetDate, premiumReset.toIso8601String()),

      );

    } else {

      writes.add(prefs.remove(_keyPremiumRenderResetDate));

    }



    final easyReset = state.easyRenderResetDate;

    if (easyReset != null) {

      writes.add(

        prefs.setString(_keyEasyRenderResetDate, easyReset.toIso8601String()),

      );

    } else {

      writes.add(prefs.remove(_keyEasyRenderResetDate));

    }



    await Future.wait(writes);

  }

}

