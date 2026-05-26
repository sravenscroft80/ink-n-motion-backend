import 'package:flutter/material.dart';

class InkShareUnlockModal {
  static Future<void> show(
    BuildContext context, {
    required Future<void> Function() onShareComplete,
  }) async {
    final shouldShare = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share Your Creation',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Share your animated tattoo to unlock premium features!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text(
                    'Maybe later',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Share Now'),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (shouldShare == true) {
      await onShareComplete();
    }
  }
}

class InkShareUnlockSnackbar {
  static void show(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share your video to unlock more features!'),
        backgroundColor: Color(0xFF6C63FF),
      ),
    );
  }
}
