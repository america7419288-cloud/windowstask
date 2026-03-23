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
import '../data/app_stickers.dart';
import 'redeem_screen.dart';
import '../services/store_service.dart';
import '../models/server_sticker_pack.dart';
import '../models/server_sticker.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final user = context.watch<UserProvider>();
    final store = context.watch<StoreService>();

    // Loading state
    if (store.isLoading && !store.hasData) {
      return _buildLoadingState(colors);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Offline warning banner
          if (store.error != null) _OfflineBanner(message: store.error!),

          // PREMIUM HEADER
          _buildPremiumHeader(colors, user),

          // SEARCH & FILTERS
          _buildSearchAndFilters(colors),

          // MAIN CONTENT
          Expanded(
            child: Stack(
              children: [
                _UnifiedStoreView(searchQuery: _searchQuery),
                if (_celebratingItem != null)
                  _CelebrationOverlay(
                    item: _celebratingItem!,
                    onClose: () => setState(() => _celebratingItem = null),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  StoreItem? _celebratingItem;

  Widget _buildLoadingState(AppColorsExtension colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading store...',
            style: AppTypography.bodyMedium.copyWith(
              color: colors.textTertiary,
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
          const SizedBox(width: 16),
          // Redeem Code Button
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RedeemScreen()),
            ),
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
                  const Icon(Icons.redeem_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text('Redeem',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      )),
                ],
              ),
            ),
          ),
          // Announcement Banner
          Container(
            height: 44,
            width: 320,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'All stickers are now available as single items!',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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

class _UnifiedStoreView extends StatelessWidget {
  final String searchQuery;
  const _UnifiedStoreView({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreService>();
    final stickers = (store.data?.stickers ?? []).where((s) =>
        s.name.toLowerCase().contains(searchQuery.toLowerCase())
    ).toList();

    if (stickers.isEmpty && searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64, color: context.appColors.textQuaternary),
            const SizedBox(height: 16),
            Text('No stickers found for "$searchQuery"',
              style: AppTypography.bodyLarge.copyWith(color: context.appColors.textTertiary)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      children: [
        // HIGHLIGHTS (Individual stickers that are marked featured)
        // For now, we show all since we only have single category
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            searchQuery.isEmpty ? 'Sticker Gallery' : 'Search Results',
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
              crossAxisCount: 5, // More compact for singles
              mainAxisSpacing: 24,
              crossAxisSpacing: 24,
              mainAxisExtent: 180,
            ),
            itemCount: stickers.length,
            itemBuilder: (context, idx) => _StoreStickerCard(serverSticker: stickers[idx]),
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
    final store = context.watch<StoreService>();
    final packs = store.data?.packs ?? [];
    
    // For individuals, we currently filter from the pack's stickers if they matches individual type
    // or if the server response has separate stickers.
    // In part 2 prompt, user mentions type = StoreItemType.pack or individual.
    // I'll filter packs if type is pack, or stickers if type is individual.
    
    final items = type == StoreItemType.pack 
        ? packs.where((p) => 
            p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            p.description.toLowerCase().contains(searchQuery.toLowerCase())
          ).toList()
        : store.data?.stickers.where((s) =>
            s.name.toLowerCase().contains(searchQuery.toLowerCase())
          ).toList() ?? [];

    return GridView.builder(
      padding: const EdgeInsets.all(32),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: type == StoreItemType.pack ? 2 : 4,
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
        mainAxisExtent: type == StoreItemType.pack ? 180 : 160,
      ),
      itemCount: items.length,
      itemBuilder: (context, idx) {
        if (type == StoreItemType.pack) {
          return _StorePackCard(serverPack: items[idx] as ServerStickerPack);
        } else {
          return _StoreStickerCard(serverSticker: items[idx] as ServerSticker);
        }
      },
    );
  }
}

class _StorePackCard extends StatefulWidget {
  final ServerStickerPack serverPack;
  final bool isFeaturedLarge;

  const _StorePackCard({required this.serverPack, this.isFeaturedLarge = false});

  @override
  State<_StorePackCard> createState() => _StorePackCardState();
}

class _StorePackCardState extends State<_StorePackCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final user = context.watch<UserProvider>();
    final isPurchased = user.hasPurchased(widget.serverPack.id);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showPackDetail(context, widget.serverPack),
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
                child: _buildMosaic(widget.serverPack, isPurchased),
              ),
              // CONTENT
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.serverPack.isFeatured && !widget.isFeaturedLarge)
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
                        widget.serverPack.name,
                        style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          widget.serverPack.description,
                          style: AppTypography.bodyMedium.copyWith(color: colors.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _PriceBadge(
                        cost: widget.serverPack.xpCost,
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

  Widget _buildMosaic(ServerStickerPack pack, bool isPurchased) {
    if (pack.previewUrls.isNotEmpty) {
      return GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        physics: const NeverScrollableScrollPhysics(),
        children: pack.previewUrls.take(4).map((url) => _NetworkPreview(url: url, size: 32)).toList(),
      );
    }

    final ids = pack.stickerIds;
    if (ids.isEmpty) {
      return Center(
        child: Text(
          pack.emoji,
          style: TextStyle(fontSize: 48, shadows: [
            Shadow(color: AppColors.xpGold.withValues(alpha: 0.5), blurRadius: 20)
          ]),
        ),
      );
    }
    
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      physics: const NeverScrollableScrollPhysics(),
      children: ids.take(4).map((id) {
        final store = context.read<StoreService>();
        final serverSticker = store.data?.stickerById(id);
        
        return Container(
          decoration: BoxDecoration(
            color: context.appColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Opacity(
            opacity: isPurchased ? 1.0 : 0.4,
            child: StickerWidget(
              serverSticker: serverSticker,
              size: 32,
              animate: _hovered && isPurchased,
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showPackDetail(BuildContext context, ServerStickerPack pack) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PackDetailSheet(item: pack.toStoreItem()),
    );
  }
}

class _StoreStickerCard extends StatefulWidget {
  final ServerSticker serverSticker;
  const _StoreStickerCard({required this.serverSticker});

  @override
  State<_StoreStickerCard> createState() => _StoreStickerCardState();
}

class _StoreStickerCardState extends State<_StoreStickerCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final user = context.watch<UserProvider>();
    final isPurchased = user.hasPurchased(widget.serverSticker.id);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showStickerDetail(context, widget.serverSticker),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hovered ? AppColors.primary.withValues(alpha: 0.3) : colors.divider,
              width: _hovered ? 2 : 1,
            ),
            boxShadow: _hovered 
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 8))]
              : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: StickerWidget(
                    serverSticker: widget.serverSticker,
                    size: 64,
                    animate: _hovered || isPurchased,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  children: [
                    Text(
                      widget.serverSticker.name,
                      style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    _PriceBadge(
                      cost: widget.serverSticker.xpCost,
                      isPurchased: isPurchased,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStickerDetail(BuildContext context, ServerSticker sticker) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PackDetailSheet(item: sticker.toStoreItem()),
    );
  }
}

class _NetworkPreview extends StatelessWidget {
  final String? url;
  final double size;
  const _NetworkPreview({this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return Center(child: Text('✨', style: TextStyle(fontSize: size * 0.6)));
    }
    return Image.network(
      url!,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Center(child: Text('✨', style: TextStyle(fontSize: size * 0.6))),
      loadingBuilder: (_, child, progress) => progress == null ? child : _StickerShimmer(size: size),
    );
  }
}

class _StickerShimmer extends StatelessWidget {
  final double size;
  const _StickerShimmer({required this.size});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
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
                final id = item.stickerIds[idx];
                final store = context.read<StoreService>();
                final serverSticker = store.data?.stickerById(id);
                // Fallback to registry for bundled ones
                final localSticker = StickerRegistry.findById(id);

                if (serverSticker == null && localSticker == null) return const SizedBox.shrink();
                
                return Container(
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: StickerWidget(
                      serverSticker: serverSticker,
                      localSticker: localSticker,
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
        final state = context.findAncestorStateOfType<_StoreScreenState>();
        state?.setState(() => state._celebratingItem = item);
      } else if (result == PurchaseResult.offline) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offline: Connect to internet to purchase stickers.'),
            backgroundColor: AppColors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (result == PurchaseResult.insufficientXP) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not enough XP to unlock this item.'),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
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

class _CelebrationOverlay extends StatelessWidget {
  final StoreItem item;
  final VoidCallback onClose;

  const _CelebrationOverlay({required this.item, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final store = context.read<StoreService>();
    final serverSticker = store.data?.stickerById(item.id);
    final localSticker = StickerRegistry.findById(item.id);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10 * value, sigmaY: 10 * value),
          child: Container(
            color: Colors.black.withOpacity(0.6 * value),
            child: child,
          ),
        );
      },
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Floating Sticker
            Container(
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.3),
                    AppColors.primary.withOpacity(0.0),
                  ],
                ),
              ),
              child: StickerWidget(
                serverSticker: serverSticker,
                localSticker: localSticker,
                size: 240,
                animate: true,
              ),
            ).animate()
              .scale(
                begin: const Offset(0.3, 0.3),
                end: const Offset(1.0, 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
              )
              .shake(hz: 2, curve: Curves.easeInOut, duration: const Duration(seconds: 2)),

            const SizedBox(height: 48),

            // Text
            Text(
              'NEW STICKER UNLOCKED!',
              style: AppTypography.displayMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ).animate()
              .fadeIn(delay: const Duration(milliseconds: 400))
              .moveY(begin: 20, end: 0, curve: Curves.easeOutBack),

            const SizedBox(height: 12),

            Text(
              item.name.toUpperCase(),
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.xpGold,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ).animate()
              .fadeIn(delay: const Duration(milliseconds: 600))
              .moveY(begin: 10, end: 0),

            const SizedBox(height: 64),

            // Continue Button
            GestureDetector(
              onTap: onClose,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Text(
                  'AWESOME!',
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ).animate()
              .fadeIn(delay: const Duration(seconds: 1))
              .scale(begin: const Offset(0.8, 0.8), duration: const Duration(milliseconds: 400), curve: Curves.easeOutBack),
          ],
        ),
      ),
    );
  }
}
class _OfflineBanner extends StatelessWidget {
  final String message;
  const _OfflineBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.warning.withOpacity(0.10),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 14, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.caption.copyWith(
                color: AppColors.warning,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.read<StoreService>().fetchStore(),
            child: Text(
              'Retry',
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
