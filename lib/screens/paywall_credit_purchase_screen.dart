import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ink_n_motion/models/paywall_tier.dart';
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

  Future<void> _completePurchase(PaywallTier tier) async {
    setState(() => _processingTierId = tier.id);

    final notifier = ref.read(appStateProvider.notifier);
    final bool success;
    switch (tier.id) {
      case PaywallTierId.introPack:
        success = await notifier.purchaseIntroPack();
      case PaywallTierId.creatorPack:
        success = await notifier.purchaseCreatorPack();
      case PaywallTierId.studioPack:
        success = await notifier.purchaseStudioPack();
      case PaywallTierId.sparkMonthly:
        success = await notifier.purchaseSparkMonthly();
      case PaywallTierId.flowMonthly:
        success = await notifier.purchaseFlowMonthly();
      case PaywallTierId.studioMonthly:
        success = await notifier.purchaseStudioMonthly();
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
