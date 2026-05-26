import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ink_n_motion/state/providers.dart';

/// Easy video pipeline — delegates live generation to [AppStateNotifier].
class EasyVideoService {
  EasyVideoService(this._ref);

  final Ref _ref;

  /// Runs the easy track via the production HTTP API.
  Future<bool> processEasyVideo() {
    return _ref.read(appStateProvider.notifier).beginEasyVideoProcessing();
  }

  void resetStatus() {
    _ref.read(appStateProvider.notifier).resetEasyGenerationStatus();
  }
}

final easyVideoServiceProvider = Provider<EasyVideoService>((ref) {
  return EasyVideoService(ref);
});
