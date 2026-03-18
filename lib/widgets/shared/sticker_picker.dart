import 'package:flutter/material.dart';
import '../../data/sticker_packs.dart';
import '../../models/sticker.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import 'sticker_widget.dart';

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

class _StickerPickerState extends State<StickerPicker>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _hoveredId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: StickerRegistry.packs.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;
    final packs = StickerRegistry.packs;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 380,
        height: 460,
        decoration: BoxDecoration(
          color: colors.isDark
              ? const Color(0xFF2A2725)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colors.isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.07),
            width: 0.75,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Text('Choose Sticker',
                    style: AppTypography.headline.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    )),
                  const Spacer(),
                  // Remove sticker button
                  if (widget.currentStickerId != null)
                    GestureDetector(
                      onTap: () => Navigator.pop(context, ''),
                      // '' means remove sticker
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.red.withValues(alpha: 0.2)),
                        ),
                        child: Text('Remove',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.red,
                            fontWeight: FontWeight.w600,
                          )),
                      ),
                    ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.pop(context, null),
                    child: Icon(Icons.close_rounded,
                        size: 20, color: colors.textSecondary),
                  ),
                ],
              ),
            ),

            // ── Pack tabs ────────────────────────────────────────
            const SizedBox(height: 12),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              indicatorColor: accent,
              indicatorWeight: 2,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: accent,
              unselectedLabelColor: colors.textTertiary,
              dividerColor: colors.divider,
              tabs: packs.map((pack) => Tab(
                child: Row(
                  children: [
                    Text(pack.emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 5),
                    Text(pack.name,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      )),
                  ],
                ),
              )).toList(),
            ),

            // ── Sticker grid ─────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: packs.map((pack) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                    itemCount: pack.stickers.length,
                    itemBuilder: (context, index) {
                      final sticker = pack.stickers[index];
                      final isSelected =
                          sticker.id == widget.currentStickerId;
                      final isHovered = _hoveredId == sticker.id;

                      return Tooltip(
                        message: sticker.name,
                        waitDuration:
                            const Duration(milliseconds: 400),
                        child: MouseRegion(
                          onEnter: (_) =>
                              setState(() => _hoveredId = sticker.id),
                          onExit: (_) =>
                              setState(() => _hoveredId = null),
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () =>
                                Navigator.pop(context, sticker.id),
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? accent.withValues(alpha: 0.12)
                                    : isHovered
                                        ? (colors.isDark
                                            ? Colors.white
                                                .withValues(alpha: 0.06)
                                            : Colors.black
                                                .withValues(alpha: 0.04))
                                        : Colors.transparent,
                                borderRadius:
                                    BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? accent.withValues(alpha: 0.5)
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: StickerWidget(
                                  sticker: sticker,
                                  size: 48,
                                  animate: isHovered || isSelected,
                                  // Only animate on hover/selected
                                  // to save performance
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
