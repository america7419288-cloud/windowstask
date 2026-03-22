import '../models/sticker.dart';
import 'app_stickers.dart';
import '../services/store_service.dart';

class StickerRegistry {
  static const List<StickerPack> packs = [
    // Stickers are now fetched from Supabase Store
  ];

  static final Map<String, Sticker> _idLookup = {
    for (final pack in packs)
      for (final sticker in pack.stickers)
        sticker.id: sticker,
  };

  static List<Sticker> get allStickers {
    final list = <Sticker>[];
    list.addAll(AppStickers.allStickers);
    
    // Add purchased stickers from store
    final storeStickers = StoreService.instance.data?.stickers ?? [];
    for (final s in storeStickers) {
      list.add(s.toSticker());
    }
    return list;
  }

  static Sticker? findById(String id) {
    // 1. Check AppStickers (Sync)
    final local = AppStickers.getById(id);
    if (local != null) return local;

    // 2. Check StoreService Data (Sync)
    final server = StoreService.instance.data?.stickerById(id);
    if (server != null) return server.toSticker();

    return null;
  }

  static List<String> getStickerIdsByPackId(String packId) {
    try {
      final pack = packs.firstWhere((p) => p.id == packId);
      return pack.stickers.map((s) => s.id).toList();
    } catch (_) {
      return [];
    }
  }
}
