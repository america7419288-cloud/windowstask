import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/sticker_packs.dart';
import '../models/user_profile.dart';
import '../models/achievement.dart';
import '../models/task.dart';
import '../models/store_item.dart';
import '../models/xp_transaction.dart';
import '../services/security/encryption_service.dart';
import '../services/security/xp_cooldown_tracker.dart';
import '../services/security/secure_xp_store.dart';
import '../services/security/integrity_checker.dart';
import '../services/storage_service.dart';

class UserProvider extends ChangeNotifier {
  UserProfile? _profile;
  UserProfile? get profile => _profile;

  bool get hasProfile =>
      _profile != null && _profile!.hasCompletedOnboarding;

  int? _pendingMilestone;
  int? get pendingMilestone => _pendingMilestone;

  bool _pendingShieldUsed = false;
  bool get pendingShieldUsed => _pendingShieldUsed;

  void clearPendingMilestone() {
    _pendingMilestone = null;
    notifyListeners();
  }

  void clearPendingShieldUsed() {
    _pendingShieldUsed = false;
    notifyListeners();
  }

  bool hasUnlocked(String stickerId) =>
      SecureXPStore.instance.isStickerUnlocked(stickerId);

  bool hasPurchased(String itemId) =>
      SecureXPStore.instance.isItemPurchased(itemId);

  Future<PurchaseResult> purchase(StoreItem item) async {
    if (_profile == null) return PurchaseResult.noProfile;
    if (totalXP < item.xpCost) return PurchaseResult.insufficientXP;
    if (hasPurchased(item.id)) return PurchaseResult.alreadyOwned;

    // Spend XP atomically
    final spent = await SecureXPStore.instance.spendXP(item.xpCost);
    if (!spent) return PurchaseResult.insufficientXP;

    // Unlock stickers
    await SecureXPStore.instance.unlockStickers(item.stickerIds);

    // If it's a pack, unlock EVERYTHING in that pack from the registry
    if (item.type == StoreItemType.pack && item.packId != null) {
      final allIds = StickerRegistry.getStickerIdsByPackId(item.packId!);
      await SecureXPStore.instance.unlockStickers(allIds);
    }

    // Master Unlock logic
    if (item.type == StoreItemType.all) {
      final allStickers = StickerRegistry.allStickers.map((s) => s.id).toList();
      await SecureXPStore.instance.unlockStickers(allStickers);
    }

    // Record purchase
    await SecureXPStore.instance.recordPurchase(item.id);

    notifyListeners();
    return PurchaseResult.success;
  }

  String get firstName => _profile?.firstName ?? 'Friend';

  int get totalXP => SecureXPStore.instance.totalXP;
  int get streak => _profile?.currentStreak ?? 0;
  int get streakShields => _profile?.streakShields ?? 0;

  /// XP level calculation (every 500 XP = 1 level)
  int get level => (totalXP / 500).floor() + 1;
  double get levelProgress => (totalXP % 500) / 500;

  // Obfuscated profile storage key
  static const _profileKey = 'e7a3c9f2';

  Future<void> init([BuildContext? context]) async {
    // 1. Init encryption first
    await EncryptionService.instance.init();

    // 2. Init cooldown tracker
    await XPCooldownTracker.instance.init();

    // 3. Init secure store
    await SecureXPStore.instance.init();

    // 4. Load user profile (name, avatar, streak)
    // XP now comes from SecureXPStore
    final prefs = await SharedPreferences.getInstance();
    String? profileJson = prefs.getString(_profileKey);
    
    if (profileJson == null) {
      // ── MIGRATION FROM OLD STORAGE ──
      final oldData = StorageService.instance.getProfile();
      if (oldData != null) {
        try {
          _profile = UserProfile.fromJson(oldData);
          // Migrate XP if ledger is empty
          if (_profile!.totalXP > 0 && SecureXPStore.instance.totalXP == 0) {
            await SecureXPStore.instance.addXP(
              amount: _profile!.totalXP,
              source: XPSource.migration,
            );
          }
          // Migrate stickers/items
          if (_profile!.unlockedStickerIds.isNotEmpty) {
            await SecureXPStore.instance.unlockStickers(_profile!.unlockedStickerIds);
          }
          if (_profile!.purchasedItemIds.isNotEmpty) {
            for (final id in _profile!.purchasedItemIds) {
              await SecureXPStore.instance.recordPurchase(id);
            }
          }
          // Save to new secure key
          await _persist();
        } catch (_) {}
      }
    } else {
      try {
        _profile = UserProfile.fromJson(jsonDecode(profileJson));
      } catch (_) {}
    }

    // ── NEW USER STARTER BONUS ──
    // Grant if ledger is empty (existing users who didn't get it yet)
    if (SecureXPStore.instance.totalXP == 0 && SecureXPStore.instance.auditLog.isEmpty) {
      await SecureXPStore.instance.addXP(
        amount: 1000,
        source: XPSource.migration,
      );
    }

    // 5. Run integrity check
    if (context != null) {
      await IntegrityChecker.runOnStartup(context);
    }

    await _updateDailyStreak();
    notifyListeners();
  }

  Future<void> saveProfile(UserProfile profile) async {
    _profile = profile;
    await _persist();
    notifyListeners();
  }

  Future<void> addXP(int amount, {
    String? reason,
    XPSource source = XPSource.taskCompletion,
    String? taskId,
  }) async {
    if (_profile == null) return;
    await SecureXPStore.instance.addXP(
      amount: amount,
      source: source,
      taskId: taskId,
    );
    notifyListeners();
  }

  Future<void> earnBadge(String badgeId) async {
    if (_profile == null) return;
    if (_profile!.earnedBadgeIds.contains(badgeId)) return;

    final badges = [..._profile!.earnedBadgeIds, badgeId];
    _profile = _profile!.copyWith(earnedBadgeIds: badges);

    final achievement = Achievements.findById(badgeId);
    if (achievement != null) {
      await addXP(
        achievement.xpReward, 
        reason: achievement.name,
        source: XPSource.achievementUnlock,
      );
    }
    await _persist();
    notifyListeners();
  }

  Future<void> _updateDailyStreak() async {
    if (_profile == null) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = _profile!.lastActiveDate;

    if (last == null) return;

    final lastDay = DateTime(last.year, last.month, last.day);
    final diff = today.difference(lastDay).inDays;

    if (diff == 1) {
      // Consecutive day — increment streak
      final newStreak = _profile!.currentStreak + 1;
      _profile = _profile!.copyWith(
        currentStreak: newStreak,
        longestStreak: newStreak > _profile!.longestStreak
            ? newStreak
            : _profile!.longestStreak,
        lastActiveDate: now,
      );
      
      // Award shields at milestones
      if (newStreak == 7) {
        _profile = _profile!.copyWith(streakShields: _profile!.streakShields + 1);
      }
      if (newStreak == 30) {
        _profile = _profile!.copyWith(streakShields: _profile!.streakShields + 2);
      }

      // Check for milestone celebration
      if (const {3, 7, 14, 30, 60, 100}.contains(newStreak)) {
        _pendingMilestone = newStreak;
      }

      // Check streak achievements
      if (newStreak >= 7) {
        await earnBadge('streak_7');
      }
      if (newStreak >= 30) {
        await earnBadge('streak_30');
      }

      // Award streak bonus XP (signed transaction)
      await addXP(
        25, // Basic streak bonus
        source: XPSource.streakBonus,
      );

    } else if (diff > 1) {
      // Streak broken — check for shield
      if (_profile!.streakShields > 0) {
        // Use shield
        _profile = _profile!.copyWith(
          streakShields: _profile!.streakShields - 1,
          lastActiveDate: now,
        );
        _pendingShieldUsed = true;
      } else {
        // Streak broken
        _profile = _profile!.copyWith(
          currentStreak: 0,
          lastActiveDate: now,
        );
      }
    }
    await _persist();
  }

  Future<void> recordTaskCompletion(Task task) async {
    if (_profile == null) return;

    // ── COOLDOWN CHECK ────────────────
    // Block if already earned XP for this task today
    if (!XPCooldownTracker.instance.canEarnXP(task.id)) {
      await _touchActiveDate();
      return;
    }

    // ── CALCULATE XP ──────────────────
    int xp = XPValues.completeTask;
    if (task.priority == Priority.high) {
      xp = XPValues.completeHigh;
    } else if (task.priority == Priority.urgent) {
      xp = XPValues.completeUrgent;
    }

    // ── RECORD COOLDOWN ───────────────
    await XPCooldownTracker.instance.recordXPEarned(task.id);

    // ── AWARD XP ──────────────────────
    await SecureXPStore.instance.addXP(
      amount: xp,
      source: XPSource.taskCompletion,
      taskId: task.id,
    );

    // ── BADGES ────────────────────────
    if (DateTime.now().hour < 9) {
      await earnBadge('early_bird');
    }

    await _touchActiveDate();
    await _updateDailyStreak();
    notifyListeners();
  }

  Future<void> _touchActiveDate() async {
    if (_profile == null) return;
    _profile = _profile!.copyWith(
      lastActiveDate: DateTime.now(),
    );
    await _persist();
  }

  Future<void> recordFocusCompletion(int durationMinutes) async {
    if (_profile == null) return;
    await addXP(
      XPValues.completeFocus,
      source: XPSource.focusSession,
    );
    if (durationMinutes >= 60) {
      await earnBadge('deep_work_master');
    }
  }

  Future<void> _persist() async {
    if (_profile == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(_profile!.toJson()));
  }

  void refresh() => notifyListeners();
}

enum PurchaseResult {
  success,
  insufficientXP,
  alreadyOwned,
  noProfile,
}
