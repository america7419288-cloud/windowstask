import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/task.dart';
import '../../../models/subtask.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/tag_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/colors.dart';
import '../../../theme/typography.dart';

// ─── DESIGN TOKENS ─────────────────────────────────────────────────────────

class CardDesign {
  static const double radius = 14.0;
  static const double borderWidth = 1.0;
  
  static BoxBorder border(BuildContext context) {
    final colors = context.appColors;
    return Border.all(
      color: colors.border,
      width: borderWidth,
    );
  }

  static List<BoxShadow> shadow(BuildContext context) {
    final colors = context.appColors;
    if (colors.isDark) return [];
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
  }

  static Color background(BuildContext context) {
    final colors = context.appColors;
    return colors.surfaceElevated;
  }
}

// ─── PRIORITY UTILS ───────────────────────────────────────────────────────

Color getPriorityColor(Priority p) {
  switch (p) {
    case Priority.none:   return const Color(0xFF94A3B8);
    case Priority.low:    return const Color(0xFF22C55E);
    case Priority.medium: return const Color(0xFFF59E0B);
    case Priority.high:   return const Color(0xFFEF4444);
    case Priority.urgent: return const Color(0xFFEC4899);
  }
}

String getPriorityLabel(Priority p) {
  switch (p) {
    case Priority.none:   return 'None';
    case Priority.low:    return 'Low';
    case Priority.medium: return 'Medium';
    case Priority.high:   return 'High';
    case Priority.urgent: return 'Urgent';
  }
}

// ─── SHARED WIDGETS ───────────────────────────────────────────────────────

class CardTagPill extends StatelessWidget {
  final String tagName;
  const CardTagPill({super.key, required this.tagName});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.isDark
            ? accent.withValues(alpha: 0.15)
            : accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.isDark
              ? accent.withValues(alpha: 0.25)
              : accent.withValues(alpha: 0.15),
          width: 0.75,
        ),
      ),
      child: Text(
        '#$tagName',
        style: AppTypography.micro.copyWith(
          fontSize: 10,
          color: accent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class InlineSubtaskRow extends StatelessWidget {
  final Subtask sub;
  final String taskId;
  final bool compact;

  const InlineSubtaskRow({
    super.key,
    required this.sub,
    required this.taskId,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 2 : 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.read<TaskProvider>().toggleSubtask(taskId, sub.id),
            child: Container(
              width: compact ? 12 : 14,
              height: compact ? 12 : 14,
              decoration: BoxDecoration(
                color: sub.isCompleted ? accent : Colors.transparent,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: sub.isCompleted ? accent : colors.textTertiary.withValues(alpha: 0.4),
                  width: 1.25,
                ),
              ),
              child: sub.isCompleted
                  ? Icon(Icons.check_rounded, size: compact ? 8 : 9, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              sub.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                fontSize: compact ? 11 : 12,
                color: sub.isCompleted ? colors.textTertiary : colors.textSecondary,
                decoration: sub.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DashedDivider extends StatelessWidget {
  const DashedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      height: 1,
      child: CustomPaint(
        painter: _DashedLinePainter(
          color: colors.isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.10),
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    double x = 0;
    const dashWidth = 5.0;
    const dashSpace = 4.0;

    while (x < size.width) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + dashWidth, 0),
        paint,
      );
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}

class PriorityBadgeInline extends StatelessWidget {
  final Priority priority;
  const PriorityBadgeInline({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = getPriorityColor(priority);
    final label = getPriorityLabel(priority);
    final isDark = context.appColors.isDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: 0.20) : color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label.toUpperCase(),
            style: AppTypography.micro.copyWith(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
