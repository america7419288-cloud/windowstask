import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/task.dart';
import 'models/task_list.dart';
import 'models/tag.dart';
import 'models/subtask.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'app.dart';

// Conditional window setup — only imported on native (dart:io) platforms
import 'window_setup_stub.dart'
    if (dart.library.io) 'window_setup_native.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── 1. Init Hive FIRST ───────────────────────────────────────────────────
  await Hive.initFlutter();

  // TypeIds 0–5 are reserved. Next available: 6
  // Guard adapter registration (hot-reload safe)
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TaskStatusAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(PriorityAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(TaskAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(SubtaskAdapter());
  if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(TaskListAdapter());
  if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(TagAdapter());

  // ── 2. Open storage boxes ────────────────────────────────────────────────
  await StorageService.instance.init();

  // ── 3. Init notifications (stub on web) ──────────────────────────────────
  await NotificationService.instance.init();

  // ── 4. Native window setup (Windows only, skipped on web) ────────────────
  await setupWindow();

  // ── 5. Run app ───────────────────────────────────────────────────────────
  runApp(const TaskiApp());
}
