import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ink_n_motion/screens/home_shell_screen.dart';
import 'package:ink_n_motion/state/providers.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';
import 'package:ink_n_motion/widgets/ink_frosted_glass.dart';
import 'package:ink_n_motion/widgets/ink_neon_glow.dart';

/// First-time introduction carousel before the capture workspace.
class OnboardingCarouselScreen extends ConsumerStatefulWidget {
  const OnboardingCarouselScreen({super.key});

  @override
  ConsumerState<OnboardingCarouselScreen> createState() =>
      _OnboardingCarouselScreenState();
}

class _OnboardingCarouselScreenState extends ConsumerState<OnboardingCarouselScreen> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  static const _pages = [
    _CarouselCardData(
      icon: CupertinoIcons.camera_viewfinder,
      title: 'Snap Your Ink',
      subtitle:
          'Capture any tattoo instantly from your camera roll with auto-adjusting perspective processing.',
      accent: InkColors.accentNeonCyan,
    ),
    _CarouselCardData(
      icon: CupertinoIcons.wand_stars,
      title: 'Select Your Aesthetic',
      subtitle:
          'Choose from curated premium styles including Cyberpunk Neon, Traditional Japanese, and 3D Pop Pop.',
      accent: InkColors.accentNeonMagenta,
    ),
    _CarouselCardData(
      icon: CupertinoIcons.play_circle,
      title: 'Animate into Motion',
      subtitle:
          'Deduct credits or go Unlimited to watch your design transform into high-definition looping cinematic streams.',
      accent: InkColors.accentSuccess,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isLastPage => _pageIndex == _pages.length - 1;

  Future<void> _onGetStarted() async {
    await ref.read(appStateProvider.notifier).completeOnboarding();
    if (!mounted) return;

    await Navigator.of(context).pushReplacement(
      CupertinoPageRoute<void>(builder: (_) => const HomeShellScreen()),
    );
  }

  void _onPrimaryAction() {
    if (_isLastPage) {
      unawaited(_onGetStarted());
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: InkColors.backgroundPrimary,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) => setState(() => _pageIndex = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: InkSpacing.lg,
                      vertical: InkSpacing.md,
                    ),
                    child: _OnboardingCarouselCard(page: page),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                final active = index == _pageIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active
                        ? InkColors.accentNeonCyan
                        : InkColors.textTertiary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                InkSpacing.lg,
                InkSpacing.md,
                InkSpacing.lg,
                InkSpacing.lg,
              ),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  color: _isLastPage
                      ? InkColors.accentNeonCyan
                      : InkColors.backgroundSecondary,
                  onPressed: _onPrimaryAction,
                  child: Text(
                    _isLastPage ? 'Get Started' : 'Continue',
                    style: TextStyle(
                      color: _isLastPage
                          ? CupertinoColors.black
                          : InkColors.textPrimary,
                      fontWeight:
                          _isLastPage ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingCarouselCard extends StatelessWidget {
  const _OnboardingCarouselCard({required this.page});

  final _CarouselCardData page;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkNeonGlow(
          color: page.accent,
          child: InkFrostedGlass(
            borderRadius: InkRadius.xl,
            padding: const EdgeInsets.all(InkSpacing.xl),
            child: Icon(
              page.icon,
              size: 64,
              color: page.accent,
            ),
          ),
        ),
        const SizedBox(height: InkSpacing.xl),
        Text(
          page.title,
          style: InkTypography.title1,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: InkSpacing.md),
        Text(
          page.subtitle,
          style: InkTypography.body.copyWith(color: InkColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _CarouselCardData {
  const _CarouselCardData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
}
