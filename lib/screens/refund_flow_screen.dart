import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ink_n_motion/models/refund_reason_option.dart';
import 'package:ink_n_motion/screens/home_shell_screen.dart';
import 'package:ink_n_motion/services/refund_service.dart';
import 'package:ink_n_motion/state/app_state.dart';
import 'package:ink_n_motion/state/providers.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';
import 'package:ink_n_motion/utils/ink_haptics.dart';
import 'package:ink_n_motion/widgets/ink_frosted_glass.dart';

class RefundFlowScreen extends ConsumerStatefulWidget {
  const RefundFlowScreen({super.key});

  @override
  ConsumerState<RefundFlowScreen> createState() => _RefundFlowScreenState();
}

class _RefundFlowScreenState extends ConsumerState<RefundFlowScreen> {
  final Set<String> _selectedReasonIds = {};
  bool _submitting = false;

  static const _refundLimitDialogMessage =
      'Daily refund limit reached. Please try again 24 hours after your oldest request.';

  bool get _canSubmit => _selectedReasonIds.isNotEmpty && !_submitting;

  void _toggleReason(RefundReasonOption option) {
    setState(() {
      if (_selectedReasonIds.contains(option.id)) {
        _selectedReasonIds.remove(option.id);
      } else {
        _selectedReasonIds.add(option.id);
      }
    });
  }

  String get _combinedReasonTag {
    final labels = RefundReasonOption.all
        .where((option) => _selectedReasonIds.contains(option.id))
        .map((option) => option.label)
        .toList();
    return labels.join('; ');
  }

  Future<void> _showRefundLimitDialog() async {
    await InkHaptics.blockedOrError();
    if (!mounted) return;
    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Refund limit'),
        content: const Text(_refundLimitDialogMessage),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSuccessOverlay() async {
    await showCupertinoDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Refund approved'),
        content: Text(
          '${AppState.refundCreditsRestored} credits have been restored to your balance.',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _returnToMainHub() {
    Navigator.of(context).pushAndRemoveUntil(
      CupertinoPageRoute<void>(builder: (_) => const HomeShellScreen()),
      (_) => false,
    );
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;

    setState(() => _submitting = true);

    final result = await ref.read(refundServiceProvider).requestRefundCredit(
          reasonTag: _combinedReasonTag,
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.limitReached) {
      await _showRefundLimitDialog();
      return;
    }

    if (result.approved) {
      await _showSuccessOverlay();
      if (mounted) _returnToMainHub();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);

    return CupertinoPageScaffold(
      backgroundColor: InkColors.backgroundPrimary,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: InkColors.backgroundSecondary.withValues(alpha: 0.9),
        border: null,
        middle: const Text('Refund'),
        leading: CupertinoNavigationBarBackButton(
          onPressed: _submitting ? null : () => Navigator.of(context).maybePop(),
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            const CupertinoSliverNavigationBar(
              largeTitle: Text('Report bad output'),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(InkSpacing.md),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  InkFrostedGlass(
                    padding: const EdgeInsets.all(InkSpacing.md),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.exclamationmark_triangle,
                          color: InkColors.accentWarning,
                        ),
                        const SizedBox(width: InkSpacing.md),
                        Expanded(
                          child: Text(
                            '${appState.refundsRemaining} of ${AppState.rollingRefundCap} '
                            'refunds left in the last 24 hours',
                            style: InkTypography.body,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: InkSpacing.lg),
                  Text(
                    'Select all issues that apply',
                    style: InkTypography.headline,
                  ),
                  const SizedBox(height: InkSpacing.sm),
                  CupertinoListSection.insetGrouped(
                    backgroundColor: InkColors.backgroundPrimary,
                    children: RefundReasonOption.all.map((option) {
                      final checked = _selectedReasonIds.contains(option.id);
                      return CupertinoListTile(
                        title: Text(option.label),
                        leading: CupertinoCheckbox(
                          value: checked,
                          activeColor: InkColors.accentNeonCyan,
                          onChanged: _submitting
                              ? null
                              : (_) => _toggleReason(option),
                        ),
                        onTap: _submitting ? null : () => _toggleReason(option),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: InkSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      onPressed: _canSubmit ? _submit : null,
                      child: _submitting
                          ? const CupertinoActivityIndicator()
                          : const Text('Submit Refund Request'),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
