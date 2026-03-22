import 'dart:ui';
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
import '../data/app_stickers.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
          // PREMIUM HEADER
          _buildPremiumHeader(colors, user),

          // SEARCH & FILTERS
          _buildSearchAndFilters(colors),

          // MAIN CONTENT
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _FeaturedView(searchQuery: _searchQuery),
                _CategoryView(type: StoreItemType.pack, searchQuery: _searchQuery),
                _CategoryView(type: StoreItemType.individual, searchQuery: _searchQuery),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(AppColorsExtension colors, UserProvider user) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 24),
      decoration: BoxDecoration(
        color: colors.isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
        border: Border(bottom: BorderSide(color: colors.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          DecoSticker(
            sticker: AppStickers.sidebarMascot,
            size: 56,
            animate: true,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sticker Store',
                  style: AppTypography.displayMedium.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  'Personalize your workflow with premium stickers',
                  style: AppTypography.bodyLarge.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _XPBalanceCard(xp: user.totalXP),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
      child: Row(
        children: [
          // Search Bar
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: colors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.divider, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, size: 20, color: colors.textTertiary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: AppTypography.bodyMedium.copyWith(color: colors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search stickers or packs...',
                        hintStyle: AppTypography.bodyMedium.copyWith(color: colors.textQuaternary),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _searchQuery = "");
                      },
                      child: Icon(Icons.close_rounded, size: 18, color: colors.textTertiary),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Tab Switcher
          Container(
            height: 44,
            width: 320,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(8),
                boxShadow: AppColors.ambientShadow(opacity: 0.08, blur: 8, offset: const Offset(0, 2)),
              ),
              labelColor: AppColors.primary,
              unselectedLabelColor: colors.textTertiary,
              labelStyle: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
              unselectedLabelStyle: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'Featured'),
                Tab(text: 'Packs'),
                Tab(text: 'Single'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _XPBalanceCard extends StatelessWidget {
  final int xp;
  const _XPBalanceCard({required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.xpGold, AppColors.xpGold.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.xpGold.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, color: Colors.white, size: 24),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'YOUR BALANCE',
                style: AppTypography.micro.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '$xp XP',
                style: AppTypography.displayMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeaturedView extends StatelessWidget {
  final String searchQuery;
  const _FeaturedView({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final featured = StoreCatalog.featured.where((i) => 
      i.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
      i.description.toLowerCase().contains(searchQuery.toLowerCase())
    ).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      children: [
        // BIG FEATURED CAROUSEL (Simulated)
        if (searchQuery.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Highlights',
              style: AppTypography.displayMedium.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: featured.take(3).length,
              itemBuilder: (context, idx) => _StorePackCard(
                item: featured[idx],
                isFeaturedLarge: true,
              ),
            ),
          ),
          const SizedBox(height: 48),
        ],

        // ALL PACKS GRID
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            searchQuery.isEmpty ? 'All Sticker Packs' : 'Search Results',
            style: AppTypography.displayMedium.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 24,
              crossAxisSpacing: 24,
              mainAxisExtent: 180,
            ),
            itemCount: StoreCatalog.packs.length,
            itemBuilder: (context, idx) => _StorePackCard(item: StoreCatalog.packs[idx]),
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}

class _CategoryView extends StatelessWidget {
  final StoreItemType type;
  final String searchQuery;
  const _CategoryView({required this.type, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final items = (type == StoreItemType.pack ? StoreCatalog.packs : StoreCatalog.individuals)
        .where((i) => 
          i.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          i.description.toLowerCase().contains(searchQuery.toLowerCase())
        ).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(32),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: type == StoreItemType.pack ? 2 : 3,
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
        mainAxisExtent: type == StoreItemType.pack ? 180 : 220,
      ),
      itemCount: items.length,
      itemBuilder: (context, idx) => _StorePackCard(item: items[idx]),
    );
  }
}

class _StorePackCard extends StatefulWidget {
  final StoreItem item;
  final bool isFeaturedLarge;

  const _StorePackCard({required this.item, this.isFeaturedLarge = false});

  @override
  State<_StorePackCard> createState() => _StorePackCardState();
}

class _StorePackCardState extends State<_StorePackCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final user = context.watch<UserProvider>();
    final isPurchased = user.hasPurchased(widget.item.id);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showPackDetail(context, widget.item),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.isFeaturedLarge ? 420 : null,
          margin: widget.isFeaturedLarge ? const EdgeInsets.symmetric(horizontal: 8) : null,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _hovered ? AppColors.primary.withValues(alpha: 0.3) : colors.divider,
              width: _hovered ? 2 : 1,
            ),
            boxShadow: _hovered 
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 8))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              // PREVIEW MOSAIC
              Container(
                width: widget.isFeaturedLarge ? 160 : 130,
                height: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(23)),
                ),
                child: _buildMosaic(widget.item.stickerIds, isPurchased),
              ),
              // CONTENT
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.item.isFeatured && !widget.isFeaturedLarge)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppColors.xpGold.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('FEATURED', style: AppTypography.micro.copyWith(color: AppColors.xpGold, fontWeight: FontWeight.w800)),
                        ),
                      Text(
                        widget.item.name,
                        style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          widget.item.description,
                          style: AppTypography.bodyMedium.copyWith(color: colors.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _PriceBadge(
                        cost: widget.item.xpCost,
                        isPurchased: isPurchased,
                        isLarge: widget.isFeaturedLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMosaic(List<String> ids, bool isPurchased) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      physics: const NeverScrollableScrollPhysics(),
      children: ids.take(4).map((id) {
        final sticker = StickerRegistry.findById(id);
        if (sticker == null) return const SizedBox.shrink();
        return Container(
          decoration: BoxDecoration(
            color: context.appColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Opacity(
            opacity: isPurchased ? 1.0 : 0.4,
            child: StickerWidget(
              sticker: sticker,
              size: 32,
              animate: _hovered && isPurchased,
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showPackDetail(BuildContext context, StoreItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PackDetailSheet(item: item),
    );
  }
}

class _PriceBadge extends StatelessWidget {
  final int cost;
  final bool isPurchased;
  final bool isLarge;

  const _PriceBadge({required this.cost, required this.isPurchased, this.isLarge = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (isPurchased) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.tertiary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.tertiary),
            const SizedBox(width: 6),
            Text('OWNED', style: AppTypography.labelSmall.copyWith(color: AppColors.tertiary, fontWeight: FontWeight.w800)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, size: 14, color: AppColors.xpGold),
          const SizedBox(width: 6),
          Text(
            '$cost XP',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PackDetailSheet extends StatelessWidget {
  final StoreItem item;
  const _PackDetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final user = context.watch<UserProvider>();
    final isPurchased = user.hasPurchased(item.id);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 40)],
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: colors.divider, borderRadius: BorderRadius.circular(2)),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              children: [
                Text(item.emoji, style: const TextStyle(fontSize: 48)),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: AppTypography.displayMedium.copyWith(fontWeight: FontWeight.w900)),
                      Text(item.description, style: AppTypography.bodyLarge.copyWith(color: colors.textSecondary)),
                    ],
                  ),
                ),
                if (!isPurchased)
                  ElevatedButton(
                    onPressed: () => _purchase(context, item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: AppColors.primary.withValues(alpha: 0.4),
                    ),
                    child: Text('Unlock for ${item.xpCost} XP', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800)),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.tertiary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('COLLECTION UNLOCKED', style: AppTypography.labelLarge.copyWith(color: AppColors.tertiary, fontWeight: FontWeight.w900)),
                  ),
              ],
            ),
          ),
          const Divider(),
          // Sticker Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(32),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 24,
                crossAxisSpacing: 24,
              ),
              itemCount: item.stickerIds.length,
              itemBuilder: (context, idx) {
                final sticker = StickerRegistry.findById(item.stickerIds[idx]);
                if (sticker == null) return const SizedBox.shrink();
                return Container(
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: StickerWidget(
                      sticker: sticker,
                      size: 64,
                      animate: isPurchased,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _purchase(BuildContext context, StoreItem item) async {
    final user = context.read<UserProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmPurchaseDialog(item: item, currentXP: user.totalXP),
    );

    if (confirmed == true) {
      final result = await user.purchase(item);
      if (result == PurchaseResult.success) {
        Navigator.pop(context); // Close sheet
        _showSuccess(context, item);
      }
    }
  }

  void _showSuccess(BuildContext context, StoreItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Succesfully unlocked ${item.name}!'),
        backgroundColor: AppColors.tertiary,
        behavior: SnackBarBehavior.floating,
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

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Dialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          padding: const EdgeInsets.all(32),
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppColors.xpGold.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 40))),
              ),
              const SizedBox(height: 24),
              Text(
                'Unlock ${item.name}?',
                style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              Text(
                'This will use ${item.xpCost} of your hard-earned XP. You will have ${currentXP - item.xpCost} XP remaining.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('MAYBE LATER', style: AppTypography.labelLarge.copyWith(color: colors.textTertiary)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: canAfford ? () => Navigator.pop(context, true) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('UNLOCK NOW', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
              if (!canAfford) ...[
                const SizedBox(height: 16),
                Text(
                  'NOT ENOUGH XP (Need ${item.xpCost - currentXP} more)',
                  style: AppTypography.micro.copyWith(color: AppColors.red, fontWeight: FontWeight.w900),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
