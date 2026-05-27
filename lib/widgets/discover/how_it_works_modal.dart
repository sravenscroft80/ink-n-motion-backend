import 'package:flutter/cupertino.dart';

class HowItWorksModal {
  static Future<void> show(BuildContext context) async {
    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text(
          'How It Works',
          style: TextStyle(color: CupertinoColors.white),
        ),
        content: const Text(
          '1. Upload or scan your tattoo photo\n'
          '2. Choose an animation style\n'
          '3. Generate your animated video\n'
          '4. Share your living tattoo!',
          style: TextStyle(color: CupertinoColors.systemGrey),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
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
