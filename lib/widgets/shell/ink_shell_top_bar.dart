import 'package:flutter/cupertino.dart';
import 'package:ink_n_motion/screens/settings_screen.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';
import 'package:ink_n_motion/utils/navigation.dart';
import 'package:ink_n_motion/utils/shell_layout.dart';

/// Fixed brand bar — persistent across Discover, Studio, and Gallery tabs.
class InkShellTopBar extends StatefulWidget {
  const InkShellTopBar({super.key});

  @override
  State<InkShellTopBar> createState() => _InkShellTopBarState();
}

class _InkShellTopBarState extends State<InkShellTopBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  static const String _brandLabel = 'INK • N • MOTION';

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  void _openSettings() {
    pushCupertino(context, const SettingsScreen());
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: InkColors.backgroundPrimary.withValues(alpha: 0.62),
        border: Border(
          bottom: BorderSide(
            color: InkColors.textPrimary.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: InkShellLayout.topBarContentHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: InkSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _ShimmerBrandMark(
                      animation: _shimmerController,
                      label: _brandLabel,
                    ),
                  ),
                ),
                InkProfileAvatarChip(onTap: _openSettings),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShimmerBrandMark extends StatelessWidget {
  const _ShimmerBrandMark({
    required this.animation,
    required this.label,
  });

  final Animation<double> animation;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textStyle = InkTypography.caption1.copyWith(
      color: InkColors.chromeWhite,
      letterSpacing: 2.4,
      fontWeight: FontWeight.w600,
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            final slide = animation.value * 2;
            return LinearGradient(
              begin: Alignment(-1.2 + slide, 0),
              end: Alignment(0.2 + slide, 0),
              colors: const [
                InkColors.chromeSilver,
                InkColors.platinum,
                InkColors.chromeWhite,
                InkColors.platinum,
                InkColors.chromeSilver,
              ],
              stops: const [0.0, 0.28, 0.5, 0.72, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: Text(label, style: textStyle),
    );
  }
}

/// Gold profile chip — opens settings from the shell top bar.
class InkProfileAvatarChip extends StatelessWidget {
  const InkProfileAvatarChip({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: InkColors.goldCtaGradient,
          border: Border.all(
            color: InkColors.accentGoldLight.withValues(alpha: 0.5),
          ),
        ),
        child: Icon(
          CupertinoIcons.person_fill,
          color: CupertinoColors.black.withValues(alpha: 0.88),
          size: 20,
        ),
      ),
    );
  }
}
