import 'package:flutter/material.dart';
import '../../theme/typography.dart';

class TodayHeader extends StatelessWidget {
  final int taskCount;
  final int completedCount;

  const TodayHeader({
    super.key,
    required this.taskCount,
    required this.completedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      decoration: BoxDecoration(
        gradient: _timeBasedGradient(),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.12),
            blurRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Shimmer overlay
            Positioned.fill(
              child: CustomPaint(painter: _HeaderShimmerPainter()),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(),
                          style: AppTypography.title2.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _dateString(),
                          style: AppTypography.callout.copyWith(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• ${_taskSummary()}',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _DailyProgressRing(
                    completed: completedCount,
                    total: taskCount,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient _timeBasedGradient() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return const LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      );
    } else if (hour >= 12 && hour < 17) {
      return const LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      );
    } else if (hour >= 17 && hour < 21) {
      return const LinearGradient(
        colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      );
    } else {
      return const LinearGradient(
        colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      );
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning ☀️';
    if (hour >= 12 && hour < 17) return 'Good afternoon 🌤';
    if (hour >= 17 && hour < 21) return 'Good evening 🌆';
    return 'Good night 🌙';
  }

  String _dateString() {
    final now = DateTime.now();
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  String _taskSummary() {
    if (taskCount == 0) return 'Nothing scheduled — enjoy your day ✨';
    if (completedCount == taskCount) return 'All $taskCount tasks done! 🎉';
    if (completedCount == 0) return '$taskCount tasks to tackle today 💪';
    return '$completedCount of $taskCount done';
  }
}

class _DailyProgressRing extends StatelessWidget {
  final int completed;
  final int total;

  const _DailyProgressRing({required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : completed / total;
    final percent = (progress * 100).round();
    final isAllDone = progress >= 1.0;
    final ringColor = isAllDone ? const Color(0xFFFFD60A) : Colors.white;

    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background track
          SizedBox(
            width: 72, height: 72,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 6,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ),
          // Progress arc with gold celebration
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (_, value, __) => TweenAnimationBuilder<Color?>(
              tween: ColorTween(begin: Colors.white, end: ringColor),
              duration: const Duration(milliseconds: 600),
              builder: (_, color, __) => SizedBox(
                width: 72, height: 72,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 6,
                  strokeCap: StrokeCap.round,
                  valueColor: AlwaysStoppedAnimation(color ?? Colors.white),
                ),
              ),
            ),
          ),
          // Center text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isAllDone)
                const Text('🎉', style: TextStyle(fontSize: 18))
              else ...[
                Text(
                  '$percent%',
                  style: AppTypography.bodySemibold.copyWith(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'done',
                  style: AppTypography.micro.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderShimmerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.12),
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.06),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
