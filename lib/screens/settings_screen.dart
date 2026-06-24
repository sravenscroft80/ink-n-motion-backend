import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ink_n_motion/screens/legal/about_screen.dart';
import 'package:ink_n_motion/screens/legal/privacy_policy_screen.dart';
import 'package:ink_n_motion/screens/legal/safety_notice_screen.dart';
import 'package:ink_n_motion/screens/legal/terms_of_service_screen.dart';
import 'package:ink_n_motion/screens/paywall_credit_purchase_screen.dart';
import 'package:ink_n_motion/screens/refund_flow_screen.dart';
import 'package:ink_n_motion/services/billing_service.dart';
import 'package:ink_n_motion/services/firestore_wallet_service.dart';
import 'package:ink_n_motion/state/app_state.dart';
import 'package:ink_n_motion/state/providers.dart';
import 'package:ink_n_motion/utils/app_links.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';
import 'package:ink_n_motion/utils/share_origin.dart';
import 'package:ink_n_motion/utils/navigation.dart';
import 'package:ink_n_motion/widgets/settings/settings_section_header.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const Color _gold = Color(0xFFD4A017);

  bool _isRestoring = false;

  Stream<InkWallet?> get _walletStream {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return FirestoreWalletService.instance.watchWallet(uid);
  }

  void _openPaywall() {
    pushCupertino(context, const PaywallCreditPurchaseScreen());
  }

  void _showAlert(String message) {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
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

  void _showAffiliateDisclosure() {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Affiliate Disclosure'),
        content: const Text(
          'Ink-N-Motion participates in the Amazon Associates program. '
          'Some links in the Resource Library are affiliate links — we may earn a '
          'small commission if you purchase through them, at no extra cost to you.',
        ),
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

  void _rateApp() {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Rate Ink-N-Motion'),
        content: const Text(
          "We'd love your feedback! Rating will be available when the app launches on the App Store.",
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _restorePurchases() async {
    if (!BillingService.isConfigured) {
      _showAlert('Restore is only available on iOS and Android');
      return;
    }

    setState(() => _isRestoring = true);
    try {
      final customerInfo = await BillingService.restorePurchases();
      if (!mounted) return;

      if (customerInfo != null) {
        await ref.read(appStateProvider.notifier).syncPremiumFromRevenueCat();
        if (!mounted) return;
        _showAlert('Purchases restored successfully.');
      } else {
        _showAlert('No purchases found to restore.');
      }
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  Future<void> _openCommunity() async {
    final uri = Uri.parse('https://labrhood.com');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      _showAlert('Unable to open community link.');
    }
  }

  Future<void> _shareApp() async {
    await SharePlus.instance.share(
      ShareParams(
        text: kShareMessage,
        sharePositionOrigin: shareOriginFromContext(context),
      ),
    );
  }

  Future<void> _contactSupport() async {
    final uri = Uri.parse('mailto:support@ink-n-motion.com');
    final launched = await launchUrl(uri);
    if (!launched && mounted) {
      _showAlert('Unable to open email client.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);

    return CupertinoPageScaffold(
      backgroundColor: InkColors.backgroundPrimary,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          const CupertinoSliverNavigationBar(
            largeTitle: Text('Settings'),
          ),

          // ① MY ACCOUNT
          const SliverToBoxAdapter(child: SettingsSectionHeader(label: 'MY ACCOUNT')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: InkSpacing.md),
              child: _AccountProfileHeader(gold: _gold),
            ),
          ),
          SliverToBoxAdapter(
            child: CupertinoListSection.insetGrouped(
              backgroundColor: InkColors.backgroundPrimary,
              children: [
                StreamBuilder<InkWallet?>(
                  stream: _walletStream,
                  builder: (context, snapshot) {
                    final wallet = snapshot.data;
                    final subTokens = wallet?.subscriptionTokens ?? 0;
                    final purchTokens = wallet?.purchasedTokens ?? 0;
                    final total = subTokens + purchTokens;
                    final balanceLabel = subTokens > 0 && purchTokens > 0
                        ? '$total ($subTokens + $purchTokens)'
                        : '$total';

                    return CupertinoListTile(
                      leading: Icon(
                        CupertinoIcons.money_dollar_circle_fill,
                        color: _gold,
                      ),
                      title: const Text('Token Balance'),
                      additionalInfo: Text(balanceLabel),
                      trailing: const CupertinoListTileChevron(),
                      onTap: _openPaywall,
                    );
                  },
                ),
                CupertinoListTile(
                  title: const Text('Subscription'),
                  additionalInfo: Text(
                    appState.isPremiumSubscriber ? 'Active ✦' : 'Free',
                  ),
                  trailing: const CupertinoListTileChevron(),
                  onTap: _openPaywall,
                ),
                if (appState.isPremiumSubscriber)
                  CupertinoListTile(
                    title: const Text('Premium Renders This Month'),
                    additionalInfo: Text(
                      '${appState.premiumRendersRemaining} / '
                      '${AppState.premiumMonthlyRenderCap} remaining',
                    ),
                  ),
                if (!appState.isPremiumSubscriber)
                  CupertinoListTile(
                    title: const Text('Free Renders Today'),
                    additionalInfo: Text(
                      '${appState.easyRendersRemainingToday} / '
                      '${AppState.freeEasyRendersPerDay} remaining',
                    ),
                  ),
                CupertinoListTile(
                  title: Text(
                    _isRestoring ? 'Restoring…' : 'Restore Purchases',
                  ),
                  trailing: _isRestoring
                      ? const CupertinoActivityIndicator(radius: 10)
                      : null,
                  onTap: _isRestoring ? null : _restorePurchases,
                ),
              ],
            ),
          ),

          // ② HOW CREDITS WORK
          const SliverToBoxAdapter(
            child: SettingsSectionHeader(label: 'HOW TOKENS WORK'),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: InkSpacing.md),
              child: _CreditsInfoCard(gold: _gold),
            ),
          ),

          // ③ COMMUNITY
          const SliverToBoxAdapter(
            child: SettingsSectionHeader(label: 'COMMUNITY'),
          ),
          SliverToBoxAdapter(
            child: CupertinoListSection.insetGrouped(
              backgroundColor: InkColors.backgroundPrimary,
              children: [
                CupertinoListTile(
                  title: const Text('Join the Ink-N-Motion Community'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: _openCommunity,
                ),
                CupertinoListTile(
                  title: const Text('Share the App'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: _shareApp,
                ),
              ],
            ),
          ),

          // ④ SUPPORT
          const SliverToBoxAdapter(
            child: SettingsSectionHeader(label: 'SUPPORT'),
          ),
          SliverToBoxAdapter(
            child: CupertinoListSection.insetGrouped(
              backgroundColor: InkColors.backgroundPrimary,
              children: [
                CupertinoListTile(
                  title: const Text('Request a Refund'),
                  subtitle: Text(
                    '${appState.refundsRemaining}/${AppState.rollingRefundCap} '
                    'refunds (24h window)',
                  ),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => pushCupertino(context, const RefundFlowScreen()),
                ),
                CupertinoListTile(
                  title: const Text('Contact Support'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: _contactSupport,
                ),
                CupertinoListTile(
                  title: const Text('Rate the App'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: _rateApp,
                ),
              ],
            ),
          ),

          // ⑤ LEGAL & PRIVACY
          const SliverToBoxAdapter(
            child: SettingsSectionHeader(label: 'LEGAL & PRIVACY'),
          ),
          SliverToBoxAdapter(
            child: CupertinoListSection.insetGrouped(
              backgroundColor: InkColors.backgroundPrimary,
              children: [
                CupertinoListTile(
                  title: const Text('Privacy Policy'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => pushCupertino(context, const PrivacyPolicyScreen()),
                ),
                CupertinoListTile(
                  title: const Text('Terms of Service'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => pushCupertino(context, const TermsOfServiceScreen()),
                ),
                CupertinoListTile(
                  title: const Text('Safety Notice'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => pushCupertino(context, const SafetyNoticeScreen()),
                ),
                CupertinoListTile(
                  title: const Text('About Ink-N-Motion'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => pushCupertino(context, const AboutScreen()),
                ),
                CupertinoListTile(
                  title: const Text('Affiliate Disclosure'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: _showAffiliateDisclosure,
                ),
              ],
            ),
          ),

          // ⑥ APP INFO
          const SliverToBoxAdapter(
            child: SettingsSectionHeader(label: 'APP INFO'),
          ),
          SliverToBoxAdapter(
            child: CupertinoListSection.insetGrouped(
              backgroundColor: InkColors.backgroundPrimary,
              children: const [
                CupertinoListTile(
                  title: Text('Version'),
                  additionalInfo: Text('1.0.0 (Build 1)'),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                InkSpacing.lg,
                InkSpacing.md,
                InkSpacing.lg,
                InkSpacing.xl,
              ),
              child: Text(
                'Made with ❤️ for the ink community',
                textAlign: TextAlign.center,
                style: InkTypography.caption1.copyWith(
                  color: InkColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountProfileHeader extends ConsumerStatefulWidget {
  const _AccountProfileHeader({required this.gold});

  final Color gold;

  @override
  ConsumerState<_AccountProfileHeader> createState() =>
      _AccountProfileHeaderState();
}

class _AccountProfileHeaderState extends ConsumerState<_AccountProfileHeader> {
  bool _isSigningIn = false;

  Future<void> _handleGoogleSignIn() async {
    if (_isSigningIn) return;
    setState(() => _isSigningIn = true);
    try {
      final authService = ref.read(firebaseAuthServiceProvider);
      await authService.signInWithGoogle();
    } catch (_) {
      if (!mounted) return;
      showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Sign In Failed'),
          content: const Text(
            'Unable to sign in with Google. Please try again.',
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  void _showSignOutSheet() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              unawaited(_confirmSignOut());
            },
            child: const Text('Sign Out'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(firebaseAuthServiceProvider).signOut();
    } catch (_) {
      if (!mounted) return;
      showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Sign Out Failed'),
          content: const Text('Unable to sign out. Please try again.'),
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
  }

  Widget _buildAvatar(User? user) {
    final photoUrl = user?.photoURL;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: widget.gold, width: 2),
        color: InkColors.backgroundElevated,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasPhoto
          ? Image.network(
              photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                CupertinoIcons.person_fill,
                color: widget.gold,
                size: 28,
              ),
            )
          : Icon(
              CupertinoIcons.person_fill,
              color: widget.gold,
              size: 28,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(firebaseAuthServiceProvider);

    return StreamBuilder<User?>(
      stream: authService.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data ?? authService.currentUser;
        final signedIn = user != null && !user.isAnonymous;

        final name = user?.displayName?.trim();
        final email = user?.email?.trim();
        final hasName = name != null && name.isNotEmpty;

        final primaryText = signedIn
            ? (hasName ? name : (email ?? 'Signed in'))
            : 'Sign in';
        final secondaryText = signedIn
            ? (hasName && email != null && email.isNotEmpty
                ? email
                : 'Signed in')
            : 'Tap to sign in with Google';

        return GestureDetector(
          onTap: _isSigningIn
              ? null
              : signedIn
                  ? _showSignOutSheet
                  : () => unawaited(_handleGoogleSignIn()),
          child: Padding(
            padding: const EdgeInsets.only(bottom: InkSpacing.sm),
            child: Row(
              children: [
                _buildAvatar(signedIn ? user : null),
                const SizedBox(width: InkSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        primaryText,
                        style: InkTypography.headline.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: InkSpacing.xs),
                      Text(
                        secondaryText,
                        style: InkTypography.subhead.copyWith(
                          color: InkColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isSigningIn)
                  const CupertinoActivityIndicator(radius: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CreditsInfoCard extends StatelessWidget {
  const _CreditsInfoCard({required this.gold});

  final Color gold;

  static const _lines = [
    '1 AI Concept Render = 1 token (1 free per day)',
    '10-Second Animation = 15 tokens',
    'Coverup Studio Render = 3 tokens',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(InkSpacing.md),
      decoration: BoxDecoration(
        color: InkColors.backgroundElevated,
        borderRadius: BorderRadius.circular(InkRadius.lg),
        border: Border.all(color: gold.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _lines.length; i++) ...[
            if (i > 0) const SizedBox(height: InkSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: gold,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: InkSpacing.sm),
                Expanded(
                  child: Text(
                    _lines[i],
                    style: InkTypography.subhead.copyWith(
                      color: InkColors.textPrimary.withValues(alpha: 0.88),
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
