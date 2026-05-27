import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:ink_n_motion/screens/coverup_studio_picker.dart'
    if (dart.library.html) 'package:ink_n_motion/screens/coverup_studio_picker_web.dart'
    if (dart.library.io) 'package:ink_n_motion/screens/coverup_studio_picker_io.dart';

/// Animate My Ink — upload tattoo photo and render a Kling AI animation.
class AnimateMyInkScreen extends StatefulWidget {
  const AnimateMyInkScreen({super.key});

  @override
  State<AnimateMyInkScreen> createState() => _AnimateMyInkScreenState();
}

class _InkStyle {
  final String id;
  final String label;
  final String emoji;
  final String hint;
  final bool isFree;

  const _InkStyle({
    required this.id,
    required this.label,
    required this.emoji,
    required this.hint,
    required this.isFree,
  });
}

class _AnimateMyInkScreenState extends State<AnimateMyInkScreen> {
  static const Color _background = Color(0xFF0D0D0D);
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _goldDisabled = Color(0xFF8B7D2A);
  static const Color _surface = Color(0xFF1A1A1A);
  static const Color _border = Color(0xFF333333);
  static const Color _hintGrey = Color(0xFF666666);
  static const Color _mutedGrey = Color(0xFF444444);
  static const Color _snippetGrey = Color(0xFF999999);
  static const Color _errorRed = Color(0xFFCC3333);
  static const Color _pillDarkText = Color(0xFF0D0D0D);

  static const List<_InkStyle> _styles = [
    _InkStyle(
      id: 'ember_glow',
      label: 'Ember Glow',
      emoji: '🔥',
      hint: 'Warm golden light pulses through the linework',
      isFree: true,
    ),
    _InkStyle(
      id: 'fluid_flow',
      label: 'Fluid Flow',
      emoji: '🌊',
      hint: 'Ink ripples and breathes like liquid',
      isFree: true,
    ),
    _InkStyle(
      id: 'mystic_drift',
      label: 'Mystic Drift',
      emoji: '✨',
      hint: 'Elements drift with an ethereal smoke energy',
      isFree: true,
    ),
    _InkStyle(
      id: 'electric_storm',
      label: 'Electric Storm',
      emoji: '⚡',
      hint: 'Neon electricity arcs between the linework',
      isFree: false,
    ),
    _InkStyle(
      id: 'watercolor_bloom',
      label: 'Watercolor Bloom',
      emoji: '🎨',
      hint: 'Ink bleeds outward like pigment on wet paper',
      isFree: false,
    ),
    _InkStyle(
      id: 'shadow_reaper',
      label: 'Shadow Reaper',
      emoji: '🌑',
      hint: 'Dark gothic forms emerge from deep shadows',
      isFree: false,
    ),
  ];

  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  _InkStyle _selectedStyle = _styles[0];
  bool _isGenerating = false;
  String? _taskId;
  String? _pollStatus;
  String? _videoUrl;
  String? _errorMessage;

  Future<void> _pickImage() async {
    final picked = await pickCoverupImage();
    if (!mounted || picked == null) return;

    setState(() {
      _selectedImageBytes = picked.bytes;
      _selectedImageName = picked.name;
      _errorMessage = null;
    });
  }

  Future<void> _generateVideo() async {
    if (_selectedImageBytes == null) {
      _showNotice('Please upload a tattoo photo first');
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _videoUrl = null;
      _taskId = null;
      _pollStatus = 'Submitting...';
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
          'https://ink-n-motion-api.onrender.com/api/generate-video',
        ),
      )
        ..fields['style'] = _selectedStyle.id
        ..fields['duration'] = '10'
        ..files.add(
          http.MultipartFile.fromBytes(
            'image',
            _selectedImageBytes!,
            filename: _selectedImageName ?? 'tattoo.jpg',
          ),
        );

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode != 200 && response.statusCode != 202) {
        throw Exception(
          'Server error (${response.statusCode}). Please try again.',
        );
      }

      final submitData = jsonDecode(response.body) as Map<String, dynamic>;
      final taskId = (submitData['taskId'] ?? submitData['task_id']) as String?;
      if (taskId == null || taskId.isEmpty) {
        throw Exception('No task ID returned');
      }

      setState(() {
        _taskId = taskId;
        _pollStatus = 'Queued — waiting for Kling...';
      });

      String? videoUrl;
      for (var i = 1; i <= 40; i++) {
        await Future<void>.delayed(const Duration(seconds: 5));
        if (!mounted) return;

        final pollResponse = await http.get(
          Uri.parse(
            'https://ink-n-motion-api.onrender.com/api/generate-video-status/$_taskId',
          ),
        );

        if (!mounted) return;

        if (pollResponse.statusCode != 200) {
          throw Exception(
            'Server error (${pollResponse.statusCode}). Please try again.',
          );
        }

        final pollData = jsonDecode(pollResponse.body) as Map<String, dynamic>;
        final status = pollData['status'] as String?;
        final polledVideoUrl =
            (pollData['videoUrl'] ?? pollData['video_url']) as String?;

        if (status == 'succeed' && polledVideoUrl != null) {
          videoUrl = polledVideoUrl;
          setState(() {
            _videoUrl = videoUrl;
            _pollStatus = 'Complete!';
          });
          break;
        }

        if (status == 'failed') {
          throw Exception('Kling render failed');
        }

        setState(() {
          _pollStatus = 'Processing... ($i/40)';
        });
      }

      if (videoUrl == null) {
        throw Exception('Timed out waiting for video');
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Request timed out submitting to Kling';
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  void _showNotice(String message, {String? title}) {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: title != null ? Text(title) : null,
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _saveVideo() {
    if (_videoUrl == null) return;
    _showNotice(
      'Copy this link to download:\n$_videoUrl',
      title: 'Video Ready',
    );
  }

  void _shareVideo() {
    _showNotice('Share coming soon');
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: _background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: const Icon(
                      CupertinoIcons.back,
                      color: CupertinoColors.white,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Animate My Ink',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Bring Your Tattoo to Life',
                    style: TextStyle(
                      color: _gold,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Upload your tattoo photo and choose an animation style',
                    style: TextStyle(
                      color: _snippetGrey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Step 1 — Your Tattoo Photo',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 220,
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _selectedImageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                _selectedImageBytes!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 220,
                              ),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.photo,
                                  color: _hintGrey,
                                  size: 40,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Tap to upload tattoo photo',
                                  style: TextStyle(
                                    color: _hintGrey,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'JPG or PNG',
                                  style: TextStyle(
                                    color: _mutedGrey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(
                        CupertinoIcons.info_circle,
                        color: Color(0xFF666666),
                        size: 13,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Tip: Frame your shot so the tattoo fills most of the photo for best results.',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Step 2 — Choose Animation Style',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final style in _styles)
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: GestureDetector(
                              onTap: () {
                                if (!style.isFree) {
                                  _showNotice(
                                    'This style costs 2 additional tokens on top of your base render.\n\nToken wallet coming soon — style will unlock automatically.',
                                    title:
                                        '${style.emoji} ${style.label} — Premium Style',
                                  );
                                  return;
                                }
                                setState(() => _selectedStyle = style);
                              },
                              child: Opacity(
                                opacity: style.isFree ? 1.0 : 0.65,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _selectedStyle.id == style.id
                                        ? _gold
                                        : _surface,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: !style.isFree
                                          ? const Color(0xFF4FC3F7)
                                          : const Color(0x00000000),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        style.emoji,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        style.label,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight:
                                              _selectedStyle.id == style.id
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                          color: _selectedStyle.id == style.id
                                              ? _pillDarkText
                                              : _snippetGrey,
                                        ),
                                      ),
                                      if (!style.isFree) ...[
                                        const SizedBox(width: 6),
                                        const Text(
                                          '🔒',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedStyle.hint,
                    style: const TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Step 3 — Video Duration',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          CupertinoIcons.play_circle,
                          color: _gold,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '10 Seconds',
                                style: TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Loops beautifully for social media sharing',
                                style: TextStyle(
                                  color: _snippetGrey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.sparkles, color: _gold, size: 14),
                      SizedBox(width: 6),
                      Text(
                        '10 tokens per render  ·  First render free',
                        style: TextStyle(
                          color: _gold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _isGenerating ? null : _generateVideo,
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _isGenerating ? _goldDisabled : _gold,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: _isGenerating
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CupertinoActivityIndicator(
                                    color: CupertinoColors.black,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _pollStatus ?? 'Submitting...',
                                    style: const TextStyle(
                                      color: CupertinoColors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
                                '✦  Animate My Ink',
                                style: TextStyle(
                                  color: CupertinoColors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0x22CC3333),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _errorRed),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: _errorRed,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                  if (_videoUrl != null) ...[
                    const SizedBox(height: 28),
                    const Text(
                      'Your Animation',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Save or share your animated tattoo',
                      style: TextStyle(
                        color: _snippetGrey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              CupertinoIcons.play_circle_fill,
                              color: _gold,
                              size: 64,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Video Ready!',
                              style: TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                _videoUrl!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: _snippetGrey,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ActionButton(
                          label: 'Save',
                          icon: CupertinoIcons.arrow_down_circle,
                          backgroundColor: _surface,
                          foregroundColor: CupertinoColors.white,
                          onTap: _saveVideo,
                        ),
                        _ActionButton(
                          label: 'Share',
                          icon: CupertinoIcons.share,
                          backgroundColor: _surface,
                          foregroundColor: CupertinoColors.white,
                          onTap: _shareVideo,
                        ),
                        _ActionButton(
                          label: 'Re-render',
                          icon: CupertinoIcons.refresh,
                          backgroundColor: _gold,
                          foregroundColor: CupertinoColors.black,
                          onTap: _isGenerating ? null : _generateVideo,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Center(
                      child: Text(
                        'Videos are stored for 7 days · Save to keep permanently',
                        style: TextStyle(
                          color: _snippetGrey,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        height: 64,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: foregroundColor, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
