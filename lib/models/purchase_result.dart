import 'package:purchases_flutter/purchases_flutter.dart';

/// Outcome of an in-app purchase attempt (store + wallet credit).
enum PurchaseOutcome {
  success,
  cancelled,
  notConfigured,
  productNotFound,
  creditFailed,
  error,
}

/// Result returned from [BillingService.purchaseProduct] and purchase notifiers.
class PurchaseResult {
  const PurchaseResult({
    required this.outcome,
    this.customerInfo,
    this.message,
  });

  final PurchaseOutcome outcome;
  final CustomerInfo? customerInfo;
  final String? message;

  bool get isSuccess => outcome == PurchaseOutcome.success;

  static const PurchaseResult successResult =
      PurchaseResult(outcome: PurchaseOutcome.success);

  static PurchaseResult cancelled([String? message]) => PurchaseResult(
        outcome: PurchaseOutcome.cancelled,
        message: message,
      );

  static PurchaseResult notConfigured([String? message]) => PurchaseResult(
        outcome: PurchaseOutcome.notConfigured,
        message: message,
      );

  static PurchaseResult productNotFound([String? message]) => PurchaseResult(
        outcome: PurchaseOutcome.productNotFound,
        message: message,
      );

  static PurchaseResult creditFailed([String? message]) => PurchaseResult(
        outcome: PurchaseOutcome.creditFailed,
        message: message,
      );

  static PurchaseResult error([String? message]) => PurchaseResult(
        outcome: PurchaseOutcome.error,
        message: message,
      );

  static PurchaseResult fromStoreSuccess(CustomerInfo customerInfo) =>
      PurchaseResult(
        outcome: PurchaseOutcome.success,
        customerInfo: customerInfo,
      );
}
