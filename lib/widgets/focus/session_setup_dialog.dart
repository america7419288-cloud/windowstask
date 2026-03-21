import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../providers/focus_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/typography.dart';
import '../../data/app_stickers.dart';
import '../shared/deco_sticker.dart';
import '../../utils/constants.dart';

class SessionSetupDialog extends StatefulWidget {
  const SessionSetupDialog({super.key});

  @override
  State<SessionSetupDialog> createState() => _SessionSetupDialogState();
}

class _SessionSetupDialogState extends State<SessionSetupDialog> {
  late int _durationMinutes;
  final Set<String> _selectedTaskIds = {};

  @override
  void initState() {
    super.initState();
    _durationMinutes = context.read<SettingsProvider>().focusDuration;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;
    final nav = context.watch<NavigationProvider>();
    final tasks = context.watch<TaskProvider>().getTasksForNav(
      AppConstants.navAll,
      filterMITs: nav.filterMITs,
      filterHighPriority: nav.filterHighPriority,
      filterOverdue: nav.filterOverdue,
      mitIds: nav.mitTaskIds,
    )
        .where((t) => !t.isCompleted)
        .toList();

    return Container(
      width: 440,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mascot & Title
          DecoSticker(sticker: AppStickers.settingsTasks, size: 80),
          const SizedBox(height: 16),
          Text(
            'Ready to focus?',
            style: AppTypography.headline.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Select your goals and set a timer to stay productive.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Duration Selector
          _SectionHeader(title: 'DURATION'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [15, 25, 30, 45, 60].map((m) {
              final isSelected = _durationMinutes == m;
              return GestureDetector(
                onTap: () => setState(() => _durationMinutes = m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? accent : colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? accent : colors.border,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '$m min',
                    style: AppTypography.caption.copyWith(
                      color: isSelected ? Colors.white : colors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Task Selector
          _SectionHeader(title: 'SESSION GOALS'),
          const SizedBox(height: 12),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: colors.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border, width: 0.5),
              ),
              child: tasks.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'No active tasks found.',
                          style: AppTypography.caption.copyWith(color: colors.textTertiary),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(8),
                      itemCount: tasks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final t = tasks[index];
                        final isSelected = _selectedTaskIds.contains(t.id);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedTaskIds.remove(t.id);
                              } else {
                                _selectedTaskIds.add(t.id);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? accent.withValues(alpha: 0.08) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill) : PhosphorIcons.circle(),
                                  size: 18,
                                  color: isSelected ? accent : colors.textSecondary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    t.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.body.copyWith(
                                      color: isSelected ? colors.textPrimary : colors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 32),

          // Actions
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Cancel', style: AppTypography.body.copyWith(color: colors.textTertiary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    context.read<FocusProvider>().startFocus(
                      taskIds: _selectedTaskIds.toList(),
                      durationMinutes: _durationMinutes,
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Start Focus',
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        const SizedBox(width: 4),
        Text(
          title,
          style: AppTypography.caption.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: colors.textQuaternary,
          ),
        ),
      ],
    );
  }
}
