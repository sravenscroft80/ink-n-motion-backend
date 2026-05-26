import 'package:dio/dio.dart';

/// Client for OpenAI DALL-E image generation.
class OpenAiService {
  OpenAiService({
    Dio? dio,
    String? apiKey,
    this.baseUrl = 'https://api.openai.com/v1',
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 120),
                headers: const {
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                },
              ),
            ),
        _apiKey = apiKey ?? const String.fromEnvironment('OPENAI_API_KEY');

  final Dio _dio;
  final String _apiKey;
  final String baseUrl;

  bool get isConfigured => _apiKey.isNotEmpty;

  /// Generates a single image and returns its hosted URL.
  Future<String> generateImage({
    required String prompt,
    String model = 'dall-e-3',
    String size = '1024x1024',
  }) async {
    if (!isConfigured) {
      throw OpenAiServiceException(
        'OpenAI API key is not configured. '
        'Pass OPENAI_API_KEY via --dart-define.',
      );
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$baseUrl/images/generations',
        options: Options(
          headers: {'Authorization': 'Bearer $_apiKey'},
        ),
        data: {
          'model': model,
          'prompt': prompt,
          'n': 1,
          'size': size,
        },
      );

      final data = response.data?['data'];
      if (data is! List || data.isEmpty) {
        throw OpenAiServiceException('OpenAI returned no image data.');
      }

      final url = data.first['url'];
      if (url is! String || url.isEmpty) {
        throw OpenAiServiceException('OpenAI response missing image URL.');
      }

      return url;
    } on DioException catch (error) {
      String? message;
      final responseData = error.response?.data;
      if (responseData is Map<String, dynamic>) {
        final errorBody = responseData['error'];
        if (errorBody is Map && errorBody['message'] != null) {
          message = errorBody['message'].toString();
        }
      }
      throw OpenAiServiceException(
        message ?? error.message ?? 'OpenAI image generation failed.',
      );
    }
  }
}

class OpenAiServiceException implements Exception {
  OpenAiServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
