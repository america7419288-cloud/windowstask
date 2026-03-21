import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/task.dart';
import 'models/task_list.dart';
import 'models/tag.dart';
import 'models/subtask.dart';
import 'models/task_template.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'providers/user_provider.dart';
import 'providers/task_provider.dart';
import 'app.dart';

// Conditional window setup — only imported on native (dart:io) platforms
import 'window_setup_stub.dart'
    if (dart.library.io) 'window_setup_native.dart';

import 'dart:async';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // ── 0. Window setup (Await to prevent flicker) ──────────────────────────
    await setupWindow();

    // Custom Error UI for Production
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        color: const Color(0xFF0F1115),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                   const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                   const SizedBox(height: 24),
                   const Text(
                    'Something went wrong',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'The application encountered an unexpected error.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  if (kDebugMode)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        details.exceptionAsString(),
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontFamily: 'monospace'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    };

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
  if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(TaskTemplateAdapter());

  // ── 2 & 3. Init Services in Parallel ─────────────────────────────────────
  await Future.wait([
    StorageService.instance.init(),
    NotificationService.instance.init(),
  ]);

  // ── 5. Init Core Providers in Parallel ───────────────────────────────────
  final userProvider = UserProvider();
  final taskProvider = TaskProvider();
  
  await Future.wait([
    userProvider.init(),
    taskProvider.init(),
  ]);

    // ── 6. Run app ───────────────────────────────────────────────────────────
    runApp(TaskiApp(
      userProvider: userProvider,
      taskProvider: taskProvider,
    ));
  }, (error, stack) {
    debugPrint('GLOBAL ERROR: $error');
    debugPrint(stack.toString());
  });
}
