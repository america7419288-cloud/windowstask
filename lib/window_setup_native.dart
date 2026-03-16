import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/material.dart';

Future<void> setupWindow() async {
  await windowManager.ensureInitialized();

  const WindowOptions windowOptions = WindowOptions(
    size: Size(1280, 820),
    minimumSize: Size(1200, 800),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // bitsdojo_window setup
  doWhenWindowReady(() {
    final win = appWindow;
    win.minSize = const Size(1200, 800);
    win.size = const Size(1280, 820);
    win.alignment = Alignment.center;
    win.title = 'Taski';
    win.show();
  });
}
