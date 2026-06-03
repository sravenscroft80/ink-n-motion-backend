import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ink_n_motion/utils/gallery_media_saver.dart';
import 'package:video_player/video_player.dart';

bool inkIsNetworkVideoUrl(String url) {
  return url.startsWith('http://') || url.startsWith('https://');
}

class InkNetworkVideoPlayer extends StatefulWidget {
  const InkNetworkVideoPlayer({
    super.key,
    required this.url,
    this.autoPlay = true,
    this.showFullscreenButton = true,
  });

  final String url;
  final bool autoPlay;
  final bool showFullscreenButton;

  @override
  State<InkNetworkVideoPlayer> createState() => _InkNetworkVideoPlayerState();
}

class _InkNetworkVideoPlayerState extends State<InkNetworkVideoPlayer> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _failed = false;
  bool _muted = true;

  @override
  void initState() {
    super.initState();
    unawaited(_initController());
  }

  @override
  void didUpdateWidget(InkNetworkVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      unawaited(_reinitController());
    }
  }

  Future<void> _reinitController() async {
    await _disposeController();
    setState(() {
      _initialized = false;
      _failed = false;
    });
    await _initController();
  }

  Future<void> _initController() async {
    final trimmed = widget.url.trim();
    if (trimmed.isEmpty) {
      if (mounted) setState(() => _failed = true);
      return;
    }

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(trimmed));
      await controller.initialize();
      controller.setLooping(true);
      controller.setVolume(_muted ? 0 : 1);
      if (widget.autoPlay) {
        await controller.play();
      }
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initialized = true;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      await controller.dispose();
    }
  }

  void _toggleMute() {
    final controller = _controller;
    if (controller == null) return;
    setState(() => _muted = !_muted);
    controller.setVolume(_muted ? 0 : 1);
  }

  void _openFullscreen() {
    FullscreenVideoPlayerScreen.open(context, widget.url);
  }

  @override
  void dispose() {
    unawaited(_disposeController());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return _VideoLoadPlaceholder(
        message: 'Unable to load video preview',
        icon: CupertinoIcons.exclamationmark_triangle,
      );
    }

    if (!_initialized || _controller == null) {
      return const _VideoLoadPlaceholder(
        message: 'Loading video...',
        showSpinner: true,
      );
    }

    final controller = _controller!;

    return GestureDetector(
      onTap: _toggleMute,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          ColoredBox(
            color: CupertinoColors.black,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
          ),
          Positioned(
            left: 8,
            bottom: 8,
            child: _MuteBadge(muted: _muted),
          ),
          if (widget.showFullscreenButton)
            Positioned(
              right: 8,
              top: 8,
              child: GestureDetector(
                onTap: _openFullscreen,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: CupertinoColors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    CupertinoIcons.fullscreen,
                    color: CupertinoColors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MuteBadge extends StatelessWidget {
  const _MuteBadge({required this.muted});

  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CupertinoColors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            muted ? CupertinoIcons.volume_mute : CupertinoIcons.volume_up,
            color: CupertinoColors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            muted ? 'Tap for sound' : 'Sound on',
            style: const TextStyle(color: CupertinoColors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _VideoLoadPlaceholder extends StatelessWidget {
  const _VideoLoadPlaceholder({
    required this.message,
    this.icon = CupertinoIcons.play_circle,
    this.showSpinner = false,
  });

  final String message;
  final IconData icon;
  final bool showSpinner;

  static const Color _gold = Color(0xFFD4AF37);
  static const Color _snippetGrey = Color(0xFF999999);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CupertinoColors.black,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSpinner)
            const CupertinoActivityIndicator(color: _gold)
          else
            Icon(icon, color: _gold, size: 48),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _snippetGrey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class FullscreenVideoPlayerScreen extends StatelessWidget {
  const FullscreenVideoPlayerScreen({
    super.key,
    required this.url,
  });

  final String url;

  static const Color _background = Color(0xFF0D0D0D);

  static void open(BuildContext context, String url) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => FullscreenVideoPlayerScreen(url: url),
      ),
    );
  }

  void _showAlert(BuildContext context, String message) {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
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

  Future<void> _copyLink(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    _showAlert(context, 'Link copied!');
  }

  Future<void> _saveVideo(BuildContext context) async {
    if (kIsWeb) {
      _showAlert(context, 'Right-click the video link to download');
      return;
    }

    final saved = await saveNetworkVideoToGallery(url);
    if (!context.mounted) return;
    _showAlert(
      context,
      saved
          ? 'Video saved to your gallery!'
          : 'Unable to save video. Please try again.',
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
                      'Your Animation',
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
            child: InkNetworkVideoPlayer(
              url: url,
              autoPlay: true,
              showFullscreenButton: false,
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _FullscreenActionButton(
                    icon: CupertinoIcons.link,
                    label: 'Copy Link',
                    onTap: () => _copyLink(context),
                  ),
                  _FullscreenActionButton(
                    icon: CupertinoIcons.arrow_down_circle,
                    label: 'Save',
                    onTap: () => _saveVideo(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullscreenActionButton extends StatelessWidget {
  const _FullscreenActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  static const Color _gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _gold, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
