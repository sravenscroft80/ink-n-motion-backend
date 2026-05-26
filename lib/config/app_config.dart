/// Client-side configuration (FlutterFlow-compatible environment variable names).
///
/// Local / CI injection:
///   flutter run --dart-define-from-file=config/app.env
///   flutter build apk --dart-define-from-file=config/app.env
abstract final class AppConfig {
  /// RevenueCat Google Play **public** SDK key (safe to embed in the mobile app).
  static const String revenueCatAndroidApiKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY',
  );

  /// RevenueCat App Store **public** SDK key (set when iOS billing goes live).
  static const String revenueCatIosApiKey = String.fromEnvironment(
    'REVENUECAT_IOS_API_KEY',
  );

  static bool get hasRevenueCatAndroidKey => revenueCatAndroidApiKey.isNotEmpty;

  static bool get hasRevenueCatIosKey => revenueCatIosApiKey.isNotEmpty;

  /// Firebase Web/Android/iOS client config (public — safe to embed).
  static const String firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String firebaseMessagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const String firebaseProjectId =
      String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String firebaseAuthDomain =
      String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const String firebaseStorageBucket =
      String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static const String firebaseIosBundleId =
      String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');
  static const String firebaseAndroidClientId =
      String.fromEnvironment('FIREBASE_ANDROID_CLIENT_ID');

  static bool get isFirebaseConfigured =>
      firebaseProjectId.isNotEmpty &&
      firebaseApiKey.isNotEmpty &&
      firebaseAppId.isNotEmpty;
}
