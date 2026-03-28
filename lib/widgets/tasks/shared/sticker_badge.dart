import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/sticker_packs.dart';
import '../../shared/sticker_widget.dart';
import '../../../models/app_settings.dart';
import '../../../services/store_service.dart';

class StickerBadge extends StatelessWidget {
  final String stickerId;
  const StickerBadge({super.key, required this.stickerId});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreService>();
    final serverSticker = store.data?.stickerById(stickerId);
    final localSticker = StickerRegistry.findById(stickerId);
    
    if (serverSticker == null && localSticker == null) return const SizedBox.shrink();

    final stickerSizeEnum = context.watch<SettingsProvider>().stickerSize;
    double scale;
    switch (stickerSizeEnum) {
      case StickerSize.small: scale = 0.7; break;
      case StickerSize.normal: scale = 1.0; break;
      case StickerSize.large: scale = 1.35; break;
      case StickerSize.jumbo: scale = 1.8; break;
    }

    final double outerSize = 32 * scale;
    final double innerSize = 25 * scale;

    return Container(
      width: outerSize, height: outerSize,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A2725)
            : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8 * scale,
            offset: Offset(0, 2 * scale),
          ),
        ],
      ),
      child: ClipOval(
        child: Padding(
          padding: EdgeInsets.all(4 * scale),
          child: StickerWidget(
            serverSticker: serverSticker,
            localSticker: localSticker,
            size: innerSize,
            animate: true,
          ),
        ),
      ),
    );
  }
}
