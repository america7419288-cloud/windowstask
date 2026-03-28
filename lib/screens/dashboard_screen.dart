import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/user_provider.dart';
import '../providers/settings_provider.dart';
import '../services/store_service.dart';
import '../theme/app_theme.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';
import '../models/task.dart';
import '../models/achievement.dart';
import '../data/app_stickers.dart';
import '../widgets/shared/sticker_widget.dart';
import '../widgets/shared/section_label.dart';
import '../widgets/tasks/task_card.dart';
import '../widgets/tasks/views/view_toggle_bar.dart';
import '../widgets/tasks/views/grid_view_layout.dart';
import '../widgets/tasks/views/compact_layout.dart';
import '../widgets/tasks/views/magazine_layout.dart';
import '../widgets/tasks/views/kanban_layout.dart';
import '../widgets/tasks/task_list_view.dart';
import '../models/app_settings.dart';
import 'planning_screen.dart';
import '../widgets/shared/milestone_celebration.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<UserProvider>();
    if (user.pendingMilestone != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final streak = user.pendingMilestone!;
        await MilestoneCelebration.show(context, streak);
        user.clearPendingMilestone();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left 62%
        Expanded(
          flex: 62,
          child: _DashLeft(),
        ),
        // Right 38% — fixed width
        SizedBox(
          width: 310,
          child: _DashRight(),
        ),
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// LEFT PANEL
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _DashLeft extends StatefulWidget {
  const _DashLeft();

  @override
  State<_DashLeft> createState() => _DashLeftState();
}

class _DashLeftState extends State<_DashLeft> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    context.read<TaskProvider>().createTask(
      title: trimmed,
      dueDate: DateTime.now(),
    );
    _ctrl.clear();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final nav = context.watch<NavigationProvider>();
    final tasks = context.watch<TaskProvider>();
    final user = context.watch<UserProvider>();

    final todayTasks = tasks.getTasksForNav(
      AppConstants.navToday,
      filterMITs: nav.filterMITs,
      filterHighPriority: nav.filterHighPriority,
      filterOverdue: nav.filterOverdue,
      mitIds: nav.mitTaskIds,
    );

    final totalToday = todayTasks.length;
    final completedToday = todayTasks.where((t) => t.isCompleted).length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GreetingBand(
            user: user,
            totalCount: totalToday,
            completedCount: completedToday,
            colors: colors,
          ),
          _CaptureBar(
            ctrl: _ctrl,
            focusNode: _focusNode,
            focused: _focused,
            submit: _submit,
            colors: colors,
          ),
          if (nav.mitTaskIds.isNotEmpty)
            _MITSection(nav: nav, tasks: tasks, colors: colors),

          _TodayHeader(totalCount: totalToday, nav: nav, colors: colors),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildLayout(
              nav.layoutForCurrentSection(context.watch<SettingsProvider>().currentLayout),
              todayTasks.toList(),
              nav,
            ),
          ),

          if (DateTime.now().hour < 12 && nav.mitTaskIds.isEmpty && todayTasks.isNotEmpty)
            _PlanMyDayButton(onTap: () => PlanningScreen.show(context)),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildLayout(TaskViewLayout layout, List<Task> tasks, NavigationProvider nav) {
    if (tasks.isEmpty) return const SizedBox.shrink();

    switch (layout) {
      case TaskViewLayout.list:
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tasks.length,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TaskCard(task: tasks[i], isSelected: nav.selectedTaskId == tasks[i].id),
          ),
        );
      case TaskViewLayout.grid:
        return GridViewLayout(tasks: tasks, shrinkWrap: true, physics: const NeverScrollableScrollPhysics());
      case TaskViewLayout.kanban:
        return KanbanLayout(tasks: tasks, shrinkWrap: true, physics: const NeverScrollableScrollPhysics());
      case TaskViewLayout.compact:
        return CompactLayout(tasks: tasks, shrinkWrap: true, physics: const NeverScrollableScrollPhysics());
      case TaskViewLayout.magazine:
        return MagazineLayout(tasks: tasks, shrinkWrap: true, physics: const NeverScrollableScrollPhysics());
    }
  }
}


class _GreetingBand extends StatelessWidget {
  final UserProvider user;
  final int totalCount;
  final int completedCount;
  final AppColorsExtension colors;

  const _GreetingBand({
    required this.user,
    required this.totalCount,
    required this.completedCount,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.indigo.withValues(alpha: .06),
            AppColors.indigoL.withValues(alpha: .03),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppStickerWidget(
            assetPath: AppStickers.greetingPath(
              allDone: completedCount == totalCount && totalCount > 0,
              hour: DateTime.now().hour,
            ),
            size: 64,
            animate: true,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting()}, ${user.firstName}',
                  style: AppTypography.displayLG.copyWith(color: colors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  _subtitle(totalCount, completedCount),
                  style: AppTypography.bodyMD.copyWith(color: colors.textTertiary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${DateTime.now().day}',
                style: AppTypography.displayXL.copyWith(
                  color: AppColors.indigo,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                _dayName(DateTime.now().weekday).toUpperCase(),
                style: AppTypography.micro.copyWith(
                  color: colors.textQuaternary,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _subtitle(int total, int done) {
    if (total == 0) return 'Your canvas is clear for today.';
    if (done >= total) return 'Day complete! You\'ve handled everything.';
    return 'You have $total tasks on the agenda.';
  }

  String _dayName(int weekday) {
    return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday - 1];
  }
}

class _CaptureBar extends StatelessWidget {
  final TextEditingController ctrl;
  final FocusNode focusNode;
  final bool focused;
  final Function(String) submit;
  final AppColorsExtension colors;

  const _CaptureBar({
    required this.ctrl,
    required this.focusNode,
    required this.focused,
    required this.submit,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.shadowSM(isDark: colors.isDark),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.bolt_rounded, size: 17, color: AppColors.indigo),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: ctrl,
              focusNode: focusNode,
              style: AppTypography.titleMD.copyWith(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'What\'s on your mind? Press Enter to capture...',
                hintStyle: AppTypography.bodyMD.copyWith(color: colors.textTertiary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                isDense: true,
              ),
              onSubmitted: submit,
            ),
          ),
          if (focused)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => submit(ctrl.text),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.indigoDim,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Capture',
                      style: AppTypography.labelMD.copyWith(color: AppColors.indigo)),
                ),
              ),
            )
          else
            const SizedBox(width: 12),
        ],
      ),
    );
  }
}

class _MITSection extends StatelessWidget {
  final NavigationProvider nav;
  final TaskProvider tasks;
  final AppColorsExtension colors;

  const _MITSection({required this.nav, required this.tasks, required this.colors});

  @override
  Widget build(BuildContext context) {
    final mitTasks = tasks.allTasks.where((t) => nav.mitTaskIds.contains(t.id)).toList();
    if (mitTasks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: SectionLabel(text: 'Most Important Tasks'),
        ),
        ...mitTasks.map((t) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: TaskCard(task: t, isSelected: nav.selectedTaskId == t.id),
        )),
      ],
    );
  }
}

class _TodayHeader extends StatelessWidget {
  final int totalCount;
  final NavigationProvider nav;
  final AppColorsExtension colors;

  const _TodayHeader({required this.totalCount, required this.nav, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const SectionLabel(text: 'Today\'s Priorities'),
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.indigoDim,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$totalCount',
                      style: AppTypography.micro.copyWith(color: AppColors.indigo, letterSpacing: 0)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const ViewToggleBar(),
        ],
      ),
    );


  }
}

class _PlanMyDayButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PlanMyDayButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.indigoDim,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.indigo.withValues(alpha: .15),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wb_sunny_outlined, size: 15, color: AppColors.indigo),
              const SizedBox(width: 8),
              Text('Plan my day',
                  style: AppTypography.labelMD.copyWith(
                    color: AppColors.indigo,
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// RIGHT PANEL
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _DashRight extends StatelessWidget {
  const _DashRight();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 20, 20, 20),
      child: Column(
        children: [
          const _MomentumCard(),
          const SizedBox(height: 12),
          const _UpcomingCard(),
          const SizedBox(height: 12),
          const _AchievementsCard(),
          const SizedBox(height: 12),
          const _QuickStatsCard(),
        ],
      ),
    );
  }
}

class _MomentumCard extends StatelessWidget {
  const _MomentumCard();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final tasks = context.watch<TaskProvider>();
    
    final todayTasks = tasks.allTasks.where((t) => 
      !t.isDeleted && t.dueDate != null && AppDateUtils.isToday(t.dueDate!)
    ).toList();
    final totalCount = todayTasks.length;
    final completedCount = todayTasks.where((t) => t.isCompleted).length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.gradMomentum,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.shadowPrimary(),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('Daily Momentum',
                  style: AppTypography.titleMD.copyWith(
                    color: Colors.white.withValues(alpha: .85),
                    fontWeight: FontWeight.w700,
                  )),
              const Spacer(),
              AppStickerWidget(
                assetPath: progress >= 1.0
                    ? AppStickers.celebrationPath
                    : AppStickers.greetingMorningPath,
                size: 30,
                animate: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: v,
                        strokeWidth: 6,
                        strokeCap: StrokeCap.round,
                        color: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: .15),
                      ),
                      Text('${(v * 100).round()}%',
                          style: AppTypography.labelLG.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$completedCount / $totalCount',
                      style: AppTypography.displayLG.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      )),
                  Text('Tasks Completed',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: .6),
                      )),
                  const SizedBox(height: 10),
                  Text('${user.streak} Days 🔥',
                      style: AppTypography.titleSM.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      )),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(7, (i) {
              final day = DateTime.now().subtract(Duration(days: 6 - i));
              final isToday = i == 6;
              final hasActivity = tasks.allTasks.any((t) => 
                t.isCompleted && t.completedAt != null && AppDateUtils.isSameDay(t.completedAt!, day)
              );
              return Expanded(
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isToday ? 10 : 7,
                    height: isToday ? 10 : 7,
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppColors.gold
                          : hasActivity
                              ? Colors.white
                              : Colors.white.withValues(alpha: .15),
                      shape: BoxShape.circle,
                      boxShadow: isToday ? AppColors.shadowGold() : [],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final nav = context.watch<NavigationProvider>();
    final upcomingTasks = context.watch<TaskProvider>().getTasksForNav(AppConstants.navUpcoming);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.shadowSM(isDark: colors.isDark),
      ),
      child: Column(
        children: [
          const SectionLabel(text: 'Upcoming'),
          const SizedBox(height: 12),
          if (upcomingTasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No upcoming tasks this week',
                  style: AppTypography.caption.copyWith(color: colors.textTertiary)),
            )
          else
            ...upcomingTasks.take(3).map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.indigo,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (t.stickerId != null) ...[
                        AppStickerWidget(
                          serverSticker: StoreService.instance.data?.stickerById(t.stickerId!),
                          size: 22,
                          animate: false,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_dateLabel(t.dueDate!),
                                style: AppTypography.caption.copyWith(
                                  color: colors.textQuaternary,
                                  letterSpacing: 0.5,
                                  fontWeight: FontWeight.w700,
                                )),
                            Text(t.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.titleSM.copyWith(
                                  color: colors.textPrimary,
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          GestureDetector(
            onTap: () => nav.selectNav('calendar'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: colors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text('Open Calendar →',
                    style: AppTypography.labelMD.copyWith(color: colors.textSecondary)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime date) {
    if (AppDateUtils.isToday(date)) return 'Today';
    if (AppDateUtils.isTomorrow(date)) return 'Tomorrow';
    return AppDateUtils.formatDate(date);
  }
}

class _AchievementsCard extends StatelessWidget {
  const _AchievementsCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final user = context.watch<UserProvider>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.shadowSM(isDark: colors.isDark),
      ),
      child: Column(
        children: [
          const SectionLabel(text: 'Achievements'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: Achievements.all.take(6).map((a) {
              final earned = user.profile?.earnedBadgeIds.contains(a.id) ?? false;
              return AnimatedOpacity(
                opacity: earned ? 1.0 : 0.35,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: earned ? AppColors.indigoDim : colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(earned ? a.emoji : '🔒', style: const TextStyle(fontSize: 11)),
                      const SizedBox(width: 5),
                      Text(a.name.toUpperCase(),
                          style: AppTypography.micro.copyWith(
                            color: earned ? AppColors.indigo : colors.textQuaternary,
                            letterSpacing: 0.5,
                          )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _QuickStatsCard extends StatelessWidget {
  const _QuickStatsCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final user = context.watch<UserProvider>();

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.shadowSM(isDark: colors.isDark),
      ),
      child: Row(
        children: [
          _QuickStat(
            icon: '⚡',
            value: _formatXP(user.totalXP),
            label: 'Total XP',
            colors: colors,
          ),
          _StatDivider(colors: colors),
          _QuickStat(
            icon: '🔥',
            value: '${user.profile?.longestStreak ?? 0}d',
            label: 'Best Streak',
            colors: colors,
          ),
          _StatDivider(colors: colors),
          _QuickStat(
            icon: '🏅',
            value: '${user.profile?.earnedBadgeIds.length ?? 0}',
            label: 'Badges',
            colors: colors,
          ),
        ],
      ),
    );
  }

  String _formatXP(int xp) {
    if (xp >= 1000) return '${(xp / 1000).toStringAsFixed(1)}k';
    return '$xp';
  }
}

class _QuickStat extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final AppColorsExtension colors;

  const _QuickStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 5),
            Text(value,
                style: AppTypography.headlineSM.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                )),
            Text(label, style: AppTypography.caption.copyWith(color: colors.textTertiary)),
          ],
        ),
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  final AppColorsExtension colors;
  const _StatDivider({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: colors.divider,
    );
  }
}
