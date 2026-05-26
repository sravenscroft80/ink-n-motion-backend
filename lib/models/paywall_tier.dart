/// Paywall purchase tier identifiers.
enum PaywallTierId {
  spark10,
  creator30,
  pro60,
  plusMonthly,
  plusAnnual,
}

/// Optional promotional badge on a paywall card.
enum PaywallBadge {
  mostPopular,
  bestValue,
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

  static const spark10 = PaywallTier(
    id: PaywallTierId.spark10,
    title: 'Spark Pack',
    priceLabel: '\$2.99',
    subtitle: '10 Credits',
    creditsGranted: 10,
    grantsPremium: false,
  );

  static const creator30 = PaywallTier(
    id: PaywallTierId.creator30,
    title: 'Creator Pack',
    priceLabel: '\$6.99',
    subtitle: '30 Credits',
    creditsGranted: 30,
    grantsPremium: false,
    badge: PaywallBadge.mostPopular,
  );

  static const pro60 = PaywallTier(
    id: PaywallTierId.pro60,
    title: 'Pro Pack',
    priceLabel: '\$12.99',
    subtitle: '60 Credits',
    creditsGranted: 60,
    grantsPremium: false,
  );

  static const plusMonthly = PaywallTier(
    id: PaywallTierId.plusMonthly,
    title: 'Ink Plus Monthly',
    priceLabel: '\$9.99/month',
    subtitle: '30 premium renders / month · no watermark',
    creditsGranted: 0,
    grantsPremium: true,
  );

  static const plusAnnual = PaywallTier(
    id: PaywallTierId.plusAnnual,
    title: 'Ink Plus Annual',
    priceLabel: '\$79.99/year',
    subtitle: '30 premium renders / month · no watermark',
    creditsGranted: 0,
    grantsPremium: true,
    badge: PaywallBadge.bestValue,
    secondaryPriceLabel: '\$6.67/mo',
  );

  static const List<PaywallTier> creditPacks = [
    spark10,
    creator30,
    pro60,
  ];

  static const List<PaywallTier> subscriptions = [
    plusMonthly,
    plusAnnual,
  ];

  static const List<PaywallTier> all = [
    ...creditPacks,
    ...subscriptions,
  ];
}
