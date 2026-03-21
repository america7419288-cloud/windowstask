import 'dart:async';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

enum FocusState { idle, running, paused, onBreak, done }

class FocusProvider extends ChangeNotifier {
  FocusState _state = FocusState.idle;
  int _totalSeconds = 25 * 60;
  int _remainingSeconds = 25 * 60;
  
  // Session goals
  List<String> _sessionTaskIds = [];
  String? _currentTaskId;
  
  // Break state
  int _breakTotalSeconds = 5 * 60;
  int _breakRemainingSeconds = 5 * 60;

  int _completedSessions = 0;
  Timer? _timer;
  bool _isProcessing = false;

  FocusState get state => _state;
  int get remainingSeconds => _remainingSeconds;
  int get breakRemainingSeconds => _breakRemainingSeconds;
  int get completedSessions => _completedSessions;
  List<String> get sessionTaskIds => List.unmodifiable(_sessionTaskIds);
  String? get currentTaskId => _currentTaskId;
  
  bool get isRunning => _state == FocusState.running;
  bool get isActive => _state != FocusState.idle;
  bool get isBreakMode => _state == FocusState.onBreak;

  String get timeDisplay {
    final seconds = isBreakMode ? _breakRemainingSeconds : _remainingSeconds;
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get progress {
    if (isBreakMode) {
      return _breakTotalSeconds > 0 
          ? (_breakTotalSeconds - _breakRemainingSeconds) / _breakTotalSeconds 
          : 0;
    }
    return _totalSeconds > 0 
        ? (_totalSeconds - _remainingSeconds) / _totalSeconds 
        : 0;
  }

  void startFocus({
    required List<String> taskIds,
    String? currentTaskId,
    int durationMinutes = 25,
  }) {
    _sessionTaskIds = taskIds;
    _currentTaskId = currentTaskId;
    _totalSeconds = durationMinutes * 60;
    _remainingSeconds = _totalSeconds;
    _state = FocusState.running;
    _startTimer();
    notifyListeners();
  }

  void pauseFocus() {
    _timer?.cancel();
    _state = FocusState.paused;
    notifyListeners();
  }

  void resumeFocus() {
    _state = isBreakMode ? FocusState.onBreak : FocusState.running;
    _startTimer();
    notifyListeners();
  }

  void stopFocus() {
    _timer?.cancel();
    _state = FocusState.idle;
    _sessionTaskIds = [];
    _currentTaskId = null;
    _remainingSeconds = _totalSeconds;
    notifyListeners();
  }

  void skipBreak() {
    _timer?.cancel();
    _state = FocusState.idle;
    _sessionTaskIds = [];
    _currentTaskId = null;
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (_isProcessing) return;

      if (isBreakMode) {
        if (_breakRemainingSeconds > 0) {
          _breakRemainingSeconds--;
          notifyListeners();
        } else {
          t.cancel();
          _onBreakComplete();
        }
      } else {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          notifyListeners();
        } else {
          t.cancel();
          _isProcessing = true;
          await _onSessionComplete();
          _isProcessing = false;
        }
      }
    });
  }

  Future<void> _onSessionComplete() async {
    _completedSessions++;
    _state = FocusState.onBreak;
    _breakRemainingSeconds = _breakTotalSeconds;
    
    // Save stats
    final minutes = _totalSeconds ~/ 60;
    await StorageService.instance.saveFocusSession(minutes);

    NotificationService.instance.showNotification(
      taskId: 'focus_session_complete',
      title: '🎉 Focus Session Complete!',
      body: 'Great work! Time for a 5-minute break.',
    );
    
    _startTimer(); // Start break timer automatically
    notifyListeners();
  }

  void _onBreakComplete() {
    _state = FocusState.done;
    NotificationService.instance.showNotification(
      taskId: 'focus_break_complete',
      title: '☕ Break Over',
      body: 'Ready for another session?',
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
