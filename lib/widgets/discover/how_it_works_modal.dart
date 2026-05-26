import 'package:flutter/material.dart';

class HowItWorksModal {
  static Future<void> show(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'How It Works',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '1. Upload or scan your tattoo photo\n'
          '2. Choose an animation style\n'
          '3. Generate your animated video\n'
          '4. Share your living tattoo!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Got it!',
              style: TextStyle(color: Color(0xFF6C63FF)),
            ),
          ),
        ],
      ),
    );
  }
}
