class ChronicleEntry {
  const ChronicleEntry({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.heroImage,
  });

  factory ChronicleEntry.fromJson(Map<String, dynamic> json) {
    return ChronicleEntry(
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      body: json['body'] as String,
      heroImage: json['hero_image'] as String,
    );
  }

  final String title;
  final String subtitle;
  final String body;
  final String heroImage;
}

class ArtistSpotlightEntry {
  const ArtistSpotlightEntry({
    required this.name,
    required this.location,
    required this.nationality,
    required this.specialization,
    required this.experienceYears,
    required this.workLink,
    required this.profilePhotoUrl,
    required this.heroImage,
    required this.bio,
  });

  factory ArtistSpotlightEntry.fromJson(Map<String, dynamic> json) {
    return ArtistSpotlightEntry(
      name: json['name'] as String,
      location: json['location'] as String? ?? '',
      nationality: json['nationality'] as String,
      specialization: json['specialization'] as String? ??
          json['specialty'] as String? ??
          '',
      experienceYears: (json['experience_years'] as num?)?.toInt() ?? 0,
      workLink: json['work_link'] as String,
      profilePhotoUrl: json['profile_photo_url'] as String? ?? '',
      heroImage: json['hero_image'] as String,
      bio: json['bio'] as String? ?? '',
    );
  }

  final String name;
  final String location;
  final String nationality;
  final String specialization;
  final int experienceYears;
  final String workLink;
  final String profilePhotoUrl;
  final String heroImage;
  final String bio;

  bool get hasWorkLink => workLink.trim().isNotEmpty;
}

class StyleGalleryImage {
  const StyleGalleryImage({
    required this.asset,
    required this.caption,
    required this.referenceType,
  });

  factory StyleGalleryImage.fromJson(Map<String, dynamic> json) {
    return StyleGalleryImage(
      asset: json['asset'] as String,
      caption: json['caption'] as String,
      referenceType: StyleReferenceType.fromJson(
        json['reference_type'] as String? ?? 'historical_reference',
      ),
    );
  }

  final String asset;
  final String caption;
  final StyleReferenceType referenceType;
}

enum StyleReferenceType {
  historicalReference('historical_reference'),
  modernInterpretation('modern_interpretation');

  const StyleReferenceType(this.jsonValue);

  final String jsonValue;

  static StyleReferenceType fromJson(String value) {
    return StyleReferenceType.values.firstWhere(
      (type) => type.jsonValue == value,
      orElse: () => StyleReferenceType.historicalReference,
    );
  }

  String get displayLabel => switch (this) {
        StyleReferenceType.historicalReference => 'Historical Reference',
        StyleReferenceType.modernInterpretation => 'Modern Interpretation',
      };
}

class StyleArchiveEntry {
  const StyleArchiveEntry({
    required this.id,
    required this.name,
    required this.description,
    required this.historicalEra,
    required this.heroImage,
    required this.origin,
    required this.technique,
    required this.galleryImages,
  });

  factory StyleArchiveEntry.fromJson(Map<String, dynamic> json) {
    final galleryRaw = json['gallery_images'] ?? json['example_images'];
    final galleryList = galleryRaw is List<dynamic> ? galleryRaw : const [];

    return StyleArchiveEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      historicalEra: json['historical_era'] as String? ??
          json['mood'] as String? ??
          'Modern',
      heroImage: json['hero_image'] as String,
      origin: json['origin'] as String? ??
          json['history'] as String? ??
          '',
      technique: json['technique'] as String? ??
          json['cultural_significance'] as String? ??
          '',
      galleryImages: galleryList
          .map(
            (item) => StyleGalleryImage.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  final String id;
  final String name;
  final String description;
  final String historicalEra;
  final String heroImage;
  final String origin;
  final String technique;
  final List<StyleGalleryImage> galleryImages;

  bool get hasDescription => description.trim().isNotEmpty;

  bool get hasOrigin => origin.trim().isNotEmpty;

  bool get hasTechnique => technique.trim().isNotEmpty;

  bool get hasGallery => galleryImages.isNotEmpty;

  List<StyleGalleryImage> get historicalReferences => galleryImages
      .where(
        (image) => image.referenceType == StyleReferenceType.historicalReference,
      )
      .toList();

  List<StyleGalleryImage> get modernInterpretations => galleryImages
      .where(
        (image) =>
            image.referenceType == StyleReferenceType.modernInterpretation,
      )
      .toList();
}

class DiscoverContent {
  const DiscoverContent({
    required this.inkChronicles,
    required this.artistSpotlight,
    required this.styleArchive,
  });

  factory DiscoverContent.fromJson(Map<String, dynamic> json) {
    return DiscoverContent(
      inkChronicles: (json['inkChronicles'] as List<dynamic>)
          .map((item) => ChronicleEntry.fromJson(item as Map<String, dynamic>))
          .toList(),
      artistSpotlight: (json['artistSpotlight'] as List<dynamic>)
          .map(
            (item) => ArtistSpotlightEntry.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      styleArchive: (json['styleArchive'] as List<dynamic>)
          .map(
            (item) => StyleArchiveEntry.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  final List<ChronicleEntry> inkChronicles;
  final List<ArtistSpotlightEntry> artistSpotlight;
  final List<StyleArchiveEntry> styleArchive;

  ChronicleEntry chronicleForToday() => entryForDay(inkChronicles);

  ArtistSpotlightEntry artistForToday() => entryForDay(artistSpotlight);

  StyleArchiveEntry? styleById(String id) {
    for (final entry in styleArchive) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  /// Maps calendar day (1–31) to a list index in `[0, length)`.
  ///
  /// Safe when live RSS count (e.g. 10) differs from bundled JSON (e.g. 12):
  /// modulo always keeps the index in range for the current list length.
  static int dayListIndex(int listLength) {
    assert(listLength > 0, 'Content list must not be empty.');
    return (DateTime.now().day - 1) % listLength;
  }

  static T entryForDay<T>(List<T> items) {
    if (items.isEmpty) {
      throw StateError('Content list must not be empty.');
    }
    return items[dayListIndex(items.length)];
  }
}
