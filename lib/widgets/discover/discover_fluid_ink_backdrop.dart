import 'package:flutter/cupertino.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';
import 'package:ink_n_motion/utils/shell_layout.dart';

/// Dark fluid-ink hero backdrop — bleeds behind the shell top bar on Discover.
class DiscoverFluidInkBackdrop extends StatelessWidget {
  const DiscoverFluidInkBackdrop({super.key});

  static const String imageUrl =
      'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=600';

  static const double _backdropHeight = 360;

  @override
  Widget build(BuildContext context) {
    final topBleed = InkShellLayout.totalTopInset(context);

    return Positioned(
      top: -topBleed,
      left: 0,
      right: 0,
      height: _backdropHeight + topBleed,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            filterQuality: FilterQuality.medium,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const ColoredBox(
                color: InkColors.backgroundPrimary,
                child: Center(
                  child: CupertinoActivityIndicator(radius: 12),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1A1028),
                      Color(0xFF0A0A0F),
                    ],
                  ),
                ),
              );
            },
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x33000000),
                  Color(0x99000000),
                  Color(0xFF000000),
                ],
                stops: [0.0, 0.62, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
