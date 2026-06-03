import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ink_n_motion/services/firestore_wallet_service.dart';
import 'package:ink_n_motion/utils/app_links.dart';
import 'package:ink_n_motion/utils/gallery_media_saver.dart';
import 'package:ink_n_motion/widgets/video/ink_network_video_player.dart';
import 'package:share_plus/share_plus.dart';
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
  final String assetPath;

  const _InkStyle({
    required this.id,
    required this.label,
    required this.emoji,
    required this.hint,
    required this.isFree,
    required this.assetPath,
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

  static const List<_InkStyle> _styles = [
    _InkStyle(
      id: 'ember_glow',
      label: 'Ember Glow',
      emoji: '🔥',
      hint: 'Warm golden light pulses through the linework',
      isFree: true,
      assetPath: 'assets/images/animation_styles/ember_glow.png',
    ),
    _InkStyle(
      id: 'fluid_flow',
      label: 'Fluid Flow',
      emoji: '🌊',
      hint: 'Ink ripples and breathes like liquid',
      isFree: true,
      assetPath: 'assets/images/animation_styles/fluid_flow.png',
    ),
    _InkStyle(
      id: 'shadow_reaper',
      label: 'Shadow Reaper',
      emoji: '🌑',
      hint: 'Dark gothic forms emerge from deep shadows',
      isFree: true,
      assetPath: 'assets/images/animation_styles/shadow_reaper.png',
    ),
    _InkStyle(
      id: 'electric_storm',
      label: 'Electric Storm',
      emoji: '⚡',
      hint: 'Neon electricity arcs between the linework',
      isFree: true,
      assetPath: 'assets/images/animation_styles/electric_storm.png',
    ),
    _InkStyle(
      id: 'japanese_wave',
      label: 'Japanese Wave',
      emoji: '🎴',
      hint: 'Ink flows like traditional brush strokes and waves',
      isFree: true,
      assetPath: 'assets/images/animation_styles/japanese_wave.png',
    ),
    _InkStyle(
      id: 'alex_grey',
      label: 'Alex Grey',
      emoji: '🔮',
      hint: 'Sacred geometry and visionary light grids activate',
      isFree: true,
      assetPath: 'assets/images/animation_styles/alex_grey.png',
    ),
    _InkStyle(
      id: 'steampunk',
      label: 'Steampunk',
      emoji: '⚙️',
      hint: 'Gears turn, copper glows, steam rises from the ink',
      isFree: true,
      assetPath: 'assets/images/animation_styles/steampunk.png',
    ),
    _InkStyle(
      id: 'horror',
      label: 'Horror',
      emoji: '🩸',
      hint: 'Ink drips, veins pulse, darkness breathes',
      isFree: true,
      assetPath: 'assets/images/animation_styles/horror.png',
    ),
    _InkStyle(
      id: 'watercolor_bloom',
      label: 'Watercolor Bloom',
      emoji: '🎨',
      hint: 'Ink bleeds outward like pigment on wet paper',
      isFree: true,
      assetPath: 'assets/images/animation_styles/watercolor_bloom.png',
    ),
    _InkStyle(
      id: 'mystic_drift',
      label: 'Mystic Drift',
      emoji: '✨',
      hint: 'Elements drift with an ethereal smoke energy',
      isFree: true,
      assetPath: 'assets/images/animation_styles/mystic_drift.png',
    ),
  ];

  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  _InkStyle _selectedStyle = _styles[0];
  bool _isGenerating = false;
  bool _isSaving = false;
  String? _taskId;
  String? _pollStatus;
  String? _videoUrl;
  String? _errorMessage;

  Future<void> _pickImage() async {
    ({Uint8List bytes, String name})? picked;

    if (kIsWeb) {
      picked = await pickCoverupImage();
    } else {
      final choice = await showCupertinoModalPopup<String>(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          title: const Text('Add Tattoo Photo'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(ctx).pop('camera'),
              child: const Text('Take Photo'),
            ),
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(ctx).pop('gallery'),
              child: const Text('Choose from Gallery'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ),
      );

      if (!mounted) return;
      if (choice == 'camera') {
        picked = await captureCoverupImage();
      } else if (choice == 'gallery') {
        picked = await pickCoverupImage();
      }
    }

    if (!mounted || picked == null) return;

    final result = picked;
    setState(() {
      _selectedImageBytes = result.bytes;
      _selectedImageName = result.name;
      _errorMessage = null;
    });
  }

  Future<void> _generateVideo() async {
    if (_selectedImageBytes == null) {
      _showNotice('Please upload a tattoo photo first');
      return;
    }

    // 1. Get current user
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _showNotice('Please wait while we set up your account.', title: 'Not Ready');
      return;
    }

    // 2. Get wallet
    final wallet = await FirestoreWalletService.instance.getWallet(uid);
    if (wallet == null) {
      _showNotice('Unable to load your token balance. Please try again.', title: 'Wallet Error');
      return;
    }

    if (wallet.totalBalance < InkTokenCost.animateMyInk) {
      _showNotice(
        'You need 10 tokens to animate. Visit the store to top up.',
        title: 'Not Enough Tokens',
      );
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
        _pollStatus = 'Queued — preparing your animation...';
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
          await FirestoreWalletService.instance.deductTokens(
            uid,
            InkTokenCost.animateMyInk,
          );
          break;
        }

        if (status == 'failed') {
          throw Exception('Animation render failed');
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
        _errorMessage = 'Request timed out while starting your animation';
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

  Future<void> _saveVideo() async {
    final videoUrl = _videoUrl;
    if (videoUrl == null || videoUrl.isEmpty) {
      _showNotice('Nothing to save yet.');
      return;
    }

    if (kIsWeb) {
      _showNotice('Right-click the video link to save');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final saved = await saveNetworkVideoToGallery(videoUrl);
      if (!mounted) return;
      _showNotice(
        saved
            ? 'Video saved to your gallery!'
            : 'Unable to save video. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _shareVideo() async {
    if (_videoUrl == null) return;
    await SharePlus.instance.share(
      ShareParams(
        text: '${_videoUrl!}\n\n$kShareMessage',
      ),
    );
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
                                  width: 96,
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: _selectedStyle.id == style.id
                                        ? _gold.withValues(alpha: 0.15)
                                        : _surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _selectedStyle.id == style.id
                                          ? _gold
                                          : (!style.isFree
                                              ? const Color(0xFF4FC3F7)
                                              : _border),
                                      width: _selectedStyle.id == style.id
                                          ? 2
                                          : 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: _StylePreviewImage(
                                          assetPath: style.assetPath,
                                          emoji: style.emoji,
                                          width: 84,
                                          height: 52,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            style.emoji,
                                            style:
                                                const TextStyle(fontSize: 11),
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              style.label,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight:
                                                    _selectedStyle.id ==
                                                            style.id
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                color: _selectedStyle.id ==
                                                        style.id
                                                    ? CupertinoColors.white
                                                    : _snippetGrey,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          if (!style.isFree) ...[
                                            const SizedBox(width: 2),
                                            const Text(
                                              '🔒',
                                              style: TextStyle(fontSize: 9),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: _background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const ColoredBox(color: _background),
                        Positioned.fill(
                          child: _StylePreviewImage(
                            assetPath: _selectedStyle.assetPath,
                            emoji: _selectedStyle.emoji,
                            fit: BoxFit.contain,
                            expand: true,
                          ),
                        ),
                        Positioned(
                          left: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: CupertinoColors.black.withValues(
                                alpha: 0.55,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${_selectedStyle.emoji} ${_selectedStyle.label} — plain vs effect',
                              style: const TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
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
                        '10 tokens per render',
                        style: TextStyle(
                          color: _gold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Tip: all-blackout tattoos or full sleeves may produce varied results.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _snippetGrey,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                  if (_isGenerating) ...[
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        '✦ Quality renders take time — great ink is worth the wait.\nKeep the app open while we bring your tattoo to life.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _snippetGrey,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 300,
                        decoration: BoxDecoration(
                          color: _surface,
                          border: Border.all(color: _border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkNetworkVideoPlayer(
                          url: _videoUrl!,
                          autoPlay: true,
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
                          onTap: _isSaving ? null : _saveVideo,
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

/// Local animation-style preview with emoji fallback when asset is missing.
class _StylePreviewImage extends StatelessWidget {
  const _StylePreviewImage({
    required this.assetPath,
    required this.emoji,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.expand = false,
  });

  final String assetPath;
  final String emoji;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool expand;

  static const Color _surface = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      assetPath,
      width: expand ? null : width,
      height: expand ? null : height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: _surface,
          alignment: Alignment.center,
          child: Text(
            emoji,
            style: TextStyle(
              fontSize: height != null ? (height! * 0.35).clamp(18, 40) : 28,
            ),
          ),
        );
      },
    );
    if (expand) {
      return SizedBox.expand(child: image);
    }
    return image;
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
