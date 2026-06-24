import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ink_n_motion/config/app_config.dart';
import 'package:ink_n_motion/models/entitlement_status.dart';
import 'package:ink_n_motion/models/purchase_result.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Production RevenueCat product identifiers (App Store / Google Play).
/// Must match exactly what is configured in the RevenueCat dashboard.
abstract final class BillingProductIds {
  // ─── Credit packs (non-subscription) ────────────────────────────────────
  static const String introPack = 'ink_intro_pack'; // $6.99  · 25 tokens
  static const String creatorPack = 'ink_creator_pack'; // $14.99 · 60 tokens
  static const String studioPack = 'ink_studio_pack'; // $27.99 · 130 tokens

  // ─── Monthly subscriptions ───────────────────────────────────────────────
  static const String sparkMonthly = 'ink_spark_monthly'; // $8.99/mo  · 50 tokens
  static const String flowMonthly = 'ink_flow_monthly'; // $14.99/mo · 110 tokens
  static const String studioMonthly = 'ink_studio_monthly'; // $24.99/mo · 300 tokens

  /// Maps a product ID → token grant for local wallet credit after purchase.
  static int tokensForProduct(String productId) {
    switch (productId) {
      case introPack:
        return 25;
      case creatorPack:
        return 60;
      case studioPack:
        return 130;
      case sparkMonthly:
        return 50;
      case flowMonthly:
        return 110;
      case studioMonthly:
        return 300;
      default:
        return 0;
    }
  }

  /// Maps a product ID → subscription tier string stored in Firestore.
  /// Returns null for non-subscription (credit pack) products.
  static String? tierForProduct(String productId) {
    switch (productId) {
      case sparkMonthly:
        return 'spark';
      case flowMonthly:
        return 'flow';
      case studioMonthly:
        return 'studio';
      default:
        return null;
    }
  }
}

/// RevenueCat entitlement identifiers configured in the dashboard.
abstract final class BillingEntitlements {
  static const String inkMotionPro = 'ink_motion_pro';
}

/// RevenueCat initialization and store purchase wrappers.
abstract final class BillingService {
  static bool _isConfigured = false;

  static bool get isConfigured => _isConfigured;

  /// Configures the RevenueCat SDK for the current mobile platform.
  static Future<void> init() async {
    if (kIsWeb || (!Platform.isIOS && !Platform.isAndroid)) {
      return;
    }

    if (_isConfigured) return;

    final apiKey = Platform.isIOS
        ? AppConfig.revenueCatIosApiKey
        : AppConfig.revenueCatAndroidApiKey;

    if (apiKey.isEmpty) {
      debugPrint(
        'BillingService: missing RevenueCat API key for '
        '${Platform.isIOS ? "iOS" : "Android"} — '
        'run with --dart-define-from-file=config/app.env',
      );
      return;
    }

    await Purchases.configure(PurchasesConfiguration(apiKey));
    _isConfigured = true;
  }

  /// Links the RevenueCat customer to the Firebase uid for cross-device continuity.
  static Future<String?> linkToFirebaseUser(String firebaseUid) async {
    if (!_isConfigured || firebaseUid.isEmpty) return null;

    try {
      final anonymousId = await Purchases.appUserID;
      final loginResult = await Purchases.logIn(firebaseUid);
      debugPrint(
        'BillingService: RevenueCat linked anonymousId=$anonymousId -> firebaseUid=$firebaseUid',
      );
      return loginResult.customerInfo.originalAppUserId;
    } on PlatformException catch (error) {
      debugPrint(
        'BillingService: RevenueCat logIn failed — ${error.code}: ${error.message}',
      );
      return null;
    } catch (error, stackTrace) {
      debugPrint('BillingService: unexpected RevenueCat logIn error — $error');
      debugPrint('$stackTrace');
      return null;
    }
  }

  /// Reads whether [BillingEntitlements.inkMotionPro] is active on [customerInfo].
  static bool readProEntitlement(CustomerInfo customerInfo) {
    return customerInfo.entitlements.all[BillingEntitlements.inkMotionPro]
            ?.isActive ??
        false;
  }

  /// Fetches current customer info and returns Pro entitlement status.
  static Future<EntitlementStatus> checkEntitlements() async {
    if (!_isConfigured) {
      return const EntitlementStatus(
        hasProEntitlement: false,
        isAvailable: false,
      );
    }

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final hasProEntitlement = readProEntitlement(customerInfo);

      debugPrint(
        'BillingService: entitlement sync ink_motion_pro=$hasProEntitlement',
      );

      return EntitlementStatus(
        hasProEntitlement: hasProEntitlement,
        isAvailable: true,
      );
    } on PlatformException catch (error) {
      debugPrint(
        'BillingService: checkEntitlements failed — ${error.code}: ${error.message}',
      );
      return const EntitlementStatus(
        hasProEntitlement: false,
        isAvailable: false,
      );
    } catch (error, stackTrace) {
      debugPrint('BillingService: unexpected checkEntitlements error — $error');
      debugPrint('$stackTrace');
      return const EntitlementStatus(
        hasProEntitlement: false,
        isAvailable: false,
      );
    }
  }

  /// Returns the current RevenueCat app user id.
  static Future<String?> currentAppUserId() async {
    if (!_isConfigured) return null;
    try {
      return Purchases.appUserID;
    } catch (error) {
      debugPrint('BillingService: unable to read appUserID — $error');
      return null;
    }
  }

  /// Restores previous App Store / Google Play purchases via RevenueCat.
  static Future<CustomerInfo?> restorePurchases() async {
    if (!_isConfigured) return null;

    try {
      final customerInfo = await Purchases.restorePurchases();
      debugPrint('BillingService: restorePurchases completed');
      return customerInfo;
    } on PlatformException catch (error) {
      debugPrint(
        'BillingService: restorePurchases failed — ${error.code}: ${error.message}',
      );
      return null;
    } catch (error, stackTrace) {
      debugPrint('BillingService: unexpected restorePurchases error — $error');
      debugPrint('$stackTrace');
      return null;
    }
  }

  /// Fetches [productId] from the store and completes a RevenueCat purchase.
  static Future<PurchaseResult> purchaseProduct(
    String productId, {
    required bool isSubscription,
  }) async {
    if (!_isConfigured) {
      debugPrint(
          'BillingService: SDK not configured — skipping purchase for $productId');
      return PurchaseResult.notConfigured();
    }

    try {
      final products = await Purchases.getProducts(
        [productId],
        productCategory: isSubscription
            ? ProductCategory.subscription
            : ProductCategory.nonSubscription,
      );

      if (products.isEmpty) {
        debugPrint('BillingService: product not found — $productId');
        return PurchaseResult.productNotFound(
          'Product "$productId" was not returned by the App Store. '
          'Confirm it exists in App Store Connect and RevenueCat.',
        );
      }

      final customerInfo =
          await Purchases.purchaseStoreProduct(products.first);
      return PurchaseResult.fromStoreSuccess(customerInfo);
    } on PlatformException catch (error) {
      final errorCode = PurchasesErrorHelper.getErrorCode(error);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('BillingService: purchase cancelled for $productId');
        return PurchaseResult.cancelled();
      }
      final message = _formatPurchaseError(errorCode, error, productId);
      debugPrint(
        'BillingService: purchase failed for $productId — $message',
      );
      return PurchaseResult.error(message);
    } catch (error, stackTrace) {
      debugPrint('BillingService: unexpected purchase error — $error');
      debugPrint('$stackTrace');
      return PurchaseResult.error('Purchase failed for "$productId": $error');
    }
  }

  static String _formatPurchaseError(
    PurchasesErrorCode errorCode,
    PlatformException error,
    String productId,
  ) {
    final rcCode = errorCode.name;
    final platformCode = error.code;
    final detail = error.message?.trim();
    final detailSuffix =
        detail != null && detail.isNotEmpty ? ' — $detail' : '';

    switch (errorCode) {
      case PurchasesErrorCode.storeProblemError:
        return 'App Store error ($rcCode/$platformCode)$detailSuffix';
      case PurchasesErrorCode.purchaseNotAllowedError:
        return 'Purchases are not allowed on this device ($rcCode)';
      case PurchasesErrorCode.productNotAvailableForPurchaseError:
        return 'Product "$productId" is not available for purchase ($rcCode). '
            'Confirm it is Ready to Submit in App Store Connect and attached '
            'to the submission.';
      case PurchasesErrorCode.productAlreadyPurchasedError:
        return 'You already own "$productId" ($rcCode). Try Restore Purchases.';
      case PurchasesErrorCode.networkError:
        return 'Network error during purchase ($rcCode)$detailSuffix';
      case PurchasesErrorCode.receiptAlreadyInUseError:
        return 'Receipt already in use ($rcCode)$detailSuffix';
      case PurchasesErrorCode.invalidCredentialsError:
        return 'RevenueCat credentials error ($rcCode)$detailSuffix';
      default:
        return 'Purchase failed for "$productId" ($rcCode/$platformCode)$detailSuffix';
    }
  }
}
