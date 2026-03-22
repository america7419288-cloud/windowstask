import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_template.dart';
import '../../models/task.dart';
import '../../providers/template_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../widgets/shared/priority_badge.dart';
import '../../widgets/tasks/shared/card_helpers.dart';

class TemplatePicker extends StatelessWidget {
  const TemplatePicker({super.key});

  static Future<TaskTemplate?> show(BuildContext context) async {
    return await showDialog<TaskTemplate>(
      context: context,
      builder: (_) => const TemplatePicker(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final templates = context.watch<TemplateProvider>().templates;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.isDark
              ? AppColors.surfaceContainerDk
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppColors.ambientShadow(
            opacity: 0.2,
            blur: 40,
            offset: const Offset(0, 12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Choose Template',
                  style: AppTypography.headlineSmall.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close_rounded,
                      size: 20, color: colors.textTertiary),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (templates.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bookmark_outline_rounded,
                          size: 48, color: colors.textTertiary.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'No templates yet',
                        style: AppTypography.titleMedium.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Long-press any task to save it as a template',
                        style: AppTypography.caption.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: templates.length,
                  itemBuilder: (context, index) {
                    final template = templates[index];
                    return GestureDetector(
                      onTap: () => Navigator.pop(context, template),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppColors.ambientShadow(
                            opacity: 0.04,
                            blur: 12,
                            offset: const Offset(0, 2),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(template.emoji,
                                style: const TextStyle(fontSize: 32)),
                            const SizedBox(height: 8),
                            Text(
                              template.name,
                              style: AppTypography.titleSmall.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            // Info pills
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              alignment: WrapAlignment.center,
                              children: [
                                if (template.subtaskTitles.isNotEmpty)
                                  _TemplatePill(
                                      '${template.subtaskTitles.length} subtasks'),
                                if (template.priority != Priority.none)
                                  _TemplatePill(PriorityBadge.labelForPriority(
                                      template.priority)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TemplatePill extends StatelessWidget {
  final String label;
  const _TemplatePill(this.label);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.textTertiary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: colors.textTertiary,
        ),
      ),
    );
  }
}
