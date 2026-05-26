import 'package:ink_n_motion/models/discover_content.dart';
import 'package:ink_n_motion/services/chronicle_image_resolver.dart';

/// Maps GNews API articles to [ChronicleEntry] with museum-grade heroes.
abstract final class ChronicleGNewsMapper {
  static const int defaultMaxArticles = 30;

  static List<ChronicleEntry> fromArticles(
    List<dynamic> raw, {
    int maxArticles = defaultMaxArticles,
  }) {
    final entries = <ChronicleEntry>[];

    for (final item in raw) {
      if (entries.length >= maxArticles) break;
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final entry = fromArticle(item);
      if (entry.title.trim().isEmpty) {
        continue;
      }
      entries.add(entry);
    }

    return entries;
  }

  static ChronicleGNewsParseResult parseArticles(List<dynamic> raw) {
    final entries = fromArticles(raw);
    return ChronicleGNewsParseResult(
      entries: entries,
      rawArticleCount: raw.length,
      mappedCount: entries.length,
      skippedCount: raw.length - entries.length,
    );
  }

  static ChronicleEntry fromArticle(Map<String, dynamic> json) {
    final title = (json['title'] as String? ?? '').trim();
    final description = (json['description'] as String? ?? '').trim();
    final content = (json['content'] as String? ?? '').trim();
    final imageUrl = json['image'] as String?;
    final source = json['source'];
    final sourceName = source is Map<String, dynamic>
        ? (source['name'] as String? ?? '').trim()
        : '';

    final body = _buildBody(description: description, content: content);
    final subtitle = sourceName.isNotEmpty
        ? 'Ink Chronicles · $sourceName'
        : 'Ink Chronicles · Curated';

    return ChronicleEntry(
      title: title.isEmpty ? 'Ink Chronicles' : title,
      subtitle: subtitle,
      body: body,
      heroImage: ChronicleImageResolver.resolveArticleHero(
        imageUrl,
        seed: title,
      ),
    );
  }

  static String _buildBody({
    required String description,
    required String content,
  }) {
    final primary = _stripHtml(description);
    if (primary != null && primary.isNotEmpty) {
      return _truncate(primary, 480);
    }

    final full = _stripHtml(content);
    if (full != null && full.isNotEmpty) {
      return _truncate(full, 480);
    }

    return 'Latest tattoo culture from our curated news feed.';
  }

  static String? _stripHtml(String? html) {
    if (html == null || html.trim().isEmpty) return null;
    return html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength).trimRight()}…';
  }
}

class ChronicleGNewsParseResult {
  const ChronicleGNewsParseResult({
    required this.entries,
    required this.rawArticleCount,
    required this.mappedCount,
    required this.skippedCount,
  });

  final List<ChronicleEntry> entries;
  final int rawArticleCount;
  final int mappedCount;
  final int skippedCount;
}
