import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ink_n_motion/data/tattoo_advisor_questions.dart';
import 'package:ink_n_motion/models/chat_message.dart';
import 'package:ink_n_motion/models/tattoo_discovery_summary.dart';
import 'package:ink_n_motion/services/api_service.dart';
import 'package:ink_n_motion/services/render_motion_service.dart';
import 'package:ink_n_motion/state/tattoo_discovery_categorizer.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class AiCoachState {
  const AiCoachState({
    this.messages = const [],
    this.currentIndex = 0,
    this.isThinking = false,
    this.isGeneratingMockup = false,
    this.sessionComplete = false,
    this.answers = const [],
    this.discoverySummary = const TattooDiscoverySummary(),
    this.generatedImageUrl,
    this.feedbackMessage,
  });

  final List<ChatMessage> messages;
  final int currentIndex;
  final bool isThinking;
  final bool isGeneratingMockup;
  final bool sessionComplete;
  final List<String> answers;
  final TattooDiscoverySummary discoverySummary;
  final String? generatedImageUrl;
  final String? feedbackMessage;

  bool get hasGeneratedDesign =>
      generatedImageUrl != null && generatedImageUrl!.isNotEmpty;

  static const String _shareFooter = '''
────────────────────────
Created with Ink-N-Motion
Discover · Studio · Share
Your tattoo vision, in motion.''';

  AiCoachState copyWith({
    List<ChatMessage>? messages,
    int? currentIndex,
    bool? isThinking,
    bool? isGeneratingMockup,
    bool? sessionComplete,
    List<String>? answers,
    TattooDiscoverySummary? discoverySummary,
    String? generatedImageUrl,
    String? feedbackMessage,
    bool clearFeedback = false,
    bool clearGeneratedImageUrl = false,
  }) {
    return AiCoachState(
      messages: messages ?? this.messages,
      currentIndex: currentIndex ?? this.currentIndex,
      isThinking: isThinking ?? this.isThinking,
      isGeneratingMockup: isGeneratingMockup ?? this.isGeneratingMockup,
      sessionComplete: sessionComplete ?? this.sessionComplete,
      answers: answers ?? this.answers,
      discoverySummary: discoverySummary ?? this.discoverySummary,
      generatedImageUrl: clearGeneratedImageUrl
          ? null
          : (generatedImageUrl ?? this.generatedImageUrl),
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
    );
  }

  /// Professional share/export text with Ink-N-Motion footer.
  String buildShareText() {
    final buffer = StringBuffer();
    buffer.writeln('Premium Tattoo Blueprint');
    buffer.writeln('Ink-N-Motion · AI Coach');
    buffer.writeln();
    buffer.write(discoverySummary.toPremiumBlueprintBody());
    buffer.writeln();
    buffer.writeln('Consultation Summary');
    buffer.writeln('────────────────────');
    for (var i = 0; i < answers.length; i++) {
      buffer.writeln('${i + 1}. ${TattooAdvisorQuestions.prompts[i]}');
      buffer.writeln('   ${answers[i]}');
      buffer.writeln();
    }
    buffer.write(_shareFooter);
    return buffer.toString().trim();
  }

  String buildVisionSummary() => buildShareText();
}

class AiCoachNotifier extends StateNotifier<AiCoachState> {
  AiCoachNotifier() : super(const AiCoachState()) {
    _postCoachMessage(TattooAdvisorQuestions.prompts.first);
  }

  static final String _generateMockupUrl =
      '${RenderMotionService.defaultBaseUrl}/generate-mockup';

  final Dio _apiDio = Dio(
    BaseOptions(
      connectTimeout: ApiService.connectTimeout,
      receiveTimeout: const Duration(seconds: 180),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  static const _thinkingDelay = Duration(milliseconds: 1500);

  int? _pendingReplyToken;

  @override
  void dispose() {
    _pendingReplyToken = null;
    _apiDio.close();
    super.dispose();
  }

  /// Clears the session and restarts from question 1.
  void resetSession() {
    _pendingReplyToken = null;
    state = const AiCoachState();
    _postCoachMessage(TattooAdvisorQuestions.prompts.first);
  }

  void _postCoachMessage(String text) {
    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(role: ChatMessageRole.coach, text: text),
      ],
    );
  }

  void _postUserMessage(String text) {
    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(role: ChatMessageRole.user, text: text),
      ],
    );
  }

  /// POSTs [AiCoachState.discoverySummary] to the Render mockup relay and
  /// stores the returned URL in [AiCoachState.generatedImageUrl] for
  /// [StudioConceptDialog] / [Image.network].
  Future<void> generateTattooMockup() async {
    if (state.isGeneratingMockup || state.hasGeneratedDesign) {
      return;
    }

    if (!state.sessionComplete && !state.discoverySummary.hasAnyField) {
      return;
    }

    final discoverySummary = state.discoverySummary.toJson();
    final payload = <String, dynamic>{
      'discovery_summary': discoverySummary,
      'discoverySummary': discoverySummary,
    };

    debugPrint(
      '[AiCoach] POST $_generateMockupUrl\n'
      'Payload: ${jsonEncode(payload)}',
    );

    state = state.copyWith(
      isGeneratingMockup: true,
      clearFeedback: true,
    );

    try {
      final response = await _apiDio.post<Map<String, dynamic>>(
        _generateMockupUrl,
        data: payload,
        options: Options(
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      debugPrint(
        '[AiCoach] generate-mockup response HTTP ${response.statusCode} '
        'body: ${response.data}',
      );

      if (!mounted) return;

      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        state = state.copyWith(
          isGeneratingMockup: false,
          feedbackMessage:
              'Mockup service returned HTTP $status. Please try again.',
        );
        return;
      }

      final imageUrl = _parseMockupImageUrl(response.data);
      if (imageUrl == null || imageUrl.isEmpty) {
        state = state.copyWith(
          isGeneratingMockup: false,
          feedbackMessage:
              'Mockup service did not return an image URL. Please try again.',
        );
        return;
      }

      debugPrint('[AiCoach] Mockup imageUrl: $imageUrl');

      state = state.copyWith(
        generatedImageUrl: imageUrl,
        messages: [
          ...state.messages,
          ChatMessage(
            role: ChatMessageRole.coach,
            type: ChatMessageType.generatedImage,
            text: 'Here is your tattoo design concept:',
            imageUrl: imageUrl,
          ),
        ],
        isGeneratingMockup: false,
      );
    } on DioException catch (error) {
      debugPrint(
        '[AiCoach] generate-mockup DioException: ${error.message} '
        'status=${error.response?.statusCode} data=${error.response?.data}',
      );
      if (!mounted) return;
      state = state.copyWith(
        isGeneratingMockup: false,
        feedbackMessage:
            error.message ?? 'Unable to reach mockup service. Please try again.',
      );
    } catch (error, stackTrace) {
      debugPrint('[AiCoach] generate-mockup error: $error\n$stackTrace');
      if (!mounted) return;
      state = state.copyWith(
        isGeneratingMockup: false,
        feedbackMessage: 'Unable to generate design. Please try again.',
      );
    }
  }

  /// Extracts a network image URL from the Render mockup API JSON body.
  String? _parseMockupImageUrl(dynamic data) {
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);

    for (final key in ['image_url', 'imageUrl', 'url', 'image']) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    final nested = map['data'];
    if (nested is Map) {
      return _parseMockupImageUrl(nested);
    }

    return null;
  }

  Future<void> submitAnswer(String rawAnswer) async {
    final answer = rawAnswer.trim();
    if (answer.isEmpty ||
        state.sessionComplete ||
        state.isThinking ||
        state.isGeneratingMockup) {
      return;
    }

    _postUserMessage(answer);
    final updatedAnswers = [...state.answers, answer];
    final updatedSummary = TattooDiscoveryCategorizer.categorize(
      questionIndex: state.currentIndex,
      answer: answer,
      current: state.discoverySummary,
    );
    final nextIndex = state.currentIndex + 1;

    if (nextIndex >= TattooAdvisorQuestions.prompts.length) {
      state = state.copyWith(
        answers: updatedAnswers,
        discoverySummary: updatedSummary,
        currentIndex: nextIndex,
        sessionComplete: true,
        isThinking: false,
        clearFeedback: true,
      );
      unawaited(generateTattooMockup());
      return;
    }

    final replyToken = (_pendingReplyToken ?? 0) + 1;
    _pendingReplyToken = replyToken;

    state = state.copyWith(
      answers: updatedAnswers,
      discoverySummary: updatedSummary,
      isThinking: true,
      clearFeedback: true,
    );

    await Future<void>.delayed(_thinkingDelay);

    if (!mounted || _pendingReplyToken != replyToken) return;

    _postCoachMessage(TattooAdvisorQuestions.prompts[nextIndex]);
    state = state.copyWith(
      currentIndex: nextIndex,
      isThinking: false,
    );
  }

  Future<void> saveSummary() async {
    await Clipboard.setData(ClipboardData(text: state.buildShareText()));

    var savedImage = false;
    if (state.hasGeneratedDesign) {
      savedImage = await _saveGeneratedImageToGallery(state.generatedImageUrl!);
    }

    if (!mounted) return;
    state = state.copyWith(
      feedbackMessage: savedImage
          ? 'Blueprint copied and design saved to your photo library.'
          : state.hasGeneratedDesign
              ? 'Blueprint copied. Allow Photos access to save the design image.'
              : 'Blueprint copied to clipboard. Design is still generating.',
    );
  }

  Future<bool> _saveGeneratedImageToGallery(String imageUrl) async {
    try {
      final file = await _downloadShareImage(imageUrl);
      if (file == null) return false;

      if (!await Gal.hasAccess()) {
        final granted = await Gal.requestAccess();
        if (!granted) return false;
      }

      await Gal.putImage(file.path);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// [sharePositionOrigin] should be passed from the calling widget
  /// (see shareOriginFromContext); falls back to the view size on iPad.
  Future<void> shareBlueprint({ui.Rect? sharePositionOrigin}) async {
    final text = state.buildShareText();

    try {
      List<XFile>? files;
      if (state.hasGeneratedDesign) {
        final imageFile = await _downloadShareImage(state.generatedImageUrl!);
        if (imageFile != null) {
          files = [XFile(imageFile.path, mimeType: 'image/png')];
        }
      }

      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: 'My Ink-N-Motion Tattoo Blueprint',
          files: files,
          sharePositionOrigin: sharePositionOrigin ?? _fallbackShareOrigin(),
        ),
      );

      if (!mounted) return;
      state = state.copyWith(
        feedbackMessage: 'Blueprint shared.',
      );
    } catch (error, stackTrace) {
      debugPrint('AiCoachNotifier.shareBlueprint failed: $error');
      debugPrint('$stackTrace');
      if (!mounted) return;
      state = state.copyWith(
        feedbackMessage: 'Unable to open share sheet. Try Save Blueprint.',
      );
    }
  }

  static ui.Rect _fallbackShareOrigin() {
    final view = ui.PlatformDispatcher.instance.implicitView;
    if (view == null) {
      return const ui.Rect.fromLTWH(0, 0, 1, 1);
    }
    final size = view.physicalSize / view.devicePixelRatio;
    return ui.Rect.fromLTWH(0, 0, size.width, size.height / 2);
  }

  Future<File?> _downloadShareImage(String url) async {
    try {
      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/ink_blueprint_${DateTime.now().millisecondsSinceEpoch}.png';
      await _apiDio.download(url, path);
      return File(path);
    } catch (_) {
      return null;
    }
  }
}
