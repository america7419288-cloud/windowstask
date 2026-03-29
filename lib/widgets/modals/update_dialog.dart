import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../utils/constants.dart';

import '../../theme/app_theme.dart';

class UpdateDialog extends StatelessWidget {
  final String currentVersion;
  final String latestVersion;
  final String changelog;
  final String downloadUrl;
  final VoidCallback onSkip;

  const UpdateDialog({
    super.key,
    required this.currentVersion,
    required this.latestVersion,
    required this.changelog,
    required this.downloadUrl,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 500,
          constraints: const BoxConstraints(maxHeight: 600),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppConstants.radiusModal),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.1),
                      colors.surfaceElevated,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppConstants.radiusModal)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(PhosphorIcons.rocketLaunch(PhosphorIconsStyle.fill), color: AppColors.primary, size: 32),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'New Update Available! 🚀',
                      style: AppTypography.headlineSM.copyWith(color: colors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.background,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: colors.border),
                      ),
                      child: Text(
                        'v$currentVersion → v$latestVersion',
                        style: AppTypography.labelMD.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // Changelog
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('What\'s New:', style: AppTypography.titleSM.copyWith(color: colors.textSecondary)),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.background.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colors.border),
                          ),
                          child: Markdown(
                            data: changelog,
                            shrinkWrap: true,
                            selectable: true,
                            styleSheet: MarkdownStyleSheet(
                              p: AppTypography.bodyMD.copyWith(color: colors.textSecondary),
                              h1: AppTypography.titleMD.copyWith(color: colors.textPrimary),
                              h2: AppTypography.titleSM.copyWith(color: colors.textPrimary),
                              h3: AppTypography.labelLG.copyWith(color: colors.textPrimary),
                              listBullet: AppTypography.bodyMD.copyWith(color: colors.textPrimary),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Buttons
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          onSkip();
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Skip Version',
                          style: AppTypography.bodyMD.copyWith(color: colors.textTertiary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusButton)),
                          elevation: 0,
                        ).copyWith(
                          overlayColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.1)),
                        ),
                        onPressed: () async {
                          final uri = Uri.parse(downloadUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(PhosphorIcons.downloadSimple(PhosphorIconsStyle.bold), size: 20),
                            const SizedBox(width: 8),
                            const Text('Download Now'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
