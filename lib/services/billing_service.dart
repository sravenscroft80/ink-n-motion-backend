import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ink_n_motion/config/app_config.dart';
import 'package:ink_n_motion/models/entitlement_status.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Production RevenueCat product identifiers (App Store / Google Play).
abstract final class BillingProductIds {
  static const String spark10 = 'ink_spark_10';
  static const String creator30 = 'ink_creator_30';
  static const String pro60 = 'ink_pro_60';
  static const String plusMonthly = 'ink_plus_monthly';
  static const String plusAnnual = 'ink_plus_annual';
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

  /// Returns the current RevenueCat app user id (anonymous before [linkToFirebaseUser]).
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
  static Future<CustomerInfo?> purchaseProduct(
    String productId, {
    required bool isSubscription,
  }) async {
    if (!_isConfigured) {
      debugPrint('BillingService: SDK not configured — skipping purchase for $productId');
      return null;
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
        return null;
      }

      final customerInfo = await Purchases.purchaseStoreProduct(products.first);
      return customerInfo;
    } on PlatformException catch (error) {
      final errorCode = PurchasesErrorHelper.getErrorCode(error);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('BillingService: purchase cancelled for $productId');
      } else {
        debugPrint(
          'BillingService: purchase failed for $productId — '
          '${error.code}: ${error.message}',
        );
      }
      return null;
    } catch (error, stackTrace) {
      debugPrint('BillingService: unexpected purchase error — $error');
      debugPrint('$stackTrace');
      return null;
    }
  }
}
