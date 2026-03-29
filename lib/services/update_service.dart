import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/modals/update_dialog.dart';

class UpdateService {
  static const String _lastCheckKey = 'last_update_check';
  static const String _skippedVersionKey = 'skipped_version_';

  /// Replace these with your actual details
  static const String owner = 'america7419288-cloud'; // Placeholder
  static const String repo = 'windowstask'; // Placeholder

  static Future<void> checkForUpdates(BuildContext context, {bool manual = false}) async {
    try {
      // 1. Check if we should check (Throttle to once per hour if not manual)
      if (!manual) {
        final prefs = await SharedPreferences.getInstance();
        final lastCheck = prefs.getInt(_lastCheckKey) ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - lastCheck < 3600000) return; // 1 hour
        await prefs.setInt(_lastCheckKey, now);
      }

      // 2. Fetch latest release from GitHub
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$owner/$repo/releases/latest'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode != 200) {
        if (manual && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to check for updates (Status: ${response.statusCode})')),
          );
        }
        return;
      }

      final data = json.decode(response.body);
      final String latestVersion = (data['tag_name'] as String).replaceAll('v', '');
      final String changelog = data['body'] ?? 'No release notes provided.';
      final String downloadUrl = data['html_url'] ?? '';

      // 3. Get current version
      final packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;

      // 4. Compare
      if (_isNewer(latestVersion, currentVersion)) {
        // Check if user skipped this version
        final prefs = await SharedPreferences.getInstance();
        final isSkipped = prefs.getBool('$_skippedVersionKey$latestVersion') ?? false;
        
        if (!isSkipped || manual) {
          if (context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: !manual,
              builder: (ctx) => UpdateDialog(
                currentVersion: currentVersion,
                latestVersion: latestVersion,
                changelog: changelog,
                downloadUrl: downloadUrl,
                onSkip: () async {
                  await prefs.setBool('$_skippedVersionKey$latestVersion', true);
                },
              ),
            );
          }
        }
      } else if (manual) {
         if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('You are on the latest version!')),
           );
         }
      }
    } catch (e) {
      debugPrint('Update Check Error: $e');
    }
  }

  static bool _isNewer(String latest, String current) {
    List<int> latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < latestParts.length; i++) {
       if (i >= currentParts.length) return true;
       if (latestParts[i] > currentParts[i]) return true;
       if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }
}
