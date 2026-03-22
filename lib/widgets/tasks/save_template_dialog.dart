import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../providers/template_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';

class SaveTemplateDialog extends StatefulWidget {
  final Task task;

  const SaveTemplateDialog({super.key, required this.task});

  static Future<bool> show(BuildContext context, Task task) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => SaveTemplateDialog(task: task),
    );
    return result ?? false;
  }

  @override
  State<SaveTemplateDialog> createState() => _SaveTemplateDialogState();
}

class _SaveTemplateDialogState extends State<SaveTemplateDialog> {
  final _nameCtrl = TextEditingController();
  String _emoji = '📋';

  // Emoji picker — 12 options
  final _emojis = [
    '📋', '🚀', '💡', '🎯', '💼',
    '🏃', '📚', '🌿', '⚡', '🔧',
    '🎨', '🌟',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.isDark
              ? AppColors.surfaceContainerDk
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.ambientShadow(
              opacity: 0.2, blur: 40, offset: const Offset(0, 12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(children: [
              Text('Save as Template',
                  style: AppTypography.headlineSmall.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  )),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context, false),
                child: Icon(Icons.close_rounded,
                    size: 20, color: colors.textTertiary),
              ),
            ]),
            const SizedBox(height: 6),
            Text(
              'Save "${widget.task.title}" with its structure for reuse.',
              style: AppTypography.bodyMedium.copyWith(
                color: colors.textTertiary,
              ),
            ),
            const SizedBox(height: 20),

            // Template name input
            Text('Template name',
                style: AppTypography.labelMedium.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _nameCtrl,
                autofocus: true,
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. Weekly Report...',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: colors.textTertiary,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Emoji picker
            Text('Icon',
                style: AppTypography.labelMedium.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _emojis
                  .map((e) => GestureDetector(
                        onTap: () => setState(() => _emoji = e),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _emoji == e
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : colors.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(e, style: const TextStyle(fontSize: 20)),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context, false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: colors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text('Cancel',
                          style: AppTypography.labelLarge.copyWith(
                            color: colors.textSecondary,
                          )),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: _save,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPrimary,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: AppColors.ambientShadow(
                        opacity: 0.20,
                        blur: 12,
                        offset: const Offset(0, 4),
                      ),
                    ),
                    child: Center(
                      child: Text('Save',
                          style: AppTypography.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    await context.read<TemplateProvider>().saveFromTask(widget.task, name, _emoji);
    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$_emoji Template saved!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ));
    }
  }
}
