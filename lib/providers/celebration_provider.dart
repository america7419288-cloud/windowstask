import 'package:flutter/material.dart';

class CelebrationProvider extends ChangeNotifier {
  final GlobalKey progressRingKey = GlobalKey();
  
  bool _isCelebrating = false;
  bool get isCelebrating => _isCelebrating;

  void triggerCelebration() {
    if (_isCelebrating) return;
    _isCelebrating = true;
    notifyListeners();
  }

  void stopCelebration() {
    _isCelebrating = false;
    notifyListeners();
  }
}
