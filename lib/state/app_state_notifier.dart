import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ink_n_motion/data/style_template_catalog.dart';
import 'package:ink_n_motion/models/generate_video_response.dart';
import 'package:ink_n_motion/models/purchase_result.dart';
import 'package:ink_n_motion/models/style_template.dart';
import 'package:ink_n_motion/models/transaction_results.dart';
import 'package:ink_n_motion/models/video_generation_status.dart';
import 'package:ink_n_motion/services/api_service.dart';
import 'package:ink_n_motion/services/billing_service.dart';
import 'package:ink_n_motion/services/firestore_wallet_service.dart';
import 'package:ink_n_motion/services/storage_service.dart';
import 'package:ink_n_motion/services/user_service.dart';
import 'package:ink_n_motion/state/app_state.dart';
import 'package:ink_n_motion/utils/exceptions.dart';
import 'package:ink_n_motion/utils/gallery_media_saver.dart';
import 'package:ink_n_motion/utils/ink_haptics.dart';
class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier(this._storage, this._userService, this._api)
      : super(const AppState()) {
    unawaited(_hydrate());
  }
  final StorageService _storage;
  final UserService _userService;
  final ApiService _api;
  bool _isHydrated = false;
  bool _persistPending = false;
  int _lastPremiumCreditCost = AppState.kPremiumCreditCost;
  bool get isHydrated => _isHydrated;
  Future<void> _hydrate() async {
    final inMemoryPath = state.selectedImagePath;
    final inMemoryBytes = state.selectedImageBytes;
    final local = await _storage.loadPersistedState();
    if (_userService.isAvailable) {
      final profile = await _userService.loadProfile();
      state = profile == null
          ? local
          : local.copyWith(
              creditsBalance: profile.creditBalance,
              isPremiumSubscriber: profile.isPremium,
              premiumRendersThisMonth: profile.premiumRendersThisMonth,
              premiumRenderResetDate: profile.premiumRenderResetDate,
              easyRendersToday: profile.easyRendersToday,
              easyRenderResetDate: profile.easyRenderResetDate,
            );
    } else {
      final wallet = await _storage.loadWallet();
      state = local.copyWith(
        creditsBalance: wallet.creditBalance,
        isPremiumSubscriber: wallet.isPremium,
      );
    }
    if (inMemoryPath != null) {
      state = state.copyWith(
        selectedImagePath: inMemoryPath,
        selectedImageBytes: inMemoryBytes,
      );
    }
    state = _withSyncedRenderCycles(state);
    _isHydrated = true;
    if (_persistPending) {
      _persistPending = false;
      await _persist();
    }
  }
  void _commit(AppState next) {
    state = _withSyncedRenderCycles(next);
    unawaited(_persist());
  }
  Future<void> _persist() async {
    if (!_isHydrated) {
      _persistPending = true;
      return;
    }
    final persistTasks = <Future<void>>[
      _storage.savePersistedState(state),
    ];
    if (_userService.isAvailable) {
      persistTasks.add(
        _userService.syncWallet(
          creditBalance: state.creditsBalance,
          isPremium: state.isPremiumSubscriber,
          premiumRendersThisMonth: state.premiumRendersThisMonth,
          premiumRenderResetDate: state.premiumRenderResetDate,
          easyRendersToday: state.easyRendersToday,
          easyRenderResetDate: state.easyRenderResetDate,
        ),
      );
    } else {
      persistTasks.add(
        _storage.saveWallet(
          creditBalance: state.creditsBalance,
          isPremium: state.isPremiumSubscriber,
        ),
      );
    }
    await Future.wait(persistTasks);
  }
  AppState _withSyncedRenderCycles(AppState current) {
    var next = current;
    final now = DateTime.now();
    final premiumReset = next.premiumRenderResetDate;
    if (premiumReset != null && now.isAfter(premiumReset)) {
      next = next.copyWith(
        premiumRendersThisMonth: 0,
        clearPremiumRenderResetDate: true,
      );
    }
    final easyReset = next.easyRenderResetDate;
    if (easyReset != null && now.isAfter(easyReset)) {
      next = next.copyWith(
        easyRendersToday: 0,
        clearEasyRenderResetDate: true,
      );
    }
    return next;
  }
  static DateTime _startOfNextCalendarDay(DateTime from) {
    return DateTime(from.year, from.month, from.day + 1);
  }
  static String _formatResetDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
  void setCredits(int balance) {
    _commit(state.copyWith(creditsBalance: balance));
  }
  void addCredits(int amount) {
    _commit(state.copyWith(creditsBalance: state.creditsBalance + amount));
  }
  void setPremium(bool isPremium) {
    _commit(state.copyWith(isPremiumSubscriber: isPremium));
  }
  /// Applies premium status from RevenueCat entitlements (source of truth when available).
  void applyPremiumEntitlement(bool isPremium) {
    if (state.isPremiumSubscriber == isPremium) return;
    setPremium(isPremium);
  }
  Future<void> syncPremiumFromRevenueCat() async {
    final status = await BillingService.checkEntitlements();
    if (!status.isAvailable) return;
    applyPremiumEntitlement(status.hasProEntitlement);
  }

  /// Shared helper for all consumable (non-subscription) pack purchases.
  Future<PurchaseResult> _purchasePack(String productId) async {
    try {
      final storeResult = await BillingService.purchaseProduct(
        productId,
        isSubscription: false,
      );
      if (!storeResult.isSuccess) {
        return storeResult;
      }

      final customerInfo = storeResult.customerInfo;
      if (customerInfo == null) {
        return PurchaseResult.error('Purchase completed without customer info.');
      }

      final uid = _userService.getCurrentUid();
      if (uid == null) {
        debugPrint(
          'AppStateNotifier._purchasePack($productId): no uid — cannot credit Firestore wallet',
        );
        return PurchaseResult.creditFailed();
      }

      final tokens = BillingProductIds.tokensForProduct(productId);
      if (tokens <= 0) {
        debugPrint(
          'AppStateNotifier._purchasePack($productId): invalid token grant ($tokens)',
        );
        return PurchaseResult.error('Invalid token grant for $productId.');
      }

      try {
        await FirestoreWalletService.instance.initializeWallet(uid);
        await FirestoreWalletService.instance.addPurchasedTokens(uid, tokens);
      } catch (error, stackTrace) {
        _logPurchaseFailure(
          '_purchasePack($productId) firestore credit',
          error,
          stackTrace,
        );
        return PurchaseResult.creditFailed();
      }

      await InkHaptics.purchaseSuccess();
      return PurchaseResult.fromStoreSuccess(customerInfo);
    } catch (error, stackTrace) {
      _logPurchaseFailure('_purchasePack($productId)', error, stackTrace);
      return PurchaseResult.error('$error');
    }
  }

  /// Shared helper for all subscription purchases.
  Future<PurchaseResult> _purchaseSubscription(String productId) async {
    try {
      final storeResult = await BillingService.purchaseProduct(
        productId,
        isSubscription: true,
      );
      if (!storeResult.isSuccess) {
        return storeResult;
      }

      final customerInfo = storeResult.customerInfo;
      if (customerInfo == null) {
        return PurchaseResult.error('Purchase completed without customer info.');
      }

      final uid = _userService.getCurrentUid();
      if (uid == null) {
        debugPrint(
          'AppStateNotifier._purchaseSubscription($productId): no uid — cannot credit Firestore wallet',
        );
        return PurchaseResult.creditFailed();
      }

      final tokens = BillingProductIds.tokensForProduct(productId);
      if (tokens <= 0) {
        debugPrint(
          'AppStateNotifier._purchaseSubscription($productId): invalid token grant ($tokens)',
        );
        return PurchaseResult.error('Invalid token grant for $productId.');
      }

      final tier = BillingProductIds.tierForProduct(productId);
      if (tier == null) {
        debugPrint(
          'AppStateNotifier._purchaseSubscription($productId): unknown subscription tier',
        );
        return PurchaseResult.error('Unknown subscription tier for $productId.');
      }

      try {
        await FirestoreWalletService.instance.initializeWallet(uid);
        final entitlement =
            customerInfo.entitlements.all[BillingEntitlements.inkMotionPro];
        await FirestoreWalletService.instance.handleSubscriptionRenewal(
          uid,
          tier: tier,
          renewalDate: _parseEntitlementExpiration(entitlement?.expirationDate),
        );
      } catch (error, stackTrace) {
        _logPurchaseFailure(
          '_purchaseSubscription($productId) firestore credit',
          error,
          stackTrace,
        );
        return PurchaseResult.creditFailed();
      }

      await syncPremiumFromRevenueCat();
      await InkHaptics.purchaseSuccess();
      return PurchaseResult.fromStoreSuccess(customerInfo);
    } catch (error, stackTrace) {
      _logPurchaseFailure(
        '_purchaseSubscription($productId)',
        error,
        stackTrace,
      );
      return PurchaseResult.error('$error');
    }
  }

  DateTime? _parseEntitlementExpiration(String? expirationDate) {
    if (expirationDate == null || expirationDate.isEmpty) return null;
    return DateTime.tryParse(expirationDate);
  }

  Future<PurchaseResult> purchaseIntroPack() =>
      _purchasePack(BillingProductIds.introPack);

  Future<PurchaseResult> purchaseCreatorPack() =>
      _purchasePack(BillingProductIds.creatorPack);

  Future<PurchaseResult> purchaseStudioPack() =>
      _purchasePack(BillingProductIds.studioPack);

  Future<PurchaseResult> purchaseSparkMonthly() =>
      _purchaseSubscription(BillingProductIds.sparkMonthly);

  Future<PurchaseResult> purchaseFlowMonthly() =>
      _purchaseSubscription(BillingProductIds.flowMonthly);

  Future<PurchaseResult> purchaseStudioMonthly() =>
      _purchaseSubscription(BillingProductIds.studioMonthly);

  /// Grants share-to-unlock bonus credits once per calendar day.
  Future<bool> grantShareUnlockCredits() async {
    if (!await _storage.canUseShareUnlockToday()) return false;
    await _storage.recordShareUnlockUsedToday();
    addCredits(AppState.shareUnlockCreditsGranted);
    return true;
  }
  void _logPurchaseFailure(
    String method,
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint('AppStateNotifier.$method failed: $error');
    debugPrint('$stackTrace');
  }
  void setVideoGenerationStatus(VideoGenerationStatus status) {
    state = state.copyWith(videoGenerationStatus: status);
  }
  void _updateQueueStep(String queueStatus) {
    state = state.copyWith(currentQueueStep: queueStatus);
  }
  void clearRateLimitBlockedMessage() {
    state = state.copyWith(
      clearRateLimitBlockedMessage: true,
      videoGenerationStatus: VideoGenerationStatus.idle,
      clearCurrentQueueStep: true,
    );
  }
  void clearMonthlyLimitMessage() {
    state = state.copyWith(
      clearMonthlyLimitMessage: true,
      videoGenerationStatus: VideoGenerationStatus.idle,
    );
  }
  void clearDeviceOfflineMode() {
    state = state.copyWith(
      clearDeviceOfflineMode: true,
      videoGenerationStatus: VideoGenerationStatus.idle,
      clearCurrentQueueStep: true,
    );
  }
  /// Socket/connection loss — restore upfront credits, show offline overlay.
  void handleGenerationOffline({required bool refundUpfrontCredits}) {
    final cost = _lastPremiumCreditCost;
    final credits = refundUpfrontCredits
        ? state.creditsBalance + cost
        : state.creditsBalance;
    _commit(
      state.copyWith(
        videoGenerationStatus: VideoGenerationStatus.idle,
        creditsBalance: credits,
        isDeviceOfflineMode: true,
        clearCurrentQueueStep: true,
      ),
    );
  }
  /// Rate-limited before AI render — restore upfront credits, no fraud flagging.
  void handleGenerationRateLimit(
    RateLimitException error, {
    required bool refundUpfrontCredits,
  }) {
    final cost = _lastPremiumCreditCost;
    final credits = refundUpfrontCredits
        ? state.creditsBalance + cost
        : state.creditsBalance;
    _commit(
      state.copyWith(
        videoGenerationStatus: VideoGenerationStatus.idle,
        creditsBalance: credits,
        rateLimitBlockedMessage: error.message,
        clearCurrentQueueStep: true,
      ),
    );
  }
  Future<void> completeOnboarding() async {
    _commit(state.copyWith(hasCompletedOnboarding: true));
  }
  void clearPaywallNavigationIntent() {
    if (state.navigateToPaywall) {
      state = state.copyWith(clearNavigateToPaywall: true);
    }
  }
  void updateQueueStep(String queueStatus) {
    _updateQueueStep(queueStatus);
  }

  void setSelectedImage(String? path) {
    if (path == null) {
      state = state.copyWith(
        clearSelectedImagePath: true,
        clearSelectedImageBytes: true,
      );
      return;
    }
    state = state.copyWith(selectedImagePath: path);
  }

  void setSelectedImageWithBytes({
    required String path,
    required Uint8List bytes,
  }) {
    state = state.copyWith(
      selectedImagePath: path,
      selectedImageBytes: bytes,
    );
  }

  Future<void> completePremiumGeneration(String videoUrl) async {
    _commit(
      _generationSuccessState(GenerateVideoResponse(videoUrl: videoUrl)).copyWith(
        totalVideosGenerated: state.totalVideosGenerated + 1,
      ),
    );
    if (state.isPremiumSubscriber) {
      _recordPremiumSubscriberRender();
    }
    await InkHaptics.generationSuccess();
    _evaluateAccountHonesty();
  }
  AppState _generationSuccessState(GenerateVideoResponse response) {
    final watermark = !state.isPremiumSubscriber;
    if (response.isLocalOverlay) {
      return state.copyWith(
        videoGenerationStatus: VideoGenerationStatus.success,
        isLocalOverlay: true,
        sparkleMaskUrl: response.maskUrl,
        clearDynamicOutputVideoPath: true,
        clearCurrentQueueStep: true,
        outputHasWatermark: watermark,
      );
    }
    return state.copyWith(
      videoGenerationStatus: VideoGenerationStatus.success,
      dynamicOutputVideoPath: response.videoUrl,
      clearLocalOverlay: true,
      clearCurrentQueueStep: true,
      outputHasWatermark: watermark,
    );
  }
  void _recordPremiumSubscriberRender() {
    final now = DateTime.now();
    var count = state.premiumRendersThisMonth;
    var resetDate = state.premiumRenderResetDate;
    if (resetDate == null || now.isAfter(resetDate)) {
      count = 0;
      resetDate = now.add(const Duration(days: 30));
    }
    count += 1;
    _commit(
      state.copyWith(
        premiumRendersThisMonth: count,
        premiumRenderResetDate: resetDate,
      ),
    );
  }
  void _recordEasyRenderForFreeUser() {
    if (state.isPremiumSubscriber) return;
    final now = DateTime.now();
    var count = state.easyRendersToday;
    var resetDate = state.easyRenderResetDate;
    if (resetDate == null || now.isAfter(resetDate)) {
      count = 0;
      resetDate = _startOfNextCalendarDay(now);
    }
    count += 1;
    _commit(
      state.copyWith(
        easyRendersToday: count,
        easyRenderResetDate: resetDate,
      ),
    );
  }
  void setSelectedStyleTemplate(String? templateId) {
    if (templateId == null) {
      state = state.copyWith(clearSelectedStyleTemplateId: true);
      return;
    }
    state = state.copyWith(selectedStyleTemplateId: templateId);
  }
  /// Applies a successful Render `/generate` response to app state.
  void applyRenderMotionResponse(GenerateVideoResponse response) {
    _commit(_generationSuccessState(response));
    if (state.isPremiumSubscriber) {
      _recordPremiumSubscriberRender();
    } else {
      _recordEasyRenderForFreeUser();
    }
  }
  void markRenderMotionGenerating() {
    state = state.copyWith(
      videoGenerationStatus: VideoGenerationStatus.generating,
      clearDynamicOutputVideoPath: true,
      currentQueueStep: 'rendering',
      clearRateLimitBlockedMessage: true,
      clearMonthlyLimitMessage: true,
      clearDeviceOfflineMode: true,
      clearLocalOverlay: true,
    );
  }
  void markRenderMotionFailed() {
    state = state.copyWith(
      videoGenerationStatus: VideoGenerationStatus.failed,
      clearCurrentQueueStep: true,
    );
  }
  /// Easy track gate — enforces free daily limit before starting pipeline.
  EasyGenerationStartResult beginEasyGeneration() {
    state = _withSyncedRenderCycles(state);
    if (!state.isPremiumSubscriber &&
        state.easyRendersToday >= AppState.freeEasyRendersPerDay) {
      state = state.copyWith(
        navigateToPaywall: true,
        videoGenerationStatus: VideoGenerationStatus.idle,
      );
      return EasyGenerationStartResult.dailyLimitReached;
    }
    state = state.copyWith(
      videoGenerationStatus: VideoGenerationStatus.generating,
      clearDynamicOutputVideoPath: true,
      currentQueueStep: 'queued',
      clearRateLimitBlockedMessage: true,
      clearMonthlyLimitMessage: true,
      clearDeviceOfflineMode: true,
      clearLocalOverlay: true,
      clearNavigateToPaywall: true,
    );
    return EasyGenerationStartResult.started;
  }
  /// Easy track — live API pipeline with generating → success / failed transitions.
  Future<bool> beginEasyVideoProcessing() async {
    final startResult = beginEasyGeneration();
    if (startResult == EasyGenerationStartResult.dailyLimitReached) {
      return false;
    }
    try {
      final imagePath = state.selectedImagePath;
      final styleId = state.selectedStyleTemplateId ?? 'unspecified_style';
      if (imagePath == null || imagePath.isEmpty) {
        state = state.copyWith(
          videoGenerationStatus: VideoGenerationStatus.failed,
          clearCurrentQueueStep: true,
        );
        return false;
      }
      final response = await _api.generateVideoFromImage(
        imagePath: imagePath,
        styleId: styleId,
        onQueueStatusUpdate: _updateQueueStep,
      );
      _commit(_generationSuccessState(response));
      if (!state.isPremiumSubscriber) {
        _recordEasyRenderForFreeUser();
      }
      await InkHaptics.generationSuccess();
      return true;
    } on OfflineNetworkException {
      handleGenerationOffline(refundUpfrontCredits: false);
      return false;
    } on RateLimitException catch (error) {
      handleGenerationRateLimit(error, refundUpfrontCredits: false);
      return false;
    } on DioException catch (error, stackTrace) {
      logApiFailure('beginEasyVideoProcessing', error, stackTrace);
      state = state.copyWith(
        videoGenerationStatus: VideoGenerationStatus.failed,
        clearCurrentQueueStep: true,
      );
      return false;
    } catch (error, stackTrace) {
      logApiFailure('beginEasyVideoProcessing', error, stackTrace);
      state = state.copyWith(
        videoGenerationStatus: VideoGenerationStatus.failed,
        clearCurrentQueueStep: true,
      );
      return false;
    }
  }
  /// Premium credit matrix gate — deducts upfront credits when required.
  PremiumGenerationStartResult beginPremiumGeneration({int durationSeconds = 5}) {
    assert(durationSeconds == 5 || durationSeconds == 10);
    state = _withSyncedRenderCycles(state);

    if (durationSeconds == 10 && !state.isPremiumSubscriber) {
      state = state.copyWith(
        navigateToPaywall: true,
        videoGenerationStatus: VideoGenerationStatus.idle,
      );
      return PremiumGenerationStartResult.insufficientCredits;
    }

    final cost = durationSeconds == 10
        ? AppState.kPremiumCreditCostTenSecond
        : AppState.kPremiumCreditCost;
    _lastPremiumCreditCost = cost;

    if (state.isPremiumSubscriber) {
      if (state.premiumRendersThisMonth >= AppState.premiumMonthlyRenderCap) {
        final resetDate = state.premiumRenderResetDate;
        final resetLabel = resetDate != null
            ? _formatResetDate(resetDate)
            : 'your next billing cycle';
        state = state.copyWith(
          monthlyLimitMessage:
              'Monthly limit reached. Your premium renders reset on $resetLabel.',
          videoGenerationStatus: VideoGenerationStatus.idle,
        );
        return PremiumGenerationStartResult.monthlyLimitReached;
      }
      state = state.copyWith(
        videoGenerationStatus: VideoGenerationStatus.generating,
        clearNavigateToPaywall: true,
        clearDynamicOutputVideoPath: true,
        currentQueueStep: 'queued',
        clearRateLimitBlockedMessage: true,
        clearMonthlyLimitMessage: true,
        clearDeviceOfflineMode: true,
        clearLocalOverlay: true,
      );
      return PremiumGenerationStartResult.started;
    }
    if (state.creditsBalance < cost) {
      state = state.copyWith(
        navigateToPaywall: true,
        videoGenerationStatus: VideoGenerationStatus.idle,
      );
      return PremiumGenerationStartResult.insufficientCredits;
    }
    _commit(
      state.copyWith(
        creditsBalance: state.creditsBalance - cost,
        videoGenerationStatus: VideoGenerationStatus.generating,
        clearNavigateToPaywall: true,
        clearDynamicOutputVideoPath: true,
        currentQueueStep: 'queued',
        clearRateLimitBlockedMessage: true,
        clearMonthlyLimitMessage: true,
        clearDeviceOfflineMode: true,
        clearLocalOverlay: true,
      ),
    );
    return PremiumGenerationStartResult.started;
  }
  /// Premium track — credit gate + live API pipeline with refund on failure.
  Future<bool> processPremiumVideoGeneration({int durationSeconds = 5}) async {
    final startResult = beginPremiumGeneration(durationSeconds: durationSeconds);
    if (startResult == PremiumGenerationStartResult.insufficientCredits ||
        startResult == PremiumGenerationStartResult.monthlyLimitReached) {
      return false;
    }
    final refundCreditsOnFailure = !state.isPremiumSubscriber;
    try {
      final imageBytes = state.selectedImageBytes;
      final styleId = state.selectedStyleTemplateId ?? 'unspecified_style';
      if (imageBytes == null || imageBytes.isEmpty) {
        failPremiumGeneration(refundUpfrontCredits: refundCreditsOnFailure);
        return false;
      }
      final taskId = await _api.submitKlingJob(
        imageBytes: imageBytes,
        styleId: styleId,
        durationSeconds: durationSeconds,
      );
      final videoUrl = await _api.pollKlingStatus(taskId);
      _commit(
        _generationSuccessState(GenerateVideoResponse(videoUrl: videoUrl)).copyWith(
          totalVideosGenerated: state.totalVideosGenerated + 1,
        ),
      );
      if (state.isPremiumSubscriber) {
        _recordPremiumSubscriberRender();
      }
      await InkHaptics.generationSuccess();
      _evaluateAccountHonesty();
      return true;
    } on OfflineNetworkException {
      handleGenerationOffline(refundUpfrontCredits: refundCreditsOnFailure);
      return false;
    } on RateLimitException catch (error) {
      handleGenerationRateLimit(
        error,
        refundUpfrontCredits: refundCreditsOnFailure,
      );
      return false;
    } on DioException catch (error, stackTrace) {
      logApiFailure('processPremiumVideoGeneration', error, stackTrace);
      failPremiumGeneration(refundUpfrontCredits: refundCreditsOnFailure);
      return false;
    } catch (error, stackTrace) {
      logApiFailure('processPremiumVideoGeneration', error, stackTrace);
      failPremiumGeneration(refundUpfrontCredits: refundCreditsOnFailure);
      return false;
    }
  }
  void failPremiumGeneration({required bool refundUpfrontCredits}) {
    final cost = _lastPremiumCreditCost;
    final credits = refundUpfrontCredits
        ? state.creditsBalance + cost
        : state.creditsBalance;
    _commit(
      state.copyWith(
        videoGenerationStatus: VideoGenerationStatus.failed,
        creditsBalance: credits,
        clearCurrentQueueStep: true,
      ),
    );
  }
  void resetPremiumGenerationStatus() {
    state = state.copyWith(
      videoGenerationStatus: VideoGenerationStatus.idle,
      clearCurrentQueueStep: true,
      clearRateLimitBlockedMessage: true,
      clearMonthlyLimitMessage: true,
      clearDeviceOfflineMode: true,
      clearLocalOverlay: true,
    );
  }
  void resetEasyGenerationStatus() {
    state = state.copyWith(
      videoGenerationStatus: VideoGenerationStatus.idle,
      clearCurrentQueueStep: true,
      clearRateLimitBlockedMessage: true,
      clearMonthlyLimitMessage: true,
      clearDeviceOfflineMode: true,
      clearLocalOverlay: true,
    );
  }
  Future<bool> saveCurrentVideoToGallery() async {
    final path = state.isLocalOverlay
        ? (state.sparkleMaskUrl ?? state.selectedImagePath)
        : state.dynamicOutputVideoPath;
    if (path == null || path.isEmpty) return false;

    if (kIsWeb) return false;

    if (state.generatedVideoPaths.contains(path)) return true;

    final saved = looksLikeVideoUrl(path)
        ? await saveNetworkVideoToGallery(path)
        : await saveNetworkImageToGallery(
            path,
            filename: 'ink_motion_preview.png',
          );

    if (saved) {
      _commit(
        state.copyWith(
          generatedVideoPaths: [...state.generatedVideoPaths, path],
        ),
      );
    }
    return saved;
  }
  StyleTemplate? get selectedStyleTemplate =>
      StyleTemplateCatalog.findById(state.selectedStyleTemplateId);
  RefundRequestResult processRefundRequest({required String reasonTag}) {
    final tag = reasonTag.trim();
    if (tag.isEmpty) {
      return RefundRequestResult.rejectedEmptyTag;
    }
    _recordRefundSubmission();
    final now = DateTime.now();
    final windowStart = now.subtract(AppState.rollingRefundWindow);
    final pruned = state.refundTimestamps
        .where((timestamp) => timestamp.isAfter(windowStart))
        .toList();
    state = state.copyWith(refundTimestamps: pruned);
    unawaited(_persist());
    if (pruned.length >= AppState.rollingRefundCap) {
      return RefundRequestResult.limitReached;
    }
    _commit(
      state.copyWith(
        refundTimestamps: [...pruned, now],
        creditsBalance: state.creditsBalance + AppState.refundCreditsRestored,
      ),
    );
    _evaluateAccountHonesty();
    return RefundRequestResult.approved;
  }
  void _recordRefundSubmission() {
    _commit(
      state.copyWith(
        totalRefundsRequested: state.totalRefundsRequested + 1,
      ),
    );
    _evaluateAccountHonesty();
  }
  void _evaluateAccountHonesty() {
    final shouldFlag = state.totalVideosGenerated >=
            AppState.accountReviewMinVideosGenerated &&
        state.refundRatio > AppState.accountReviewRefundRatioThreshold;
    if (shouldFlag && !state.isAccountFlaggedForReview) {
      _commit(state.copyWith(isAccountFlaggedForReview: true));
    }
  }
}
