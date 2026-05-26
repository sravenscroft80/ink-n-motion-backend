/// Artist spotlight entry — sourced from [SpotlightService] remote roster.
class SpotlightEntry {
  const SpotlightEntry({
    required this.name,
    required this.profileUrl,
    required this.portfolioLink,
    required this.bio,
  });

  factory SpotlightEntry.fromJson(Map<String, dynamic> json) {
    return SpotlightEntry(
      name: json['name'] as String,
      profileUrl: json['profile_url'] as String? ?? '',
      portfolioLink: json['portfolio_link'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
    );
  }

  final String name;
  final String profileUrl;
  final String portfolioLink;
  final String bio;

  bool get hasPortfolioLink => portfolioLink.trim().isNotEmpty;
}
