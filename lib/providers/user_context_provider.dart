import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_context.dart';

class UserContextProvider extends ChangeNotifier {
  static const String _contextKey = 'ai_user_context';
  static const String _apiKeySecret = 'gemini_api_key';
  static const String _onboardingKey = 'ai_onboarding_completed';

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  UserContext _context = const UserContext();
  String? _apiKey;
  bool _hasCompletedOnboarding = false;

  UserContextProvider(this._prefs) {
    _loadData();
  }

  UserContext get context => _context;
  bool get hasApiKey => _apiKey != null && _apiKey!.isNotEmpty;
  String? get apiKey => _apiKey;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

  Future<void> _loadData() async {
    // Load context
    final contextStr = _prefs.getString(_contextKey);
    if (contextStr != null) {
      try {
        _context = UserContext.fromJson(jsonDecode(contextStr));
      } catch (e) {
        debugPrint('Error loading AI context: $e');
      }
    }

    // Load onboarding status
    _hasCompletedOnboarding = _prefs.getBool(_onboardingKey) ?? false;

    // Load API Key from secure storage
    _apiKey = await _secureStorage.read(key: _apiKeySecret);

    notifyListeners();
  }

  Future<void> saveContext(UserContext newContext) async {
    _context = newContext;
    await _prefs.setString(_contextKey, jsonEncode(newContext.toJson()));
    notifyListeners();
  }

  Future<void> saveApiKey(String key) async {
    _apiKey = key;
    await _secureStorage.write(key: _apiKeySecret, value: key);
    notifyListeners();
  }

  Future<void> clearApiKey() async {
    _apiKey = null;
    await _secureStorage.delete(key: _apiKeySecret);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _hasCompletedOnboarding = true;
    await _prefs.setBool(_onboardingKey, true);
    notifyListeners();
  }

  Future<void> resetOnboarding() async {
    _hasCompletedOnboarding = false;
    await _prefs.setBool(_onboardingKey, false);
    notifyListeners();
  }
}
