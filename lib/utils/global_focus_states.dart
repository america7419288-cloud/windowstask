import 'package:flutter/foundation.dart';

class GlobalFocusStates {
  /// Incrementing this value indicates a request to focus the Quick Add bar.
  static final ValueNotifier<int> quickAddFocus = ValueNotifier<int>(0);

  /// Whether the app is currently in the compact "System Tray Quick Add" mode.
  static final ValueNotifier<bool> isTrayQuickAddMode = ValueNotifier<bool>(false);
}
