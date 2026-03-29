import 'server_sticker_pack.dart';
import 'store_item.dart';
import 'sticker.dart';

class ServerSticker {
  final String id;
  final String name;
  final String emoji;
  final String? packId;
  final int xpCost;
  final String? storagePath;
  final String? previewUrl;
  // webp thumbnail
  final String? animationUrl;
  // .tgs file URL
  final bool isActive;
  final bool isPremium;
  final int displayOrder;

  const ServerSticker({
    required this.id,
    required this.name,
    required this.emoji,
    this.packId,
    required this.xpCost,
    this.storagePath,
    this.previewUrl,
    this.animationUrl,
    required this.isActive,
    required this.isPremium,
    required this.displayOrder,
  });

  factory ServerSticker.fromJson(Map<String, dynamic> j) => ServerSticker(
        id: (j['id'] as String?) ?? '',
        name: (j['name'] as String?) ?? 'Sticker',
        emoji: (j['emoji'] as String?) ?? '✨',
        packId: j['pack_id'] as String?,
        xpCost: (j['xp_cost'] as int?) ?? 0,
        storagePath: j['storage_path'] as String?,
        previewUrl: j['preview_url'] as String?,
        animationUrl: j['animation_url'] as String?,
        isActive: (j['is_active'] as bool?) ?? true,
        isPremium: (j['is_premium'] as bool?) ?? false,
        displayOrder: (j['display_order'] as int?) ?? 0,
      );

  StoreItem toStoreItem() => StoreItem(
        id: id,
        name: name,
        description: 'Single sticker from the $id collection.',
        emoji: emoji,
        xpCost: xpCost,
        type: StoreItemType.individual,
        packId: packId,
        stickerIds: [id],
      );

  Sticker toSticker() => Sticker(
        id: id,
        packId: packId ?? 'purchased',
        assetPath: '', // Always use server bytes
        name: name,
        emoji: emoji,
      );
}

class StoreData {
  final List<ServerStickerPack> packs;
  final List<ServerSticker> stickers;
  final Map<String, dynamic> config;
  final DateTime fetchedAt;

  const StoreData({
    required this.packs,
    required this.stickers,
    required this.config,
    required this.fetchedAt,
  });

  List<ServerStickerPack> get featuredPacks => packs.where((p) => p.isFeatured).toList();

  ServerStickerPack? packById(String id) => packs.where((p) => p.id == id).firstOrNull;

  ServerSticker? stickerById(String id) => stickers.where((s) => s.id == id).firstOrNull;

  String get bannerText => config['store_banner_text'] as String? ?? 'Complete tasks to earn XP!';
}
