import 'dart:async';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';

enum FocusState { idle, running, paused, onBreak, done }

class FocusProvider extends ChangeNotifier {
  FocusState _state = FocusState.idle;
  int _totalSeconds = 25 * 60;
  int _remainingSeconds = 25 * 60;
  String? _activeTaskId;
  String? _activeTaskTitle;
  int _completedSessions = 0;
  Timer? _timer;

  FocusState get state => _state;
  int get remainingSeconds => _remainingSeconds;
  int get completedSessions => _completedSessions;
  String? get activeTaskId => _activeTaskId;
  String? get activeTaskTitle => _activeTaskTitle;
  bool get isRunning => _state == FocusState.running;
  bool get isActive => _state != FocusState.idle;

  String get timeDisplay {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get progress =>
      _totalSeconds > 0 ? (_totalSeconds - _remainingSeconds) / _totalSeconds : 0;

  void startFocus({
    required String taskId,
    required String taskTitle,
    int durationMinutes = 25,
  }) {
    _activeTaskId = taskId;
    _activeTaskTitle = taskTitle;
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
    _state = FocusState.running;
    _startTimer();
    notifyListeners();
  }

  void stopFocus() {
    _timer?.cancel();
    _state = FocusState.idle;
    _activeTaskId = null;
    _activeTaskTitle = null;
    _remainingSeconds = _totalSeconds;
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        t.cancel();
        _onSessionComplete();
      }
    });
  }

  void _onSessionComplete() {
    _completedSessions++;
    _state = FocusState.done;
    NotificationService.instance.showNotification(
      id: 1000,
      title: '🎉 Focus Session Complete!',
      body: 'Great work on "$_activeTaskTitle". Take a 5 minute break!',
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
