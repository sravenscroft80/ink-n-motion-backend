/// Thrown when the device cannot reach the Ink-N-Motion API (socket/timeout drop).
class OfflineNetworkException implements Exception {}

/// Thrown when the Ink-N-Motion API returns HTTP 429 (rate limited).
class RateLimitException implements Exception {
  RateLimitException(this.message);

  final String message;

  @override
  String toString() => 'RateLimitException: $message';
}
