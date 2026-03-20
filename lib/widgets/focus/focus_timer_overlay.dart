import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../providers/focus_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/celebration_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/typography.dart';
import '../../theme/colors.dart';
import '../../utils/constants.dart';

class FocusTimerOverlay extends StatelessWidget {
  const FocusTimerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = colors.isDark;

    return Consumer<FocusProvider>(
      builder: (context, focus, _) {
        if (!focus.isActive && focus.state == FocusState.idle) {
          return const SizedBox.shrink();
        }

        final isBreak = focus.isBreakMode;
        final statusColor = isBreak ? AppColors.green : AppColors.red;

        return Positioned(
          bottom: 24,
          right: 24,
          child: Material(
            elevation: 0,
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 260,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: AppColors.glassBackground(isDark),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: focus.isActive ? 0.2 : 0.05),
                        blurRadius: focus.isActive ? 30 : 15,
                        spreadRadius: focus.isActive ? 4 : 0,
                      ),
                    ],
                    border: Border.all(
                      color: statusColor.withValues(alpha: isDark ? 0.3 : 0.1),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        children: [
                          Icon(
                            isBreak ? PhosphorIcons.coffee() : PhosphorIcons.timer(),
                            size: 16,
                            color: statusColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isBreak ? 'Break Time' : 'Focus Session',
                              style: AppTypography.caption.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => focus.stopFocus(),
                            child: Icon(PhosphorIcons.x(), size: 14, color: colors.textQuaternary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Timer
                      Text(
                        focus.timeDisplay,
                        style: AppTypography.headline.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Progress
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: focus.progress,
                          minHeight: 4,
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05),
                          valueColor: AlwaysStoppedAnimation(statusColor),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Session Goals checklist
                      if (!isBreak && focus.sessionTaskIds.isNotEmpty) ...[
                        _SectionTitle(title: 'GOALS', color: colors.textQuaternary),
                        const SizedBox(height: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 120),
                          child: SingleChildScrollView(
                            child: Column(
                              children: focus.sessionTaskIds.map((taskId) {
                                return _GoalItem(taskId: taskId);
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (focus.state == FocusState.running || focus.state == FocusState.onBreak)
                            _TimerBtn(
                              icon: PhosphorIcons.pause(PhosphorIconsStyle.fill),
                              onTap: () => focus.pauseFocus(),
                              color: AppColors.orange,
                            )
                          else if (focus.state == FocusState.paused)
                            _TimerBtn(
                              icon: PhosphorIcons.play(PhosphorIconsStyle.fill),
                              onTap: () => focus.resumeFocus(),
                              color: AppColors.green,
                            ),
                          const SizedBox(width: 12),
                          _TimerBtn(
                            icon: PhosphorIcons.stop(PhosphorIconsStyle.fill),
                            onTap: () => focus.stopFocus(),
                            color: AppColors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GoalItem extends StatelessWidget {
  final String taskId;
  const _GoalItem({required this.taskId});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final task = taskProvider.getById(taskId);
    if (task == null) return const SizedBox.shrink();

    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: () => taskProvider.toggleComplete(
          taskId,
          celebration: context.read<CelebrationProvider>(),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: task.isCompleted ? accent.withValues(alpha: 0.08) : colors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: task.isCompleted ? accent.withValues(alpha: 0.2) : colors.border,
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                task.isCompleted ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill) : PhosphorIcons.circle(),
                size: 14,
                color: task.isCompleted ? accent : colors.textTertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    fontSize: 11,
                    color: task.isCompleted ? colors.textPrimary : colors.textSecondary,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionTitle({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: AppTypography.caption.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _TimerBtn extends StatelessWidget {
  const _TimerBtn({required this.icon, required this.onTap, required this.color});
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
