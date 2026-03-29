import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/ai_message.dart';
import '../../models/task.dart';
import '../../providers/ai_provider.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/app_theme.dart';
import '../tasks/task_card.dart';

class MessageBubble extends StatelessWidget {
  final AIMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == AIMessageRole.user;
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                _AIAvatar(),
                const SizedBox(width: 12),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.indigo : colors.surfaceElevated,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                    boxShadow: AppColors.shadowSM(isDark: colors.isDark),
                  ),
                  child: _buildContent(context),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 12),
                _UserAvatar(),
              ],
            ],
          ),
          if (message.type == AIMessageType.schedule && message.tasks != null)
            _ScheduleActions(tasks: message.tasks!),
          if (message.type == AIMessageType.taskSuggestion && message.suggestion != null)
            _SuggestionActions(suggestion: message.suggestion!),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildContent(BuildContext context) {
    final colors = context.appColors;
    final isUser = message.role == AIMessageRole.user;

    switch (message.type) {
      case AIMessageType.thinking:
        return _ThinkingIndicator();
      case AIMessageType.schedule:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.content, 
                style: AppTypography.bodyMD.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...message.tasks!.map((t) => _MiniTaskRow(task: t)),
          ],
        );
      case AIMessageType.taskSuggestion:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.content, 
                style: AppTypography.bodyMD.copyWith(color: colors.textPrimary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.indigo.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.indigo),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message.suggestion!.suggestionText,
                      style: AppTypography.caption.copyWith(color: colors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      default:
        return Text(
          message.content,
          style: AppTypography.bodyMD.copyWith(
            color: isUser ? Colors.white : colors.textPrimary,
          ),
        );
    }
  }
}

class _AIAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32, height: 32,
      decoration: const BoxDecoration(
        gradient: AppColors.gradPrimary,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.auto_awesome_rounded, size: 18, color: Colors.white),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(color: colors.surfaceElevated, shape: BoxShape.circle),
      child: Icon(Icons.person_rounded, size: 18, color: colors.textSecondary),
    );
  }
}

class _ThinkingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => Container(
        width: 6, height: 6,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(color: colors.textQuaternary, shape: BoxShape.circle),
      ).animate(onPlay: (c) => c.repeat()).scale(
        begin: const Offset(1, 1), end: const Offset(1.5, 1.5),
        duration: 600.ms, delay: (i * 200).ms, curve: Curves.easeInOut,
      ).then().scale(begin: const Offset(1.5, 1.5), end: const Offset(1, 1))),
    );
  }
}

class _MiniTaskRow extends StatelessWidget {
  final Task task;
  const _MiniTaskRow({required this.task});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4, height: 24,
            decoration: BoxDecoration(
              color: task.priority.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, style: AppTypography.labelMD.copyWith(fontWeight: FontWeight.bold, color: colors.textPrimary)),
                Text('${task.dueHour ?? 0}:${(task.dueMinute ?? 0).toString().padLeft(2, "0")} • ${task.estimatedMinutes ?? 0}m', 
                    style: AppTypography.caption.copyWith(color: colors.textTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleActions extends StatelessWidget {
  final List<Task> tasks;
  const _ScheduleActions({required this.tasks});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 44, top: 8),
      child: Row(
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => context.read<AIProvider>().acceptAllTasks(context, tasks),
            icon: const Icon(Icons.add_task_rounded, size: 16),
            label: Text('Add all to my day', style: AppTypography.labelMD),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {},
            child: Text('Ignore', style: AppTypography.labelMD.copyWith(color: context.appColors.textTertiary)),
          ),
        ],
      ),
    );
  }
}

class _SuggestionActions extends StatelessWidget {
  final AISuggestion suggestion;
  const _SuggestionActions({required this.suggestion});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 44, top: 8),
      child: Row(
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {},
            icon: const Icon(Icons.check_rounded, size: 16),
            label: Text('Apply Change', style: AppTypography.labelMD),
          ),
        ],
      ),
    );
  }
}
