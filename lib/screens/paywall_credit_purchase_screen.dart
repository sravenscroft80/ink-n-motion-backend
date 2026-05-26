import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ink_n_motion/models/paywall_tier.dart';
import 'package:ink_n_motion/services/billing_service.dart';
import 'package:ink_n_motion/state/app_state.dart';
import 'package:ink_n_motion/state/providers.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';
import 'package:ink_n_motion/widgets/ink_frosted_glass.dart';
import 'package:ink_n_motion/widgets/paywall/paywall_tier_card.dart';

/// Premium Cupertino paywall for credit packs and Ink Plus subscriptions.
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

  Future<void> _completePurchase(PaywallTier tier) async {
    setState(() => _processingTierId = tier.id);

    final notifier = ref.read(appStateProvider.notifier);
    final bool success;
    switch (tier.id) {
      case PaywallTierId.spark10:
        success = await notifier.purchaseSparkPack();
      case PaywallTierId.creator30:
        success = await notifier.purchaseCreatorPack();
      case PaywallTierId.pro60:
        success = await notifier.purchaseProPack();
      case PaywallTierId.plusMonthly:
        success = await notifier.purchasePlusMonthly();
      case PaywallTierId.plusAnnual:
        success = await notifier.purchasePlusAnnual();
    }

    if (!mounted) return;
    setState(() => _processingTierId = null);

    if (success) {
      Navigator.of(context).pop();
    }
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
                              Text(
                                '${appState.creditsBalance} credits',
                                style: InkTypography.title3,
                              ),
                              Text(
                                appState.isPremiumSubscriber
                                    ? 'Ink Plus active · ${appState.premiumRendersRemaining} premium renders left'
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
                  const SizedBox(height: InkSpacing.md),
                  ...PaywallTier.creditPacks.map((tier) {
                    return PaywallTierCard(
                      tier: tier,
                      selected: _selectedTierId == tier.id,
                      isProcessing: _processingTierId == tier.id,
                      onSelect: isBusy
                          ? () {}
                          : () => setState(() => _selectedTierId = tier.id),
                      onPurchase: isBusy ? () {} : () => _completePurchase(tier),
                    );
                  }),
                  const SizedBox(height: InkSpacing.lg),
                  Text('Ink Plus subscriptions', style: InkTypography.title2),
                  const SizedBox(height: InkSpacing.sm),
                  Text(
                    'Includes ${AppState.premiumMonthlyRenderCap} premium renders per month and no watermark.',
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
                      onPurchase: isBusy ? () {} : () => _completePurchase(tier),
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
