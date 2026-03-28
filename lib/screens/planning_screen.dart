import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/user_provider.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/app_theme.dart';
import '../models/task.dart';
import '../data/app_stickers.dart';
import '../widgets/shared/deco_sticker.dart';
import '../widgets/shared/priority_badge.dart';

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const PlanningScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  int _step = 0;
  final List<String> _skippedYesterdayIds = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NavigationProvider>().enterPlanningMode();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final user = context.watch<UserProvider>();
    final nav = context.watch<NavigationProvider>();
    final taskProvider = context.watch<TaskProvider>();

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Row(
                children: [
                  Text(
                    'Daily Planning',
                    style: AppTypography.labelLarge.copyWith(
                      color: colors.textTertiary,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  // Counter for MIT pick step
                  if (_step == 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.xpGold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${nav.mitTaskIds.length}/5 chosen',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.xpGold,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _buildStepContent(context, user, nav, taskProvider),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
              child: Column(
                children: [
                  // Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _step == i ? 24 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: _step == i ? AppColors.primary : colors.textQuaternary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  ),
                  const SizedBox(height: 32),
                  // Buttons
                  Row(
                    children: [
                      if (_step > 0)
                        _SecondaryBtn(
                          label: 'Back',
                          onTap: () => setState(() => _step--),
                        ),
                      const Spacer(),
                      _PrimaryBtn(
                        label: _step == 2 ? 'Start your day →' : 'Next →',
                        onTap: () {
                          if (_step < 2) {
                            setState(() => _step++);
                          } else {
                            nav.exitPlanningMode();
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(BuildContext context, UserProvider user, NavigationProvider nav, TaskProvider taskProvider) {
    switch (_step) {
      case 0:
        return _ReviewStep(
          user: user,
          tasks: taskProvider,
          skippedIds: _skippedYesterdayIds,
          onTaskAction: () => setState(() {}),
          onAutoAdvance: () => setState(() => _step = 1),
        );
      case 1:
        return _PriorityStep(nav: nav, tasks: taskProvider);
      case 2:
        return _SummaryStep(user: user, nav: nav, tasks: taskProvider);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 1 — REVIEW YESTERDAY
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewStep extends StatelessWidget {
  final UserProvider user;
  final TaskProvider tasks;
  final List<String> skippedIds;
  final VoidCallback onTaskAction;
  final VoidCallback onAutoAdvance;

  const _ReviewStep({
    required this.user,
    required this.tasks,
    required this.skippedIds,
    required this.onTaskAction,
    required this.onAutoAdvance,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
    
    final yesterdayTasks = tasks.allTasks.where((t) {
      if (t.isDeleted || t.isCompleted || t.dueDate == null) return false;
      final d = t.dueDate!;
      final taskDay = DateTime(d.year, d.month, d.day);
      return taskDay.isBefore(DateTime(now.year, now.month, now.day)) && !skippedIds.contains(t.id);
    }).toList();

    if (yesterdayTasks.isEmpty) {
      Future.delayed(const Duration(seconds: 2), onAutoAdvance);
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DecoSticker(sticker: AppStickers.celebration, size: 100, animate: true),
            const SizedBox(height: 24),
            Text('Yesterday was clean ✨', style: AppTypography.displayMedium.copyWith(color: colors.textPrimary)),
            const SizedBox(height: 8),
            Text('Nothing to carry over.', style: AppTypography.bodyLarge.copyWith(color: colors.textSecondary)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const DecoSticker(sticker: AppStickers.todayMorning, size: 80, animate: true),
          const SizedBox(height: 24),
          Text('Good morning, ${user.firstName}', style: AppTypography.displayMedium.copyWith(color: colors.textPrimary)),
          const SizedBox(height: 8),
          Text("Let's review what's left from yesterday", style: AppTypography.bodyLarge.copyWith(color: colors.textSecondary)),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: yesterdayTasks.length,
              itemBuilder: (context, index) {
                final t = yesterdayTasks[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(t.title, style: AppTypography.titleMedium.copyWith(color: colors.textPrimary)),
                      ),
                      const SizedBox(width: 12),
                      _ActionBtn(
                        label: 'Skip',
                        icon: Icons.close_rounded,
                        onTap: () {
                          skippedIds.add(t.id);
                          onTaskAction();
                        },
                      ),
                      const SizedBox(width: 8),
                      _ActionBtn(
                        label: 'Today',
                        icon: Icons.today_rounded,
                        isPrimary: true,
                        onTap: () {
                          tasks.updateDueDate(t.id, DateTime.now());
                          onTaskAction();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 2 — PICK PRIORITIES
// ─────────────────────────────────────────────────────────────────────────────

class _PriorityStep extends StatelessWidget {
  final NavigationProvider nav;
  final TaskProvider tasks;

  const _PriorityStep({required this.nav, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final todayTasks = tasks.allTasks.where((t) {
      if (t.isDeleted || t.isCompleted || t.dueDate == null) return false;
      final d = t.dueDate!;
      final taskDay = DateTime(d.year, d.month, d.day);
      return taskDay == today;
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Text('Pick your priorities', style: AppTypography.displayMedium.copyWith(color: colors.textPrimary)),
          const SizedBox(height: 8),
          Text('Select up to 5 tasks as your Most Important Tasks', style: AppTypography.bodyLarge.copyWith(color: colors.textSecondary)),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: todayTasks.length,
              itemBuilder: (context, index) {
                final t = todayTasks[index];
                final isMIT = nav.isMIT(t.id);
                final limitReached = nav.mitTaskIds.length >= 5 && !isMIT;

                return Opacity(
                  opacity: limitReached ? 0.4 : 1.0,
                  child: GestureDetector(
                    onTap: limitReached ? null : () => nav.toggleMIT(t.id),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isMIT ? AppColors.xpGold.withValues(alpha: 0.08) : colors.surfaceElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: isMIT ? Border.all(color: AppColors.xpGold.withValues(alpha: 0.3)) : null,
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: isMIT ? AppColors.xpGold.withValues(alpha: 0.15) : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isMIT ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 18,
                              color: isMIT ? AppColors.xpGold : colors.textTertiary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(t.title, style: AppTypography.titleMedium.copyWith(color: colors.textPrimary)),
                          ),
                          const SizedBox(width: 12),
                          PriorityBadge(priority: t.priority),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 3 — SUMMARY
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryStep extends StatelessWidget {
  final UserProvider user;
  final NavigationProvider nav;
  final TaskProvider tasks;

  const _SummaryStep({required this.user, required this.nav, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final mitTasks = nav.mitTaskIds.map((id) => tasks.getById(id)).whereType<Task>().toList();
    final highCount = mitTasks.where((t) => t.priority == Priority.high || t.priority == Priority.urgent).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const DecoSticker(sticker: AppStickers.celebration, size: 100, animate: true),
          const SizedBox(height: 24),
          Text("You're all set, ${user.firstName}!", style: AppTypography.displayMedium.copyWith(color: colors.textPrimary)),
          const SizedBox(height: 8),
          Text('${mitTasks.length} tasks planned · $highCount high priority', style: AppTypography.bodyLarge.copyWith(color: colors.textSecondary)),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: mitTasks.length,
              itemBuilder: (context, index) {
                final t = mitTasks[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, color: AppColors.xpGold, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(t.title, style: AppTypography.titleMedium.copyWith(color: colors.textPrimary)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
        child: Text(label, style: AppTypography.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _SecondaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SecondaryBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Text(label, style: AppTypography.labelLarge.copyWith(color: colors.textTertiary, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary.withValues(alpha: 0.1) : colors.textQuaternary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isPrimary ? AppColors.primary : colors.textSecondary),
            const SizedBox(width: 4),
            Text(label, style: AppTypography.micro.copyWith(color: isPrimary ? AppColors.primary : colors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
