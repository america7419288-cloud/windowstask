import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/achievement.dart';
import '../models/task.dart';
import '../models/store_item.dart';
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
      _profile?.unlockedStickerIds.contains(stickerId) ?? false;

  bool hasPurchased(String itemId) =>
      _profile?.purchasedItemIds.contains(itemId) ?? false;

  Future<PurchaseResult> purchase(StoreItem item) async {
    if (_profile == null) return PurchaseResult.noProfile;
    if (_profile!.totalXP < item.xpCost) return PurchaseResult.insufficientXP;
    if (hasPurchased(item.id)) return PurchaseResult.alreadyOwned;

    // Deduct XP
    final newXP = _profile!.totalXP - item.xpCost;

    // Unlock all stickers in this item
    final newUnlocked = {
      ..._profile!.unlockedStickerIds,
      ...item.stickerIds,
    }.toList();

    final newPurchased = {
      ..._profile!.purchasedItemIds,
      item.id,
    }.toList();

    _profile = _profile!.copyWith(
      totalXP: newXP,
      unlockedStickerIds: newUnlocked,
      purchasedItemIds: newPurchased,
    );

    await _persist();
    notifyListeners();
    return PurchaseResult.success;
  }

  String get firstName => _profile?.firstName ?? 'Friend';

  int get totalXP => _profile?.totalXP ?? 0;
  int get streak => _profile?.currentStreak ?? 0;
  int get streakShields => _profile?.streakShields ?? 0;

  /// XP level calculation (every 500 XP = 1 level)
  int get level => (totalXP / 500).floor() + 1;
  double get levelProgress => (totalXP % 500) / 500;

  Future<void> init() async {
    final data = StorageService.instance.getProfile();
    if (data != null) {
      try {
        _profile = UserProfile.fromJson(data);
      } catch (_) {
        // Corrupt data — ignore
      }
    }

    // BREAKING FOR TESTING: Add 10,000 XP once
    final prefs = await SharedPreferences.getInstance();
    if (_profile != null && !(prefs.getBool('test_xp_added') ?? false)) {
      _profile = _profile!.copyWith(totalXP: _profile!.totalXP + 10000);
      await prefs.setBool('test_xp_added', true);
      await _persist();
    }

    // Update streak on init
    await _updateDailyStreak();
    notifyListeners();
  }

  Future<void> saveProfile(UserProfile profile) async {
    _profile = profile;
    await _persist();
    notifyListeners();
  }

  Future<void> addXP(int amount, {String? reason}) async {
    if (_profile == null) return;
    _profile = _profile!.copyWith(
      totalXP: _profile!.totalXP + amount,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> earnBadge(String badgeId) async {
    if (_profile == null) return;
    if (_profile!.earnedBadgeIds.contains(badgeId)) return;

    final badges = [..._profile!.earnedBadgeIds, badgeId];
    _profile = _profile!.copyWith(earnedBadgeIds: badges);

    final achievement = Achievements.findById(badgeId);
    if (achievement != null) {
      await addXP(achievement.xpReward, reason: achievement.name);
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
      // (Actually checking the exact milestone values requested: 3, 7, 14, 30, 60, 100)
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

    // XP for completion based on priority
    int xp = XPValues.completeTask;
    if (task.priority == Priority.high) {
      xp = XPValues.completeHigh;
    } else if (task.priority == Priority.urgent) {
      xp = XPValues.completeUrgent;
    }
    await addXP(xp);

    // Early bird badge
    if (DateTime.now().hour < 9) {
      await earnBadge('early_bird');
    }

    // Update last active
    _profile = _profile!.copyWith(
      lastActiveDate: DateTime.now(),
    );
    await _updateDailyStreak();
    await _persist();
    notifyListeners();
  }

  Future<void> recordFocusCompletion(int durationMinutes) async {
    if (_profile == null) return;
    await addXP(XPValues.completeFocus);
    if (durationMinutes >= 60) {
      await earnBadge('deep_work_master');
    }
  }

  Future<void> _persist() async {
    if (_profile == null) return;
    await StorageService.instance.saveProfile(_profile!.toJson());
  }
}

enum PurchaseResult {
  success,
  insufficientXP,
  alreadyOwned,
  noProfile,
}
