import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/achievement.dart';
import '../providers/user_provider.dart';
import '../theme/colors.dart';
import '../widgets/shared/sticker_widget.dart';
import '../widgets/shared/taski_button.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  String _filter = 'all'; // 'all', 'unlocked'

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final allAchievements = Achievements.all;
    final earnedIds = userProvider.profile?.earnedBadgeIds ?? [];
    
    final filteredAchievements = allAchievements.where((a) {
      if (_filter == 'unlocked') return earnedIds.contains(a.id);
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HEADER ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Achievements',
                  style: GoogleFonts.nunito(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.t1Dark : AppColors.t1Light,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Track your journey and collect unique stickers for your achievements.',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    color: isDark ? AppColors.t2Dark : AppColors.t2Light,
                  ),
                ),
                const SizedBox(height: 24),
                
                // ── FILTERS ─────────────────────────────────────────────────
                Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      isSelected: _filter == 'all',
                      onTap: () => setState(() => _filter = 'all'),
                      count: allAchievements.length,
                    ),
                    const SizedBox(width: 12),
                    _FilterChip(
                      label: 'Unlocked',
                      isSelected: _filter == 'unlocked',
                      onTap: () => setState(() => _filter = 'unlocked'),
                      count: earnedIds.length,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── GRID ──────────────────────────────────────────────────────────
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 280,
                mainAxisExtent: 320,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              itemCount: filteredAchievements.length,
              itemBuilder: (context, index) {
                final a = filteredAchievements[index];
                final isEarned = earnedIds.contains(a.id);
                final progress = userProvider.getAchievementProgress(a);
                
                return _AchievementCard(
                  achievement: a,
                  isEarned: isEarned,
                  progress: progress,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int count;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected 
              ? (isDark ? AppColors.indigo : AppColors.indigo)
              : (isDark ? AppColors.sur2Dark : AppColors.surLight),
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected ? AppColors.shadowSM(isDark: isDark) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : (isDark ? AppColors.t2Dark : AppColors.t2Light),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? Colors.white.withOpacity(0.2) 
                    : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : (isDark ? AppColors.t3Dark : AppColors.t3Light),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool isEarned;
  final double progress;

  const _AchievementCard({
    required this.achievement,
    required this.isEarned,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surDark : AppColors.surLight,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.shadowMD(isDark: isDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── STICKER ──
                SizedBox(
                  height: 120,
                  width: 120,
                  child: ColorFiltered(
                    colorFilter: isEarned 
                      ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                      : const ColorFilter.matrix([
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0.2126, 0.7152, 0.0722, 0, 0,
                          0,      0,      0,      1, 0,
                        ]), // Grayscale for locked
                    child: Opacity(
                      opacity: isEarned ? 1.0 : 0.4,
                      child: StickerWidget(
                        assetPath: achievement.assetPath,
                        size: 120,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // ── INFO ──
                Text(
                  achievement.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.t1Dark : AppColors.t1Light,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  achievement.description,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: isDark ? AppColors.t2Dark : AppColors.t2Light,
                    height: 1.3,
                  ),
                ),
                
                const Spacer(),
                
                // ── PROGRESS OR REWARD ──
                if (isEarned)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill), color: AppColors.success, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Unlocked',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: isDark ? AppColors.sur3Dark : AppColors.sur3Light,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            achievement.tier == AchievementTier.gold ? AppColors.gold : AppColors.indigo
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(progress * 100).toInt()}% Progress',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.t3Dark : AppColors.t3Light,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          
          // ── TIER BADGE ──
          Positioned(
            top: 16,
            right: 16,
            child: _TierBadge(tier: achievement.tier),
          ),
        ],
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  final AchievementTier tier;

  const _TierBadge({required this.tier});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    
    switch (tier) {
      case AchievementTier.gold:
        color = AppColors.gold;
        label = 'Gold';
        break;
      case AchievementTier.silver:
        color = const Color(0xFF94A3B8);
        label = 'Silver';
        break;
      case AchievementTier.bronze:
        color = const Color(0xFFB45309);
        label = 'Bronze';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
