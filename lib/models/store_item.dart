enum StoreItemType { pack, individual }

class StoreItem {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final int xpCost;
  final StoreItemType type;
  final String? packId;
  // For individual: which pack it belongs to
  final List<String> stickerIds;
  // All stickers in this pack/item
  final bool isFeatured;

  const StoreItem({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.xpCost,
    required this.type,
    this.packId,
    required this.stickerIds,
    this.isFeatured = false,
  });
}
