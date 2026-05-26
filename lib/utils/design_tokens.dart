import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Ink-N-Motion design tokens — see DESIGN.md for full specification.
abstract final class InkColors {
  static const Color backgroundPrimary = Color(0xFF0A0A0F);
  static const Color backgroundSecondary = Color(0xFF14141C);
  static const Color backgroundElevated = Color(0xFF1C1C28);

  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFF8E8E93);
  /// Premium label / muted caption grey (#888888).
  static const Color textSecondaryMuted = Color(0xFF888888);
  static const Color textTertiary = Color(0xFF636366);

  static const Color accentNeonCyan = Color(0xFF00E5FF);
  /// Studio canvas glow / free-style selection highlight.
  static const Color accentTeal = Color(0xFF00E5CC);
  static const Color accentNeonMagenta = Color(0xFFFF2D92);
  static const Color accentNeonViolet = Color(0xFFBF5AF2);
  static const Color accentSuccess = Color(0xFF30D158);
  static const Color accentWarning = Color(0xFFFFD60A);
  static const Color accentError = Color(0xFFFF453A);

  /// Premium gold palette — Discover / Studio marketing surfaces.
  static const Color accentGold = Color(0xFFD4AF37);
  /// Bright gold for active CTAs (#F5C842).
  static const Color accentGoldBright = Color(0xFFF5C842);
  static const Color accentGoldLight = Color(0xFFE8C547);
  static const Color accentGoldDark = Color(0xFFB8862E);
  static const Color accentGoldMuted = Color(0xFF8A7340);

  static const Color premiumGradientStart = Color(0xFFC850C0);
  static const Color premiumGradientEnd = Color(0xFF4158D0);

  static const LinearGradient premiumChipGradient = LinearGradient(
    colors: [premiumGradientStart, premiumGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldCtaGradient = LinearGradient(
    colors: [accentGoldBright, accentGold, accentGoldDark],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Cool metallics for the shell brand shimmer.
  static const Color chromeSilver = Color(0xFF8E939C);
  static const Color platinum = Color(0xFFC4C8D0);
  static const Color chromeWhite = Color(0xFFF2F4F8);
}

abstract final class InkSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

abstract final class InkRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

abstract final class InkTypography {
  static const TextStyle largeTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    height: 41 / 34,
    color: InkColors.textPrimary,
    letterSpacing: 0.37,
  );

  static const TextStyle title1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 34 / 28,
    color: InkColors.textPrimary,
  );

  static const TextStyle title2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 28 / 22,
    color: InkColors.textPrimary,
  );

  static const TextStyle title3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 25 / 20,
    color: InkColors.textPrimary,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 22 / 17,
    color: InkColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 22 / 17,
    color: InkColors.textPrimary,
  );

  static const TextStyle callout = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 21 / 16,
    color: InkColors.textPrimary,
  );

  static const TextStyle subhead = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 20 / 15,
    color: InkColors.textSecondary,
  );

  static const TextStyle footnote = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 18 / 13,
    color: InkColors.textSecondary,
  );

  static const TextStyle caption1 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    color: InkColors.textSecondary,
  );

  static const TextStyle caption2 = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 13 / 11,
    color: InkColors.textTertiary,
  );

  /// Section labels — STUDIO ARENA, STYLE, etc.
  static const TextStyle sectionLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 3.0,
    color: InkColors.textSecondaryMuted,
  );
}

/// Teal studio spinner — 24px diameter.
class InkActivityIndicator extends StatelessWidget {
  const InkActivityIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoActivityIndicator(
      color: InkColors.accentTeal,
      radius: 12,
    );
  }
}

/// Cupertino button with a subtle 0.97 scale-down on press.
class InkTactileButton extends StatefulWidget {
  const InkTactileButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.alignment = Alignment.center,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry alignment;

  @override
  State<InkTactileButton> createState() => _InkTactileButtonState();
}

class _InkTactileButtonState extends State<InkTactileButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed && enabled ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: Padding(
          padding: widget.padding,
          child: Align(
            alignment: widget.alignment,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

CupertinoThemeData buildInkCupertinoTheme() {
  return const CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: InkColors.accentNeonCyan,
    scaffoldBackgroundColor: InkColors.backgroundPrimary,
    barBackgroundColor: Color(0xE614141C),
    textTheme: CupertinoTextThemeData(
      primaryColor: InkColors.textPrimary,
      textStyle: InkTypography.body,
      actionTextStyle: TextStyle(
        color: InkColors.accentNeonCyan,
        fontSize: 17,
        fontWeight: FontWeight.w400,
      ),
      navTitleTextStyle: InkTypography.headline,
      navLargeTitleTextStyle: InkTypography.largeTitle,
      tabLabelTextStyle: InkTypography.caption2,
    ),
  );
}

/// Material root theme — keeps Cupertino chrome via [cupertinoOverrideTheme].
ThemeData buildInkMaterialTheme() {
  TextStyle noDecoration(TextStyle style) =>
      style.copyWith(decoration: TextDecoration.none);

  final textTheme = TextTheme(
    displayLarge: noDecoration(InkTypography.largeTitle),
    displayMedium: noDecoration(InkTypography.title1),
    displaySmall: noDecoration(InkTypography.title2),
    headlineLarge: noDecoration(InkTypography.title1),
    headlineMedium: noDecoration(InkTypography.title2),
    headlineSmall: noDecoration(InkTypography.title3),
    titleLarge: noDecoration(InkTypography.title3),
    titleMedium: noDecoration(InkTypography.headline),
    titleSmall: noDecoration(InkTypography.headline),
    bodyLarge: noDecoration(InkTypography.body),
    bodyMedium: noDecoration(InkTypography.callout),
    bodySmall: noDecoration(InkTypography.subhead),
    labelLarge: noDecoration(InkTypography.footnote),
    labelMedium: noDecoration(InkTypography.caption1),
    labelSmall: noDecoration(InkTypography.caption2),
  );

  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: InkColors.backgroundPrimary,
    cupertinoOverrideTheme: buildInkCupertinoTheme(),
    useMaterial3: true,
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    colorScheme: const ColorScheme.dark(
      primary: InkColors.accentNeonCyan,
      surface: InkColors.backgroundSecondary,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: InkColors.backgroundSecondary,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: InkColors.backgroundSecondary,
    ),
  );
}
