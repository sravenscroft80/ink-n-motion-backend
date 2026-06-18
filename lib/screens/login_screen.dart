import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ink_n_motion/screens/home_shell_screen.dart';
import 'package:ink_n_motion/screens/onboarding_carousel_screen.dart';
import 'package:ink_n_motion/services/firebase_auth_service.dart';
import 'package:ink_n_motion/state/providers.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';
import 'package:ink_n_motion/widgets/ink_neon_glow.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Cupertino sign-in gate — Apple, Google, or continue as guest.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  Future<void> _navigateAfterAuth() async {
    if (!mounted) return;

    final hasCompletedOnboarding =
        ref.read(appStateProvider).hasCompletedOnboarding;
    final nextScreen = hasCompletedOnboarding
        ? const HomeShellScreen()
        : const OnboardingCarouselScreen();

    await Navigator.of(context).pushReplacement(
      CupertinoPageRoute<void>(builder: (_) => nextScreen),
    );
  }

  void _showError(String message) {
    debugPrint('LoginScreen sign-in error: $message');
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Sign In Failed'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _authErrorMessage(Object error, {required String providerLabel}) {
    if (error is ExistingAccountSignInRequiredException) {
      return error.userMessage;
    }
    if (error is FirebaseAuthException) {
      final detail = error.message?.trim();
      if (detail != null && detail.isNotEmpty) {
        return '$providerLabel sign-in failed (${error.code}): $detail';
      }
      return '$providerLabel sign-in failed (${error.code})';
    }
    if (error is SignInWithAppleAuthorizationException) {
      final detail = error.message.trim();
      if (detail.isNotEmpty) {
        return '$providerLabel authorization failed (${error.code.name}): $detail';
      }
      return '$providerLabel authorization failed (${error.code.name})';
    }
    if (error is StateError) {
      return error.message;
    }
    return '$providerLabel sign-in failed: $error';
  }

  Future<void> _handleAppleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(firebaseAuthServiceProvider);
      final user = await authService.signInWithApple();
      if (!mounted) return;
      if (user == null) return;
      await _navigateAfterAuth();
    } catch (error, stackTrace) {
      debugPrint('LoginScreen._handleAppleSignIn failed: $error');
      debugPrint('$stackTrace');
      if (mounted) {
        _showError(_authErrorMessage(error, providerLabel: 'Apple'));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(firebaseAuthServiceProvider);
      final user = await authService.signInWithGoogle();
      if (!mounted) return;
      if (user == null) return;
      await _navigateAfterAuth();
    } catch (error, stackTrace) {
      debugPrint('LoginScreen._handleGoogleSignIn failed: $error');
      debugPrint('$stackTrace');
      if (mounted) {
        _showError(_authErrorMessage(error, providerLabel: 'Google'));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _continueAsGuest() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(firebaseAuthServiceProvider);
      await authService.ensureSignedIn();
      if (!mounted) return;
      await _navigateAfterAuth();
    } catch (_) {
      if (mounted) {
        _showError('Unable to continue as guest. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showAppleButton = !kIsWeb;

    return CupertinoPageScaffold(
      backgroundColor: InkColors.backgroundPrimary,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: InkSpacing.lg),
          child: Column(
            children: [
              const Spacer(flex: 2),
              InkNeonGlow(
                color: InkColors.accentNeonCyan,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: InkColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(InkRadius.xl),
                    border: Border.all(
                      color: InkColors.accentNeonCyan.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    CupertinoIcons.wand_stars,
                    size: 40,
                    color: InkColors.accentNeonCyan,
                  ),
                ),
              ),
              const SizedBox(height: InkSpacing.lg),
              const Text('Ink‑N‑Motion', style: InkTypography.largeTitle),
              const SizedBox(height: InkSpacing.sm),
              Text(
                'Sign in to save your designs',
                style: InkTypography.subhead.copyWith(
                  color: InkColors.textSecondary,
                ),
              ),
              const Spacer(flex: 3),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: InkSpacing.lg),
                  child: CupertinoActivityIndicator(radius: 14),
                ),
              if (showAppleButton) ...[
                _SignInButton(
                  backgroundColor: CupertinoColors.black,
                  foregroundColor: CupertinoColors.white,
                  borderColor: CupertinoColors.white.withValues(alpha: 0.15),
                  onPressed: _isLoading ? null : _handleAppleSignIn,
                  leading: const Text(
                    '\uF8FF',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 20,
                      height: 1,
                    ),
                  ),
                  label: 'Sign in with Apple',
                ),
                const SizedBox(height: InkSpacing.md),
              ],
              _SignInButton(
                backgroundColor: CupertinoColors.white,
                foregroundColor: const Color(0xFF1F1F1F),
                borderColor: CupertinoColors.systemGrey4,
                onPressed: _isLoading ? null : _handleGoogleSignIn,
                leading: const Text(
                  'G',
                  style: TextStyle(
                    color: Color(0xFFEA4335),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                label: 'Sign in with Google',
              ),
              const SizedBox(height: InkSpacing.lg),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: InkSpacing.sm),
                onPressed: _isLoading ? null : () => unawaited(_continueAsGuest()),
                child: Text(
                  'Continue as Guest',
                  style: InkTypography.subhead.copyWith(
                    color: InkColors.textSecondary,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignInButton extends StatelessWidget {
  const _SignInButton({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.leading,
    required this.label,
    required this.onPressed,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final Widget leading;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(InkRadius.md),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            leading,
            const SizedBox(width: InkSpacing.sm),
            Text(
              label,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
