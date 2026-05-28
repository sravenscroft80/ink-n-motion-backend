import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ink_n_motion/screens/home_shell_screen.dart';
import 'package:ink_n_motion/screens/login_screen.dart';
import 'package:ink_n_motion/screens/onboarding_carousel_screen.dart';
import 'package:ink_n_motion/state/providers.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';
import 'package:ink_n_motion/widgets/ink_neon_glow.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(_bootSequence());
  }

  Future<void> _bootSequence() async {
    await Future<void>.delayed(const Duration(milliseconds: 2200));

    final notifier = ref.read(appStateProvider.notifier);
    ref.read(billingProvider.notifier);

    while ((!notifier.isHydrated ||
            !ref.read(billingProvider).hasSyncedOnLaunch) &&
        mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }

    if (!mounted) return;

    final authService = ref.read(firebaseAuthServiceProvider);
    final user = authService.currentUser;

    final Widget nextScreen;
    if (user == null || authService.isAnonymous) {
      nextScreen = const LoginScreen();
    } else {
      final hasCompletedOnboarding =
          ref.read(appStateProvider).hasCompletedOnboarding;
      nextScreen = hasCompletedOnboarding
          ? const HomeShellScreen()
          : const OnboardingCarouselScreen();
    }

    await Navigator.of(context).pushReplacement(
      CupertinoPageRoute<void>(builder: (_) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: InkColors.backgroundPrimary,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            Text('Ink‑N‑Motion', style: InkTypography.largeTitle),
            const SizedBox(height: InkSpacing.sm),
            Text(
              'Motion from your ink',
              style: InkTypography.subhead,
            ),
            const SizedBox(height: InkSpacing.xl),
            const CupertinoActivityIndicator(radius: 12),
          ],
        ),
      ),
    );
  }
}
