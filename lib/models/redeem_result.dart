// What the server returns on success
class RedeemRewards {
  final int xp;
  final List<String> stickerPacks;
  final List<String> stickerIds;
  final List<String> premiumFeatures;

  const RedeemRewards({
    this.xp = 0,
    this.stickerPacks = const [],
    this.stickerIds = const [],
    this.premiumFeatures = const [],
  });

  bool get isEmpty =>
      xp == 0 &&
      stickerPacks.isEmpty &&
      stickerIds.isEmpty &&
      premiumFeatures.isEmpty;

  int get totalItems =>
      stickerPacks.length +
      stickerIds.length +
      premiumFeatures.length;

  factory RedeemRewards.fromJson(Map<String, dynamic> j) => RedeemRewards(
        xp: j['xp'] as int? ?? 0,
        stickerPacks: (j['sticker_packs'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        stickerIds: (j['sticker_ids'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        premiumFeatures: (j['premium_features'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );
}

enum RedeemError {
  invalidFormat,
  notFound,
  alreadyClaimed,
  expired,
  exhausted,
  disabled,
  networkError,
  serverError,
}

class RedeemResult {
  final bool success;
  final RedeemRewards? rewards;
  final String? codeDescription;
  final RedeemError? error;
  final String? errorMessage;

  const RedeemResult.success({
    required this.rewards,
    this.codeDescription,
  })  : success = true,
        error = null,
        errorMessage = null;

  const RedeemResult.failure({
    required this.error,
    required this.errorMessage,
  })  : success = false,
        rewards = null,
        codeDescription = null;
}
