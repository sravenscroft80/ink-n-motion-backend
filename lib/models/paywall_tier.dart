/// Paywall purchase tier identifiers.
enum PaywallTierId {
  introPack,
  creatorPack,
  studioPack,
  sparkMonthly,
  flowMonthly,
  studioMonthly,
}

/// Optional promotional badge on a paywall card.
enum PaywallBadge {
  mostPopular,
  bestValue,
  artistDirectory,
}

/// Immutable paywall tier presentation + credit/subscription mapping.
class PaywallTier {
  const PaywallTier({
    required this.id,
    required this.title,
    required this.priceLabel,
    required this.subtitle,
    required this.creditsGranted,
    required this.grantsPremium,
    this.badge,
    this.secondaryPriceLabel,
  });

  final PaywallTierId id;
  final String title;
  final String priceLabel;
  final String subtitle;
  final int creditsGranted;
  final bool grantsPremium;
  final PaywallBadge? badge;
  final String? secondaryPriceLabel;

  // ─── CREDIT PACKS ────────────────────────────────────────────────────────

  /// $6.99 · 25 tokens · 2 full animations with 5 left over (casino pull).
  static const introPack = PaywallTier(
    id: PaywallTierId.introPack,
    title: 'Intro Pack',
    priceLabel: '\$6.99',
    subtitle: '25 Tokens · Try the magic',
    creditsGranted: 25,
    grantsPremium: false,
  );

  /// $14.99 · 60 tokens · best pack value.
  static const creatorPack = PaywallTier(
    id: PaywallTierId.creatorPack,
    title: 'Creator Pack',
    priceLabel: '\$14.99',
    subtitle: '60 Tokens · More renders, more wow',
    creditsGranted: 60,
    grantsPremium: false,
    badge: PaywallBadge.mostPopular,
  );

  /// $27.99 · 130 tokens · makes monthly look like a deal.
  static const studioPack = PaywallTier(
    id: PaywallTierId.studioPack,
    title: 'Studio Pack',
    priceLabel: '\$27.99',
    subtitle: '130 Tokens · Best pack value',
    creditsGranted: 130,
    grantsPremium: false,
    badge: PaywallBadge.bestValue,
  );

  // ─── MONTHLY SUBSCRIPTIONS ───────────────────────────────────────────────

  /// $8.99/mo · 50 tokens · entry subscription.
  static const sparkMonthly = PaywallTier(
    id: PaywallTierId.sparkMonthly,
    title: 'Ink Spark',
    priceLabel: '\$8.99/mo',
    subtitle: '50 tokens / month · refreshed monthly',
    creditsGranted: 50,
    grantsPremium: true,
  );

  /// $14.99/mo · 100 tokens · sweet spot subscription.
  static const flowMonthly = PaywallTier(
    id: PaywallTierId.flowMonthly,
    title: 'Ink Flow',
    priceLabel: '\$14.99/mo',
    subtitle: '100 tokens / month · best value',
    creditsGranted: 100,
    grantsPremium: true,
    badge: PaywallBadge.mostPopular,
  );

  /// $24.99/mo · 200 tokens · studio/artist tier with directory badge.
  static const studioMonthly = PaywallTier(
    id: PaywallTierId.studioMonthly,
    title: 'Ink Studio',
    priceLabel: '\$24.99/mo',
    subtitle: '200 tokens / month · Artist Directory badge (beta)',
    creditsGranted: 200,
    grantsPremium: true,
    badge: PaywallBadge.artistDirectory,
  );

  // ─── LISTS ───────────────────────────────────────────────────────────────

  static const List<PaywallTier> creditPacks = [
    introPack,
    creatorPack,
    studioPack,
  ];

  static const List<PaywallTier> subscriptions = [
    sparkMonthly,
    flowMonthly,
    studioMonthly,
  ];

  static const List<PaywallTier> all = [
    ...creditPacks,
    ...subscriptions,
  ];
}
