import 'package:flutter/cupertino.dart';
import 'package:ink_n_motion/screens/home_shell_screen.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';
import 'package:ink_n_motion/widgets/ink_frosted_glass.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  static const _pages = [
    _OnboardingPage(
      icon: CupertinoIcons.camera_viewfinder,
      title: 'Capture your art',
      subtitle: 'Frame your drawing with a native camera-style viewport.',
    ),
    _OnboardingPage(
      icon: CupertinoIcons.sparkles,
      title: 'Pick a motion style',
      subtitle: 'Browse placeholder styles — premium packs arrive later.',
    ),
    _OnboardingPage(
      icon: CupertinoIcons.play_rectangle,
      title: 'Generate & share',
      subtitle: 'Easy or Premium video loops with credit-based placeholders.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (_pageIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    Navigator.of(context).pushReplacement(
      CupertinoPageRoute<void>(builder: (_) => const HomeShellScreen()),
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
                onPageChanged: (i) => setState(() => _pageIndex = i),
                itemCount: _pages.length,
                itemBuilder: (_, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(InkSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkFrostedGlass(
                          padding: const EdgeInsets.all(InkSpacing.xl),
                          borderRadius: InkRadius.xl,
                          child: Icon(
                            page.icon,
                            size: 56,
                            color: InkColors.accentNeonCyan,
                          ),
                        ),
                        const SizedBox(height: InkSpacing.xl),
                        Text(page.title, style: InkTypography.title1, textAlign: TextAlign.center),
                        const SizedBox(height: InkSpacing.md),
                        Text(
                          page.subtitle,
                          style: InkTypography.body.copyWith(color: InkColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final active = i == _pageIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? InkColors.accentNeonCyan : InkColors.textTertiary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.all(InkSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: _onContinue,
                  child: Text(_pageIndex == _pages.length - 1 ? 'Get Started' : 'Continue'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}
