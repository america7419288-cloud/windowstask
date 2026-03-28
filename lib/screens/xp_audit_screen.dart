import 'package:flutter/material.dart';
import '../services/security/secure_xp_store.dart';
import '../models/xp_transaction.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class XPAuditScreen extends StatelessWidget {
  const XPAuditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = SecureXPStore.instance;
    final log = store.auditLog.reversed.toList();
    
    // Manual theme context helper
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1115) : Colors.white,
      appBar: AppBar(
        title: Text('XP History',
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.w700,
          )),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(children: [
        // Total XP header
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.gradientMomentum,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(children: [
            const Icon(Icons.bolt_rounded,
                color: AppColors.xpGold,
                size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${store.totalXP} XP Total',
                    style: AppTypography.headlineSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    )),
                  Text(
                    'Level ${(store.totalXP / 500).floor() + 1}',
                    style: AppTypography.labelMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${log.where((t) => t.amount > 0).length} earnings',
              style: AppTypography.caption.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              )),
          ]),
        ),

        // Transaction list
        Expanded(
          child: log.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_rounded, 
                        size: 48, color: isDark ? Colors.white12 : Colors.black12),
                    const SizedBox(height: 16),
                    Text(
                      'No XP earned yet',
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? Colors.white38 : Colors.black38,
                      )),
                  ],
                ))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: log.length,
                itemBuilder: (ctx, i) {
                  final t = log[i];
                  final isPositive = t.amount > 0;
                  final isValid = t.isValid;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? const Color(0xFF1E2128)
                          : const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(12),
                      border: !isValid 
                          ? Border.all(color: Colors.red.withValues(alpha: 0.5), width: 1)
                          : null,
                    ),
                    child: Row(children: [
                      // Source icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isPositive
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _iconForSource(t.source),
                          size: 18,
                          color: isPositive
                              ? AppColors.primary
                              : Colors.redAccent,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _labelForSource(t.source),
                              style: AppTypography.titleSmall.copyWith(
                                color: isDark ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w600,
                              )),
                            Text(
                              _formatDate(t.earnedAt),
                              style: AppTypography.caption.copyWith(
                                color: isDark ? Colors.white38 : Colors.black38,
                              )),
                          ],
                        ),
                      ),

                      // Amount
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isPositive ? '+${t.amount}' : '${t.amount}',
                            style: AppTypography.titleMedium.copyWith(
                              color: isPositive ? AppColors.tertiary : Colors.redAccent,
                              fontWeight: FontWeight.w800,
                            )),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isValid ? 'Verified' : 'Tampered',
                                style: AppTypography.caption.copyWith(
                                  color: isValid ? Colors.green.withValues(alpha: 0.5) : Colors.red,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                isValid ? Icons.verified_rounded : Icons.warning_rounded,
                                size: 10,
                                color: isValid ? Colors.green.withValues(alpha: 0.5) : Colors.red,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ]),
                  );
                },
              ),
        ),
      ]),
    );
  }

  IconData _iconForSource(XPSource s) {
    switch (s) {
      case XPSource.taskCompletion:
        return Icons.check_circle_outline_rounded;
      case XPSource.streakBonus:
        return Icons.local_fire_department_rounded;
      case XPSource.achievementUnlock:
        return Icons.emoji_events_rounded;
      case XPSource.focusSession:
        return Icons.timer_rounded;
      case XPSource.dailyPlanningBonus:
        return Icons.sunny_snowing;
      case XPSource.migration:
        return Icons.auto_fix_high_rounded;
      case XPSource.redeemCode:
        return Icons.redeem_rounded;
    }
  }

  String _labelForSource(XPSource s) {
    switch (s) {
      case XPSource.taskCompletion:
        return 'Task Completed';
      case XPSource.streakBonus:
        return 'Streak Bonus';
      case XPSource.achievementUnlock:
        return 'Achievement Unlocked';
      case XPSource.focusSession:
        return 'Focus Session';
      case XPSource.dailyPlanningBonus:
        return 'Daily Planning';
      case XPSource.migration:
        return 'Legacy XP Migrated';
      case XPSource.redeemCode:
        return 'Code Redeemed';
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
