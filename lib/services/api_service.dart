import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ink_n_motion/models/generate_video_response.dart';
import 'package:ink_n_motion/models/tattoo_discovery_summary.dart';
import 'package:ink_n_motion/services/firebase_auth_service.dart';
import 'package:ink_n_motion/utils/exceptions.dart';

class ApiService {
  ApiService({
    Dio? dio,
    String? baseUrl,
    FirebaseAuthService? authService,
  }) : _authService = authService {
    _dio = dio ??
        Dio(
          BaseOptions(
            baseUrl: baseUrl ?? resolveBaseApiUrl(),
            connectTimeout: connectTimeout,
            receiveTimeout: receiveTimeout,
            headers: const {'Accept': 'application/json'},
          ),
        );

    final authService = _authService;
    if (authService != null) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            try {
              final token = await authService.getIdToken();
              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }
            } catch (_) {
              // auth stub — skip token
            }
            handler.next(options);
          },
        ),
      );
    }
  }

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 120);
  static const int _maxPollIterations = 120;
  static const Duration _pollInterval = Duration(seconds: 5);

  static const String renderApiUrlOverride = String.fromEnvironment('RENDER_API_URL');
  static const String localPhysicalDeviceLanBaseUrl = '';
  static const String productionBaseApiUrl = 'https://ink-n-motion-api.onrender.com/v1';
  static const String klingBaseUrl = 'https://ink-n-motion-api.onrender.com/v1';
  static const String generateMotionPath = '/generate';

  static String resolveBaseApiUrl() {
    if (kReleaseMode) return productionBaseApiUrl;
    final override = renderApiUrlOverride.trim();
    if (override.isNotEmpty) return _ensureV1Suffix(override);
    if (localPhysicalDeviceLanBaseUrl.isNotEmpty) return localPhysicalDeviceLanBaseUrl;
    return productionBaseApiUrl;
  }

  static String resolveApiOrigin() {
    const v1Suffix = '/v1';
    final base = resolveBaseApiUrl();
    if (base.endsWith(v1Suffix)) return base.substring(0, base.length - v1Suffix.length);
    return base;
  }

  static String _ensureV1Suffix(String url) {
    final trimmed = url.trim().replaceAll(RegExp(r'/+$'), '');
    if (trimmed.endsWith('/v1')) return trimmed;
    return '$trimmed/v1';
  }

  final FirebaseAuthService? _authService;
  late final Dio _dio;
  String get baseApiUrl => _dio.options.baseUrl;

  // ── KLING PREMIUM VIDEO ───────────────────────────────────────────────────

  Future<String> submitKlingJob({
    required Uint8List imageBytes,
    required String styleId,
    int durationSeconds = 5,
  }) async {
    final b64 = base64Encode(imageBytes);
    debugPrint('DEBUG submitKlingJob: imageBytes=${imageBytes.length}, b64=${b64.length}');

    final url = Uri.parse('$klingBaseUrl/studio/generate/animate');
    final body = jsonEncode({
      'image_base64': b64,
      'style_id': styleId,
      'duration_seconds': durationSeconds,
    });

    debugPrint('DEBUG submitKlingJob: POST $url body size=${body.length}');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      ).timeout(const Duration(seconds: 60));

      debugPrint('DEBUG submitKlingJob: status=${response.statusCode}');
      debugPrint('DEBUG submitKlingJob: body=${response.body.substring(0, response.body.length.clamp(0, 300))}');

      if (response.statusCode == 200 || response.statusCode == 202) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final taskId = data['task_id'] ?? data['job_id'] ?? data['id'];
        if (taskId == null) {
          throw Exception('No task_id in response: ${response.body}');
        }
        return taskId.toString();
      }

      throw Exception('Kling submit failed ${response.statusCode}: ${response.body}');
    } catch (e) {
      debugPrint('DEBUG submitKlingJob ERROR: $e');
      rethrow;
    }
  }

  Future<String> pollKlingStatus(String taskId) async {
    final url = '$klingBaseUrl/studio/generate/status/$taskId';
    debugPrint('DEBUG pollKlingStatus: polling $url');

    for (var i = 0; i < _maxPollIterations; i++) {
      await Future<void>.delayed(_pollInterval);
      debugPrint('DEBUG pollKlingStatus: tick ${i + 1}/$_maxPollIterations');

      try {
        final response = await _dio.get<Map<String, dynamic>>(
          url,
          options: Options(validateStatus: (s) => s != null && s < 500),
        );

        final data = response.data;
        final status = data?['status']?.toString();
        debugPrint('DEBUG pollKlingStatus: status=$status');

        if (status == 'succeed' || status == 'succeeded' || status == 'completed') {
          final works = data?['data']?['task_result']?['videos'];
          if (works is List && works.isNotEmpty) {
            final videoUrl = works[0]['url']?.toString();
            if (videoUrl != null && videoUrl.isNotEmpty) {
              debugPrint('DEBUG pollKlingStatus: video ready! $videoUrl');
              return videoUrl;
            }
          }
          final flat = data?['video_url'] ?? data?['data']?['video_url'];
          if (flat is String && flat.isNotEmpty) return flat;
          throw Exception('Kling succeeded but no video URL: $data');
        }

        if (status == 'failed' || status == 'error') {
          throw Exception('Kling task failed: ${data?['message'] ?? data}');
        }
      } catch (e) {
        if (e is DioException) {
          debugPrint('DEBUG pollKlingStatus DioException: $e');
          continue;
        }
        rethrow;
      }
    }

    throw Exception('Kling polling timed out after ${_maxPollIterations * _pollInterval.inSeconds}s');
  }

  // ── LEGACY METHODS ────────────────────────────────────────────────────────

  Future<GenerateVideoResponse> generateMotionFromBlueprint({
    TattooDiscoverySummary? discoverySummary,
    String? styleId,
    String? imagePath,
  }) async {
    final body = <String, dynamic>{
      'discovery_summary': discoverySummary?.toJson() ?? <String, dynamic>{},
      if (styleId != null && styleId.isNotEmpty) 'style_id': styleId,
    };
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        generateMotionPath,
        data: body,
        options: Options(
          contentType: 'application/json',
          validateStatus: (s) => s != null && s >= 200 && s < 300,
        ),
      );
      final payload = response.data;
      if (payload == null) throw Exception('Empty response from motion API');
      return _parseGenerateMotionPayload(payload, response);
    } on DioException catch (error) {
      _rethrowMappedDioException(error);
      rethrow;
    }
  }

  Future<GenerateVideoResponse> generateVideoFromImage({
    required String imagePath,
    required String styleId,
    void Function(String)? onQueueStatusUpdate,
  }) async {
    throw UnsupportedError('Use submitKlingJob with Uint8List instead.');
  }

  void _rethrowMappedDioException(DioException error) {
    _throwIfOffline(error);
    _throwIfRateLimited(error);
  }

  void _throwIfOffline(DioException error) {
    if (error.type != DioExceptionType.connectionError &&
        error.type != DioExceptionType.sendTimeout) {
      return;
    }
    throw OfflineNetworkException();
  }

  void _throwIfRateLimited(DioException error) {
    if (error.response?.statusCode != 429) return;
    final payload = error.response?.data;
    var message = 'Too many generations. Please wait a few minutes.';
    if (payload is Map) {
      final s = payload['error'];
      if (s is String && s.isNotEmpty) message = s;
    }
    throw RateLimitException(message);
  }

  static GenerateVideoResponse _parseGenerateMotionPayload(
    Map<String, dynamic> payload,
    Response<Map<String, dynamic>> response,
  ) {
    if (payload['engine'] == 'local_overlay') {
      final maskUrl = payload['mask_url'];
      if (maskUrl is String && maskUrl.isNotEmpty) {
        return GenerateVideoResponse(maskUrl: maskUrl, isLocalOverlay: true);
      }
    }
    final videoUrl = payload['video_url'] ?? payload['videoUrl'];
    if (videoUrl is String && videoUrl.isNotEmpty) {
      return GenerateVideoResponse(videoUrl: videoUrl);
    }
    final nested = payload['data'];
    if (nested is Map<String, dynamic>) {
      return _parseGenerateMotionPayload(nested, response);
    }
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: 'Motion API response missing video_url or mask_url',
      type: DioExceptionType.badResponse,
    );
  }
}

void logApiFailure(String context, Object error, StackTrace stackTrace) {
  debugPrint('ApiService.$context failed: $error');
}