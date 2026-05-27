import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

bool inkIsNetworkVideoUrl(String url) {
  return url.startsWith('http://') || url.startsWith('https://');
}

class InkNetworkVideoPlayer extends StatefulWidget {
  const InkNetworkVideoPlayer({
    super.key,
    required this.url,
    this.autoPlay = false,
  });

  final String url;
  final bool autoPlay;

  @override
  State<InkNetworkVideoPlayer> createState() => _InkNetworkVideoPlayerState();
}

class _InkNetworkVideoPlayerState extends State<InkNetworkVideoPlayer> {
  static const Color _gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CupertinoColors.black,
      alignment: Alignment.center,
      child: const Icon(
        CupertinoIcons.play_circle,
        color: _gold,
        size: 48,
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
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _surface = Color(0xFF1A1A1A);
  static const Color _border = Color(0xFF333333);
  static const Color _snippetGrey = Color(0xFF999999);

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
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: CupertinoColors.black),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.play_circle,
                          color: _gold,
                          size: 72,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Your animation is ready!',
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap the link below to watch:',
                          style: TextStyle(
                            color: _snippetGrey,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => _copyLink(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: _surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _border),
                            ),
                            child: Text(
                              url,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _gold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap to copy link',
                          style: TextStyle(
                            color: _snippetGrey,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
                    icon: CupertinoIcons.share,
                    label: 'Share',
                    onTap: () => _showAlert(context, 'Share coming soon'),
                  ),
                  _FullscreenActionButton(
                    icon: CupertinoIcons.arrow_down_circle,
                    label: 'Save',
                    onTap: () =>
                        _showAlert(context, 'Right-click link to download'),
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
