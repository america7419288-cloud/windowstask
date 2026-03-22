import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/user_provider.dart';
import '../providers/celebration_provider.dart';
import '../services/store_service.dart';
import '../theme/app_theme.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';
import '../models/task.dart';
import '../models/achievement.dart';
import '../models/sticker.dart';
import '../data/sticker_packs.dart';
import '../data/app_stickers.dart';
import '../widgets/shared/sticker_widget.dart';
import '../widgets/shared/deco_sticker.dart';
import '../widgets/tasks/task_card.dart';
import '../models/app_settings.dart';
import '../providers/settings_provider.dart';
import '../widgets/tasks/views/view_toggle_bar.dart';
import '../widgets/tasks/views/grid_view_layout.dart';
import '../widgets/tasks/views/magazine_layout.dart';
import '../widgets/tasks/views/kanban_layout.dart';
import '../widgets/tasks/views/compact_layout.dart';
import 'planning_screen.dart';
import '../widgets/shared/milestone_celebration.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left — 60%
        const Expanded(
          flex: 6,
          child: _DashboardLeft(),
        ),
        // Right — 40%
        const SizedBox(
          width: 340,
          child: _DashboardRight(),
        ),
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// LEFT PANEL
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _DashboardLeft extends StatefulWidget {
  const _DashboardLeft();

  @override
  State<_DashboardLeft> createState() => _DashboardLeftState();
}

class _DashboardLeftState extends State<_DashboardLeft> {
  final _ctrl = TextEditingController();
  bool _focused = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<UserProvider>();
    
    // Check for pending milestone
    if (user.pendingMilestone != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final streak = user.pendingMilestone!;
        await MilestoneCelebration.show(context, streak);
        user.clearPendingMilestone();
        // Award XP (if not already awarded by earnBadge)
        // Note: earnBadge already awards XP for 7 and 30 day milestones.
        // For others (3, 14, 60, 100), we can add here if they don't have badges.
        if (const {3, 14, 60, 100}.contains(streak)) {
          await user.addXP(streak * 10, reason: '$streak-day streak milestone');
        }
      });
    }

    // Check for shield used
    if (user.pendingShieldUsed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Text('Streak Shield used! Your momentum is preserved.'),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
        user.clearPendingShieldUsed();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final now = DateTime.now();
    context.read<TaskProvider>().createTask(
      title: trimmed,
      dueDate: DateTime(now.year, now.month, now.day),
    );
    _ctrl.clear();
    setState(() => _focused = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final navItem = context.select<NavigationProvider, String>((n) => n.selectedNavItem);
    final hasMITs = context.select<NavigationProvider, bool>((n) => n.mitTaskIds.isNotEmpty);
    final showPlanning = context.select<NavigationProvider, bool>((n) => n.shouldShowPlanningPrompt);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // 1. Greeting header
        const _DashboardGreeting(),

        // 2. Quick capture bar
        _DashboardQuickCapture(colors: colors),

        const SizedBox(height: 12),

        // MIT Section
        if (hasMITs)
          const _MITSection(),

        // 3. Today's Priorities header
        const _DashboardTaskListHeader(),

        // 4. Task list
        const _DashboardTasksContent(),

        // Empty state
        Selector2<NavigationProvider, TaskProvider, bool>(
          selector: (context, nav, tasks) => tasks.getTasksForNav(
            AppConstants.navToday,
            filterMITs: nav.filterMITs,
            filterHighPriority: nav.filterHighPriority,
            filterOverdue: nav.filterOverdue,
            mitIds: nav.mitTaskIds,
          ).isEmpty,
          builder: (context, isEmpty, _) {
            if (!isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.fromLTRB(32, 40, 32, 0),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 48,
                    color: colors.textTertiary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Nothing scheduled for today',
                    style: AppTypography.bodyLarge.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Use the capture bar above to add a task',
                    style: AppTypography.caption.copyWith(
                      color: colors.textQuaternary,
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}

class _DashboardTasksContent extends StatelessWidget {
  const _DashboardTasksContent();

  @override
  Widget build(BuildContext context) {
    return Selector2<NavigationProvider, TaskProvider, Map<String, dynamic>>(
      selector: (context, nav, tasks) {
        final list = tasks.getTasksForNav(
          AppConstants.navToday,
          filterMITs: nav.filterMITs,
          filterHighPriority: nav.filterHighPriority,
          filterOverdue: nav.filterOverdue,
          mitIds: nav.mitTaskIds,
        );
        final layout = nav.layoutForCurrentSection(context.read<SettingsProvider>().currentLayout);
        final selectedId = nav.selectedTaskId;
        return {
          'tasks': list,
          'layout': layout,
          'selectedTaskId': selectedId,
        };
      },
      builder: (context, data, _) {
        final todayTasks = data['tasks'] as List<Task>;
        final layout = data['layout'] as TaskViewLayout;
        final selectedTaskId = data['selectedTaskId'] as String?;

        if (todayTasks.isEmpty) return const SizedBox.shrink();
        
        switch (layout) {
          case TaskViewLayout.list:
            return Column(
              children: todayTasks.map((task) => TaskCard(
                key: ValueKey(task.id),
                task: task,
                isSelected: selectedTaskId == task.id,
              )).toList(),
            );
          case TaskViewLayout.grid:
            return GridViewLayout(tasks: todayTasks, shrinkWrap: true, physics: const NeverScrollableScrollPhysics());
          case TaskViewLayout.kanban:
            return KanbanLayout(tasks: todayTasks, shrinkWrap: true, physics: const NeverScrollableScrollPhysics());
          case TaskViewLayout.compact:
            return CompactLayout(tasks: todayTasks, shrinkWrap: true, physics: const NeverScrollableScrollPhysics());
          case TaskViewLayout.magazine:
            return MagazineLayout(tasks: todayTasks, shrinkWrap: true, physics: const NeverScrollableScrollPhysics());
        }
      },
    );
  }
}

class _DashboardGreeting extends StatelessWidget {
  const _DashboardGreeting();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final now = DateTime.now();
    return Selector3<UserProvider, TaskProvider, NavigationProvider, Map<String, dynamic>>(
      selector: (context, user, tasks, nav) {
        final todayTasks = tasks.getTasksForNav(AppConstants.navToday, mitIds: nav.mitTaskIds);
        final taskCount = todayTasks.where((t) => !t.isCompleted).length;
        final completedCount = tasks.completedToday;
        return {
          'firstName': user.firstName,
          'taskCount': taskCount,
          'completedCount': completedCount,
          'showPlanning': nav.shouldShowPlanningPrompt,
        };
      },
      builder: (context, data, _) {
        final firstName = data['firstName'];
        final taskCount = data['taskCount'];
        final completedCount = data['completedCount'];
        final showPlanning = data['showPlanning'];
        
        return Container(
          padding: const EdgeInsets.fromLTRB(32, 28, 24, 16),
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  DecoSticker(
                    sticker: AppStickers.todayHeaderSticker(
                      allDone: completedCount == taskCount && taskCount > 0,
                    ),
                    size: 48,
                    animate: true,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_greeting()}, $firstName',
                          style: AppTypography.displayLarge.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _subtitle(taskCount, completedCount),
                          style: AppTypography.bodyLarge.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        if (showPlanning)
                          GestureDetector(
                            onTap: () => PlanningScreen.show(context),
                            child: Container(
                              margin: const EdgeInsets.only(top: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.xpGold.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.sunny_snowing, size: 14, color: AppColors.xpGold),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Plan my day',
                                    style: AppTypography.labelMedium.copyWith(
                                      color: AppColors.xpGold,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.xpGold),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  _DateDisplay(now: now),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _subtitle(int total, int done) {
    if (total == 0) return 'Nothing scheduled — enjoy your day.';
    if (done >= total && total > 0) return 'All $total tasks done! You crushed it.';
    return 'You have $total tasks to complete today. Stay focused.';
  }
}

class _DateDisplay extends StatelessWidget {
  final DateTime now;
  const _DateDisplay({required this.now});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${now.day}',
          style: AppTypography.displayMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          _dayName(now.weekday).toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: context.appColors.textTertiary,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  String _dayName(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[weekday - 1];
  }
}

class _DashboardQuickCapture extends StatefulWidget {
  final AppColorsExtension colors;
  const _DashboardQuickCapture({required this.colors});

  @override
  State<_DashboardQuickCapture> createState() => _DashboardQuickCaptureState();
}

class _DashboardQuickCaptureState extends State<_DashboardQuickCapture> {
  final _ctrl = TextEditingController();
  bool _focused = false;

  void _submit(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    context.read<TaskProvider>().createTask(
      title: trimmed,
      dueDate: DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0),
    );
    _ctrl.clear();
    setState(() => _focused = false);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: Container(
        margin: const EdgeInsets.fromLTRB(32, 0, 24, 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppColors.ambientShadow(
            opacity: 0.04, blur: 20, offset: const Offset(0, 4),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.bolt_rounded, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _ctrl,
                style: AppTypography.bodyMedium.copyWith(color: widget.colors.textPrimary),
                decoration: InputDecoration(
                  hintText: "What's on your mind? Press Enter to quick capture...",
                  hintStyle: AppTypography.bodyMedium.copyWith(color: widget.colors.textTertiary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                onSubmitted: _submit,
              ),
            ),
            if (_focused)
              GestureDetector(
                onTap: () => _submit(_ctrl.text),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Capture', style: AppTypography.labelMedium.copyWith(color: widget.colors.textPrimary)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DashboardTaskListHeader extends StatelessWidget {
  const _DashboardTaskListHeader();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 8, 24, 8),
      child: Row(
        children: [
          Text("Today's Priorities", style: AppTypography.headlineSmall.copyWith(color: colors.textPrimary)),
          const SizedBox(width: 10),
          Selector2<NavigationProvider, TaskProvider, int>(
            selector: (context, nav, tasks) => tasks.getTasksForNav(
              AppConstants.navToday,
              filterMITs: nav.filterMITs,
              filterHighPriority: nav.filterHighPriority,
              filterOverdue: nav.filterOverdue,
              mitIds: nav.mitTaskIds,
            ).where((t) => !t.isCompleted).length,
            builder: (context, count, _) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$count', style: AppTypography.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.read<NavigationProvider>().selectNav(AppConstants.navAll),
            child: Text('View All →', style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
          ),
          const SizedBox(width: 16),
          const ViewToggleBar(),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// RIGHT PANEL
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _DashboardRight extends StatelessWidget {
  const _DashboardRight();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final nav = context.read<NavigationProvider>();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // 1. Daily Momentum card
        const _DashboardMomentumCard(),

        // 2. Upcoming Planning
        const _DashboardUpcomingSection(),

        // 3. Achievement badges
        const _DashboardBadges(),

        const SizedBox(height: 32),
      ],
    );
  }
}

class _DashboardMomentumCard extends StatelessWidget {
  const _DashboardMomentumCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Selector2<UserProvider, TaskProvider, Map<String, dynamic>>(
      selector: (context, user, tasks) {
        final allTodayTasks = tasks.allTasks.where((t) =>
            !t.isDeleted && t.dueDate != null && AppDateUtils.isToday(t.dueDate!)
        ).toList();
        final totalCount = allTodayTasks.length;
        final completedCount = allTodayTasks.where((t) => t.isCompleted).length;
        final progress = totalCount > 0 ? completedCount / totalCount : 0.0;
        
        return {
          'streak': user.streak,
          'streakShields': user.streakShields,
          'progress': progress,
          'completedCount': completedCount,
          'totalCount': totalCount,
        };
      },
      builder: (context, data, _) {
        final streak = data['streak'];
        final streakShields = data['streakShields'];
        final progress = data['progress'];
        final completedCount = data['completedCount'];
        final totalCount = data['totalCount'];

        return Container(
          margin: const EdgeInsets.fromLTRB(0, 28, 24, 16),
          decoration: BoxDecoration(
            gradient: AppColors.gradientMomentum,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.ambientShadow(
              opacity: 0.15, blur: 30, offset: const Offset(0, 10),
            ),
          ),
          child: InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (_) => const _StreakDetailSheet(),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Momentum',
                            style: AppTypography.titleMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (streakShields > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.shield_rounded, size: 12, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  '$streakShields Shields active',
                                  style: AppTypography.micro.copyWith(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      DecoSticker(
                        sticker: streak >= 7 ? AppStickers.celebration : AppStickers.todayAfternoon,
                        size: 32,
                        animate: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      SizedBox(
                        width: 84,
                        height: 84,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: (progress as double).clamp(0.0, 1.0)),
                          duration: const Duration(milliseconds: 1200),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox.expand(
                                  child: CircularProgressIndicator(
                                    value: value,
                                    strokeWidth: 8,
                                    strokeCap: StrokeCap.round,
                                    color: Colors.white,
                                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    child: Text(
                                      '${(value * 100).round()}%',
                                      style: AppTypography.titleMedium.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$completedCount / $totalCount',
                              style: AppTypography.headlineSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Tasks Completed',
                              style: AppTypography.caption.copyWith(color: Colors.white.withValues(alpha: 0.7)),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'CURRENT STREAK',
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.6),
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  '$streak Days 🔥',
                                  style: AppTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                                ),
                                const Spacer(),
                                DecoSticker(sticker: AppStickers.celebration, size: 36, animate: (streak as int) > 0),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DashboardUpcomingSection extends StatelessWidget {
  const _DashboardUpcomingSection();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Selector<TaskProvider, List<Task>>(
      selector: (context, tasks) => tasks.getTasksForNav(AppConstants.navUpcoming),
      builder: (context, upcomingTasks, _) => Container(
        margin: const EdgeInsets.fromLTRB(0, 0, 24, 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.ambientShadow(opacity: 0.04, blur: 20, offset: const Offset(0, 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('UPCOMING PLANNING', style: AppTypography.labelSmall.copyWith(color: colors.textTertiary, letterSpacing: 2)),
            const SizedBox(height: 16),
            ...upcomingTasks.take(3).map((task) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    width: 3, height: 42,
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 12),
                  if (task.stickerId != null && task.stickerId!.isNotEmpty) ...[
                    _InlineSticker(stickerId: task.stickerId!),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.dueDate != null ? AppDateUtils.formatDate(task.dueDate!).toUpperCase() : 'NO DATE',
                          style: AppTypography.labelSmall.copyWith(color: colors.textTertiary, letterSpacing: 1),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          task.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleSmall.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
            if (upcomingTasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('No upcoming tasks this week', style: AppTypography.caption.copyWith(color: colors.textTertiary)),
              ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => context.read<NavigationProvider>().selectNav(AppConstants.navUpcoming),
              child: Container(
                width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: colors.surfaceElevated, borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text('Open Calendar →', style: AppTypography.labelMedium.copyWith(color: colors.textSecondary))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardBadges extends StatelessWidget {
  const _DashboardBadges();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Selector<UserProvider, List<String>>(
      selector: (context, user) => user.profile?.earnedBadgeIds ?? [],
      builder: (context, badgeIds, _) {
        if (badgeIds.isEmpty) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.fromLTRB(0, 0, 24, 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.ambientShadow(opacity: 0.04, blur: 20, offset: const Offset(0, 4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ACHIEVEMENTS', style: AppTypography.labelSmall.copyWith(color: colors.textTertiary, letterSpacing: 2)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: badgeIds.map((id) {
                  final badge = Achievements.findById(id);
                  if (badge == null) return const SizedBox.shrink();
                  final isGold = badge.tier == AchievementTier.gold;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: isGold ? AppColors.gradientSuccess : null,
                      color: isGold ? null : AppColors.tertiaryContainer.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(badge.emoji, style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 5),
                        Text(
                          badge.name.toUpperCase(),
                          style: AppTypography.micro.copyWith(
                            color: isGold ? AppColors.onTertiary : AppColors.tertiary,
                            fontWeight: FontWeight.w700, letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

  Widget _buildMomentumCard(
    BuildContext context,
    AppColorsExtension colors,
    UserProvider user,
    double progress,
    int completedCount,
    int totalCount,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 28, 24, 16),
      decoration: BoxDecoration(
        gradient: AppColors.gradientMomentum,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.ambientShadow(
          opacity: 0.15,
          blur: 30,
          offset: const Offset(0, 10),
        ),
      ),
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) => const _StreakDetailSheet(),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Momentum',
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (user.streakShields > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.shield_rounded, size: 12, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(
                              '${user.streakShields} Shields active',
                              style: AppTypography.micro.copyWith(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
              DecoSticker(
                sticker: user.streak >= 7
                    ? AppStickers.celebration
                    : AppStickers.todayAfternoon,
                size: 32,
                animate: true,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Progress ring + stats
          Row(
            children: [
              // Ring
              SizedBox(
                width: 84,
                height: 84,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: progress.clamp(0.0, 1.0)),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: value,
                            strokeWidth: 8,
                            strokeCap: StrokeCap.round,
                            color: Colors.white,
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: Text(
                              '${(value * 100).round()}%',
                              style: AppTypography.titleMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 20),

              // Stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$completedCount / $totalCount',
                      style: AppTypography.headlineSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Tasks Completed',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'CURRENT STREAK',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '${user.streak} Days 🔥',
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        DecoSticker(
                          sticker: AppStickers.celebration,
                          size: 36,
                          animate: user.streak > 0,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ]),
      ),
    ),
    );}


class _MITSection extends StatelessWidget {
  const _MITSection();

  @override
  Widget build(BuildContext context) {
    final nav = context.read<NavigationProvider>();
    return Selector<TaskProvider, List<Task>>(
      selector: (context, tasks) => nav.mitTaskIds
          .map((id) => tasks.getById(id))
          .whereType<Task>()
          .where((t) => !t.isCompleted)
          .toList(),
      builder: (context, mitTasks, _) {
        if (mitTasks.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: AppColors.xpGold),
                    const SizedBox(width: 8),
                    Text(
                      'TOP PRIORITIES',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.xpGold,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.xpGold.withValues(alpha: 0.4),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // MIT task cards
              ...mitTasks.map((t) => TaskCard(
                key: ValueKey(t.id),
                task: t,
                isSelected: nav.selectedTaskId == t.id,
              )),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _StreakDetailSheet extends StatelessWidget {
  const _StreakDetailSheet();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final user = context.watch<UserProvider>();
    final streak = user.streak;
    final longest = user.profile?.longestStreak ?? 0;
    
    // Find next milestone
    final milestones = [3, 7, 14, 30, 60, 100];
    final nextMilestone = milestones.firstWhere((m) => m > streak, orElse: () => 0);
    final progressToNext = nextMilestone > 0 ? streak / nextMilestone : 1.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textQuaternary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Header
          Row(
            children: [
              const DecoSticker(sticker: AppStickers.celebration, size: 60, animate: true),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Streak',
                    style: AppTypography.headlineSmall.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Building habits, one day at a time',
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Stats Grid
          Row(
            children: [
              _StatCard(
                label: 'CURRENT',
                value: '$streak',
                unit: 'Days',
                icon: Icons.local_fire_department_rounded,
                color: AppColors.priorityHigh,
              ),
              const SizedBox(width: 16),
              _StatCard(
                label: 'LONGEST',
                value: '$longest',
                unit: 'Days',
                icon: Icons.emoji_events_rounded,
                color: AppColors.xpGold,
              ),
              const SizedBox(width: 16),
              _StatCard(
                label: 'SHIELDS',
                value: '${user.streakShields}',
                unit: 'Active',
                icon: Icons.shield_rounded,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Next Milestone
          if (nextMilestone > 0) ...[
            Text(
              'NEXT MILESTONE',
              style: AppTypography.labelSmall.copyWith(
                color: colors.textTertiary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$streak / $nextMilestone days',
                        style: AppTypography.titleMedium.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${nextMilestone - streak} more to go!',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.xpGold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progressToNext,
                      minHeight: 8,
                      backgroundColor: colors.textQuaternary.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation(AppColors.xpGold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],

          // Shield Explanation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 20, color: AppColors.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Shields protect your streak if you miss a day. Earn more at 7 and 30 day milestones!',
                    style: AppTypography.caption.copyWith(color: colors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: AppTypography.headlineSmall.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              unit,
              style: AppTypography.micro.copyWith(
                color: colors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineSticker extends StatelessWidget {
  final String stickerId;
  const _InlineSticker({required this.stickerId});

  @override
  Widget build(BuildContext context) {
    return Consumer<StoreService>(
      builder: (context, store, _) {
        final serverSticker = store.data?.stickerById(stickerId);
        final localSticker = StickerRegistry.findById(stickerId);
        
        if (serverSticker == null && localSticker == null) {
          return const SizedBox.shrink();
        }
        
        return StickerWidget(
          serverSticker: serverSticker,
          localSticker: localSticker,
          size: 24,
          animate: true,
        );
      },
    );
  }
}

