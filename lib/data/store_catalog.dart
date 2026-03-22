import '../models/store_item.dart';

class StoreCatalog {
  // Starter pack — free
  static const freePackId = 'pack_free';

  static const List<StoreItem> items = [
    // ── FEATURED PACKS ──────────────────
    StoreItem(
      id: 'pack_work_purchase',
      name: 'Work Pack',
      description: '6 animated stickers for work & productivity',
      emoji: '💼',
      xpCost: 200,
      type: StoreItemType.pack,
      packId: 'pack_work',
      stickerIds: [
        'work_rocket',
        'work_target',
        'work_laptop',
        'work_bulb',
        'work_fire',
        'work_star',
      ],
      isFeatured: true,
    ),

    StoreItem(
      id: 'pack_premium_purchase',
      name: 'Premium Pack',
      description: 'Exclusive premium animated stickers',
      emoji: '💎',
      xpCost: 500,
      type: StoreItemType.pack,
      packId: 'pack_premium',
      stickerIds: [
        'premium_diamond',
        'premium_crown',
        'premium_trophy',
        'premium_magic',
        'premium_lightning',
        'premium_infinity',
      ],
      isFeatured: true,
    ),

    // ── ANIMATED PACKS ──────────────────
    StoreItem(
      id: 'pack_bears_purchase',
      name: 'Bears Pack',
      description: '15+ adorable animated bear stickers',
      emoji: '🐻',
      xpCost: 350,
      type: StoreItemType.pack,
      packId: 'pack_bears',
      stickerIds: [
        'bear_happy', 'bear_heart', 'bear_work', 'bear_sleep', 'bear_bath',
        'bear_laugh', 'bear_shock', 'bear_cry', 'bear_why', 'bear_security'
      ],
    ),

    StoreItem(
      id: 'pack_space_purchase',
      name: 'Space Pack',
      description: 'Journey into the cosmos with 18 stickers',
      emoji: '👨‍🚀',
      xpCost: 400,
      type: StoreItemType.pack,
      packId: 'pack_space',
      stickerIds: [
        'astronaut_smiling', 'astronaut_floating_bottle', 'astronaut_party_moon',
        'astronaut_driving_space_car', 'astronaut_rich_money', 'astronaut_shrug'
      ],
    ),

    StoreItem(
      id: 'pack_bees_purchase',
      name: 'Bees Pack',
      description: 'Buzzing with 13 happy bee stickers',
      emoji: '🐝',
      xpCost: 250,
      type: StoreItemType.pack,
      packId: 'pack_bees',
      stickerIds: [
        'bee_in_love', 'bee_laughing', 'bee_shocked', 'bee_sleeping',
        'bee_thumbs_up_giant', 'bee_winking'
      ],
    ),

    StoreItem(
      id: 'pack_home_purchase',
      name: 'Home Pack',
      description: 'Cozy living with 9 home appliance stickers',
      emoji: '🏠',
      xpCost: 200,
      type: StoreItemType.pack,
      packId: 'pack_home',
      stickerIds: [
        'blender_happy', 'fridge_hi_cookie', 'speaker_party', 'vacuum_on_my_way'
      ],
    ),
    
    StoreItem(
      id: 'pack_nature_purchase',
      name: 'Nature Pack',
      description: '14 calming flowers and plants',
      emoji: '🌵',
      xpCost: 250,
      type: StoreItemType.pack,
      packId: 'pack_nature',
      stickerIds: [
        'cactus_double_thumbs_up', 'daisy_kiss', 'flower_in_love', 'plant_running', 'rose_smiling'
      ],
    ),

    StoreItem(
      id: 'pack_weather_purchase',
      name: 'Weather Pack',
      description: '22 atmospheric weather stickers',
      emoji: '☁️',
      xpCost: 300,
      type: StoreItemType.pack,
      packId: 'pack_weather',
      stickerIds: [
        'sun_happy_plain', 'cloud_big_smile', 'weather_party_sun_cloud', 'weather_rainbow_sun_cloud'
      ],
    ),

    StoreItem(
      id: 'pack_ducks_purchase',
      name: 'Ducks Pack',
      description: 'Classic duck variety',
      emoji: '🦆',
      xpCost: 150,
      type: StoreItemType.pack,
      packId: 'pack_ducks',
      stickerIds: [
        'duck_happy', 'duck_enjoy', 'duck_fuck'
      ],
    ),

    StoreItem(
      id: 'pack_peaches_purchase',
      name: 'Peaches Pack',
      description: '25+ expressive peach character stickers',
      emoji: '🍑',
      xpCost: 450,
      type: StoreItemType.pack,
      packId: 'pack_peaches',
      stickerIds: [
        'peach_dance', 'peach_heart', 'peach_cheer', 'peach_laugh2', 'peach_sleep', 'peach_shock'
      ],
    ),

    StoreItem(
      id: 'pack_frogs_purchase',
      name: 'Frogs Pack',
      description: '16 hilarious frog stickers',
      emoji: '🐸',
      xpCost: 300,
      type: StoreItemType.pack,
      packId: 'pack_frogs',
      stickerIds: [
        'frog_thumbs_up_giant', 'frog_laughing', 'frog_thinking', 'frog_vomiting_rainbow', 'frog_muscular_glow'
      ],
    ),

    StoreItem(
      id: 'pack_pigeons_purchase',
      name: 'Pigeons Pack',
      description: '20+ cool urban pigeon stickers',
      emoji: '🐦',
      xpCost: 400,
      type: StoreItemType.pack,
      packId: 'pack_pigeons',
      stickerIds: [
        'pigeon_ok', 'pigeon_waving', 'pigeon_rich_smoking', 'pigeon_working_hard', 'pigeon_buff'
      ],
    ),

    StoreItem(
      id: 'pack_puppies_purchase',
      name: 'Puppies Pack',
      description: '16 cute dog stickers',
      emoji: '🐶',
      xpCost: 350,
      type: StoreItemType.pack,
      packId: 'pack_puppies',
      stickerIds: [
        'puppy_love', 'puppy_celebration', 'puppy_hopeful', 'puppy_rich', 'puppy_mischievous'
      ],
      isFeatured: true,
    ),

    // ── INDIVIDUALS ───────────────────
    StoreItem(
      id: 'ind_rocket',
      name: 'Rocket',
      description: 'Launch your tasks!',
      emoji: '🚀',
      xpCost: 50,
      type: StoreItemType.individual,
      packId: 'pack_work',
      stickerIds: ['work_rocket'],
    ),
    StoreItem(
      id: 'ind_party',
      name: 'Party',
      description: 'Celebrate!',
      emoji: '🎉',
      xpCost: 50,
      type: StoreItemType.individual,
      packId: 'pack_home',
      stickerIds: ['speaker_party'],
    ),
  ];

  static StoreItem? findById(String id) =>
      items.where((i) => i.id == id).firstOrNull;

  static List<StoreItem> get packs =>
      items.where((i) => i.type == StoreItemType.pack).toList();

  static List<StoreItem> get individuals =>
      items.where((i) => i.type == StoreItemType.individual).toList();

  static List<StoreItem> get featured =>
      items.where((i) => i.isFeatured).toList();
}
