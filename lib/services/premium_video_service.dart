import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ink_n_motion/state/app_state.dart';
import 'package:ink_n_motion/state/providers.dart';

/// Premium video pipeline — credit matrix + live HTTP API via [AppStateNotifier].
class PremiumVideoService {
  PremiumVideoService(this._ref);

  final Ref _ref;

  static int get creditCost => AppState.kPremiumCreditCost;

  /// Returns `true` when generation completes; `false` when blocked or failed.
  Future<bool> generatePremiumVideo() {
    return _ref.read(appStateProvider.notifier).processPremiumVideoGeneration();
  }

  void resetStatus() {
    _ref.read(appStateProvider.notifier).resetPremiumGenerationStatus();
  }
}

final premiumVideoServiceProvider = Provider<PremiumVideoService>((ref) {
  return PremiumVideoService(ref);
});
