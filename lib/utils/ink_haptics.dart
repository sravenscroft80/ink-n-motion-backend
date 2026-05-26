import 'package:flutter/services.dart';

/// Centralized tactile feedback for Ink‑N‑Motion actions.
abstract final class InkHaptics {
  static Future<void> shutterCapture() => HapticFeedback.mediumImpact();

  static Future<void> generationSuccess() => HapticFeedback.successNotification();

  static Future<void> purchaseSuccess() => HapticFeedback.vibrate();

  static Future<void> blockedOrError() => HapticFeedback.heavyImpact();
}
