/// Compiled tattoo discovery session — categorized from the 20-question flow.
class TattooDiscoverySummary {
  const TattooDiscoverySummary({
    this.style,
    this.size,
    this.location,
    this.reasoning,
    this.estimatedTime,
  });

  final String? style;
  final String? size;
  final String? location;
  final String? reasoning;
  final String? estimatedTime;

  bool get hasAnyField =>
      style != null ||
      size != null ||
      location != null ||
      reasoning != null ||
      estimatedTime != null;

  TattooDiscoverySummary copyWith({
    String? style,
    String? size,
    String? location,
    String? reasoning,
    String? estimatedTime,
    bool mergeReasoning = false,
  }) {
    return TattooDiscoverySummary(
      style: style ?? this.style,
      size: size ?? this.size,
      location: location ?? this.location,
      reasoning: mergeReasoning && reasoning != null && this.reasoning != null
          ? '${this.reasoning!}\n$reasoning'
          : (reasoning ?? this.reasoning),
      estimatedTime: estimatedTime ?? this.estimatedTime,
    );
  }

  TattooDiscoverySummary merge(TattooDiscoverySummary other) {
    return TattooDiscoverySummary(
      style: other.style ?? style,
      size: other.size ?? size,
      location: other.location ?? location,
      reasoning: _mergeText(reasoning, other.reasoning),
      estimatedTime: other.estimatedTime ?? estimatedTime,
    );
  }

  String toBlueprintText() => toPremiumBlueprintBody();

  /// Formatted blueprint body for UI cards and sharing.
  String toPremiumBlueprintBody() {
    final buffer = StringBuffer();
    buffer.writeln('Style: ${style ?? '—'}');
    buffer.writeln('Size: ${size ?? '—'}');
    buffer.writeln('Placement: ${location ?? '—'}');
    buffer.writeln('Vision: ${reasoning ?? '—'}');
    buffer.writeln('Session Plan: ${estimatedTime ?? '—'}');
    return buffer.toString().trim();
  }

  /// JSON payload for Render motion generation (`discovery_summary` body field).
  Map<String, dynamic> toJson() => {
        if (style != null) 'style': style,
        if (size != null) 'size': size,
        if (location != null) 'location': location,
        if (reasoning != null) 'reasoning': reasoning,
        if (estimatedTime != null) 'estimated_time': estimatedTime,
      };

  factory TattooDiscoverySummary.fromJson(Map<String, dynamic> json) {
    return TattooDiscoverySummary(
      style: json['style'] as String?,
      size: json['size'] as String?,
      location: json['location'] as String?,
      reasoning: json['reasoning'] as String?,
      estimatedTime: json['estimated_time'] as String?,
    );
  }

  static String? _mergeText(String? existing, String? incoming) {
    if (incoming == null || incoming.trim().isEmpty) return existing;
    if (existing == null || existing.trim().isEmpty) return incoming;
    if (existing.contains(incoming)) return existing;
    return '$existing\n$incoming';
  }
}
