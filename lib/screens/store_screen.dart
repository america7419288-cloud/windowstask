import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/store_item.dart';
import '../data/store_catalog.dart';
import '../data/sticker_packs.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/app_theme.dart';
import '../widgets/shared/deco_sticker.dart';
import '../widgets/shared/sticker_widget.dart';
import '../painters/confetti_painter.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final user = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sticker Store',
                      style: AppTypography.displayMedium.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Spend XP to unlock stickers',
                      style: AppTypography.bodyLarge.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // XP balance badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppColors.ambientShadow(
                      opacity: 0.20,
                      blur: 16,
                      offset: const Offset(0, 4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt_rounded, size: 18, color: AppColors.xpGold),
                      const SizedBox(width: 6),
                      Text(
                        '${user.totalXP} XP',
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                dividerColor: Colors.transparent,
                indicatorColor: AppColors.primary,
                labelColor: colors.textPrimary,
                unselectedLabelColor: colors.textTertiary,
                labelStyle: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                unselectedLabelStyle: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w500),
                tabs: const [
                  Tab(text: 'Featured'),
                  Tab(text: 'Packs'),
                  Tab(text: 'Individual'),
                ],
              ),
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGrid(StoreCatalog.featured),
                _buildGrid(StoreCatalog.packs),
                _buildGrid(StoreCatalog.individuals),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<StoreItem> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
        childAspectRatio: 0.75,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _PackCard(item: items[index]),
    );
  }
}

class _PackCard extends StatelessWidget {
  final StoreItem item;

  const _PackCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final user = context.watch<UserProvider>();
    final isPurchased = user.hasPurchased(item.id);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPurchased
            ? AppColors.tertiary.withValues(alpha: 0.05)
            : colors.isDark
                ? AppColors.surfaceContainerDk
                : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: colors.isDark
            ? []
            : AppColors.ambientShadow(
                opacity: 0.05,
                blur: 16,
                offset: const Offset(0, 3),
              ),
      ),
      child: Column(
        children: [
          // Featured banner
          if (item.isFeatured)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: AppColors.gradientWarm,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '⭐ FEATURED',
                style: AppTypography.micro.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),

          if (!item.isFeatured) const SizedBox(height: 12),

          // Sticker preview grid (2x2)
          Expanded(
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
              physics: const NeverScrollableScrollPhysics(),
              children: item.stickerIds.take(4).map((id) {
                final sticker = StickerRegistry.findById(id);
                if (sticker == null) {
                  return const SizedBox.shrink();
                }
                return Container(
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: isPurchased
                      ? StickerWidget(
                          sticker: sticker,
                          size: 40,
                          animate: true,
                        )
                      : Stack(
                          children: [
                            Opacity(
                              opacity: 0.3,
                              child: StickerWidget(
                                sticker: sticker,
                                size: 40,
                                animate: false,
                              ),
                            ),
                            Center(
                              child: Icon(
                                Icons.lock_rounded,
                                size: 16,
                                color: colors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Pack info
          Text(
            item.name,
            style: AppTypography.titleMedium.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.description,
            style: AppTypography.bodyMedium.copyWith(
              color: colors.textTertiary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 16),

          // Buy / Owned button
          GestureDetector(
            onTap: isPurchased ? null : () => _purchase(context, item),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: isPurchased ? null : AppColors.gradientPrimary,
                color: isPurchased ? AppColors.tertiary.withValues(alpha: 0.10) : null,
                borderRadius: BorderRadius.circular(10),
                boxShadow: isPurchased
                    ? []
                    : AppColors.ambientShadow(
                        opacity: 0.20,
                        blur: 12,
                        offset: const Offset(0, 4),
                      ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isPurchased)
                    const Icon(Icons.check_rounded, size: 16, color: AppColors.tertiary)
                  else ...[
                    const Icon(Icons.bolt_rounded, size: 14, color: AppColors.xpGold),
                    const SizedBox(width: 4),
                  ],
                  const SizedBox(width: 6),
                  Text(
                    isPurchased ? 'Owned' : '${item.xpCost} XP',
                    style: AppTypography.labelLarge.copyWith(
                      color: isPurchased ? AppColors.tertiary : Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _purchase(BuildContext context, StoreItem item) async {
    final user = context.read<UserProvider>();

    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmPurchaseDialog(item: item, currentXP: user.totalXP),
    );

    if (confirmed != true) return;

    final result = await user.purchase(item);

    if (!context.mounted) return;

    switch (result) {
      case PurchaseResult.success:
        _showPurchaseSuccess(context, item);
        break;
      case PurchaseResult.insufficientXP:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Not enough XP! Complete tasks to earn more.'),
          backgroundColor: AppColors.priorityHigh,
        ));
        break;
      case PurchaseResult.alreadyOwned:
        break;
      case PurchaseResult.noProfile:
        break;
    }
  }

  void _showPurchaseSuccess(BuildContext context, StoreItem item) {
    final colors = context.appColors;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(32),
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.emoji, style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                '${item.name} Unlocked!',
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your stickers are now available in the sticker picker.',
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmPurchaseDialog extends StatelessWidget {
  final StoreItem item;
  final int currentXP;

  const _ConfirmPurchaseDialog({required this.item, required this.currentXP});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final canAfford = currentXP >= item.xpCost;

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Unlock ${item.name}?',
              style: AppTypography.headline.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This will cost ${item.xpCost} XP.',
              style: AppTypography.bodyMedium.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: canAfford ? () => Navigator.pop(context, true) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Unlock'),
                  ),
                ),
              ],
            ),
            if (!canAfford) ...[
              const SizedBox(height: 12),
              Text(
                'Need ${item.xpCost - currentXP} more XP',
                style: AppTypography.micro.copyWith(color: AppColors.priorityHigh),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
