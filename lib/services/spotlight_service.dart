import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ink_n_motion/models/spotlight_entry.dart';

/// Fetches a spotlight roster from a remote URL and selects artist-of-the-day.
class SpotlightService {
  SpotlightService({
    Dio? dio,
    this.spotlightFeedUrl = defaultSpotlightFeedUrl,
    this.useMockResponse = true,
  }) : _dio = dio ?? Dio();

  /// Remote roster endpoint (JSON `{ "artists": [ ... ] }`).
  static const String defaultSpotlightFeedUrl =
      'https://api.ink-n-motion.app/v1/spotlight/artists';

  final String spotlightFeedUrl;
  final bool useMockResponse;
  final Dio _dio;

  List<SpotlightEntry>? _cachedRoster;

  static final List<SpotlightEntry> _fallbackRoster = [
    SpotlightEntry(
      name: 'Mara Voss',
      profileUrl: 'https://picsum.photos/seed/mara-voss/400/400',
      portfolioLink: 'https://inkedmag.com/tattoo-artists/',
      bio:
          'Mara builds gentle pulse animations into botanical pieces, favoring slow blooms over flashy effects.',
    ),
    SpotlightEntry(
      name: 'Jax Ortega',
      profileUrl: 'https://picsum.photos/seed/jax-ortega/400/400',
      portfolioLink: 'https://inkedmag.com/tattoo-artists/',
      bio:
          'Jax saturates classic motifs with rhythmic light passes, making eagles and roses feel alive.',
    ),
    SpotlightEntry(
      name: 'Sienna Kade',
      profileUrl: 'https://picsum.photos/seed/sienna-kade/400/400',
      portfolioLink: 'https://inkedmag.com/tattoo-artists/',
      bio:
          'Precision linework meets particle sparkle—sacred geometry that flickers like city lights.',
    ),
    SpotlightEntry(
      name: 'Theo Ashford',
      profileUrl: 'https://picsum.photos/seed/theo-ashford/400/400',
      portfolioLink: 'https://inkedmag.com/tattoo-artists/',
      bio:
          'Theo treats negative space as motion. Ink appears to pour and recede across large blackwork panels.',
    ),
    SpotlightEntry(
      name: 'Rin Delacroix',
      profileUrl: 'https://picsum.photos/seed/rin-delacroix/400/400',
      portfolioLink: 'https://inkedmag.com/tattoo-artists/',
      bio:
          'Subtle eye glints and hair drift give Rin\'s portraits an uncanny lifelike quality.',
    ),
    SpotlightEntry(
      name: 'Cruz Mendez',
      profileUrl: 'https://picsum.photos/seed/cruz-mendez/400/400',
      portfolioLink: 'https://inkedmag.com/tattoo-artists/',
      bio:
          'Cruz merges graffiti energy with neon glow passes, building loops that look like signage at dusk.',
    ),
    SpotlightEntry(
      name: 'Hana Iwata',
      profileUrl: 'https://picsum.photos/seed/hana-iwata/400/400',
      portfolioLink: 'https://inkedmag.com/tattoo-artists/',
      bio:
          'Single-needle pieces with one repeating motion cue—Hana proves restraint scales.',
    ),
    SpotlightEntry(
      name: 'Dante Cole',
      profileUrl: 'https://picsum.photos/seed/dante-cole/400/400',
      portfolioLink: 'https://inkedmag.com/tattoo-artists/',
      bio:
          'Mechanical joints animate in Dante\'s biomech work, turning limbs into believable machine diagrams.',
    ),
    SpotlightEntry(
      name: 'Yara Mensah',
      profileUrl: 'https://picsum.photos/seed/yara-mensah/400/400',
      portfolioLink: 'https://inkedmag.com/tattoo-artists/',
      bio:
          'Yara weaves Adinkra-inspired symbols into sequential glow patterns that honor heritage.',
    ),
    SpotlightEntry(
      name: 'Felix Arden',
      profileUrl: 'https://picsum.photos/seed/felix-arden/400/400',
      portfolioLink: 'https://inkedmag.com/tattoo-artists/',
      bio:
          'Felix storyboards tattoo narratives as multi-panel loops before the engine renders the final cut.',
    ),
    SpotlightEntry(
      name: 'Nova Keane',
      profileUrl: 'https://picsum.photos/seed/nova-keane/400/400',
      portfolioLink: 'https://inkedmag.com/tattoo-artists/',
      bio:
          'Nova layers watercolor tattoos with particle bursts timed to music for gallery-grade share clips.',
    ),
    SpotlightEntry(
      name: 'Elliot Prasad',
      profileUrl: 'https://picsum.photos/seed/elliot-prasad/400/400',
      portfolioLink: 'https://inkedmag.com/tattoo-artists/',
      bio:
          'Lettering that writes itself on loop—mantra lines revealed one stroke at a time.',
    ),
  ];

  static const SpotlightEntry _museumFallbackArtist = SpotlightEntry(
    name: 'Ink-N-Motion Artist',
    profileUrl: '',
    portfolioLink: 'https://inkedmag.com/tattoo-artists/',
    bio:
        'Curated tattoo artistry—explore featured work and discover your next piece.',
  );

  /// Calendar day-of-year (1–366) for stable daily rotation.
  static int dayOfYear([DateTime? date]) {
    final value = date ?? DateTime.now();
    final yearStart = DateTime(value.year, 1, 1);
    return value.difference(yearStart).inDays + 1;
  }

  /// Index into [roster] for the current calendar day.
  static int dayRosterIndex(int rosterLength, [DateTime? date]) {
    assert(rosterLength > 0, 'Spotlight roster must not be empty.');
    return (dayOfYear(date) - 1) % rosterLength;
  }

  /// Picks today's artist from [roster] using day-of-year rotation.
  SpotlightEntry selectArtistForDay(
    List<SpotlightEntry> roster, {
    DateTime? date,
  }) {
    if (roster.isEmpty) return _museumFallbackArtist;
    return roster[dayRosterIndex(roster.length, date)];
  }

  /// Fetches roster from [spotlightFeedUrl]; falls back to bundled roster on failure.
  Future<List<SpotlightEntry>> fetchSpotlightRoster() async {
    if (useMockResponse) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      _cachedRoster = List<SpotlightEntry>.from(_fallbackRoster);
      debugPrint(
        '[SpotlightService] Mock roster — ${_cachedRoster!.length} artists',
      );
      return _cachedRoster!;
    }

    debugPrint('[SpotlightService] GET $spotlightFeedUrl');

    try {
      final response = await _dio.get<dynamic>(
        spotlightFeedUrl,
        options: Options(
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
          headers: const {
            'Accept': 'application/json',
            'User-Agent': 'Ink-N-Motion/1.0 (Spotlight)',
          },
        ),
      );

      final parsed = _parseRosterResponse(response.data);
      if (parsed.isNotEmpty) {
        _cachedRoster = parsed;
        debugPrint(
          '[SpotlightService] Roster loaded — ${parsed.length} artists',
        );
        return parsed;
      }

      debugPrint('[SpotlightService] Empty roster in response — using fallback');
    } on DioException catch (error) {
      debugPrint(
        '[SpotlightService] DioException (${error.type}): ${error.message}',
      );
    } catch (error, stackTrace) {
      debugPrint('[SpotlightService] Fetch error: $error');
      debugPrint('$stackTrace');
    }

    return _cachedRoster ?? List<SpotlightEntry>.from(_fallbackRoster);
  }

  /// Artist-of-the-day — never throws; uses fallback roster and museum defaults.
  Future<SpotlightEntry> fetchArtistOfTheDay() async {
    final roster = await fetchSpotlightRoster();
    final entry = selectArtistForDay(roster);
    final index = roster.isEmpty ? 0 : dayRosterIndex(roster.length);
    debugPrint(
      '[SpotlightService] Artist-of-the-day — ${entry.name}, '
      'Index: $index, DayOfYear: ${dayOfYear()}, '
      'Source: ${entry.profileUrl}',
    );
    return entry;
  }

  List<SpotlightEntry> _parseRosterResponse(dynamic data) {
    if (data is! Map<String, dynamic>) return const [];
    final raw = data['artists'] as List<dynamic>? ?? const [];
    return raw
        .map((item) => SpotlightEntry.fromJson(item as Map<String, dynamic>))
        .where((entry) => entry.name.trim().isNotEmpty)
        .toList(growable: false);
  }
}
