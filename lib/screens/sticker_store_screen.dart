import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/store_item.dart';
import '../data/sticker_packs.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/app_theme.dart';
import '../widgets/shared/sticker_widget.dart';
import 'redeem_screen.dart';
import '../services/store_service.dart';
import '../models/server_sticker_pack.dart';
import '../models/server_sticker.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StickerStoreScreen extends StatefulWidget {
  const StickerStoreScreen({super.key});

  @override
  State<StickerStoreScreen> createState() => _StickerStoreScreenState();
}

class _StickerStoreScreenState extends State<StickerStoreScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  String _filter = 'all';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _formatXP(int xp) {
    if (xp >= 1000) {
      final k = xp / 1000;
      return k == k.roundToDouble()
          ? '${k.toInt()}K'
          : '${k.toStringAsFixed(1)}K';
    }
    return '$xp';
  }

  void _openRedeem() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RedeemScreen()),
    );
  }

  List<dynamic> _filteredItems(
    StoreData? data,
    UserProvider user,
  ) {
    if (data == null) return [];

    final allPacks = data.packs;
    final allStickers = data.stickers.where((s) => s.packId == null).toList();

    var packs = allPacks.where((p) {
      if (_query.isNotEmpty) {
        return p.name.toLowerCase().contains(_query.toLowerCase()) ||
            p.description.toLowerCase().contains(_query.toLowerCase());
      }
      return true;
    }).toList();

    var stickers = allStickers.where((s) {
      if (_query.isNotEmpty) {
        return s.name.toLowerCase().contains(_query.toLowerCase());
      }
      return true;
    }).toList();

    switch (_filter) {
      case 'featured':
        packs = packs.where((p) => p.isFeatured).toList();
        stickers = stickers.where((s) => false).toList(); // Individuals don't have featured flag yet
        break;
      case 'owned':
        packs = packs.where((p) => user.hasPurchased(p.id)).toList();
        stickers = stickers.where((s) => user.hasPurchased(s.id)).toList();
        break;
      case 'afford':
        packs = packs
            .where((p) => !user.hasPurchased(p.id) && user.totalXP >= p.xpCost)
            .toList();
        stickers = stickers
            .where((s) => !user.hasPurchased(s.id) && user.totalXP >= s.xpCost)
            .toList();
        break;
      case 'packs':
        stickers = [];
        break;
      case 'stickers':
        packs = [];
        break;
    }

    return [...packs, ...stickers];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final user = context.watch<UserProvider>();
    final store = context.watch<StoreService>();

    if (store.isLoading && !store.hasData) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: AppColors.indigo,
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading store...',
                style: AppTypography.bodyMD.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      );
    }



    final items = _filteredItems(store.data, user);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // ── HEADER BAND ──────────────────────────
          _buildHeaderBand(colors, user),

          // ── SEARCH + FILTER ROW ──────────────────
          _buildSearchAndFilters(colors),

          // ── PACK GRID ────────────────────────────
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 64, color: colors.textQuaternary),
                        const SizedBox(height: 16),
                        Text(
                          _query.isNotEmpty
                              ? 'No items found for "$_query"'
                              : 'No items in this category',
                          style: AppTypography.bodyMD.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final item = items[i];
                      if (item is ServerStickerPack) {
                        return _StorePackCard(
                          pack: item,
                          onPurchase: (p) => _purchase(p),
                        );
                      } else {
                        return _IndividualStickerCard(
                          sticker: item as ServerSticker,
                          onPurchase: (s) => _purchaseSticker(s),
                        );
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ── HEADER BAND ────────────────────────────────────
  Widget _buildHeaderBand(AppColorsExtension colors, UserProvider user) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
      decoration: const BoxDecoration(
        gradient: AppColors.gradMomentum,
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      size: 17,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Sticker Store',
                    style: AppTypography.headlineMD.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Unlock animated stickers with your XP',
                style: AppTypography.bodyMD.copyWith(
                  color: Colors.white.withValues(alpha: .65),
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // XP balance (glass card)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .20),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt_rounded,
                        size: 18, color: AppColors.gold),
                    const SizedBox(width: 7),
                    Text(
                      _formatXP(user.totalXP),
                      style: AppTypography.headlineSM.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Redeem code ghost button
              GestureDetector(
                onTap: () => _openRedeem(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .35),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.redeem_rounded,
                          size: 13, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'Redeem Code',
                        style: AppTypography.labelMD.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── SEARCH + FILTER ROW ────────────────────────────
  Widget _buildSearchAndFilters(AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          // Search bar
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(10),
                boxShadow: AppColors.shadowSM(isDark: colors.isDark),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(Icons.search_rounded,
                      size: 16, color: colors.textTertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v),
                      style: AppTypography.bodyMD.copyWith(
                        color: colors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Search stickers...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Filter pills
          ...[
            ('all', 'All'),
            ('featured', '⭐ Featured'),
            ('packs', '📦 Packs'),
            ('stickers', '✨ Stickers'),
            ('owned', '✓ Owned'),
            ('afford', '⚡ Can Afford'),
          ].map(
            (f) => Padding(
              padding: const EdgeInsets.only(left: 6),
              child: GestureDetector(
                onTap: () => setState(() => _filter = f.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                  decoration: BoxDecoration(
                    color: _filter == f.$1
                        ? AppColors.indigo
                        : colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    f.$2,
                    style: AppTypography.labelMD.copyWith(
                      color: _filter == f.$1
                          ? Colors.white
                          : colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── PURCHASE FLOW ──────────────────────────────────
  Future<void> _purchase(ServerStickerPack pack) async {
    final user = context.read<UserProvider>();
    final item = pack.toStoreItem();
    await _handlePurchase(item, pack.name);
  }

  Future<void> _purchaseSticker(ServerSticker sticker) async {
    final user = context.read<UserProvider>();
    final item = sticker.toStoreItem();
    await _handlePurchase(item, sticker.name);
  }

  Future<void> _handlePurchase(StoreItem item, String name) async {
    final user = context.read<UserProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmPurchaseDialog(
        item: item,
        currentXP: user.totalXP,
      ),
    );

    if (confirmed == true && mounted) {
      final result = await user.purchase(item);
      if (result == PurchaseResult.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully unlocked $name!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (result == PurchaseResult.offline) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Offline: Connect to internet to purchase stickers.'),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (result == PurchaseResult.insufficientXP) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Not enough XP to unlock this item.'),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}

// ═══════════════════════════════════════════════════════
// _StorePackCard
// ═══════════════════════════════════════════════════════

class _StorePackCard extends StatefulWidget {
  final ServerStickerPack pack;
  final ValueChanged<ServerStickerPack> onPurchase;

  const _StorePackCard({required this.pack, required this.onPurchase});

  @override
  State<_StorePackCard> createState() => _StorePackCardState();
}

class _StorePackCardState extends State<_StorePackCard> {
  bool _hovered = false;

  void _showPackDetail() {
    final item = widget.pack.toStoreItem();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PackDetailSheet(
        item: item,
        onPurchase: () => widget.onPurchase(widget.pack),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final user = context.watch<UserProvider>();
    final owned = user.hasPurchased(widget.pack.id);
    final canAfford = user.totalXP >= widget.pack.xpCost;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _showPackDetail,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: _hovered
                ? AppColors.shadowMD(isDark: colors.isDark)
                : AppColors.shadowSM(isDark: colors.isDark),
          ),
          child: Column(
            children: [
              // Preview area (top)
              Container(
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.indigo.withValues(alpha: .08),
                      AppColors.indigoL.withValues(alpha: .03),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
                child: Stack(
                  children: [
                    // 2x2 sticker mosaic
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: widget.pack.stickerIds
                            .take(4)
                            .map(
                              (id) => Container(
                                decoration: BoxDecoration(
                                  color: colors.isDark
                                      ? Colors.white.withValues(alpha: .05)
                                      : Colors.black.withValues(alpha: .03),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: StickerWidget(
                                    serverSticker: StoreService
                                        .instance.data
                                        ?.stickerById(id),
                                    size: 38,
                                    animate: false,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    // Owned overlay
                    if (owned)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    // Featured badge
                    if (widget.pack.isFeatured)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFF6B35),
                                Color(0xFFFF8C42),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 9, color: Colors.white),
                              const SizedBox(width: 3),
                              Text(
                                'HOT',
                                style: AppTypography.micro.copyWith(
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Info area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.pack.name,
                        style: AppTypography.titleMD.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${widget.pack.stickerIds.length} stickers',
                        style: AppTypography.caption.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                      const Spacer(),

                      // Price button
                      owned
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.success.withValues(alpha: .10),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_rounded,
                                      size: 13, color: AppColors.success),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Owned',
                                    style: AppTypography.labelMD.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : GestureDetector(
                              onTap: canAfford
                                  ? () => widget.onPurchase(widget.pack)
                                  : null,
                              child: Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: canAfford
                                      ? AppColors.gradPrimary
                                      : null,
                                  color: !canAfford
                                      ? colors.surfaceElevated
                                      : null,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: canAfford
                                      ? AppColors.shadowPrimary()
                                      : [],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.bolt_rounded,
                                      size: 13,
                                      color: canAfford
                                          ? AppColors.gold
                                          : colors.textTertiary,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      canAfford
                                          ? '${widget.pack.xpCost} XP'
                                          : 'Need ${widget.pack.xpCost - user.totalXP} more XP',
                                      style: AppTypography.labelMD.copyWith(
                                        color: canAfford
                                            ? Colors.white
                                            : colors.textTertiary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
}

// ═══════════════════════════════════════════════════════
// _PackDetailSheet
// ═══════════════════════════════════════════════════════

class _PackDetailSheet extends StatelessWidget {
  final StoreItem item;
  final VoidCallback onPurchase;

  const _PackDetailSheet({required this.item, required this.onPurchase});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final user = context.watch<UserProvider>();
    final isPurchased = user.hasPurchased(item.id);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.2), blurRadius: 40),
        ],
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: colors.divider,
                borderRadius: BorderRadius.circular(2)),
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
                      Text(
                        item.name,
                        style: AppTypography.displayLG.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        item.description,
                        style: AppTypography.bodyMD.copyWith(
                            color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (!isPurchased)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onPurchase();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: AppColors.indigo.withValues(alpha: 0.4),
                    ),
                    child: Text(
                      'Unlock for ${item.xpCost} XP',
                      style: AppTypography.titleMD
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'COLLECTION UNLOCKED',
                      style: AppTypography.labelLG.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(),
          // Sticker Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(32),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 24,
                crossAxisSpacing: 24,
              ),
              itemCount: item.stickerIds.length,
              itemBuilder: (context, idx) {
                final id = item.stickerIds[idx];
                final store = context.read<StoreService>();
                final serverSticker = store.data?.stickerById(id);
                final localSticker = StickerRegistry.findById(id);

                if (serverSticker == null && localSticker == null) {
                  return const SizedBox.shrink();
                }

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
}

// ═══════════════════════════════════════════════════════
// _IndividualStickerCard
// ═══════════════════════════════════════════════════════

class _IndividualStickerCard extends StatefulWidget {
  final ServerSticker sticker;
  final ValueChanged<ServerSticker> onPurchase;

  const _IndividualStickerCard({required this.sticker, required this.onPurchase});

  @override
  State<_IndividualStickerCard> createState() => _IndividualStickerCardState();
}

class _IndividualStickerCardState extends State<_IndividualStickerCard> {
  bool _hovered = false;

  void _showDetail() {
    final item = widget.sticker.toStoreItem();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PackDetailSheet(
        item: item,
        onPurchase: () => widget.onPurchase(widget.sticker),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final user = context.watch<UserProvider>();
    final owned = user.hasPurchased(widget.sticker.id);
    final canAfford = user.totalXP >= widget.sticker.xpCost;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _showDetail,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: _hovered
                ? AppColors.shadowMD(isDark: colors.isDark)
                : AppColors.shadowSM(isDark: colors.isDark),
          ),
          child: Column(
            children: [
              // Preview area (top)
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.gold.withValues(alpha: .08),
                      AppColors.gold.withValues(alpha: .03),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: StickerWidget(
                        serverSticker: widget.sticker,
                        size: 72,
                        animate: _hovered || owned,
                      ),
                    ),
                    // Owned overlay
                    if (owned)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Info area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.sticker.name,
                        style: AppTypography.titleMD.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Single Sticker',
                        style: AppTypography.caption.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                      const Spacer(),

                      // Price button
                      owned
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.success.withValues(alpha: .10),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_rounded,
                                      size: 13, color: AppColors.success),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Owned',
                                    style: AppTypography.labelMD.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : GestureDetector(
                              onTap: canAfford
                                  ? () => widget.onPurchase(widget.sticker)
                                  : null,
                              child: Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: canAfford
                                      ? AppColors.gradPrimary
                                      : null,
                                  color: !canAfford
                                      ? colors.surfaceElevated
                                      : null,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: canAfford
                                      ? AppColors.shadowPrimary()
                                      : [],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.bolt_rounded,
                                      size: 13,
                                      color: canAfford
                                          ? AppColors.gold
                                          : colors.textTertiary,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      canAfford
                                          ? '${widget.sticker.xpCost} XP'
                                          : 'Need ${widget.sticker.xpCost - user.totalXP} more XP',
                                      style: AppTypography.labelMD.copyWith(
                                        color: canAfford
                                            ? Colors.white
                                            : colors.textTertiary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
}

// ═══════════════════════════════════════════════════════
// _ConfirmPurchaseDialog
// ═══════════════════════════════════════════════════════

class _ConfirmPurchaseDialog extends StatelessWidget {
  final StoreItem item;
  final int currentXP;

  const _ConfirmPurchaseDialog({
    required this.item,
    required this.currentXP,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final canAfford = currentXP >= item.xpCost;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Dialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28)),
        child: Container(
          padding: const EdgeInsets.all(32),
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(item.emoji,
                      style: const TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Unlock ${item.name}?',
                style: AppTypography.headlineSM
                    .copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              Text(
                'This will use ${item.xpCost} of your hard-earned XP. '
                'You will have ${currentXP - item.xpCost} XP remaining.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMD
                    .copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        'MAYBE LATER',
                        style: AppTypography.labelLG
                            .copyWith(color: colors.textTertiary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          canAfford ? () => Navigator.pop(context, true) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'UNLOCK NOW',
                        style: AppTypography.labelLG
                            .copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
              if (!canAfford) ...[
                const SizedBox(height: 16),
                Text(
                  'NOT ENOUGH XP (Need ${item.xpCost - currentXP} more)',
                  style: AppTypography.micro.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
