import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ink_n_motion/models/paywall_tier.dart';
import 'package:ink_n_motion/models/purchase_result.dart';
import 'package:ink_n_motion/services/billing_service.dart';
import 'package:ink_n_motion/services/firestore_wallet_service.dart';
import 'package:ink_n_motion/state/providers.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';
import 'package:ink_n_motion/widgets/ink_frosted_glass.dart';
import 'package:ink_n_motion/widgets/paywall/paywall_tier_card.dart';

/// Premium Cupertino paywall for credit packs and Ink monthly subscriptions.
class PaywallCreditPurchaseScreen extends ConsumerStatefulWidget {
  const PaywallCreditPurchaseScreen({super.key});

  @override
  ConsumerState<PaywallCreditPurchaseScreen> createState() =>
      _PaywallCreditPurchaseScreenState();
}

class _PaywallCreditPurchaseScreenState
    extends ConsumerState<PaywallCreditPurchaseScreen> {
  PaywallTierId? _selectedTierId;
  PaywallTierId? _processingTierId;

  Stream<InkWallet?> get _walletStream {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return FirestoreWalletService.instance.watchWallet(uid);
  }

  Future<void> _showPurchaseAlert({
    required String title,
    required String message,
  }) async {
    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
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

  void _handlePurchaseResult(PurchaseResult result) {
    switch (result.outcome) {
      case PurchaseOutcome.success:
        Navigator.of(context).pop();
      case PurchaseOutcome.cancelled:
        return;
      case PurchaseOutcome.notConfigured:
        unawaited(
          _showPurchaseAlert(
            title: 'Purchases Unavailable',
            message:
                'In-app purchases are not available in this build. '
                'Please reinstall from the store or contact '
                'support@ink-n-motion.com.',
          ),
        );
      case PurchaseOutcome.productNotFound:
        unawaited(
          _showPurchaseAlert(
            title: 'Product Unavailable',
            message:
                'This item is not available in the store yet. '
                'Try again later or contact support@ink-n-motion.com.',
          ),
        );
      case PurchaseOutcome.creditFailed:
        unawaited(
          _showPurchaseAlert(
            title: 'Tokens Not Added',
            message:
                'Your payment may have gone through, but we could not add '
                'tokens to your account. Contact support@ink-n-motion.com '
                'with your receipt and we will fix it.',
          ),
        );
      case PurchaseOutcome.error:
        unawaited(
          _showPurchaseAlert(
            title: 'Purchase Failed',
            message: result.message?.isNotEmpty == true
                ? result.message!
                : 'Something went wrong. Please try again.',
          ),
        );
    }
  }

  Future<void> _completePurchase(PaywallTier tier) async {
    setState(() => _processingTierId = tier.id);

    final notifier = ref.read(appStateProvider.notifier);
    final PurchaseResult result;
    switch (tier.id) {
      case PaywallTierId.introPack:
        result = await notifier.purchaseIntroPack();
      case PaywallTierId.creatorPack:
        result = await notifier.purchaseCreatorPack();
      case PaywallTierId.studioPack:
        result = await notifier.purchaseStudioPack();
      case PaywallTierId.sparkMonthly:
        result = await notifier.purchaseSparkMonthly();
      case PaywallTierId.flowMonthly:
        result = await notifier.purchaseFlowMonthly();
      case PaywallTierId.studioMonthly:
        result = await notifier.purchaseStudioMonthly();
    }

    if (!mounted) return;
    setState(() => _processingTierId = null);

    _handlePurchaseResult(result);
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final isBusy = _processingTierId != null;

    return CupertinoPageScaffold(
      backgroundColor: InkColors.backgroundPrimary,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: InkColors.backgroundSecondary.withValues(alpha: 0.9),
        border: null,
        middle: const Text('Get Credits'),
        leading: CupertinoNavigationBarBackButton(
          onPressed: isBusy ? null : () => Navigator.of(context).maybePop(),
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            const CupertinoSliverNavigationBar(
              largeTitle: Text('Premium packs'),
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
                          CupertinoIcons.money_dollar_circle_fill,
                          color: InkColors.accentNeonCyan,
                        ),
                        const SizedBox(width: InkSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              StreamBuilder<InkWallet?>(
                                stream: _walletStream,
                                builder: (context, snapshot) {
                                  final balance =
                                      snapshot.data?.totalBalance ?? 0;
                                  return Text(
                                    '$balance tokens',
                                    style: InkTypography.title3,
                                  );
                                },
                              ),
                              Text(
                                appState.isPremiumSubscriber
                                    ? 'Subscription active'
                                    : 'Select a pack to continue',
                                style: InkTypography.footnote,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: InkSpacing.lg),
                  Text('Credit packs', style: InkTypography.title2),
                  const SizedBox(height: InkSpacing.sm),
                  Text(
                    'Tokens never expire. Subscription tokens refresh monthly.',
                    style: InkTypography.footnote,
                  ),
                  const SizedBox(height: InkSpacing.md),
                  ...PaywallTier.creditPacks.map((tier) {
                    return PaywallTierCard(
                      tier: tier,
                      selected: _selectedTierId == tier.id,
                      isProcessing: _processingTierId == tier.id,
                      onSelect: isBusy
                          ? () {}
                          : () => setState(() => _selectedTierId = tier.id),
                      onPurchase:
                          isBusy ? () {} : () => _completePurchase(tier),
                    );
                  }),
                  const SizedBox(height: InkSpacing.lg),
                  Text('Monthly plans', style: InkTypography.title2),
                  const SizedBox(height: InkSpacing.sm),
                  Text(
                    'Tokens refresh every month. Cancel anytime.',
                    style: InkTypography.footnote,
                  ),
                  const SizedBox(height: InkSpacing.md),
                  ...PaywallTier.subscriptions.map((tier) {
                    return PaywallTierCard(
                      tier: tier,
                      selected: _selectedTierId == tier.id,
                      isProcessing: _processingTierId == tier.id,
                      onSelect: isBusy
                          ? () {}
                          : () => setState(() => _selectedTierId = tier.id),
                      onPurchase:
                          isBusy ? () {} : () => _completePurchase(tier),
                    );
                  }),
                  const SizedBox(height: InkSpacing.md),
                  Text(
                    BillingService.isConfigured
                        ? 'Purchases powered by RevenueCat.'
                        : 'Billing unavailable on this platform.',
                    style: InkTypography.caption1,
                    textAlign: TextAlign.center,
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
