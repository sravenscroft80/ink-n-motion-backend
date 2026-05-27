import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show BorderRadius, Colors, TextDecoration;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ink_n_motion/screens/animate_my_ink_screen.dart';
import 'package:ink_n_motion/screens/coverup_studio_screen.dart';
import 'package:ink_n_motion/screens/discover/artist_spotlight_screen.dart';
import 'package:ink_n_motion/screens/discover/ink_chronicles_screen.dart';
import 'package:ink_n_motion/screens/discover/ai_coach_screen.dart';
import 'package:ink_n_motion/screens/discover/style_archive_screen.dart';
import 'package:ink_n_motion/services/navigation.dart';
import 'package:ink_n_motion/utils/design_tokens.dart';
import 'package:ink_n_motion/utils/shell_layout.dart';

/// Discover tab — premium minimalist landing; Studio via shell tab only.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  static const String inkChroniclesHero = 'assets/images/ink_chronicles.png';
  static const String artistSpotlightHero = 'assets/images/artist_spotlight.png';
  static const String styleArchiveHero = 'assets/images/style_archive.png';
  static const String discoverHeroFallback = 'assets/images/discover_hero.png';

  static const Color _sectionGold = Color(0xFFD4AF37);
  static const Color _cardBackground = Color(0xFF1A1A1A);
  static const Color _snippetGrey = Color(0xFF999999);
  static const Color _pillDarkText = Color(0xFF0D0D0D);

  /// Canonical registry for Discover pillar navigation.
  static Map<String, WidgetBuilder> get discoverPillarScreens => {
        InkRoutes.inkChronicles: (_) => const InkChroniclesScreen(),
        InkRoutes.artistSpotlight: (_) => const ArtistSpotlightScreen(),
        InkRoutes.styleArchive: (_) => const StyleArchiveScreen(),
        InkRoutes.aiCoach: (_) => const AiCoachScreen(),
        InkRoutes.coverupStudio: (_) => const CoverupStudioScreen(),
        InkRoutes.animateMyInk: (_) => const AnimateMyInkScreen(),
      };

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final viewportHeight = MediaQuery.sizeOf(context).height;

    return CupertinoPageScaffold(
      backgroundColor: InkColors.backgroundPrimary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _DiscoverWelcomeTypewriter(),
            _DiscoverImmersiveHero(viewportHeight: viewportHeight),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: InkSpacing.md),
              child: Text(
                '| EXPLORE',
                style: TextStyle(
                  color: HomeScreen._sectionGold,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _ExploreSectionCard(
              imageAsset: HomeScreen.inkChroniclesHero,
              pill: 'LIBRARY',
              title: 'Resource Library',
              snippet: 'Essential reads for the ink-obsessed.',
              onTap: () =>
                  InkNavigation.pushNamed(context, InkRoutes.inkChronicles),
            ),
            _ExploreSectionCard(
              imageAsset: HomeScreen.artistSpotlightHero,
              pill: 'SPOTLIGHT',
              title: 'Artist Spotlight',
              snippet: 'A new creator featured every day.',
              onTap: () =>
                  InkNavigation.pushNamed(context, InkRoutes.artistSpotlight),
            ),
            _ExploreSectionCard(
              imageAsset: HomeScreen.styleArchiveHero,
              fallbackImageAsset: HomeScreen.discoverHeroFallback,
              pill: 'ARCHIVE',
              title: 'Tattoo Style Archive',
              snippet: 'From ancient roots to modern movements.',
              onTap: () =>
                  InkNavigation.pushNamed(context, InkRoutes.styleArchive),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: InkSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '| CREATE',
                    style: TextStyle(
                      color: HomeScreen._sectionGold,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Your tattoo. Your vision. Brought to life.',
                    style: TextStyle(
                      color: HomeScreen._snippetGrey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _CreateSectionCard(
              imageAsset: 'assets/images/create_concept.png',
              pill: 'FREE DAILY',
              title: '2D Concept Generator',
              snippet:
                  'Describe your tattoo and get an AI-designed concept in seconds.',
              onTap: () =>
                  InkNavigation.pushNamed(context, InkRoutes.aiCoach),
            ),
            _CreateSectionCard(
              imageAsset: 'assets/images/create_coverup.png',
              pill: '3 TOKENS',
              title: 'Coverup Studio',
              snippet:
                  'Upload your existing tattoo and preview a coverup design over it.',
              onTap: () =>
                  InkNavigation.pushNamed(context, InkRoutes.coverupStudio),
            ),
            _CreateSectionCard(
              imageAsset: 'assets/images/create_video.png',
              pill: '10 TOKENS',
              title: 'Animate My Ink',
              snippet:
                  'Turn any tattoo photo into a stunning 10-second animated video.',
              onTap: () =>
                  InkNavigation.pushNamed(context, InkRoutes.animateMyInk),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoverWelcomeTypewriter extends StatefulWidget {
  const _DiscoverWelcomeTypewriter();

  @override
  State<_DiscoverWelcomeTypewriter> createState() =>
      _DiscoverWelcomeTypewriterState();
}

class _DiscoverWelcomeTypewriterState extends State<_DiscoverWelcomeTypewriter> {
  static const String _line1 = 'Welcome, Ink Master.';
  static const String _line2 = 'A place where your art';
  static const String _line3 = 'comes alive.';
  static const Duration _charDelay = Duration(milliseconds: 45);

  int _line1Length = 0;
  int _line2Length = 0;
  int _line3Length = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_charDelay, (_) {
      if (!mounted) return;
      setState(() {
        if (_line1Length < _line1.length) {
          _line1Length++;
          return;
        }
        if (_line2Length < _line2.length) {
          _line2Length++;
          return;
        }
        if (_line3Length < _line3.length) {
          _line3Length++;
          return;
        }
        _timer?.cancel();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 140),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
        color: Colors.transparent,
        child: Column(
          children: [
            Text(
            _line1.substring(0, _line1Length),
            textAlign: TextAlign.center,
            style: GoogleFonts.cinzel(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 1.5,
              decoration: TextDecoration.none,
            ),
          ),
          Text(
            _line2.substring(0, _line2Length),
            textAlign: TextAlign.center,
            style: GoogleFonts.cinzel(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white70,
              letterSpacing: 1.0,
              decoration: TextDecoration.none,
            ),
          ),
          Text(
            _line3.substring(0, _line3Length),
            textAlign: TextAlign.center,
            style: GoogleFonts.cinzel(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFD4A017),
              letterSpacing: 1.2,
              decoration: TextDecoration.none,
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _DiscoverImmersiveHero extends StatelessWidget {
  const _DiscoverImmersiveHero({required this.viewportHeight});

  static const String _heroImageAsset = 'assets/images/discover_hero.png';

  final double viewportHeight;

  @override
  Widget build(BuildContext context) {
    final bleed = InkShellLayout.topBarContentHeight;
    final heroHeight = viewportHeight * 0.40 + bleed;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = (screenWidth * devicePixelRatio).round();
    final cacheHeight = (heroHeight * devicePixelRatio).round();

    return Transform.translate(
      offset: Offset(0, -bleed),
      child: SizedBox(
        width: double.infinity,
        height: heroHeight,
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                _heroImageAsset,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
                cacheWidth: cacheWidth,
                cacheHeight: cacheHeight,
                gaplessPlayback: true,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      CupertinoColors.black.withValues(alpha: 0.18),
                      CupertinoColors.black.withValues(alpha: 0.28),
                      InkColors.backgroundPrimary,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoldPill extends StatelessWidget {
  const _GoldPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: HomeScreen._sectionGold,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          label,
          style: const TextStyle(
            color: HomeScreen._pillDarkText,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _ExploreSectionCard extends StatelessWidget {
  const _ExploreSectionCard({
    required this.imageAsset,
    required this.pill,
    required this.title,
    required this.snippet,
    required this.onTap,
    this.fallbackImageAsset,
  });

  final String imageAsset;
  final String? fallbackImageAsset;
  final String pill;
  final String title;
  final String snippet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: HomeScreen._cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: Image.asset(
                  imageAsset,
                  width: 110,
                  height: 110,
                  fit: BoxFit.cover,
                  errorBuilder: fallbackImageAsset == null
                      ? null
                      : (context, error, stackTrace) => Image.asset(
                            fallbackImageAsset!,
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                          ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _GoldPill(label: pill),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        snippet,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: HomeScreen._snippetGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateSectionCard extends StatelessWidget {
  const _CreateSectionCard({
    required this.imageAsset,
    required this.pill,
    required this.title,
    required this.snippet,
    required this.onTap,
  });

  final String imageAsset;
  final String pill;
  final String title;
  final String snippet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 130,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  imageAsset,
                  fit: BoxFit.cover,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xCC000000),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _GoldPill(label: pill),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 220,
                        child: Text(
                          snippet,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
