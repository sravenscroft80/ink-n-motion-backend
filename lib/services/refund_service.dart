import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ink_n_motion/models/transaction_results.dart';
import 'package:ink_n_motion/state/app_state.dart';
import 'package:ink_n_motion/state/providers.dart';

/// UI-facing result of a placeholder refund credit request.
class RefundResult {
  const RefundResult({
    required this.outcome,
    required this.message,
    this.creditsReturned = 0,
  });

  final RefundRequestResult outcome;
  final String message;
  final int creditsReturned;

  bool get approved => outcome == RefundRequestResult.approved;

  bool get limitReached => outcome == RefundRequestResult.limitReached;
}

/// Placeholder refund handler — delegates rolling window logic to [AppStateNotifier].
class RefundService {
  RefundService(this._ref);

  final Ref _ref;

  static const Duration mockReviewDuration = Duration(milliseconds: 1500);

  Future<RefundResult> requestRefundCredit({required String reasonTag}) async {
    await Future<void>.delayed(mockReviewDuration);

    final outcome = _ref
        .read(appStateProvider.notifier)
        .processRefundRequest(reasonTag: reasonTag);

    switch (outcome) {
      case RefundRequestResult.approved:
        return RefundResult(
          outcome: outcome,
          message: '${AppState.refundCreditsRestored} credits restored. Thanks for the feedback.',
          creditsReturned: AppState.refundCreditsRestored,
        );
      case RefundRequestResult.rejectedEmptyTag:
        return const RefundResult(
          outcome: RefundRequestResult.rejectedEmptyTag,
          message: 'Please tag what went wrong with the output.',
        );
      case RefundRequestResult.limitReached:
        return const RefundResult(
          outcome: RefundRequestResult.limitReached,
          message:
              'Daily refund limit reached. Please try again 24 hours after your oldest request.',
        );
    }
  }
}

final refundServiceProvider = Provider<RefundService>((ref) {
  return RefundService(ref);
});
