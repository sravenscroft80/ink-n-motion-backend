import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Keeps an anonymous auth session and exposes ID tokens for API calls.
class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? auth}) : _injectedAuth = auth;

  final FirebaseAuth? _injectedAuth;
  bool _initialized = false;

  FirebaseAuth get _auth => _injectedAuth ?? FirebaseAuth.instance;

  FirebaseAuth? get _authSafe {
    try {
      return _injectedAuth ?? FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  bool get isAvailable => _initialized;

  User? get currentUser => _authSafe?.currentUser;

  String? get uid => _authSafe?.currentUser?.uid;

  Stream<User?> authStateChanges() =>
      _authSafe?.authStateChanges() ?? const Stream<User?>.empty();

  Future<bool> initialize() async {
    if (_initialized) return true;

    await ensureSignedIn();
    _initialized = true;
    return true;
  }

  /// Anonymous sign-in — stable per install until linked to a credential.
  Future<User?> ensureSignedIn() async {
    final existing = _auth.currentUser;
    if (existing != null) return existing;

    final credential = await _auth.signInAnonymously();
    debugPrint(
      'FirebaseAuthService: signed in anonymously uid=${credential.user?.uid}',
    );
    return credential.user;
  }

  Future<String?> getIdToken({bool forceRefresh = false}) async {
    final user = _auth.currentUser ?? await ensureSignedIn();
    if (user == null) return null;
    return user.getIdToken(forceRefresh);
  }
}
