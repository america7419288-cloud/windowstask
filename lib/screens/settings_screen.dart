import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/app_settings.dart';
import '../providers/settings_provider.dart';
import '../providers/task_provider.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../theme/typography.dart';
import '../theme/colors.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: AppTypography.title1.copyWith(color: colors.textPrimary)),
          const SizedBox(height: 24),
          const _Section(title: 'Appearance', children: [
            _ThemeRow(),
            _AccentColorRow(),
          ]),
          const SizedBox(height: 16),
          const _Section(title: 'Focus', children: [
            _FocusDurationRow(),
          ]),
          const SizedBox(height: 16),
          const _Section(title: 'Calendar', children: [
            _StartOfWeekRow(),
          ]),
          const SizedBox(height: 16),
          const _Section(title: 'Notifications', children: [
            _NotificationsRow(),
          ]),
          const SizedBox(height: 16),
          const _Section(title: 'Data', children: [
            _ExportRow(),
            _ImportRow(),
          ]),
          const SizedBox(height: 16),
          const _Section(title: 'About', children: [
            _AboutRow(),
          ]),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: AppTypography.caption.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.isDark ? const Color(0xFF2C2C2E) : Colors.white,
            borderRadius: BorderRadius.circular(AppConstants.radiusCard),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: children.asMap().entries.map((e) {
              final isLast = e.key == children.length - 1;
              return Column(
                children: [
                  e.value,
                  if (!isLast) Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(height: 1, color: colors.divider),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.label,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.icon,
  });

  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusCard),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: colors.textSecondary),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTypography.body.copyWith(color: colors.textPrimary)),
                  if (subtitle != null)
                    Text(subtitle!, style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _ThemeRow extends StatelessWidget {
  const _ThemeRow();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return _SettingsRow(
      label: 'Appearance',
      icon: Icons.dark_mode_outlined,
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<ThemeMode>(
          value: settings.themeMode,
          isDense: true,
          items: const [
            DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
            DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
            DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
          ],
          onChanged: (m) => m != null ? settings.setThemeMode(m) : null,
        ),
      ),
    );
  }
}

class _AccentColorRow extends StatelessWidget {
  const _AccentColorRow();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return _SettingsRow(
      label: 'Accent Color',
      icon: Icons.color_lens_outlined,
      trailing: Row(
        children: settings.accentColorOptions.map((opt) {
          final hex = opt['hex'] as String;
          final color = opt['color'] as Color;
          final isSelected = settings.accentColorHex == hex;
          return GestureDetector(
            onTap: () => settings.setAccentColor(hex),
            child: Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(left: 6),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                boxShadow: isSelected
                    ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 4)]
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FocusDurationRow extends StatelessWidget {
  const _FocusDurationRow();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return _SettingsRow(
      label: 'Focus Duration',
      subtitle: '${settings.focusDuration} minutes per session',
      icon: Icons.timer_outlined,
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: settings.focusDuration,
          isDense: true,
          items: [15, 20, 25, 30, 45, 60].map((m) => DropdownMenuItem(
            value: m, child: Text('$m min'),
          )).toList(),
          onChanged: (m) => m != null ? settings.setFocusDuration(m) : null,
        ),
      ),
    );
  }
}

class _StartOfWeekRow extends StatelessWidget {
  const _StartOfWeekRow();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return _SettingsRow(
      label: 'Start of Week',
      icon: Icons.date_range_outlined,
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: settings.startOfWeek,
          isDense: true,
          items: const [
            DropdownMenuItem(value: 1, child: Text('Monday')),
            DropdownMenuItem(value: 7, child: Text('Sunday')),
          ],
          onChanged: (d) => d != null ? settings.setStartOfWeek(d) : null,
        ),
      ),
    );
  }
}

class _NotificationsRow extends StatelessWidget {
  const _NotificationsRow();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return _SettingsRow(
      label: 'Enable Notifications',
      icon: Icons.notifications_outlined,
      trailing: Switch(
        value: settings.notificationsEnabled,
        onChanged: (v) => settings.setNotificationsEnabled(v),
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _ExportRow extends StatelessWidget {
  const _ExportRow();

  @override
  Widget build(BuildContext context) {
    return _SettingsRow(
      label: 'Export Tasks as JSON',
      subtitle: 'Save all your tasks locally',
      icon: Icons.upload_outlined,
      trailing: const Icon(Icons.chevron_right, size: 16),
      onTap: () async {
        try {
          final data = StorageService.instance.exportAll();
          final json = jsonEncode(data);
          final path = await FilePicker.platform.saveFile(
            dialogTitle: 'Export Taski Data',
            fileName: 'taski_export.json',
            type: FileType.custom,
            allowedExtensions: ['json'],
          );
          if (path != null) {
            final file = await _createFile(path, json);
          }
        } catch (e) {
          // Show error
        }
      },
    );
  }

  Future<void> _createFile(String path, String content) async {
    // Write to file
  }
}

class _ImportRow extends StatelessWidget {
  const _ImportRow();

  @override
  Widget build(BuildContext context) {
    return _SettingsRow(
      label: 'Import from JSON',
      subtitle: 'Restore tasks from a backup',
      icon: Icons.download_outlined,
      trailing: const Icon(Icons.chevron_right, size: 16),
      onTap: () async {
        try {
          final result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['json'],
          );
          if (result != null && result.files.single.path != null) {
            // Read and import
          }
        } catch (e) {
          // Show error
        }
      },
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow();

  @override
  Widget build(BuildContext context) {
    return const _SettingsRow(
      label: 'Taski',
      subtitle: 'Version 1.0.0 • Built with Flutter',
      icon: Icons.info_outlined,
    );
  }
}
