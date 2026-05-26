/// Distinguishes easy vs premium rendering tracks.
enum StyleRenderingType {
  easy,
  premium,
}

/// Immutable style template entry for the picker grid.
class StyleTemplate {
  const StyleTemplate({
    required this.id,
    required this.name,
    required this.renderingType,
    required this.thumbnailPlaceholder,
  });

  final String id;
  final String name;
  final StyleRenderingType renderingType;
  final String thumbnailPlaceholder;

  bool get isEasy => renderingType == StyleRenderingType.easy;
  bool get isPremium => renderingType == StyleRenderingType.premium;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is StyleTemplate &&
            id == other.id &&
            name == other.name &&
            renderingType == other.renderingType &&
            thumbnailPlaceholder == other.thumbnailPlaceholder;
  }

  @override
  int get hashCode => Object.hash(id, name, renderingType, thumbnailPlaceholder);
}
