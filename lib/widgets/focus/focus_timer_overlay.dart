import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/focus_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/typography.dart';
import '../../theme/colors.dart';
import '../../utils/constants.dart';

/// WARNING: This overlay returns a Positioned as its root widget.
/// It MUST be a direct child of a Stack in the application layout.
class FocusTimerOverlay extends StatelessWidget {
  const FocusTimerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Consumer<FocusProvider>(
      builder: (context, focus, _) {
        if (!focus.isActive && focus.state == FocusState.idle) {
          return const SizedBox.shrink();
        }

        return Positioned(
          bottom: 20,
          right: 20,
          child: Material(
            elevation: 0,
            color: Colors.transparent,
            child: Container(
              width: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.isDark ? const Color(0xFF2C2C2E) : Colors.white,
                borderRadius: BorderRadius.circular(AppConstants.radiusModal),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 30,
                  ),
                ],
                border: Border.all(color: colors.divider),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 14, color: AppColors.red),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Focus Mode',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.read<FocusProvider>().stopFocus(),
                        child: Icon(Icons.close, size: 14, color: colors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Task title
                  if (focus.activeTaskTitle != null)
                    Text(
                      focus.activeTaskTitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(color: colors.textSecondary),
                    ),
                  const SizedBox(height: 12),
                  // Timer
                  Text(
                    focus.timeDisplay,
                    style: AppTypography.title1.copyWith(color: colors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  // Progress
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: focus.progress,
                      minHeight: 3,
                      backgroundColor: colors.isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.08),
                      valueColor: const AlwaysStoppedAnimation(AppColors.red),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (focus.state == FocusState.running)
                        _TimerBtn(
                          icon: Icons.pause_rounded,
                          onTap: () => focus.pauseFocus(),
                          color: AppColors.orange,
                        )
                      else if (focus.state == FocusState.paused)
                        _TimerBtn(
                          icon: Icons.play_arrow_rounded,
                          onTap: () => focus.resumeFocus(),
                          color: AppColors.green,
                        ),
                      const SizedBox(width: 8),
                      _TimerBtn(
                        icon: Icons.stop_rounded,
                        onTap: () => focus.stopFocus(),
                        color: AppColors.red,
                      ),
                    ],
                  ),
                  if (focus.completedSessions > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        focus.completedSessions.clamp(0, 8),
                        (i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
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
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
