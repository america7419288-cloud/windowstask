import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
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
      child: Row(
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
                    ? 'Task title... press Enter to save'
                    : 'Add a task',
                hintStyle: AppTypography.body.copyWith(
                  color: colors.textTertiary,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              ),
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

