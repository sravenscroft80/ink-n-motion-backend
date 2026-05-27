import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ink_n_motion/constants/discover_assets.dart';
import 'package:ink_n_motion/models/discover_content.dart';
import 'package:ink_n_motion/services/chronicle_gnews_mapper.dart';

/// Loads Discover pillar content — GNews Ink Chronicles + bundled JSON fallback.
class ContentService {
  ContentService({
    this.assetPath = 'assets/data/discover_content.json',
    Dio? dio,
    this.gNewsApiKey = defaultGNewsApiKey,
  }) : _dio = dio ?? Dio();

  static const String fallbackArticleImage =
      DiscoverAssets.fallbackArticleImage;

  static const String gNewsSearchBaseUrl = 'https://gnews.io/api/v4/search';

  /// Pass at build time: `--dart-define=GNEWS_API_KEY=your_key`
  static const String defaultGNewsApiKey =
      String.fromEnvironment('GNEWS_API_KEY');

  /// Daily refresh — no manual babysitting between sessions.
  static const Duration chronicleCacheTtl = Duration(hours: 24);

  final String assetPath;
  final String gNewsApiKey;
  final Dio _dio;

  DiscoverContent? _discoverCache;
  DateTime? _discoverCacheExpiresAt;

  List<ChronicleEntry>? _liveChroniclesCache;
  DateTime? _liveChroniclesCacheExpiresAt;

  bool get isGNewsConfigured => gNewsApiKey.trim().isNotEmpty;

  /// Fetches Ink Chronicles from GNews; 24h cache; falls back to bundled JSON.
  Future<List<ChronicleEntry>> fetchLiveChronicles({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _isCacheValid(_liveChroniclesCacheExpiresAt)) {
      debugPrint(
        '[InkChronicles] Using cached chronicles '
        '(${_liveChroniclesCache!.length} entries, TTL 24h)',
      );
      return _liveChroniclesCache!;
    }

    if (!isGNewsConfigured) {
      debugPrint(
        '[InkChronicles] GNEWS_API_KEY not set — using bundled JSON from $assetPath',
      );
      return _loadBundledChronicles(source: 'missing_api_key');
    }

    debugPrint('[InkChronicles] Fetching GNews: q=tattoo+art&lang=en');

    try {
      final entries = await _fetchGNewsArticles();
      if (entries.isEmpty) {
        debugPrint(
          '[InkChronicles] GNews returned 0 articles — falling back to '
          'bundled JSON at $assetPath',
        );
        return _loadBundledChronicles(source: 'gnews_empty');
      }

      debugPrint(
        '[InkChronicles] GNews success — ${entries.length} chronicles ready',
      );
      _liveChroniclesCache = entries;
      _liveChroniclesCacheExpiresAt =
          DateTime.now().add(chronicleCacheTtl);
      return entries;
    } on DioException catch (error) {
      debugPrint(
        '[InkChronicles] GNews DioException (${error.type}): ${error.message} '
        '— falling back to bundled JSON at $assetPath',
      );
      return _loadBundledChronicles(source: 'dio_exception');
    } catch (error, stackTrace) {
      debugPrint(
        '[InkChronicles] GNews error: $error — falling back to bundled JSON',
      );
      debugPrint('[InkChronicles] $stackTrace');
      return _loadBundledChronicles(source: 'catch');
    }
  }

  /// Hybrid loader: GNews chronicles when available, bundled JSON otherwise.
  Future<DiscoverContent> loadDiscoverContent({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _discoverCache != null &&
        _isCacheValid(_discoverCacheExpiresAt)) {
      debugPrint(
        '[InkChronicles] loadDiscoverContent: using cached bundle (TTL 24h)',
      );
      return _discoverCache!;
    }

    debugPrint('[InkChronicles] loadDiscoverContent: starting…');

    final bundled = await _loadBundledDiscoverContent();
    debugPrint(
      '[InkChronicles] Bundled JSON loaded — '
      '${bundled.inkChronicles.length} chronicles from $assetPath',
    );

    final chronicles = await fetchLiveChronicles(forceRefresh: forceRefresh);

    if (chronicles.isEmpty) {
      debugPrint(
        'ContentService: no chronicles available, continuing with empty list',
      );
    }

    final content = DiscoverContent(
      inkChronicles: chronicles,
      artistSpotlight: bundled.artistSpotlight,
      styleArchive: bundled.styleArchive,
    );

    _discoverCache = content;
    _discoverCacheExpiresAt = DateTime.now().add(chronicleCacheTtl);
    debugPrint(
      '[InkChronicles] loadDiscoverContent: complete — '
      '${chronicles.length} chronicles (cache TTL 24h)',
    );
    return content;
  }

  Future<List<ChronicleEntry>> _fetchGNewsArticles() async {
    final response = await _dio.get<Map<String, dynamic>>(
      gNewsSearchBaseUrl,
      queryParameters: {
        'q': 'tattoo art',
        'lang': 'en',
        'max': ChronicleGNewsMapper.defaultMaxArticles.toString(),
        'token': gNewsApiKey,
      },
      options: Options(
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        headers: const {
          'Accept': 'application/json',
          'User-Agent': 'Ink-N-Motion/1.0 (Discover; GNews)',
        },
      ),
    );

    final data = response.data;
    if (data == null) {
      return const [];
    }

    final articles = data['articles'] as List<dynamic>? ?? const [];
    final result = ChronicleGNewsMapper.parseArticles(articles);
    debugPrint(
      '[InkChronicles] GNews parse — raw articles: ${result.rawArticleCount}, '
      'mapped: ${result.mappedCount}, skipped: ${result.skippedCount}',
    );
    return result.entries;
  }

  Future<List<ChronicleEntry>> _loadBundledChronicles({required String source}) async {
    final bundled = await _loadBundledDiscoverContent();
    debugPrint(
      '[InkChronicles] Bundled fallback ($source) — '
      '${bundled.inkChronicles.length} chronicles from $assetPath',
    );
    return bundled.inkChronicles;
  }

  Future<DiscoverContent> _loadBundledDiscoverContent() async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      return DiscoverContent.fromJson(decoded);
    } on FlutterError catch (error) {
      debugPrint(
        '[InkChronicles] Failed to load $assetPath — '
        'is it listed under flutter/assets in pubspec.yaml? $error',
      );
      rethrow;
    }
  }

  bool _isCacheValid(DateTime? expiresAt) {
    if (expiresAt == null) return false;
    return DateTime.now().isBefore(expiresAt);
  }

  Future<StyleArchiveEntry?> styleById(String id) async {
    final content = await loadDiscoverContent();
    return content.styleById(id);
  }

  Future<List<StyleArchiveEntry>> loadStyleArchive() async {
    final content = await loadDiscoverContent();
    return content.styleArchive;
  }

  Future<ArtistSpotlightEntry> artistSpotlightForToday() async {
    final content = await loadDiscoverContent();
    return content.artistForToday();
  }

  void clearCaches() {
    _discoverCache = null;
    _discoverCacheExpiresAt = null;
    _liveChroniclesCache = null;
    _liveChroniclesCacheExpiresAt = null;
  }
}
