import 'package:window_manager/window_manager.dart';
import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'utils/global_focus_states.dart';

class _WindowSetupListener with WindowListener {
  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      await windowManager.hide();
    }
  }
}

final _windowStateListener = _WindowSetupListener();

Future<void> setupWindow() async {
  await windowManager.ensureInitialized();
  await Window.initialize();
  
  // Set window effect for Glassmorphism
  await Window.setEffect(
    effect: WindowEffect.mica, 
    dark: true, 
    color: Colors.transparent,
  ).catchError((_) {
    // Fallback if mica isn't supported
    Window.setEffect(effect: WindowEffect.solid, dark: true, color: const Color(0xFF0F1115));
  });

  const WindowOptions windowOptions = WindowOptions(
    size: Size(1280, 820),
    minimumSize: Size(800, 600),
    center: true,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    backgroundColor: Colors.transparent,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setPreventClose(true);
    windowManager.addListener(_windowStateListener);
  });

  await _initSystemTray();
  await _initHotkeys();
}

class _TrayListener with TrayListener {
  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    if (menuItem.key == 'show_app') {
      await windowManager.show();
    } else if (menuItem.key == 'quick_add') {
      await windowManager.show();
      GlobalFocusStates.quickAddFocus.value++;
    } else if (menuItem.key == 'exit_app') {
      exit(0);
    }
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
  }
}

final _trayListener = _TrayListener();

Future<void> _initSystemTray() async {
  String path = Platform.isWindows ? 'app_icon.ico' : 'assets/app_icon.png';
  
  await trayManager.setIcon(path);
  
  Menu menu = Menu(
    items: [
      MenuItem(
        key: 'show_app',
        label: 'Show App',
      ),
      MenuItem(
        key: 'quick_add',
        label: 'Quick Add',
      ),
      MenuItem.separator(),
      MenuItem(
        key: 'exit_app',
        label: 'Exit',
      ),
    ],
  );
  
  await trayManager.setContextMenu(menu);
  trayManager.addListener(_trayListener);
}

Future<void> _initHotkeys() async {
  await hotKeyManager.unregisterAll();

  HotKey quickAddHotKey = HotKey(
    key: LogicalKeyboardKey.space, // For hotkey_manager ^0.2.3
    modifiers: [HotKeyModifier.control, HotKeyModifier.shift],
    scope: HotKeyScope.system,
  );

  await hotKeyManager.register(
    quickAddHotKey,
    keyDownHandler: (hotKey) async {
      await windowManager.show();
      await windowManager.focus();
      GlobalFocusStates.quickAddFocus.value++;
    },
  );
}
