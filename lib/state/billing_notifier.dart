import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ink_n_motion/services/billing_service.dart';
import 'package:ink_n_motion/state/app_state_notifier.dart';

class BillingState {
  const BillingState({
    this.hasProEntitlement = false,
    this.hasStudioEntitlement = false,
    this.isRevenueCatAvailable = false,
    this.isSyncing = false,
    this.hasSyncedOnLaunch = false,
  });

  final bool hasProEntitlement;
  final bool hasStudioEntitlement;
  final bool isRevenueCatAvailable;
  final bool isSyncing;
  final bool hasSyncedOnLaunch;

  BillingState copyWith({
    bool? hasProEntitlement,
    bool? hasStudioEntitlement,
    bool? isRevenueCatAvailable,
    bool? isSyncing,
    bool? hasSyncedOnLaunch,
  }) {
    return BillingState(
      hasProEntitlement: hasProEntitlement ?? this.hasProEntitlement,
      hasStudioEntitlement: hasStudioEntitlement ?? this.hasStudioEntitlement,
      isRevenueCatAvailable:
          isRevenueCatAvailable ?? this.isRevenueCatAvailable,
      isSyncing: isSyncing ?? this.isSyncing,
      hasSyncedOnLaunch: hasSyncedOnLaunch ?? this.hasSyncedOnLaunch,
    );
  }
}

class BillingNotifier extends StateNotifier<BillingState> {
  BillingNotifier({
    required AppStateNotifier Function() readAppStateNotifier,
  })  : _readAppStateNotifier = readAppStateNotifier,
        super(const BillingState()) {
    unawaited(syncEntitlementsOnLaunch());
  }

  final AppStateNotifier Function() _readAppStateNotifier;

  Future<void> syncEntitlementsOnLaunch() =>
      refreshEntitlements(markLaunchSynced: true);

  Future<void> refreshEntitlements({bool markLaunchSynced = false}) async {
    state = state.copyWith(isSyncing: true);
    final status = await BillingService.checkEntitlements();

    state = state.copyWith(
      isSyncing: false,
      hasProEntitlement: status.hasProEntitlement,
      hasStudioEntitlement: status.hasStudioEntitlement,
      isRevenueCatAvailable: status.isAvailable,
      hasSyncedOnLaunch: markLaunchSynced ? true : state.hasSyncedOnLaunch,
    );

    if (status.isAvailable) {
      _readAppStateNotifier().applyPremiumEntitlement(
        status.hasProEntitlement,
      );
      debugPrint(
        'BillingNotifier: synced isPro=${status.hasProEntitlement} '
        'isStudio=${status.hasStudioEntitlement}',
      );
    }
  }
}
