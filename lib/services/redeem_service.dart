import 'dart:async';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/redeem_result.dart';
import '../services/security/device_fingerprint.dart';
import '../providers/user_provider.dart';
import '../models/xp_transaction.dart';
import '../models/store_item.dart';
import '../data/store_catalog.dart';
import '../services/security/secure_xp_store.dart';

class RedeemService {
  RedeemService._();
  static final instance = RedeemService._();

  // Format validation before hitting server
  static bool isValidFormat(String code) {
    final normalized = code.trim().toUpperCase();
    final regex = RegExp(r'^TASKI-[A-Z0-9]{4,8}-[A-Z0-9]{4,8}$');
    return regex.hasMatch(normalized);
  }

  // Format as user types:
  // auto-insert hyphens at positions 6, 11
  static String formatInput(String raw) {
    // Strip everything except alphanumeric
    final clean = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9-]'), '');

    // Auto-build TASKI-XXXX-XXXX
    final digits = clean.replaceAll('-', '');

    if (digits.length <= 5) {
      // Still typing "TASKI"
      return digits;
    } else if (digits.length <= 9) {
      // TASKI-XXXX
      return 'TASKI-${digits.substring(5)}';
    } else {
      // TASKI-XXXX-XXXX
      return 'TASKI-'
          '${digits.substring(5, 9)}-'
          '${digits.substring(9, min(17, digits.length))}';
    }
  }

  Future<RedeemResult> claimCode(String code) async {
    final normalized = code.trim().toUpperCase();

    // Client-side format check first
    if (!isValidFormat(normalized)) {
      return const RedeemResult.failure(
        error: RedeemError.invalidFormat,
        errorMessage: 'Code must be in format TASKI-XXXX-XXXX',
      );
    }

    // Get device fingerprint as user ID
    final userId = await DeviceFingerprint.get();

    try {
      final rpcName = dotenv.env['RPC_NAME'] ?? 'redeem_taski_code';
      
      // Call the Database RPC instead of an Edge Function
      final response = await Supabase.instance.client.rpc(
        rpcName,
        params: {
          'input_code': normalized,
          'input_user_id': userId,
        },
      ).timeout(
        const Duration(seconds: 15),
      );

      final result = response as Map<String, dynamic>;

      if (result['success'] == true) {
        final rewards = RedeemRewards.fromJson(result['rewards'] as Map<String, dynamic>);
        return RedeemResult.success(
          rewards: rewards,
          codeDescription: result['codeDescription'] as String?,
        );
      }

      // Map server errors to enum
      final errorCode = result['error'] as String? ?? '';
      return RedeemResult.failure(
        error: _mapError(errorCode),
        errorMessage: result['message'] as String? ?? 'Something went wrong',
      );
    } on TimeoutException {
      return const RedeemResult.failure(
        error: RedeemError.networkError,
        errorMessage: 'Connection timed out. Check your internet.',
      );
    } catch (e) {
      return const RedeemResult.failure(
        error: RedeemError.networkError,
        errorMessage: 'Could not connect to server. Check your internet.',
      );
    }
  }

  // Apply rewards locally after server confirms success
  Future<void> applyRewards(RedeemRewards rewards, UserProvider userProvider) async {
    // Grant XP
    if (rewards.xp > 0) {
      await userProvider.addXP(
        rewards.xp,
        source: XPSource.redeemCode,
      );
    }

    // Unlock sticker packs
    for (final packId in rewards.stickerPacks) {
      final item = StoreCatalog.items.firstWhere(
        (i) => i.id == packId,
        orElse: () => const StoreItem(
            id: '',
            name: '',
            description: '',
            emoji: '',
            xpCost: 0,
            type: StoreItemType.pack,
            stickerIds: []),
      );
      if (item.id.isNotEmpty) {
        await SecureXPStore.instance.unlockStickers(item.stickerIds);
        await SecureXPStore.instance.recordPurchase(item.id);
      }
    }

    // Unlock individual stickers
    if (rewards.stickerIds.isNotEmpty) {
      await SecureXPStore.instance.unlockStickers(rewards.stickerIds);
    }

    // Premium features (placeholder for now)
    for (final feature in rewards.premiumFeatures) {
      switch (feature) {
        case 'dark_aurora':
          // TODO: Implement dark theme variants if supported in the future
          break;
      }
    }

    userProvider.refresh();
  }

  RedeemError _mapError(String code) {
    switch (code) {
      case 'INVALID_FORMAT':
        return RedeemError.invalidFormat;
      case 'CODE_NOT_FOUND':
        return RedeemError.notFound;
      case 'ALREADY_CLAIMED':
        return RedeemError.alreadyClaimed;
      case 'CODE_EXPIRED':
        return RedeemError.expired;
      case 'CODE_EXHAUSTED':
        return RedeemError.exhausted;
      case 'CODE_DISABLED':
        return RedeemError.disabled;
      default:
        return RedeemError.serverError;
    }
  }
}
