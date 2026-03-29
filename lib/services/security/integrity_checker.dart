import 'package:flutter/material.dart';
import 'secure_xp_store.dart';

class IntegrityChecker {
  static Future<void> runOnStartup(BuildContext context) async {
    final result = await SecureXPStore.instance.loadAndVerify();

    if (result == IntegrityResult.tampered) {
      if (context.mounted) {
        await _handleTampering(context);
      }
    }
  }

  static Future<void> _handleTampering(BuildContext context) async {
    // Show warning dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E2128),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(children: [
          Icon(Icons.security_rounded,
              color: Color(0xFFEF4444),
              size: 22),
          SizedBox(width: 10),
          Text('Security Alert',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            )),
        ]),
        content: const Text(
          'Your XP data appears to have been modified outside the app. '
          'Invalid entries have been removed to maintain fairness.\n\n'
          'Your tasks and settings are unaffected.',
          style: TextStyle(
            color: Colors.white70,
            height: 1.5,
          )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Understood',
              style: TextStyle(
                color: Color(0xFF6366F1),
                fontWeight: FontWeight.w600,
              )),
          ),
        ],
      ),
    );
  }
}
