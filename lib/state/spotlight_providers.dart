import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ink_n_motion/models/spotlight_entry.dart';
import 'package:ink_n_motion/services/spotlight_service.dart';

final spotlightServiceProvider = Provider<SpotlightService>((ref) {
  return SpotlightService();
});

/// Full spotlight roster from the remote feed (with offline fallback).
final spotlightRosterProvider = FutureProvider<List<SpotlightEntry>>((ref) {
  return ref.watch(spotlightServiceProvider).fetchSpotlightRoster();
});

/// Artist-of-the-day — rotated by [SpotlightService.dayOfYear].
final artistOfTheDayProvider = FutureProvider<SpotlightEntry>((ref) {
  return ref.watch(spotlightServiceProvider).fetchArtistOfTheDay();
});
