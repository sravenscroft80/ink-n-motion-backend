import 'package:flutter/material.dart';

class MonthlyLimitOverlayCard extends StatelessWidget {
  const MonthlyLimitOverlayCard({
    super.key,
    required this.message,
    this.onDismiss,
    this.slotsUsed,
    this.slotsTotal,
    this.onUpgrade,
  });

  final String message;
  final VoidCallback? onDismiss;
  final int? slotsUsed;
  final int? slotsTotal;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6C63FF), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, color: Color(0xFF6C63FF), size: 40),
          const SizedBox(height: 12),
          const Text(
            'Monthly Limit Reached',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          if (onUpgrade != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
              ),
              onPressed: onUpgrade,
              child: const Text('Upgrade Plan'),
            ),
          ],
          if (onDismiss != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onDismiss,
              child: const Text(
                'Dismiss',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
