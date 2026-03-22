import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/focus_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/celebration_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/typography.dart';
import '../../theme/colors.dart';
import '../../widgets/shared/sticker_widget.dart';
import '../../data/sticker_packs.dart';
import '../../models/sticker.dart';

class FocusTimerOverlay extends StatefulWidget {
  const FocusTimerOverlay({super.key});

  @override
  State<FocusTimerOverlay> createState() => _FocusTimerOverlayState();
}

class _FocusTimerOverlayState extends State<FocusTimerOverlay> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

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
        final statusColor = isBreak ? AppColors.indigo : AppColors.accent;

        return Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            layoutBuilder: (child, previous) => Stack(children: [...previous, if (child != null) child]),
            child: _isExpanded 
              ? _buildExpandedView(context, focus, colors, statusColor, isDark, key: ValueKey('expanded_${focus.state}'))
              : Align(
                  key: ValueKey('mini_${focus.state}'),
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _buildMiniView(context, focus, colors, statusColor, isDark),
                  ),
                ),
          ),
        );
      },
    );
  }

  Widget _buildMiniView(BuildContext context, FocusProvider focus, AppColorsExtension colors, Color statusColor, bool isDark) {
    return Material(
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
                      focus.isBreakMode ? PhosphorIcons.coffee() : PhosphorIcons.timer(),
                      size: 14,
                      color: focus.isBreakMode ? AppColors.indigo : AppColors.accent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        focus.currentTaskId != null 
                            ? context.read<TaskProvider>().getById(focus.currentTaskId!)?.title.toUpperCase() ?? 'FOCUSING'
                            : (focus.isBreakMode ? 'BREAK TIME' : 'FOCUSING'),
                        style: AppTypography.caption.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _toggleExpanded,
                      child: Icon(PhosphorIcons.arrowsOutSimple(), size: 14, color: colors.textQuaternary),
                    ),
                    const SizedBox(width: 10),
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
                if (!focus.isBreakMode && focus.sessionTaskIds.isNotEmpty) ...[
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
    );
  }

  Widget _buildExpandedView(BuildContext context, FocusProvider focus, AppColorsExtension colors, Color statusColor, bool isDark, {Key? key}) {
    return Material(
      key: key,
      color: Colors.transparent,
      child: Stack(
          children: [
            // Immersive background with "breathing" blur
            Positioned.fill(
              child: Container(
                color: isDark ? Colors.black.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.7),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
               .custom(
                 duration: 10.seconds,
                 builder: (context, value, child) {
                   return BackdropFilter(
                     filter: ImageFilter.blur(sigmaX: 20 + (10 * value), sigmaY: 20 + (10 * value)),
                     child: Container(color: Colors.transparent),
                   );
                 }
               ),
            ),

            // Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Floating mascot (Random from new stickers)
                  const _MascotBadge(),
                  const SizedBox(height: 40),

                  Text(
                    focus.currentTaskId != null 
                        ? (context.read<TaskProvider>().getById(focus.currentTaskId!)?.title ?? 'STAY FOCUSED')
                        : (focus.isBreakMode ? 'BREAK TIME' : 'STAY FOCUSED'),
                    style: AppTypography.caption.copyWith(
                      color: statusColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 16),
                  
                  // Massive Timer
                  Text(
                    focus.timeDisplay,
                    style: AppTypography.headline.copyWith(
                      fontSize: 120,
                      fontWeight: FontWeight.w900,
                      color: colors.textPrimary,
                      letterSpacing: -2,
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                   .shimmer(duration: 3.seconds, color: statusColor.withValues(alpha: 0.2)),

                  const SizedBox(height: 40),

                  // Progress Ring / Bar
                  Container(
                    width: 400,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: focus.progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(color: statusColor.withValues(alpha: 0.5), blurRadius: 10),
                          ],
                        ),
                      ),
                    ),
                  ).animate().scaleX(begin: 0.8, end: 1, duration: 1.seconds, curve: Curves.easeOut),

                  const SizedBox(height: 60),

                  // Session Goals (Expanded)
                  if (!focus.isBreakMode && focus.sessionTaskIds.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxWidth: 500),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colors.surfaceElevated.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: colors.border.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionTitle(
                            title: 'ACTIVE GOALS', 
                            color: colors.textTertiary,
                          ),
                          const SizedBox(height: 16),
                          ...focus.sessionTaskIds.map((taskId) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ExpandedGoalItem(taskId: taskId, statusColor: statusColor),
                          )),
                        ],
                      ),
                    ).animate().fadeIn(delay: 300.ms, duration: 800.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 60),

                  // Big Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       if (focus.state == FocusState.running || focus.state == FocusState.onBreak)
                        _LargeControlBtn(
                          icon: PhosphorIcons.pause(PhosphorIconsStyle.fill),
                          onTap: () => focus.pauseFocus(),
                          color: AppColors.orange,
                          label: 'Pause',
                        )
                      else if (focus.state == FocusState.paused)
                        _LargeControlBtn(
                          icon: PhosphorIcons.play(PhosphorIconsStyle.fill),
                          onTap: () => focus.resumeFocus(),
                          color: AppColors.success,
                          label: 'Resume',
                        ),
                      const SizedBox(width: 40),
                      _LargeControlBtn(
                        icon: PhosphorIcons.stop(PhosphorIconsStyle.fill),
                        onTap: () => focus.stopFocus(),
                        color: AppColors.danger,
                        label: 'Stop',
                      ),
                    ],
                  ).animate().fadeIn(delay: 500.ms, duration: 800.ms),
                ],
              ),
            ),

            // Collapse Button
            Positioned(
              top: 40,
              right: 40,
              child: _CircularButton(
                icon: PhosphorIcons.arrowsInSimple(),
                onTap: _toggleExpanded,
                colors: colors,
                tooltip: 'Collapse to Mini-Player',
              ),
            ),
          ],
        ),
    );

  }
}

class _ExpandedGoalItem extends StatelessWidget {
  final String taskId;
  final Color statusColor;

  const _ExpandedGoalItem({required this.taskId, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final task = taskProvider.getById(taskId);
    if (task == null) return const SizedBox.shrink();

    final colors = context.appColors;
    final isDone = task.isCompleted;

    return GestureDetector(
      onTap: () => taskProvider.toggleComplete(
        taskId,
        celebration: context.read<CelebrationProvider>(),
      ),
      child: AnimatedContainer(
        duration: 300.ms,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDone ? statusColor.withValues(alpha: 0.1) : colors.surfaceElevated.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDone ? statusColor.withValues(alpha: 0.3) : colors.border.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isDone ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill) : PhosphorIcons.circle(),
              size: 22,
              color: isDone ? statusColor : colors.textTertiary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                task.title,
                style: AppTypography.body.copyWith(
                  fontSize: 16,
                  fontWeight: isDone ? FontWeight.w600 : FontWeight.w500,
                  color: isDone ? colors.textPrimary : colors.textSecondary,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MascotBadge extends StatefulWidget {
  const _MascotBadge();

  @override
  State<_MascotBadge> createState() => _MascotBadgeState();
}

class _MascotBadgeState extends State<_MascotBadge> {
  late Sticker mascot;

  @override
  void initState() {
    super.initState();
    _pickRandomMascot();
  }

  void _pickRandomMascot() {
    final focusPacks = ['Space', 'Bees', 'Frogs', 'Bears'];
    final randomPack = focusPacks[DateTime.now().millisecond % focusPacks.length];
    final pack = StickerRegistry.packs.firstWhere((p) => p.name == randomPack);
    mascot = pack.stickers[DateTime.now().second % pack.stickers.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 30,
            spreadRadius: -5,
          ),
        ],
      ),
      child: StickerWidget(
        localSticker: mascot,
        size: 110,
        animate: true,
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
     .moveY(begin: -15, end: 15, duration: 4.seconds, curve: Curves.easeInOut);
  }
}

class _LargeControlBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final String label;

  const _LargeControlBtn({
    required this.icon,
    required this.onTap,
    required this.color,
    required this.label,
  });

  @override
  State<_LargeControlBtn> createState() => _LargeControlBtnState();
}

class _LargeControlBtnState extends State<_LargeControlBtn> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Column(
        children: [
          GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: 200.ms,
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: _isHovered ? widget.color.withValues(alpha: 0.25) : widget.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isHovered ? widget.color : widget.color.withValues(alpha: 0.4), 
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: _isHovered ? 0.3 : 0.1), 
                    blurRadius: 30, 
                    spreadRadius: _isHovered ? 10 : 2,
                  ),
                ],
              ),
              child: Icon(widget.icon, size: 36, color: widget.color),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.label.toUpperCase(),
            style: AppTypography.caption.copyWith(
              color: colors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final AppColorsExtension colors;
  final String tooltip;

  const _CircularButton({
    required this.icon,
    required this.onTap,
    required this.colors,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surfaceElevated.withValues(alpha: 0.6),
            shape: BoxShape.circle,
            border: Border.all(color: colors.border.withValues(alpha: 0.2), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10),
            ],
          ),
          child: Icon(icon, size: 22, color: colors.textPrimary),
        ),
      ),
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
