import 'store_item.dart';

class ServerStickerPack {
  final String id;
  final String name;
  final String description;
  final int xpCost;
  final bool isActive;
  final bool isFeatured;
  final int displayOrder;
  final String emoji;
  final List<String> previewUrls;
  // Supabase Storage URLs
  final List<String> stickerIds;
  final List<String> tags;

  const ServerStickerPack({
    required this.id,
    required this.name,
    required this.description,
    required this.xpCost,
    required this.isActive,
    required this.isFeatured,
    required this.displayOrder,
    required this.emoji,
    required this.previewUrls,
    required this.stickerIds,
    required this.tags,
  });

  factory ServerStickerPack.fromJson(Map<String, dynamic> j) => ServerStickerPack(
        id: (j['id'] as String?) ?? '',
        name: (j['name'] as String?) ?? 'Unknown Pack',
        description: (j['description'] as String?) ?? '',
        xpCost: (j['xp_cost'] as int?) ?? 0,
        isActive: (j['is_active'] as bool?) ?? true,
        isFeatured: (j['is_featured'] as bool?) ?? false,
        displayOrder: (j['display_order'] as int?) ?? 0,
        emoji: (j['emoji'] as String?) ?? '📦',
        previewUrls: (j['preview_urls'] as List?)?.map((e) => e as String).toList() ?? [],
        stickerIds: (j['sticker_ids'] as List?)?.map((e) => e as String).toList() ?? [],
        tags: (j['tags'] as List?)?.map((e) => e as String).toList() ?? [],
      );

  // Convert to StoreItem for compatibility
  // with existing purchase logic
  StoreItem toStoreItem() => StoreItem(
        id: id,
        name: name,
        description: description,
        xpCost: xpCost,
        type: StoreItemType.pack,
        emoji: emoji,
        stickerIds: stickerIds,
        isFeatured: isFeatured,
        previewUrls: previewUrls,
      );
}
