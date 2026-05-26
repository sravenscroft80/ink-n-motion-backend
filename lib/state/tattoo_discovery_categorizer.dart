import 'package:ink_n_motion/models/tattoo_discovery_summary.dart';

/// Maps free-text answers and question context into [TattooDiscoverySummary].
abstract final class TattooDiscoveryCategorizer {
  static TattooDiscoverySummary categorize({
    required int questionIndex,
    required String answer,
    required TattooDiscoverySummary current,
  }) {
    final normalized = answer.trim();
    if (normalized.isEmpty) return current;

    final keywordHints = _fromKeywords(normalized);
    final questionHints = _fromQuestionIndex(questionIndex, normalized);

    return current.merge(keywordHints).merge(questionHints);
  }

  static TattooDiscoverySummary _fromQuestionIndex(int index, String answer) {
    return switch (index) {
      0 => TattooDiscoverySummary(reasoning: 'Motivation: $answer'),
      1 => TattooDiscoverySummary(style: answer),
      2 => TattooDiscoverySummary(
          reasoning: 'Symbolism: $answer',
        ),
      3 => TattooDiscoverySummary(location: answer),
      4 => TattooDiscoverySummary(
          reasoning: 'Visibility preference: $answer',
        ),
      5 => TattooDiscoverySummary(size: answer),
      6 => TattooDiscoverySummary(
          style: _appendStyleNote(answer, 'Palette'),
        ),
      7 => TattooDiscoverySummary(
          style: _appendStyleNote(answer, 'Technique'),
        ),
      8 => TattooDiscoverySummary(
          reasoning: 'Desired emotional impact: $answer',
        ),
      9 => TattooDiscoverySummary(
          size: _appendSizeNote(answer),
          reasoning: 'Collection context: $answer',
        ),
      10 => TattooDiscoverySummary(
          reasoning: 'Budget range: $answer',
        ),
      11 => TattooDiscoverySummary(
          estimatedTime: _estimateFromPainTolerance(answer),
        ),
      12 => TattooDiscoverySummary(
          reasoning: 'Existing work to complement: $answer',
        ),
      13 => TattooDiscoverySummary(
          reasoning: 'Future enhancement notes: $answer',
        ),
      14 => TattooDiscoverySummary(style: 'Artist fit: $answer'),
      15 => TattooDiscoverySummary(
          reasoning: 'Contrast planning: $answer',
        ),
      16 => TattooDiscoverySummary(
          reasoning: 'Cultural & personal motifs: $answer',
        ),
      17 => TattooDiscoverySummary(estimatedTime: answer),
      18 => TattooDiscoverySummary(
          reasoning: 'Long-term aging goals: $answer',
        ),
      19 => TattooDiscoverySummary(
          reasoning: 'Ultimate vision: $answer',
        ),
      _ => TattooDiscoverySummary(reasoning: answer),
    };
  }

  static TattooDiscoverySummary _fromKeywords(String answer) {
    final lower = answer.toLowerCase();
    var summary = const TattooDiscoverySummary();

    summary = summary.merge(TattooDiscoverySummary(
      size: _firstMatch(lower, _sizeKeywords),
    ));
    summary = summary.merge(TattooDiscoverySummary(
      location: _firstMatch(lower, _locationKeywords),
    ));
    summary = summary.merge(TattooDiscoverySummary(
      style: _firstMatch(lower, _styleKeywords),
    ));
    summary = summary.merge(TattooDiscoverySummary(
      estimatedTime: _firstMatch(lower, _timelineKeywords),
    ));

    return summary;
  }

  static String? _firstMatch(String lower, Map<String, String> keywords) {
    for (final entry in keywords.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return null;
  }

  static String _appendStyleNote(String answer, String label) {
    return '$label: $answer';
  }

  static String _appendSizeNote(String answer) {
    final lower = answer.toLowerCase();
    if (lower.contains('sleeve') || lower.contains('large')) {
      return 'Large statement / sleeve';
    }
    if (lower.contains('medium') || lower.contains('focal')) {
      return 'Medium focal piece';
    }
    return answer;
  }

  static String _estimateFromPainTolerance(String answer) {
    final lower = answer.toLowerCase();
    if (lower.contains('low') || lower.contains('minimal')) {
      return 'Shorter sessions (1–2 hours)';
    }
    if (lower.contains('high') || lower.contains('long')) {
      return 'Extended multi-session plan';
    }
    return 'Moderate session length (2–4 hours)';
  }

  static const _sizeKeywords = {
    'small': 'Small / subtle accent',
    'tiny': 'Small / subtle accent',
    'subtle': 'Small / subtle accent',
    'medium': 'Medium focal piece',
    'large': 'Large statement piece',
    'full sleeve': 'Full sleeve',
    'sleeve': 'Sleeve composition',
    'quarter sleeve': 'Quarter sleeve',
    'half sleeve': 'Half sleeve',
  };

  static const _locationKeywords = {
    'wrist': 'Wrist',
    'forearm': 'Forearm',
    'upper arm': 'Upper arm',
    'bicep': 'Bicep',
    'shoulder': 'Shoulder',
    'chest': 'Chest',
    'back': 'Back',
    'ribs': 'Ribs',
    'ankle': 'Ankle',
    'calf': 'Calf',
    'thigh': 'Thigh',
    'neck': 'Neck',
    'hand': 'Hand',
    'finger': 'Finger',
    'spine': 'Spine',
  };

  static const _styleKeywords = {
    'minimal': 'Minimal / fine line',
    'fine line': 'Fine line',
    'traditional': 'American traditional',
    'neo-traditional': 'Neo-traditional',
    'neo traditional': 'Neo-traditional',
    'new school': 'New School',
    'geometric': 'Geometric',
    'blackwork': 'Blackwork',
    'watercolor': 'Watercolor',
    'realism': 'Realism',
    'portrait': 'Portrait realism',
    'tribal': 'Tribal',
    'japanese': 'Japanese irezumi',
    'irezumi': 'Japanese irezumi',
    'dotwork': 'Dotwork',
    'illustrative': 'Illustrative',
    'organic': 'Organic / botanical',
  };

  static const _timelineKeywords = {
    'asap': 'Within a few weeks',
    'urgent': 'Within a few weeks',
    'weeks': 'Within weeks',
    'month': 'Within 1–3 months',
    'months': 'Within several months',
    'no rush': 'Flexible timeline',
    'flexible': 'Flexible timeline',
    'year': 'Long-term planning (6–12 months)',
  };
}
