import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ink_n_motion/firebase_options.dart';
import 'package:ink_n_motion/services/firestore_wallet_service.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Keeps auth sessions (anonymous or linked) and exposes ID tokens for API calls.
class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _injectedAuth = auth,
        _injectedGoogleSignIn = googleSignIn;

  final FirebaseAuth? _injectedAuth;
  final GoogleSignIn? _injectedGoogleSignIn;
  bool _initialized = false;

  FirebaseAuth? get _authSafe {
    try {
      return _injectedAuth ?? FirebaseAuth.instance;
    } catch (e) {
      debugPrint('FirebaseAuth.instance unavailable: $e');
      return null;
    }
  }

  GoogleSignIn get _googleSignIn {
    final injected = _injectedGoogleSignIn;
    if (injected != null) {
      return injected;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return GoogleSignIn(
        clientId: DefaultFirebaseOptions.ios.iosClientId,
      );
    }
    return GoogleSignIn();
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

  bool get isAnonymous {
    final user = currentUser;
    return user == null || user.isAnonymous;
  }

  String? get displayName => currentUser?.displayName;

  String? get email => currentUser?.email;

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

  Future<User?> signInWithApple() async {
    try {
      final auth = _authSafe;
      if (auth == null) return null;

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        final isAvailable = await SignInWithApple.isAvailable();
        if (!isAvailable) {
          throw StateError(
            'Sign in with Apple is not available on this device.',
          );
        }
      }

      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final identityToken = appleCredential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        throw StateError('Apple Sign-In returned no identity token.');
      }

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: identityToken,
        rawNonce: rawNonce,
      );

      final user = await _signInOrLinkCredential(auth, oauthCredential);

      if (user != null &&
          appleCredential.givenName != null &&
          user.displayName == null) {
        final givenName = appleCredential.givenName ?? '';
        final familyName = appleCredential.familyName ?? '';
        final fullName = '$givenName $familyName'.trim();
        if (fullName.isNotEmpty) {
          await user.updateDisplayName(fullName);
        }
      }

      if (user != null) {
        await FirestoreWalletService.instance.initializeWallet(user.uid);
      }
      return user;
    } on SignInWithAppleAuthorizationException catch (e, stackTrace) {
      if (e.code == AuthorizationErrorCode.canceled) {
        debugPrint('FirebaseAuthService.signInWithApple cancelled by user');
        return null;
      }
      debugPrint(
        'FirebaseAuthService.signInWithApple authorization failed: '
        '${e.code} ${e.message}',
      );
      debugPrint('$stackTrace');
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('FirebaseAuthService.signInWithApple failed: $e');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final auth = _authSafe;
      if (auth == null) return null;

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final oauthCredential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final user = await _signInOrLinkCredential(auth, oauthCredential);
      if (user != null) {
        await FirestoreWalletService.instance.initializeWallet(user.uid);
      }
      return user;
    } catch (e, stackTrace) {
      debugPrint('FirebaseAuthService.signInWithGoogle failed: $e');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _authSafe?.signOut();
      await ensureSignedIn();
    } catch (e, stackTrace) {
      debugPrint('FirebaseAuthService.signOut failed: $e');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  Future<User?> _signInOrLinkCredential(
    FirebaseAuth auth,
    AuthCredential credential,
  ) async {
    final current = auth.currentUser;
    if (current != null && current.isAnonymous) {
      try {
        final linked = await current.linkWithCredential(credential);
        return linked.user;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use' ||
            e.code == 'email-already-in-use' ||
            e.code == 'account-exists-with-different-credential') {
          // Anonymous session can't be linked — sign into the existing account.
          await auth.signOut();
          final signedIn = await auth.signInWithCredential(credential);
          return signedIn.user;
        }
        rethrow;
      }
    }
    final signedIn = await auth.signInWithCredential(credential);
    return signedIn.user;
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

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
