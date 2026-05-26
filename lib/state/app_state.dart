import 'dart:typed_data';

import 'package:ink_n_motion/models/video_generation_status.dart';

/// Central application state — wallet, generation limits, and session fields.
class AppState {
  const AppState({
    this.creditsBalance = 10,
    this.isPremiumSubscriber = false,
    this.videoGenerationStatus = VideoGenerationStatus.idle,
    this.refundTimestamps = const [],
    this.totalVideosGenerated = 0,
    this.totalRefundsRequested = 0,
    this.isAccountFlaggedForReview = false,
    this.navigateToPaywall = false,
    this.selectedImagePath,
    this.selectedImageBytes,
    this.selectedStyleTemplateId,
    this.dynamicOutputVideoPath,
    this.generatedVideoPaths = const [],
    this.currentQueueStep,
    this.rateLimitBlockedMessage,
    this.monthlyLimitMessage,
    this.isDeviceOfflineMode = false,
    this.hasCompletedOnboarding = false,
    this.isLocalOverlay = false,
    this.sparkleMaskUrl,
    this.premiumRendersThisMonth = 0,
    this.premiumRenderResetDate,
    this.easyRendersToday = 0,
    this.easyRenderResetDate,
    this.outputHasWatermark = true,
  });

  // Token costs — aligned with token_constants.dart
  // 5s render = 5 tokens, 10s render = 10 tokens
  static const int kPremiumCreditCost = 5;
  static const int kPremiumCreditCostTenSecond = 10;
  static const int premiumGenerationCreditCost = kPremiumCreditCost;

  /// Credits restored on an approved rolling-window refund.
  static const int refundCreditsRestored = kPremiumCreditCost;

  /// Premium subscribers may render up to this many premium videos per cycle.
  static const int premiumMonthlyRenderCap = 30;

  /// Free users may run this many easy renders per calendar day.
  static const int freeEasyRendersPerDay = 2;

  /// Bonus credits granted via share-to-unlock (once per day).
  static const int shareUnlockCreditsGranted = 5;

  static const int rollingRefundCap = 2;
  static const Duration rollingRefundWindow = Duration(hours: 24);

  static const double accountReviewRefundRatioThreshold = 0.50;
  static const int accountReviewMinVideosGenerated = 4;

  final int creditsBalance;
  final bool isPremiumSubscriber;
  final VideoGenerationStatus videoGenerationStatus;
  final List<DateTime> refundTimestamps;
  final int totalVideosGenerated;
  final int totalRefundsRequested;
  final bool isAccountFlaggedForReview;
  final bool navigateToPaywall;
  final String? selectedImagePath;
  final Uint8List? selectedImageBytes;
  final String? selectedStyleTemplateId;
  final String? dynamicOutputVideoPath;
  final List<String> generatedVideoPaths;

  /// Live Replicate queue phase (`queued`, `starting`, `processing`, `finalizing`).
  final String? currentQueueStep;

  /// Backend HTTP 429 message — transient UI only (not persisted).
  final String? rateLimitBlockedMessage;

  /// Premium monthly cap message — transient UI only (not persisted).
  final String? monthlyLimitMessage;

  /// True when generation failed due to socket/connection loss (not persisted).
  final bool isDeviceOfflineMode;

  /// First-time carousel completed — persisted via SharedPreferences.
  final bool hasCompletedOnboarding;

  /// Make it Sparkle — instant mask overlay track (session only).
  final bool isLocalOverlay;

  final String? sparkleMaskUrl;

  /// Premium subscriber render count for the active billing cycle.
  final int premiumRendersThisMonth;

  /// When the premium render cycle resets (30 days from first render of cycle).
  final DateTime? premiumRenderResetDate;

  /// Free-tier easy render count for the current calendar day.
  final int easyRendersToday;

  /// Start of the next calendar day — easy count resets after this instant.
  final DateTime? easyRenderResetDate;

  /// Whether the latest output should show a preview watermark overlay.
  final bool outputHasWatermark;

  List<DateTime> get activeRefundTimestamps {
    final cutoff = DateTime.now().subtract(rollingRefundWindow);
    return refundTimestamps.where((t) => t.isAfter(cutoff)).toList(growable: false);
  }

  int get activeRefundCount => activeRefundTimestamps.length;

  bool get canRequestRefund => activeRefundCount < rollingRefundCap;

  int get refundsRemaining =>
      (rollingRefundCap - activeRefundCount).clamp(0, rollingRefundCap);

  double get refundRatio => totalVideosGenerated == 0
      ? 0.0
      : totalRefundsRequested / totalVideosGenerated;

  bool get hasSavedVideos => generatedVideoPaths.isNotEmpty;

  int get premiumRendersRemaining => isPremiumSubscriber
      ? (premiumMonthlyRenderCap - premiumRendersThisMonth)
          .clamp(0, premiumMonthlyRenderCap)
      : 0;

  int get easyRendersRemainingToday => isPremiumSubscriber
      ? freeEasyRendersPerDay
      : (freeEasyRendersPerDay - easyRendersToday)
          .clamp(0, freeEasyRendersPerDay);

  AppState copyWith({
    int? creditsBalance,
    bool? isPremiumSubscriber,
    VideoGenerationStatus? videoGenerationStatus,
    List<DateTime>? refundTimestamps,
    int? totalVideosGenerated,
    int? totalRefundsRequested,
    bool? isAccountFlaggedForReview,
    bool? navigateToPaywall,
    bool clearNavigateToPaywall = false,
    String? selectedImagePath,
    bool clearSelectedImagePath = false,
    Uint8List? selectedImageBytes,
    bool clearSelectedImageBytes = false,
    String? selectedStyleTemplateId,
    bool clearSelectedStyleTemplateId = false,
    String? dynamicOutputVideoPath,
    bool clearDynamicOutputVideoPath = false,
    List<String>? generatedVideoPaths,
    String? currentQueueStep,
    bool clearCurrentQueueStep = false,
    String? rateLimitBlockedMessage,
    bool clearRateLimitBlockedMessage = false,
    String? monthlyLimitMessage,
    bool clearMonthlyLimitMessage = false,
    bool? isDeviceOfflineMode,
    bool clearDeviceOfflineMode = false,
    bool? hasCompletedOnboarding,
    bool? isLocalOverlay,
    String? sparkleMaskUrl,
    bool clearLocalOverlay = false,
    int? premiumRendersThisMonth,
    DateTime? premiumRenderResetDate,
    bool clearPremiumRenderResetDate = false,
    int? easyRendersToday,
    DateTime? easyRenderResetDate,
    bool clearEasyRenderResetDate = false,
    bool? outputHasWatermark,
  }) {
    return AppState(
      creditsBalance: creditsBalance ?? this.creditsBalance,
      isPremiumSubscriber: isPremiumSubscriber ?? this.isPremiumSubscriber,
      videoGenerationStatus:
          videoGenerationStatus ?? this.videoGenerationStatus,
      refundTimestamps: refundTimestamps ?? this.refundTimestamps,
      totalVideosGenerated: totalVideosGenerated ?? this.totalVideosGenerated,
      totalRefundsRequested:
          totalRefundsRequested ?? this.totalRefundsRequested,
      isAccountFlaggedForReview:
          isAccountFlaggedForReview ?? this.isAccountFlaggedForReview,
      navigateToPaywall: clearNavigateToPaywall
          ? false
          : (navigateToPaywall ?? this.navigateToPaywall),
      selectedImagePath: clearSelectedImagePath
          ? null
          : (selectedImagePath ?? this.selectedImagePath),
      selectedImageBytes: clearSelectedImageBytes
          ? null
          : (selectedImageBytes ?? this.selectedImageBytes),
      selectedStyleTemplateId: clearSelectedStyleTemplateId
          ? null
          : (selectedStyleTemplateId ?? this.selectedStyleTemplateId),
      dynamicOutputVideoPath: clearDynamicOutputVideoPath
          ? null
          : (dynamicOutputVideoPath ?? this.dynamicOutputVideoPath),
      generatedVideoPaths: generatedVideoPaths ?? this.generatedVideoPaths,
      currentQueueStep: clearCurrentQueueStep
          ? null
          : (currentQueueStep ?? this.currentQueueStep),
      rateLimitBlockedMessage: clearRateLimitBlockedMessage
          ? null
          : (rateLimitBlockedMessage ?? this.rateLimitBlockedMessage),
      monthlyLimitMessage: clearMonthlyLimitMessage
          ? null
          : (monthlyLimitMessage ?? this.monthlyLimitMessage),
      isDeviceOfflineMode: clearDeviceOfflineMode
          ? false
          : (isDeviceOfflineMode ?? this.isDeviceOfflineMode),
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      isLocalOverlay: clearLocalOverlay
          ? false
          : (isLocalOverlay ?? this.isLocalOverlay),
      sparkleMaskUrl: clearLocalOverlay
          ? null
          : (sparkleMaskUrl ?? this.sparkleMaskUrl),
      premiumRendersThisMonth:
          premiumRendersThisMonth ?? this.premiumRendersThisMonth,
      premiumRenderResetDate: clearPremiumRenderResetDate
          ? null
          : (premiumRenderResetDate ?? this.premiumRenderResetDate),
      easyRendersToday: easyRendersToday ?? this.easyRendersToday,
      easyRenderResetDate: clearEasyRenderResetDate
          ? null
          : (easyRenderResetDate ?? this.easyRenderResetDate),
      outputHasWatermark: outputHasWatermark ?? this.outputHasWatermark,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AppState &&
            creditsBalance == other.creditsBalance &&
            isPremiumSubscriber == other.isPremiumSubscriber &&
            videoGenerationStatus == other.videoGenerationStatus &&
            _listEquals(refundTimestamps, other.refundTimestamps) &&
            totalVideosGenerated == other.totalVideosGenerated &&
            totalRefundsRequested == other.totalRefundsRequested &&
            isAccountFlaggedForReview == other.isAccountFlaggedForReview &&
            navigateToPaywall == other.navigateToPaywall &&
            selectedImagePath == other.selectedImagePath &&
            _bytesEqual(selectedImageBytes, other.selectedImageBytes) &&
            selectedStyleTemplateId == other.selectedStyleTemplateId &&
            dynamicOutputVideoPath == other.dynamicOutputVideoPath &&
            _listEquals(generatedVideoPaths, other.generatedVideoPaths) &&
            currentQueueStep == other.currentQueueStep &&
            rateLimitBlockedMessage == other.rateLimitBlockedMessage &&
            monthlyLimitMessage == other.monthlyLimitMessage &&
            isDeviceOfflineMode == other.isDeviceOfflineMode &&
            hasCompletedOnboarding == other.hasCompletedOnboarding &&
            isLocalOverlay == other.isLocalOverlay &&
            sparkleMaskUrl == other.sparkleMaskUrl &&
            premiumRendersThisMonth == other.premiumRendersThisMonth &&
            premiumRenderResetDate == other.premiumRenderResetDate &&
            easyRendersToday == other.easyRendersToday &&
            easyRenderResetDate == other.easyRenderResetDate &&
            outputHasWatermark == other.outputHasWatermark;
  }

  @override
  int get hashCode => Object.hashAll([
        creditsBalance,
        isPremiumSubscriber,
        videoGenerationStatus,
        Object.hashAll(refundTimestamps),
        totalVideosGenerated,
        totalRefundsRequested,
        isAccountFlaggedForReview,
        navigateToPaywall,
        selectedImagePath,
        selectedImageBytes == null
            ? null
            : Object.hashAll(selectedImageBytes!),
        selectedStyleTemplateId,
        dynamicOutputVideoPath,
        Object.hashAll(generatedVideoPaths),
        currentQueueStep,
        rateLimitBlockedMessage,
        monthlyLimitMessage,
        isDeviceOfflineMode,
        hasCompletedOnboarding,
        isLocalOverlay,
        sparkleMaskUrl,
        premiumRendersThisMonth,
        premiumRenderResetDate,
        easyRendersToday,
        easyRenderResetDate,
        outputHasWatermark,
      ]);
}

bool _bytesEqual(Uint8List? a, Uint8List? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
