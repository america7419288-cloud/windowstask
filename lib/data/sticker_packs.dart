import '../models/sticker.dart';

class StickerRegistry {
  static const List<StickerPack> packs = [
    StickerPack(
      id: 'pack_reactions',
      name: 'Reactions',
      emoji: '😀',
      stickers: [
        Sticker(id: 'react_laugh',  packId: 'pack_reactions', assetPath: 'assets/stickers/laugh.tgs',  name: 'Laugh',  emoji: '😂'),
        Sticker(id: 'react_laugh2', packId: 'pack_reactions', assetPath: 'assets/stickers/laugh2.tgs', name: 'Laugh 2', emoji: '🤣'),
        Sticker(id: 'react_heart',  packId: 'pack_reactions', assetPath: 'assets/stickers/heart.tgs',  name: 'Heart',  emoji: '❤️'),
        Sticker(id: 'react_heart2', packId: 'pack_reactions', assetPath: 'assets/stickers/heart2.tgs', name: 'Heart 2', emoji: '💖'),
        Sticker(id: 'react_angry',  packId: 'pack_reactions', assetPath: 'assets/stickers/angry.tgs',  name: 'Angry',  emoji: '😡'),
        Sticker(id: 'react_anger2', packId: 'pack_reactions', assetPath: 'assets/stickers/anger2.tgs', name: 'Anger 2', emoji: '🤬'),
        Sticker(id: 'react_sleep',  packId: 'pack_reactions', assetPath: 'assets/stickers/sleep.tgs',  name: 'Sleep',  emoji: '😴'),
      ],
    ),
  ];

  // Lookup a sticker by ID from any pack
  static Sticker? findById(String id) {
    for (final pack in packs) {
      for (final sticker in pack.stickers) {
        if (sticker.id == id) return sticker;
      }
    }
    return null;
  }
}
