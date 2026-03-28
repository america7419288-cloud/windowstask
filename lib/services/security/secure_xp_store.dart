import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/xp_transaction.dart';
import 'encryption_service.dart';
import 'device_fingerprint.dart';

class SecureXPStore {
  SecureXPStore._();
  static final instance = SecureXPStore._();

  List<XPTransaction> _ledger = [];
  List<String> _unlockedStickerIds = [];
  List<String> _purchasedItemIds = [];

  // Obfuscated storage keys
  // (SHA-256 prefixes of actual names)
  static const _ledgerKey   = 'a3f7c2e9';
  static const _stickersKey = 'b8d4f1a6';
  static const _itemsKey    = 'c5e2g7h3';
  static const _checksumKey = 'd9f3k2m8';

  // Computed from verified transactions
  int get totalXP {
    return _ledger
        .where((t) => t.isValid)
        .fold(0, (sum, t) => sum + t.amount);
  }

  List<String> get unlockedStickerIds =>
      List.unmodifiable(_unlockedStickerIds);

  List<String> get purchasedItemIds =>
      List.unmodifiable(_purchasedItemIds);

  String? _cachedFingerprint;
  
  Future<void> init() async {
    _cachedFingerprint = await DeviceFingerprint.get();
    // Note: IntegrityResult is handled by IntegrityChecker
    await loadAndVerify();
  }

  // ── XP Operations ─────────────────────

  Future<bool> addXP({
    required int amount,
    required XPSource source,
    String? taskId,
    String? achievementId,
  }) async {
    // Validate amount — reject suspicious
    // (1M is plenty for migration/regular play)
    if (amount <= 0 || amount > 1000000) {
      return false;
    }

    final transaction = XPTransaction.create(
      amount: amount,
      source: source,
      taskId: taskId,
      achievementId: achievementId,
    );

    _ledger.add(transaction);
    await _save();
    return true;
  }

  Future<bool> spendXP(int amount) async {
    if (totalXP < amount) return false;
    // Spending is a negative transaction
    final transaction = XPTransaction.create(
      amount: -amount,
      source: XPSource.taskCompletion,
      // For now using taskCompletion as a placeholder for "purchase"
    );
    _ledger.add(transaction);
    await _save();
    return true;
  }

  // ── Sticker Operations ─────────────────

  Future<void> unlockStickers(List<String> stickerIds) async {
    for (final id in stickerIds) {
      if (!_unlockedStickerIds.contains(id)) {
        _unlockedStickerIds.add(id);
      }
    }
    await _save();
  }

  Future<void> recordPurchase(String itemId) async {
    if (!_purchasedItemIds.contains(itemId)) {
      _purchasedItemIds.add(itemId);
    }
    await _save();
  }

  bool isStickerUnlocked(String id) =>
      _unlockedStickerIds.contains(id);

  bool isItemPurchased(String id) =>
      _purchasedItemIds.contains(id);

  // ── Persistence ────────────────────────

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final enc = EncryptionService.instance;

    // Encrypt ledger
    final ledgerJson = jsonEncode(_ledger.map((t) => t.toJson()).toList());
    await prefs.setString(_ledgerKey, enc.encrypt(ledgerJson));

    // Encrypt sticker data
    final stickerJson = jsonEncode(_unlockedStickerIds);
    await prefs.setString(_stickersKey, enc.encrypt(stickerJson));

    // Encrypt purchased items
    final itemsJson = jsonEncode(_purchasedItemIds);
    await prefs.setString(_itemsKey, enc.encrypt(itemsJson));

    // Store checksum for integrity check
    final checksum = _computeChecksum();
    await prefs.setString(_checksumKey, enc.encrypt(checksum));
  }

  Future<IntegrityResult> loadAndVerify() async {
    final prefs = await SharedPreferences.getInstance();
    final enc = EncryptionService.instance;
    bool tampered = false;

    // ── Load ledger ─────────────────────
    final encLedger = prefs.getString(_ledgerKey);
    if (encLedger != null) {
      try {
        final json = enc.decrypt(encLedger);
        final list = jsonDecode(json) as List;
        _ledger = list.map((j) => XPTransaction.fromJson(j as Map<String, dynamic>)).toList();

        // Verify all transactions
        final invalidCount = _ledger.where((t) => !t.isValid).length;
        if (invalidCount > 0) {
          _ledger.removeWhere((t) => !t.isValid);
          tampered = true;
        }
      } catch (_) {
        _ledger = [];
        tampered = true;
      }
    }

    // ── Load stickers ───────────────────
    final encStickers = prefs.getString(_stickersKey);
    if (encStickers != null) {
      try {
        final json = enc.decrypt(encStickers);
        _unlockedStickerIds = (jsonDecode(json) as List).map((e) => e as String).toList();
      } catch (_) {
        _unlockedStickerIds = [];
        tampered = true;
      }
    }

    // ── Load purchased items ────────────
    final encItems = prefs.getString(_itemsKey);
    if (encItems != null) {
      try {
        final json = enc.decrypt(encItems);
        _purchasedItemIds = (jsonDecode(json) as List).map((e) => e as String).toList();
      } catch (_) {
        _purchasedItemIds = [];
        tampered = true;
      }
    }

    // ── Verify checksum ─────────────────
    final encChecksum = prefs.getString(_checksumKey);
    if (encChecksum != null) {
      try {
        final stored = enc.decrypt(encChecksum);
        final computed = _computeChecksum();
        if (stored != computed) {
          tampered = true;
        }
      } catch (_) {
        tampered = true;
      }
    }

    return tampered ? IntegrityResult.tampered : IntegrityResult.ok;
  }

  String _computeChecksum() {
    // HMAC of ledger + stickers + items
    // Use device fingerprint as the dynamic secret instead of a hardcoded string
    final secret = _cachedFingerprint ?? 'taski_runtime_fallback_key';
    final data = '${_ledger.map((t) => t.id).join(",")}'
        '|${_unlockedStickerIds.join(",")}'
        '|${_purchasedItemIds.join(",")}';

    final key = utf8.encode(secret);
    final bytes = utf8.encode(data);
    final hmac = Hmac(sha256, key);
    return hmac.convert(bytes).toString();
  }

  // ── Audit log ──────────────────────────

  List<XPTransaction> get auditLog => List.unmodifiable(_ledger);

  // Get XP earned on a specific date
  int xpEarnedOn(DateTime date) {
    final dateKey = '${date.year}-${date.month}-${date.day}';
    return _ledger
        .where((t) =>
            t.isValid &&
            t.amount > 0 &&
            '${t.earnedAt.year}-${t.earnedAt.month}-${t.earnedAt.day}' == dateKey)
        .fold(0, (sum, t) => sum + t.amount);
  }
}

enum IntegrityResult { ok, tampered }
