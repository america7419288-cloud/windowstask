class StickerPack {
  final String id;           // e.g. 'pack_work'
  final String name;         // e.g. 'Work'
  final String emoji;        // e.g. '💼'
  final List<Sticker> stickers;

  const StickerPack({
    required this.id,
    required this.name,
    required this.emoji,
    required this.stickers,
  });
}

class Sticker {
  final String id;           // unique ID e.g. 'work_rocket'
  final String packId;       // which pack it belongs to
  final String assetPath;    // e.g. 'assets/stickers/pack_work/rocket.tgs'
  final String name;         // e.g. 'Rocket'
  final String emoji;        // fallback emoji if TGS fails to load

  const Sticker({
    required this.id,
    required this.packId,
    required this.assetPath,
    required this.name,
    required this.emoji,
  });
}
