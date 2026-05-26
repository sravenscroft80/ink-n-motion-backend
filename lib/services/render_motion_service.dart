import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ink_n_motion/models/generate_video_response.dart';
import 'package:ink_n_motion/models/tattoo_discovery_summary.dart';
import 'package:ink_n_motion/services/api_service.dart';
import 'package:ink_n_motion/utils/exceptions.dart';

/// HTTP client for the Ink-N-Motion Render relay (`POST /generate`).
class RenderMotionService {
  RenderMotionService({Dio? dio, String? baseUrl})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? defaultBaseUrl,
                connectTimeout: ApiService.connectTimeout,
                receiveTimeout: ApiService.receiveTimeout,
                headers: const {
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                },
              ),
            );

  static const String defaultBaseUrl =
      String.fromEnvironment(
        'RENDER_API_URL',
        defaultValue: 'https://ink-n-motion-api.onrender.com',
      );

  static const String generatePath = '/generate';

  final Dio _dio;

  /// Submits AI Coach blueprint (+ optional capture) for motion rendering.
  Future<GenerateVideoResponse> generateMotion({
    TattooDiscoverySummary? discoverySummary,
    String? styleId,
    String? imagePath,
  }) async {
    final body = <String, dynamic>{
      'discovery_summary': discoverySummary?.toJson() ?? <String, dynamic>{},
      if (styleId != null && styleId.isNotEmpty) 'style_id': styleId,
    };

    if (imagePath != null && imagePath.isNotEmpty) {
      final file = File(imagePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        body['image_base64'] = base64Encode(bytes);
        body['image_mime'] = _mimeTypeForPath(imagePath);
      }
    }

    debugPrint(
      'RenderMotionService: POST $generatePath '
      '(style_id=${styleId ?? 'none'}, '
      'blueprint fields=${discoverySummary?.toJson().length ?? 0})',
    );

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        generatePath,
        data: body,
        options: Options(
          validateStatus: (status) =>
              status != null && status >= 200 && status < 300,
        ),
      );

      final payload = response.data;
      if (payload == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Empty response from Render API',
          type: DioExceptionType.badResponse,
        );
      }

      debugPrint(
        'RenderMotionService: success HTTP ${response.statusCode} '
        'keys=${payload.keys.join(', ')}',
      );

      return _parseSuccessPayload(payload, response);
    } on DioException catch (error) {
      _mapCommonErrors(error);
      logApiFailure('generateMotion', error, StackTrace.current);
      rethrow;
    }
  }

  GenerateVideoResponse _parseSuccessPayload(
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
      return _parseSuccessPayload(nested, response);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: 'Render API response missing video_url or mask_url',
      type: DioExceptionType.badResponse,
    );
  }

  void _mapCommonErrors(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.sendTimeout) {
      throw OfflineNetworkException();
    }

    if (error.response?.statusCode == 429) {
      final data = error.response?.data;
      var message =
          'Too many render requests. Please wait a moment and try again.';
      if (data is Map) {
        final serverMessage = data['error'] ?? data['message'];
        if (serverMessage is String && serverMessage.isNotEmpty) {
          message = serverMessage;
        }
      }
      throw RateLimitException(message);
    }
  }

  static String _mimeTypeForPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }
}
