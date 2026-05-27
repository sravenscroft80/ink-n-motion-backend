import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:ink_n_motion/services/firestore_wallet_service.dart';

/// Keeps an anonymous auth session and exposes ID tokens for API calls.
class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? auth}) : _injectedAuth = auth;

  final FirebaseAuth? _injectedAuth;
  bool _initialized = false;

  FirebaseAuth? get _authSafe {
    try {
      return _injectedAuth ?? FirebaseAuth.instance;
    } catch (e) {
      debugPrint('FirebaseAuth.instance unavailable: $e');
      return null;
    }
  }

  bool get isAvailable => _initialized;

  User? get currentUser {
    try {
      return _authSafe?.currentUser;
    } catch (e) {
      debugPrint('FirebaseAuthService.currentUser failed: $e');
      return null;
    }
  }

  String? get uid {
    try {
      return _authSafe?.currentUser?.uid;
    } catch (e) {
      debugPrint('FirebaseAuthService.uid failed: $e');
      return null;
    }
  }

  Stream<User?> authStateChanges() {
    try {
      return _authSafe?.authStateChanges() ?? const Stream<User?>.empty();
    } catch (e) {
      debugPrint('FirebaseAuthService.authStateChanges failed: $e');
      return const Stream<User?>.empty();
    }
  }

  Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      await ensureSignedIn();
      _initialized = true;
      return true;
    } catch (e, stackTrace) {
      debugPrint('FirebaseAuthService.initialize failed: $e');
      debugPrint('$stackTrace');
      return false;
    }
  }

  /// Anonymous sign-in — stable per install until linked to a credential.
  Future<User?> ensureSignedIn() async {
    try {
      final auth = _authSafe;
      if (auth == null) return null;

      final existing = auth.currentUser;
      if (existing != null) {
        await FirestoreWalletService.instance.initializeWallet(existing.uid);
        return existing;
      }

      final credential = await auth.signInAnonymously();
      debugPrint(
        'FirebaseAuthService: signed in anonymously uid=${credential.user?.uid}',
      );
      final user = credential.user;
      if (user != null) {
        await FirestoreWalletService.instance.initializeWallet(user.uid);
      }
      return user;
    } catch (e, stackTrace) {
      debugPrint('FirebaseAuthService.ensureSignedIn failed: $e');
      debugPrint('$stackTrace');
      return null;
    }
  }

  Future<String?> getIdToken({bool forceRefresh = false}) async {
    try {
      final auth = _authSafe;
      if (auth == null) return null;

      final user = auth.currentUser ?? await ensureSignedIn();
      if (user == null) return null;
      return user.getIdToken(forceRefresh);
    } catch (e, stackTrace) {
      debugPrint('FirebaseAuthService.getIdToken failed: $e');
      debugPrint('$stackTrace');
      return null;
    }
  }
}
