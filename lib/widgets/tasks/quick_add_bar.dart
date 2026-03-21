import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/list_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../utils/constants.dart';
import '../../utils/date_utils.dart';
import '../../services/nlp_parser.dart';
import '../../models/task.dart';
import '../../models/sticker.dart';
import '../../data/app_stickers.dart';
import '../../widgets/shared/priority_badge.dart';
import 'dart:convert';
import 'template_picker.dart';
import '../../providers/template_provider.dart';
import '../../utils/global_focus_states.dart';

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
  Sticker? _suggestedSticker;

  bool _hasDetectedAnything(ParsedTaskInput p) {
    return p.dueDate != null ||
        p.dueHour != null ||
        p.priority != null ||
        p.isFlagged ||
        p.recurrence != null ||
        _suggestedSticker != null;
  }

  void _analyzeForStickers(String text) {
    final lower = text.toLowerCase();
    Sticker? suggested;
    
    if (lower.contains('gym') || lower.contains('work') || lower.contains('run') || lower.contains('sport') || lower.contains('fit')) {
      suggested = AppStickers.fitness;
    } else if (lower.contains('work') || lower.contains('office') || lower.contains('code') || lower.contains('dev') || lower.contains('meet')) {
      suggested = AppStickers.work;
    } else if (lower.contains('care') || lower.contains('doctor') || lower.contains('health') || lower.contains('med')) {
      suggested = AppStickers.care;
    } else if (lower.contains('study') || lower.contains('exam') || lower.contains('book') || lower.contains('learn') || lower.contains('focus')) {
      suggested = AppStickers.focus;
    }

    if (_suggestedSticker != suggested) {
      setState(() => _suggestedSticker = suggested);
    }
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
    _controller.addListener(() {
      _analyzeForStickers(_controller.text);
      setState(() {});
    });
    GlobalFocusStates.quickAddFocus.addListener(_onQuickAddFocusRequested);
  }

  void _onQuickAddFocusRequested() {
    if (mounted) {
      _focusNode.requestFocus();
    }
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
    GlobalFocusStates.quickAddFocus.removeListener(_onQuickAddFocusRequested);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        boxShadow: AppColors.ambientShadow(
          opacity: 0.04,
          blur: 16,
          offset: const Offset(0, 3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.add_circle_outline_rounded,
            size: 18,
            color: AppColors.primary.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: AppTypography.bodyMedium.copyWith(
                color: colors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: _focused
                    ? 'Task title... press Enter to save'
                    : 'Add a task',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: colors.textTertiary,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  _parsed = value.trim().isNotEmpty ? NlpParser.parse(value) : null;
                });
              },
              onSubmitted: _submit,
            ),
          ),
          // NLP preview chips if parsed
          if (_focused && _controller.text.trim().isNotEmpty)
            _NlpPreviewRow(
              parsed: _parsed,
              suggestedSticker: _suggestedSticker,
              hasDetected: _parsed != null && _hasDetectedAnything(_parsed!),
            ),
        ],
      ),
    );
  }

  void _submit(String value) async {
    final parsed = NlpParser.parse(value);
    if (parsed.title.isEmpty) return;

    final tasks = context.read<TaskProvider>();
    final settings = context.read<SettingsProvider>();
    final nav = context.read<NavigationProvider>();
    final lists = context.read<ListProvider>();
    final navItem = nav.selectedNavItem;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime? dueDate = parsed.dueDate;
    String? listId = settings.settings.defaultListId;
    bool isFlagged = parsed.isFlagged;
    Priority priority = parsed.priority ?? Priority.none;
    List<String> tagsList = parsed.tags;

    // Resolve listName to listId
    if (parsed.listName != null) {
      final name = parsed.listName!.toLowerCase();
      try {
        final match = lists.activeLists.firstWhere(
          (l) => l.name.toLowerCase() == name || l.name.toLowerCase().contains(name));
        listId = match.id;
      } catch (_) {
        // List not found, create it? For now just ignore or use default
      }
    }

    // Overlay navigation context if not explicitly parsed and NO list specified
    if (dueDate == null && parsed.listName == null) {
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

    final newTask = await tasks.createTask(
      title: parsed.title,
      listId: listId,
      dueDate: dueDate,
      dueHour: parsed.dueHour,
      dueMinute: parsed.dueMinute,
      isFlagged: isFlagged,
      priority: priority,
      tags: tagsList,
      recurrenceJson: parsed.recurrence != null ? jsonEncode(parsed.recurrence!.toJson()) : null,
    );

    // Apply the suggested sticker if it was present
    if (_suggestedSticker != null) {
      await tasks.updateSticker(newTask.id, _suggestedSticker);
    }

    _controller.clear();
    if (mounted) {
      setState(() {
        _parsed = null;
        _suggestedSticker = null;
      });
    }
  }
}

class _NlpPreviewRow extends StatelessWidget {
  final ParsedTaskInput? parsed;
  final Sticker? suggestedSticker;
  final bool hasDetected;

  const _NlpPreviewRow({
    this.parsed,
    this.suggestedSticker,
    required this.hasDetected,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasDetected && suggestedSticker == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (suggestedSticker != null)
            _PreviewChip(
              icon: Icons.auto_awesome_rounded,
              label: '${suggestedSticker!.emoji} Suggest',
              color: AppColors.purple,
              isBadge: true,
            ),
          if (parsed != null && parsed!.listName != null)
            _PreviewChip(
              icon: Icons.folder_rounded,
              label: '#${parsed!.listName}',
              color: AppColors.blue,
              isBadge: true,
            ),
          if (parsed != null && parsed!.dueDate != null)
            _PreviewChip(
              icon: Icons.schedule_rounded,
              label: AppDateUtils.formatShortDate(parsed!.dueDate!),
              color: AppColors.blue,
            ),
          if (parsed != null && parsed!.priority != null && parsed!.priority != Priority.none)
            _PreviewChip(
              icon: Icons.flag_rounded,
              label: PriorityBadge.labelForPriority(parsed!.priority!),
              color: AppColors.priorityHigh,
            ),
        ],
      ),
    );
  }

}
class _PreviewChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isBadge;
  const _PreviewChip({
    required this.icon,
    required this.label,
    required this.color,
    this.isBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isBadge ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: isBadge ? 0.40 : 0.25),
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

