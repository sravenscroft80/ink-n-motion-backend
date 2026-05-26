/// Result of a RevenueCat entitlement sync.
class EntitlementStatus {
  const EntitlementStatus({
    required this.hasProEntitlement,
    required this.isAvailable,
    this.hasStudioEntitlement = false,
  });

  /// true when Ink-N-Motion Pro entitlement is active (Pro or Studio subscriber).
  final bool hasProEntitlement;

  /// true when ink_studio entitlement is active (Studio tier only).
  final bool hasStudioEntitlement;

  /// true when RevenueCat SDK is configured and responded successfully.
  final bool isAvailable;

  bool get isStudioSubscriber => hasStudioEntitlement;
  bool get isProSubscriber => hasProEntitlement && !hasStudioEntitlement;
}
