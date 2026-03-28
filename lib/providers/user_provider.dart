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
import '../services/store_service.dart';

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
    
    // Connectivity Check
    final isOnline = await StoreService.instance.checkConnectivity();
    if (!isOnline) return PurchaseResult.offline;
    
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

    // Prefetch stickers for offline use
    StoreService.instance.prefetchStickers(item.stickerIds);

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
    notifyListe    }
    await _persist();
    _checkAutoAchievements(); // Check if any new ones unlocked
  }

  Future<void> recordTaskCompletion(Task task) async {
    if (_profile == null) return;

    // Increment total count regardless of XP cooldown
    _profile = _profile!.copyWith(
      totalTasksCompleted: _profile!.totalTasksCompleted + 1,
    );

    // ── COOLDOWN CHECK ────────────────
    // Block if already earned XP for this task today
    if (!XPCooldownTracker.instance.canEarnXP(task.id)) {
      await _touchActiveDate();
      await _persist();
      _checkAutoAchievements();
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
    await _updateDailyStreak(isActivity: true);
    _checkAutoAchievements();
    notifyListeners();
  }
��────────────
    if (DateTime.now().hour < 9) {
      await earnBadge('early_bird');
    }

    await _touchActiveDate();
    await _updateDailyStreak(isActivity: true);
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
    
    // Increment count if it was a significant session
    if (durationMinutes >= 10) {
      _profile = _profile!.copyWith(
        totalFocusSessions: _profile!.totalFocusSessions + 1,
      );
    }

    await addXP(
      XPValues.completeFocus,
      source: XPSource.focusSession,
    );
    if (durationMinutes >= 60) {
      await earnBadge('deep_work_master');
    }
    await _touchActiveDate();
    await _updateDailyStreak(isActivity: true);
    _checkAutoAchievements();
    notifyListeners();
  }

  Future<void> recordPlanningSession() async {
    if (_profile == null) return;
    _profile = _profile!.copyWith(
      totalPlanningSessions: _profile!.totalPlanningSessions + 1,
    );
    await _persist();
    _checkAutoAchievements();
    notifyListeners();
  }

  // ── ACHIEVEMENT HELPERS ─────────────────────────

  double getAchievementProgress(Achievement a) {
    if (_profile == null) return 0;
    if (_profile!.earnedBadgeIds.contains(a.id)) return 1.0;

    switch (a.category) {
      case AchievementCategory.streak:
        return (_profile!.currentStreak / a.targetValue).clamp(0.0, 1.0);
      case AchievementCategory.taskCount:
        return (_profile!.totalTasksCompleted / a.targetValue).clamp(0.0, 1.0);
      case AchievementCategory.focusTime:
        return (_profile!.totalFocusSessions / a.targetValue).clamp(0.0, 1.0);
      case AchievementCategory.planning:
        return (_profile!.totalPlanningSessions / a.targetValue).clamp(0.0, 1.0);
      default:
        return 0.0;
    }
  }

  void _checkAutoAchievements() {
    if (_profile == null) return;
    
    for (final a in Achievements.all) {
      if (_profile!.earnedBadgeIds.contains(a.id)) continue;
      
      bool shouldUnlock = false;
      switch (a.category) {
        case AchievementCategory.streak:
          if (_profile!.currentStreak >= a.targetValue) shouldUnlock = true;
          break;
        case AchievementCategory.taskCount:
          if (_profile!.totalTasksCompleted >= a.targetValue) shouldUnlock = true;
          break;
        case AchievementCategory.focusTime:
          if (_profile!.totalFocusSessions >= a.targetValue) shouldUnlock = true;
          break;
        case AchievementCategory.planning:
          if (_profile!.totalPlanningSessions >= a.targetValue) shouldUnlock = true;
          break;
        default:
          break;
      }
      
      if (shouldUnlock) {
        earnBadge(a.id);
      }
    }
  }

  Future<void> _persist() async {
    if (_profile == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileKey, jsonEncode(_profile!.toJson()));
    } catch (e) {
      debugPrint('❌ USER_PROVIDER: Failed to persist profile: $e');
    }
  }

  void refresh() => notifyListeners();
}

enum PurchaseResult {
  success,
  insufficientXP,
  alreadyOwned,
  noProfile,
  offline,
}
