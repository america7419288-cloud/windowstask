import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/typography.dart';
import '../../utils/constants.dart';

class QuickAddBar extends StatefulWidget {
  const QuickAddBar({super.key});

  @override
  State<QuickAddBar> createState() => _QuickAddBarState();
}

class _QuickAddBarState extends State<QuickAddBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
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
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _focused
            ? (colors.isDark ? const Color(0xFF3A3A3C) : Colors.white)
            : (colors.isDark ? const Color(0xFF2C2C2E) : Colors.white.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(
          color: _focused ? accent.withOpacity(0.4) : colors.border,
          width: _focused ? 1.5 : 1,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: accent.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Icon(
              Icons.add_circle_outline_rounded,
              size: 18,
              color: _focused ? accent : colors.textSecondary,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: 'Add a task... (press Enter to save)',
                hintStyle: AppTypography.body.copyWith(color: colors.textSecondary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              style: AppTypography.body.copyWith(color: colors.textPrimary),
              onSubmitted: _submit,
            ),
          ),
          if (_focused && _controller.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => _submit(_controller.text),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Add',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _submit(String value) {
    final title = value.trim();
    if (title.isEmpty) return;
    final tasks = context.read<TaskProvider>();
    final settings = context.read<SettingsProvider>();
    final nav = context.read<NavigationProvider>();
    final navItem = nav.selectedNavItem;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime? dueDate;
    String? listId = settings.settings.defaultListId;
    bool isFlagged = false;

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

    tasks.createTask(
      title: title,
      listId: listId,
      dueDate: dueDate,
      isFlagged: isFlagged,
    );
    _controller.clear();
    setState(() {});
  }
}
