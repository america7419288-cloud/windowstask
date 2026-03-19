import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../utils/constants.dart';
import '../../utils/date_utils.dart';
import '../../services/nlp_parser.dart';
import '../../models/task.dart';
import '../../widgets/shared/priority_badge.dart';
import 'dart:convert';
import 'dart:async';

class QuickAddBar extends StatefulWidget {
  const QuickAddBar({super.key});

  @override
  State<QuickAddBar> createState() => _QuickAddBarState();
}

class _QuickAddBarState extends State<QuickAddBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;
  ParsedTaskInput? _parsed;

  bool _hasDetectedAnything(ParsedTaskInput p) {
    return p.dueDate != null ||
        p.dueHour != null ||
        p.priority != null ||
        p.isFlagged ||
        p.recurrence != null;
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _focused = _focusNode.hasFocus);
      if (!_focusNode.hasFocus) {
        context.read<NavigationProvider>().closeQuickAdd();
      }
    });
    _controller.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nav = context.read<NavigationProvider>();
    if (nav.isQuickAddOpen && !_focusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = colors.isDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1C1A) : Colors.white,
        border: Border(
          bottom: BorderSide(color: colors.divider, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Plus icon
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  gradient: _focused ? AppColors.gradientPrimary : null,
                  color: _focused
                      ? null
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : AppColors.primary.withValues(alpha: 0.08)),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 16,
                  color: _focused ? Colors.white : AppColors.primary,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: AppTypography.body.copyWith(
                    color: colors.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: _focused
                        ? 'e.g. \"Submit report tomorrow 3pm !high\"'
                        : 'Add a task',
                    hintStyle: AppTypography.body.copyWith(
                      color: colors.textTertiary,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _parsed = value.trim().isNotEmpty
                          ? NlpParser.parse(value)
                          : null;
                    });
                  },
                  onSubmitted: _submit,
                ),
              ),
              // Save button
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: _focused && _controller.text.isNotEmpty
                    ? Padding(
                        key: const ValueKey('add_btn'),
                        padding: const EdgeInsets.only(right: 4),
                        child: GestureDetector(
                          onTap: () => _submit(_controller.text),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: AppColors.gradientPrimary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Add',
                              style: AppTypography.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(key: ValueKey('empty'), width: 4),
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _parsed != null && _hasDetectedAnything(_parsed!)
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(36, 0, 12, 4),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (_parsed!.dueDate != null)
                          _PreviewChip(
                            icon: Icons.schedule_rounded,
                            label: AppDateUtils.formatShortDate(_parsed!.dueDate!),
                            color: AppColors.blue,
                          ),
                        if (_parsed!.dueHour != null)
                          _PreviewChip(
                            icon: Icons.access_time_rounded,
                            label: '${_parsed!.dueHour.toString().padLeft(2, '0')}:${(_parsed!.dueMinute ?? 0).toString().padLeft(2, '0')}',
                            color: AppColors.indigo,
                          ),
                        if (_parsed!.priority != null && _parsed!.priority != Priority.none)
                          _PreviewChip(
                            icon: Icons.flag_rounded,
                            label: PriorityBadge.labelForPriority(_parsed!.priority!),
                            color: AppColors.priorityHigh,
                          ),
                        if (_parsed!.isFlagged)
                          _PreviewChip(
                            icon: Icons.bookmark_rounded,
                            label: 'Flagged',
                            color: AppColors.orange,
                          ),
                        if (_parsed!.recurrence != null)
                          _PreviewChip(
                            icon: Icons.repeat_rounded,
                            label: _parsed!.recurrence!.displayLabel,
                            color: AppColors.teal,
                          ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  void _submit(String value) {
    final parsed = NlpParser.parse(value);
    if (parsed.title.isEmpty) return;

    final tasks = context.read<TaskProvider>();
    final settings = context.read<SettingsProvider>();
    final nav = context.read<NavigationProvider>();
    final navItem = nav.selectedNavItem;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime? dueDate = parsed.dueDate;
    String? listId = settings.settings.defaultListId;
    bool isFlagged = parsed.isFlagged;
    Priority priority = parsed.priority ?? Priority.none;

    // Overlay navigation context if not explicitly parsed
    if (dueDate == null) {
      switch (navItem) {
        case AppConstants.navToday:
          dueDate = today;
          break;
        case AppConstants.navUpcoming:
          dueDate = today.add(const Duration(days: 1));
          break;
        case AppConstants.navScheduled:
          dueDate = today;
          break;
        case AppConstants.navFlagged:
          isFlagged = true;
          break;
        default:
          if (navItem.startsWith('list_')) {
            listId = navItem.substring(5);
          }
      }
    }

    tasks.createTask(
      title: parsed.title,
      listId: listId,
      dueDate: dueDate,
      dueHour: parsed.dueHour,
      dueMinute: parsed.dueMinute,
      isFlagged: isFlagged,
      priority: priority,
      recurrenceJson: parsed.recurrence != null ? jsonEncode(parsed.recurrence!.toJson()) : null,
    );
    _controller.clear();
    setState(() => _parsed = null);
  }
}

class _PreviewChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _PreviewChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 0.75,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: AppTypography.micro.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              )),
        ],
      ),
    );
  }
}

