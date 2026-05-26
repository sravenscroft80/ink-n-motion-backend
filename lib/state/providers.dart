import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ink_n_motion/models/studio_handoff.dart';
import 'package:ink_n_motion/services/api_service.dart';
import 'package:ink_n_motion/services/firebase_auth_service.dart';
import 'package:ink_n_motion/services/openai_service.dart';
import 'package:ink_n_motion/services/premium_video_service.dart';
import 'package:ink_n_motion/services/render_motion_service.dart';
import 'package:ink_n_motion/services/storage_service.dart';
import 'package:ink_n_motion/services/user_service.dart';
import 'package:ink_n_motion/state/ai_coach_notifier.dart';
import 'package:ink_n_motion/state/app_state.dart';
import 'package:ink_n_motion/state/app_state_notifier.dart';
import 'package:ink_n_motion/state/billing_notifier.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

final userServiceProvider = Provider<UserService>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return UserService(authService: authService);
});

final apiServiceProvider = Provider<ApiService>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return ApiService(authService: authService);
});

final renderMotionServiceProvider = Provider<RenderMotionService>((ref) {
  return RenderMotionService();
});

final openAiServiceProvider = Provider<OpenAiService>((ref) {
  return OpenAiService();
});

final premiumVideoServiceProvider = Provider<PremiumVideoService>((ref) {
  return PremiumVideoService(ref);
});

final appStateProvider =
    StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final userService = ref.watch(userServiceProvider);
  final api = ref.watch(apiServiceProvider);
  return AppStateNotifier(storage, userService, api);
});

/// RevenueCat entitlement sync — runs on launch and exposes refresh hooks.
final billingProvider =
    StateNotifierProvider<BillingNotifier, BillingState>((ref) {
  return BillingNotifier(
    readAppStateNotifier: () => ref.read(appStateProvider.notifier),
  );
});

/// Active [CupertinoTabScaffold] index — Discover (0), Studio (1), Gallery (2).
final shellTabIndexProvider = StateProvider<int>((ref) => 0);

/// AI Coach prompt session — preserved across navigation until [AiCoachNotifier.resetSession].
final aiCoachProvider =
    StateNotifierProvider<AiCoachNotifier, AiCoachState>((ref) {
  return AiCoachNotifier();
});

/// Prompt blueprint and generated concept passed from AI Coach into Motion Studio.
final studioHandoffProvider = StateProvider<StudioHandoff?>(
  (ref) => null,
);

/// Current wallet state — reads from UserService.
/// Screens watch this to get live token balance, tier, and free render counts.
final inkWalletProvider = Provider<InkWallet>((ref) {
  final userService = ref.watch(userServiceProvider);
  return userService.wallet;
});

/// Convenience — current spendable token count (balance + rollover).
final tokenBalanceProvider = Provider<int>((ref) {
  return ref.watch(inkWalletProvider).spendable;
});

/// Convenience — current tier label string e.g. "Free", "Ink Plus".
final tierLabelProvider = Provider<String>((ref) {
  return ref.watch(inkWalletProvider).tierLabel;
});

/// True if user has any free renders remaining (lifetime).
final hasFreeRenderProvider = Provider<bool>((ref) {
  return ref.watch(inkWalletProvider).hasFreeRenderAvailable;
});

/// True if user can afford a 5s paid render.
final canAfford5sProvider = Provider<bool>((ref) {
  return ref.watch(inkWalletProvider).canAfford5sRender;
});

/// True if user can afford a 10s paid render.
final canAfford10sProvider = Provider<bool>((ref) {
  return ref.watch(inkWalletProvider).canAfford10sRender;
});

/// True if concept soft cap warning should show.
final showConceptWarningProvider = Provider<bool>((ref) {
  return ref.watch(inkWalletProvider).showConceptWarning;
});
