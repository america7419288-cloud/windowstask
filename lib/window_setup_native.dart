import 'package:window_manager/window_manager.dart';
import 'package:flutter/material.dart';

Future<void> setupWindow() async {
  await windowManager.ensureInitialized();

  const WindowOptions windowOptions = WindowOptions(
    size: Size(1280, 820),
    minimumSize: Size(1200, 800),
    center: true,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

}
