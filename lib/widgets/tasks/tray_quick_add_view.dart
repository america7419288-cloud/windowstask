import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../models/task.dart';
import '../../models/sticker.dart';
import '../../data/app_stickers.dart';
import '../../utils/date_utils.dart';
import '../../utils/global_focus_states.dart';
import '../shared/sticker_picker.dart';
import '../shared/sticker_widget.dart';
import '../shared/priority_badge.dart';

class TrayQuickAddView extends StatefulWidget {
  const TrayQuickAddView({super.key});

  @override
  State<TrayQuickAddView> createState() => _TrayQuickAddViewState();
}

class _TrayQuickAddViewState extends State<TrayQuickAddView> {
  final TextEditingController _titleController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  DateTime? _dueDate = DateTime.now();
  TimeOfDay? _dueTime;
  Priority _priority = Priority.none;
  Sticker? _selectedSticker;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() {
      _analyzeForStickers(_titleController.text);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _analyzeForStickers(String text) {
    if (_selectedSticker != null) return; // Don't override manual selection
    
    final lower = text.toLowerCase();
    Sticker? suggested;
    if (lower.contains('gym') || lower.contains('run')) suggested = AppStickers.fitness;
    else if (lower.contains('work') || lower.contains('code')) suggested = AppStickers.work;
    else if (lower.contains('health')) suggested = AppStickers.care;
    else if (lower.contains('study')) suggested = AppStickers.focus;

    if (suggested != null) setState(() => _selectedSticker = suggested);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onCancel() {
    GlobalFocusStates.isTrayQuickAddMode.value = false;
    context.read<NavigationProvider>().exitTrayQuickAddMode();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final tasks = context.read<TaskProvider>();
    final settings = context.read<SettingsProvider>();
    
    final newTask = await tasks.createTask(
      title: title,
      listId: settings.settings.defaultListId,
      dueDate: _dueDate,
      dueHour: _dueTime?.hour,
      dueMinute: _dueTime?.minute,
      priority: _priority,
    );

    if (_selectedSticker != null) {
      await tasks.updateSticker(newTask.id, _selectedSticker);
    }

    _onCancel();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 460,
          height: 340,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.divider.withOpacity(0.5), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 40,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.add_task_rounded, color: accent, size: 20),
                  const SizedBox(width: 12),
                  Text('Quick Add Task', style: AppTypography.titleMedium.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  )),
                  const Spacer(),
                  IconButton(
                    onPressed: _onCancel,
                    icon: Icon(Icons.close_rounded, color: colors.textSecondary, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title Input
              TextField(
                controller: _titleController,
                focusNode: _focusNode,
                style: AppTypography.headlineSmall.copyWith(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Task title...',
                  hintStyle: AppTypography.headlineSmall.copyWith(color: colors.textQuaternary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 20),

              const Divider(),
              const SizedBox(height: 20),

              // Controls Row
              Row(
                children: [
                  _ActionButton(
                    icon: Icons.calendar_today_rounded,
                    label: _dueDate == null ? 'No Date' : AppDateUtils.formatShortDate(_dueDate!),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dueDate ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      );
                      if (picked != null) setState(() => _dueDate = picked);
                    },
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.access_time_rounded,
                    label: _dueTime == null ? 'Add Time' : _dueTime!.format(context),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _dueTime ?? TimeOfDay.now(),
                      );
                      if (picked != null) setState(() => _dueTime = picked);
                    },
                  ),
                  const Spacer(),
                  _PrioritySelector(
                    current: _priority,
                    onSelected: (p) => setState(() => _priority = p),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Sticker Selection
              Row(
                children: [
                  _ActionButton(
                    icon: Icons.emoji_emotions_outlined,
                    label: _selectedSticker == null ? 'Select Sticker' : 'Sticker: ${_selectedSticker!.emoji}',
                    onTap: () async {
                      final stickerId = await StickerPicker.show(context, currentStickerId: _selectedSticker?.id);
                      if (stickerId != null) {
                         // Simple lookup from AppStickers
                         final found = (AppStickers.allStickers + [AppStickers.fitness, AppStickers.work, AppStickers.care, AppStickers.focus])
                             .firstWhere((s) => s.id == stickerId, orElse: () => AppStickers.allStickers.first);
                         setState(() => _selectedSticker = found);
                      }
                    },
                    child: _selectedSticker != null ? StickerWidget(
                      localSticker: _selectedSticker,
                      size: 20,
                      animate: true,
                    ) : null,
                  ),
                ],
              ),

              const Spacer(),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Add Task', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? child;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colors.divider.withOpacity(0.05),
          border: Border.all(color: colors.divider.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (child != null) child! else Icon(icon, size: 16, color: colors.textSecondary),
            const SizedBox(width: 10),
            Text(label, style: AppTypography.bodySM.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _PrioritySelector extends StatelessWidget {
  final Priority current;
  final Function(Priority) onSelected;

  const _PrioritySelector({required this.current, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return PopupMenuButton<Priority>(
      initialValue: current,
      onSelected: onSelected,
      tooltip: 'Select Priority',
      offset: const Offset(0, 40),
      color: colors.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: current == Priority.none ? colors.divider.withOpacity(0.05) : PriorityBadge.colorForPriority(current).withOpacity(0.1),
          border: Border.all(color: current == Priority.none ? colors.divider.withOpacity(0.5) : PriorityBadge.colorForPriority(current)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag_rounded, size: 16, color: current == Priority.none ? colors.textSecondary : PriorityBadge.colorForPriority(current)),
            const SizedBox(width: 8),
            Text(
              current == Priority.none ? 'Priority' : PriorityBadge.labelForPriority(current),
              style: AppTypography.bodySM.copyWith(
                color: current == Priority.none ? colors.textPrimary : PriorityBadge.colorForPriority(current),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: Priority.none, child: Text('No Priority')),
        const PopupMenuItem(value: Priority.low, child: Text('Low')),
        const PopupMenuItem(value: Priority.medium, child: Text('Medium')),
        const PopupMenuItem(value: Priority.high, child: Text('High')),
      ],
    );
  }
}
