import 'package:flutter/material.dart';
import '../../data/sticker_packs.dart';
import '../../models/sticker.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import 'sticker_widget.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../utils/constants.dart';
import '../../data/store_catalog.dart';
import '../../data/app_stickers.dart';
import '../../models/server_sticker.dart';
import '../../services/store_service.dart';

class StickerPicker extends StatefulWidget {
  final String? currentStickerId;

  const StickerPicker({super.key, this.currentStickerId});

  // Show as a modal dialog — returns selected sticker ID or null
  static Future<String?> show(
    BuildContext context, {
    String? currentStickerId,
  }) {
    return showDialog<String?>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => StickerPicker(currentStickerId: currentStickerId),
    );
  }

  @override
  State<StickerPicker> createState() => _StickerPickerState();
}

class _StickerPickerState extends State<StickerPicker> {
  String? _hoveredId;
  List<Sticker> _allStickers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStickers();
    });
  }

  @override
  void didUpdateWidget(StickerPicker old) {
    super.didUpdateWidget(old);
    if (old.currentStickerId != widget.currentStickerId) {
      _loadStickers();
    }
  }

  void _loadStickers() {
    final user = context.read<UserProvider>();
    final store = context.read<StoreService>();

    // 1. Get default stickers
    final defaultStickers = AppStickers.allStickers;

    // 2. Get purchased stickers from store
    final purchasedStickers = (store.data?.stickers ?? [])
        .where((s) => user.hasUnlocked(s.id))
        .map((s) => s.toSticker())
        .toList();

    // 3. Combine and remove duplicates (by id)
    final Map<String, Sticker> uniqueMap = {};
    for (final s in defaultStickers) {
      uniqueMap[s.id] = s;
    }
    for (final s in purchasedStickers) {
      uniqueMap[s.id] = s;
    }

    if (mounted) {
      setState(() {
        _allStickers = uniqueMap.values.toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;
    final store = context.watch<StoreService>();

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 380,
        height: 520, 
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.divider, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Text('My Stickers',
                    style: AppTypography.headlineSmall.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                    )),
                  const Spacer(),
                  if (widget.currentStickerId != null)
                    TextButton(
                      onPressed: () => Navigator.pop(context, ''),
                      child: const Text('Clear', style: TextStyle(color: AppColors.red)),
                    ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.pop(context, null),
                    child: Icon(Icons.close_rounded, color: colors.textSecondary),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ── Sticker grid ─────────────────────────────────────
            Expanded(
              child: _allStickers.isEmpty 
                ? _buildEmptyState(colors)
                : GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1,
                    ),
                    itemCount: _allStickers.length,
                    itemBuilder: (context, index) {
                      final sticker = _allStickers[index];
                      final isSelected = sticker.id == widget.currentStickerId;
                      final isHovered = _hoveredId == sticker.id;

                      return MouseRegion(
                        onEnter: (_) => setState(() => _hoveredId = sticker.id),
                        onExit: (_) => setState(() => _hoveredId = null),
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context, sticker.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? accent.withOpacity(0.12)
                                  : isHovered
                                      ? colors.surfaceElevated
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? accent : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: StickerWidget(
                                localSticker: sticker.assetPath.isNotEmpty ? sticker : null,
                                serverSticker: sticker.assetPath.isEmpty ? store.data?.stickerById(sticker.id) : null,
                                size: 64,
                                animate: isHovered || isSelected,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            ),

            // ── Footer / Store Link ──────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, null);
                  context.read<NavigationProvider>().selectNav(AppConstants.navStore);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.surfaceElevated,
                  foregroundColor: accent,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Unlock more in the Store'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppColorsExtension colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: colors.textQuaternary),
          const SizedBox(height: 16),
          Text(
            'No stickers yet',
            style: AppTypography.titleMedium.copyWith(color: colors.textTertiary),
          ),
        ],
      ),
    );
  }
}
