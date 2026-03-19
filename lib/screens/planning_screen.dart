import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../providers/navigation_provider.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../data/app_stickers.dart';
import '../widgets/shared/deco_sticker.dart';
import '../models/task.dart';
import '../models/sticker.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  int _currentStep = 1;
  final Set<String> _movedTaskIds = {};

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Frosted background
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: (colors.isDark ? Colors.black : Colors.white).withValues(alpha: 0.8),
              ),
            ),
          ),

          // Progress indicator dots
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final isActive = _currentStep == i + 1;
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? AppColors.primary : colors.textQuaternary,
                  ),
                );
              }),
            ),
          ),

          // Content
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildCurrentStep(),
            ),
          ),

          // Bottom Navigation
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1:
        return _StepYesterday(
          onToggleMove: (id) => setState(() {
            if (_movedTaskIds.contains(id)) {
              _movedTaskIds.remove(id);
            } else {
              _movedTaskIds.add(id);
            }
          }),
          movedTaskIds: _movedTaskIds,
        );
      case 2:
        return _StepMIT(movedTaskIds: _movedTaskIds);
      case 3:
        return _StepFinished(movedTaskIds: _movedTaskIds);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomNav() {
    if (_currentStep == 3) return const SizedBox.shrink();
    
    final colors = context.appColors;
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Center(
        child: SizedBox(
          width: 400,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentStep > 1)
                TextButton(
                  onPressed: () => setState(() => _currentStep--),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                  child: Text('← Back', style: AppTypography.body.copyWith(color: colors.textSecondary)),
                )
              else
                const SizedBox(width: 80),
              
              ElevatedButton(
                onPressed: () => setState(() => _currentStep++),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Row(
                  children: [
                    Text('Next', style: AppTypography.body.copyWith(fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(width: 8),
                    const Icon(PhosphorIconsStyle.bold == PhosphorIconsStyle.bold ? Icons.arrow_forward_rounded : Icons.arrow_forward_rounded, size: 16),
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

class _StepYesterday extends StatelessWidget {
  final Function(String) onToggleMove;
  final Set<String> movedTaskIds;

  const _StepYesterday({required this.onToggleMove, required this.movedTaskIds});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tasks = context.watch<TaskProvider>().allTasks.where((t) {
      if (t.isCompleted || t.isDeleted || t.dueDate == null) return false;
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      return AppDateUtils.isSameDay(t.dueDate!, yesterday);
    }).toList();

    return _WizardPage(
      sticker: AppStickers.todayMorning,
      title: "Let's review yesterday",
      subtitle: "Finish what you started or move it to today.",
      child: tasks.isEmpty
          ? Center(child: Text('All clear from yesterday!', style: AppTypography.body.copyWith(color: colors.textTertiary)))
          : ListView.separated(
              shrinkWrap: true,
              itemCount: tasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final t = tasks[i];
                final isMoved = movedTaskIds.contains(t.id);
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isMoved ? AppColors.primary : colors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(t.title, style: AppTypography.body.copyWith(color: colors.textPrimary)),
                      ),
                      const SizedBox(width: 12),
                      _ActionButton(
                        label: isMoved ? 'Moved' : 'Skip',
                        icon: isMoved ? Icons.today_rounded : Icons.redo_rounded,
                        isActive: isMoved,
                        onTap: () => onToggleMove(t.id),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _StepMIT extends StatelessWidget {
  final Set<String> movedTaskIds;
  const _StepMIT({required this.movedTaskIds});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final nav = context.watch<NavigationProvider>();
    final taskProvider = context.watch<TaskProvider>();
    
    final todayTasks = taskProvider.getTasksForNav(AppConstants.navToday)
        .where((t) => !t.isCompleted).toList();
    
    // Add any tasks moved from yesterday (if they aren't already today)
    final movedTasks = movedTaskIds
        .map((id) => taskProvider.getById(id))
        .whereType<Task>()
        .where((t) => !AppDateUtils.isToday(t.dueDate!)) 
        .toList();

    final allItems = [...todayTasks, ...movedTasks];

    return _WizardPage(
      sticker: AppStickers.todayAfternoon,
      title: "Pick your top priorities",
      subtitle: "Choose up to 5 tasks to focus on today.",
      headerExtra: Text(
        '${nav.mitTaskIds.length}/5 chosen',
        style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: allItems.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final t = allItems[i];
          final isMIT = nav.isMIT(t.id);
          return GestureDetector(
            onTap: () => nav.toggleMIT(t.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMIT ? AppColors.primary.withValues(alpha: 0.1) : colors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isMIT ? AppColors.primary : colors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    isMIT ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isMIT ? const Color(0xFFFFD60A) : colors.textQuaternary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t.title,
                      style: AppTypography.body.copyWith(
                        color: isMIT ? colors.textPrimary : colors.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StepFinished extends StatelessWidget {
  final Set<String> movedTaskIds;
  const _StepFinished({required this.movedTaskIds});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final nav = context.watch<NavigationProvider>();
    final taskProvider = context.watch<TaskProvider>();
    
    final mitTasks = nav.mitTaskIds
        .map((id) => taskProvider.getById(id))
        .whereType<Task>()
        .toList();

    return _WizardPage(
      sticker: AppStickers.celebration,
      title: "You're all set!",
      subtitle: "Your day is planned. Time to make it happen.",
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _MiniStat(label: 'Total Planned', value: '${mitTasks.length} tasks'),
                    const SizedBox(width: 32),
                    _MiniStat(label: 'High Priority', value: '${mitTasks.where((t) => t.priority == Priority.high || t.priority == Priority.urgent).length}'),
                  ],
                ),
                const SizedBox(height: 20),
                ...mitTasks.take(3).map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFD60A)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.caption)),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                // Apply "Move to today" choices
                for (final id in movedTaskIds) {
                  await taskProvider.updateDueDate(id, DateTime.now());
                }
                nav.exitPlanningMode();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text("Start your day →", style: AppTypography.body.copyWith(fontWeight: FontWeight.w800, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _WizardPage extends StatelessWidget {
  final Sticker sticker;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? headerExtra;

  const _WizardPage({
    required this.sticker,
    required this.title,
    required this.subtitle,
    required this.child,
    this.headerExtra,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: 440,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoSticker(sticker: sticker, size: 100),
          const SizedBox(height: 24),
          Text(title, style: AppTypography.headline.copyWith(color: colors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center, style: AppTypography.body.copyWith(color: colors.textSecondary)),
          if (headerExtra != null) ...[
            const SizedBox(height: 16),
            headerExtra!,
          ],
          const SizedBox(height: 32),
          Flexible(child: child),
          const SizedBox(height: 60), // Space for bottom nav
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.icon, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? AppColors.primary : colors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: isActive ? Colors.white : colors.textSecondary),
            const SizedBox(width: 5),
            Text(label, style: AppTypography.caption.copyWith(color: isActive ? Colors.white : colors.textSecondary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      children: [
        Text(label.toUpperCase(), style: AppTypography.micro.copyWith(letterSpacing: 1.0, color: colors.textQuaternary)),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.body.copyWith(fontWeight: FontWeight.w800, color: colors.textPrimary)),
      ],
    );
  }
}
