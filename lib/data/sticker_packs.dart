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
        Sticker(id: 'react_anger2', packId: 'pack_reactions', assetPath: 'assets/stickers/angry2.tgs', name: 'Anger 2', emoji: '🤬'),
        Sticker(id: 'react_sleep',  packId: 'pack_reactions', assetPath: 'assets/stickers/sleep.tgs',  name: 'Sleep',  emoji: '😴'),
      ],
    ),
    StickerPack(
      id: 'pack_bear',
      name: 'Bear',
      emoji: '🐻',
      stickers: [
        Sticker(id: 'bear_basic',      packId: 'pack_bear', assetPath: 'assets/stickers/deco/bear.tgs',           name: 'Bear',       emoji: '🐻'),
        Sticker(id: 'bear_bath',       packId: 'pack_bear', assetPath: 'assets/stickers/deco/bear_bath.tgs',      name: 'Bath',       emoji: '🛀'),
        Sticker(id: 'bear_care',       packId: 'pack_bear', assetPath: 'assets/stickers/deco/bear_care.tgs',      name: 'Care',       emoji: '🩹'),
        Sticker(id: 'bear_care2',      packId: 'pack_bear', assetPath: 'assets/stickers/deco/bear_care2.tgs',     name: 'Care 2',     emoji: '💝'),
        Sticker(id: 'bear_cry',        packId: 'pack_bear', assetPath: 'assets/stickers/deco/bear_cry.tgs',       name: 'Cry',        emoji: '😢'),
        Sticker(id: 'bear_greed',      packId: 'pack_bear', assetPath: 'assets/stickers/deco/bear_greed.tgs',     name: 'Greed',      emoji: '🤑'),
        Sticker(id: 'bear_happy',      packId: 'pack_bear', assetPath: 'assets/stickers/deco/bear_happy.tgs',     name: 'Happy',      emoji: '😊'),
        Sticker(id: 'bear_heart',      packId: 'pack_bear', assetPath: 'assets/stickers/deco/bear_heart.tgs',     name: 'Heart',      emoji: '❤️'),
        Sticker(id: 'bear_honey',      packId: 'pack_bear', assetPath: 'assets/stickers/deco/bear_honey.tgs',     name: 'Honey',      emoji: '🍯'),
        Sticker(id: 'bear_laugh',      packId: 'pack_bear', assetPath: 'assets/stickers/deco/bear_laugh.tgs',     name: 'Laugh',      emoji: '😄'),
        Sticker(id: 'bear_productive', packId: 'pack_bear', assetPath: 'assets/stickers/deco/bear_pproductive.tgs', name: 'Productive', emoji: '📈'),
        Sticker(id: 'bear_right',      packId: 'pack_bear', assetPath: 'assets/stickers/deco/bear_right.tgs',     name: 'Right',      emoji: '👉'),
        Sticker(id: 'bear_security',   packId: 'pack_bear', assetPath: 'assets/stickers/deco/bear_security.tgs',  name: 'Security',   emoji: '🛡️'),
        Sticker(id: 'bear_shock',      packId: 'pack_bear', assetPath: 'assets/stickers/deco/bear_shock.tgs',     name: 'Shock',      emoji: '😲'),
        Sticker(id: 'bear_sleep',      packId: 'pack_bear', assetPath: 'assets/stickers/deco/bear_sleep.tgs',     name: 'Sleep',      emoji: '😴'),
        Sticker(id: 'bear_why',        packId: 'pack_bear', assetPath: 'assets/stickers/deco/bear_why.tgs',       name: 'Why',        emoji: '🤷'),
        Sticker(id: 'bear_why2',       packId: 'pack_bear', assetPath: 'assets/stickers/deco/bear_why2.tgs',      name: 'Why 2',      emoji: '🤔'),
        Sticker(id: 'bear_work',       packId: 'pack_bear', assetPath: 'assets/stickers/deco/bear_work.tgs',      name: 'Work',       emoji: '💻'),
      ],
    ),
    StickerPack(
      id: 'pack_peach',
      name: 'Peach',
      emoji: '🍑',
      stickers: [
        Sticker(id: 'peach_angry',  packId: 'pack_peach', assetPath: 'assets/stickers/deco/angry_peach.tgs',  name: 'Angry',   emoji: '😠'),
        Sticker(id: 'peach_happy',  packId: 'pack_peach', assetPath: 'assets/stickers/deco/happy_peach.tgs',  name: 'Happy',   emoji: '🏮'),
        Sticker(id: 'peach_cheer',  packId: 'pack_peach', assetPath: 'assets/stickers/deco/peach_cheer.tgs',  name: 'Cheer',   emoji: '📣'),
        Sticker(id: 'peach_crash',  packId: 'pack_peach', assetPath: 'assets/stickers/deco/peach_crash.tgs',  name: 'Crash',   emoji: '💥'),
        Sticker(id: 'peach_cry',    packId: 'pack_peach', assetPath: 'assets/stickers/deco/peach_cry.tgs',    name: 'Cry',     emoji: '😫'),
        Sticker(id: 'peach_dance',  packId: 'pack_peach', assetPath: 'assets/stickers/deco/peach_dance.tgs',  name: 'Dance',   emoji: '💃'),
        Sticker(id: 'peach_heart',  packId: 'pack_peach', assetPath: 'assets/stickers/deco/peach_heart.tgs',  name: 'Heart',   emoji: '💖'),
        Sticker(id: 'peach_heart2', packId: 'pack_peach', assetPath: 'assets/stickers/deco/peach_heart2.tgs', name: 'Heart 2', emoji: '💕'),
        Sticker(id: 'peach_laugh',  packId: 'pack_peach', assetPath: 'assets/stickers/deco/peach_laugh2.tgs', name: 'Laugh',   emoji: '🤣'),
        Sticker(id: 'peach_love',   packId: 'pack_peach', assetPath: 'assets/stickers/deco/peach_love.tgs',   name: 'Love',    emoji: '😍'),
        Sticker(id: 'peach_shock',  packId: 'pack_peach', assetPath: 'assets/stickers/deco/peach_shock.tgs',  name: 'Shock',   emoji: '😱'),
        Sticker(id: 'peach_shock2', packId: 'pack_peach', assetPath: 'assets/stickers/deco/peach_shock2.tgs', name: 'Shock 2', emoji: '🤯'),
        Sticker(id: 'peach_sleep',  packId: 'pack_peach', assetPath: 'assets/stickers/deco/peach_sleep.tgs',  name: 'Sleep',   emoji: '🥱'),
        Sticker(id: 'peach_stop',   packId: 'pack_peach', assetPath: 'assets/stickers/deco/peach_stop.tgs',   name: 'Stop',    emoji: '✋'),
        Sticker(id: 'peach_why',    packId: 'pack_peach', assetPath: 'assets/stickers/deco/peach_why.tgs',    name: 'Why',     emoji: '❓'),
        Sticker(id: 'peach_womit',  packId: 'pack_peach', assetPath: 'assets/stickers/deco/peach_womit.tgs',  name: 'Womit',   emoji: '🤮'),
        Sticker(id: 'peach_sad',    packId: 'pack_peach', assetPath: 'assets/stickers/deco/sad_peach.tgs',    name: 'Sad',     emoji: '😔'),
      ],
    ),
    StickerPack(
      id: 'pack_duck',
      name: 'Duck',
      emoji: '🦆',
      stickers: [
        Sticker(id: 'duck_enjoy', packId: 'pack_duck', assetPath: 'assets/stickers/deco/duck_enjoy.tgs', name: 'Enjoy',  emoji: '🍹'),
        Sticker(id: 'duck_fuck',  packId: 'pack_duck', assetPath: 'assets/stickers/deco/duck_fuck.tgs',  name: 'Angry',  emoji: '🖕'),
        Sticker(id: 'duck_happy', packId: 'pack_duck', assetPath: 'assets/stickers/deco/duck_happy.tgs', name: 'Happy',  emoji: '😁'),
      ],
    ),
    StickerPack(
      id: 'pack_misc',
      name: 'Misc',
      emoji: '✨',
      stickers: [
        Sticker(id: 'misc_funny',     packId: 'pack_misc', assetPath: 'assets/stickers/deco/funny.tgs',          name: 'Funny',     emoji: '🤡'),
        Sticker(id: 'misc_completed', packId: 'pack_misc', assetPath: 'assets/stickers/deco/task_completed.tgs', name: 'Completed', emoji: '🎯'),
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
