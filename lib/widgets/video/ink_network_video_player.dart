import 'package:flutter/material.dart';

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
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: const Icon(
        Icons.play_circle_outline,
        color: Colors.white,
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

  static void open(BuildContext context, String url) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FullscreenVideoPlayerScreen(url: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Video'),
      ),
      body: Center(
        child: InkNetworkVideoPlayer(url: url, autoPlay: true),
      ),
    );
  }
}
