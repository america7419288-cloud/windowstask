import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/task_provider.dart';
import 'providers/list_provider.dart';
import 'providers/tag_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/focus_provider.dart';
import 'providers/celebration_provider.dart';
import 'providers/template_provider.dart';
import 'providers/user_provider.dart';
import 'providers/user_context_provider.dart';
import 'providers/ai_provider.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/storage_service.dart';
import 'services/store_service.dart';
import 'theme/app_theme.dart';
import 'widgets/layout/density_scaled_app.dart';

import 'services/update_service.dart';

class TaskiApp extends StatefulWidget {
  final UserProvider userProvider;
  final TaskProvider taskProvider;

  const TaskiApp({
    super.key,
    required this.userProvider,
    required this.taskProvider,
  });

  @override
  State<TaskiApp> createState() => _TaskiAppState();
}

class _TaskiAppState extends State<TaskiApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdates(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()..init()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => ListProvider()..init()),
        ChangeNotifierProvider(create: (_) => TagProvider()..init()),
        ChangeNotifierProvider(create: (_) => FocusProvider()),
        ChangeNotifierProvider(create: (_) => CelebrationProvider()),
        ChangeNotifierProvider(create: (_) => TemplateProvider()..init()),
        ChangeNotifierProvider.value(value: widget.userProvider),
        ChangeNotifierProxyProvider<UserProvider, TaskProvider>(
          create: (_) => widget.taskProvider,
          update: (_, user, tasks) => tasks!..userProvider = user,
        ),
        ChangeNotifierProvider.value(value: StoreService.instance..fetchStore()),
        ChangeNotifierProvider(create: (_) => UserContextProvider(StorageService.instance.prefs)),
        ChangeNotifierProxyProvider<UserContextProvider, AIProvider>(
          create: (_) => AIProvider(),
          update: (_, ctx, ai) {
            if (ctx.hasApiKey) {
              ai?.init(ctx.apiKey!);
            }
            return ai!;
          },
        ),
      ],
      child: Consumer2<SettingsProvider, UserProvider>(
        builder: (context, settings, user, _) {
          return MaterialApp(
            title: 'Taski',
            debugShowCheckedModeBanner: false,
            themeMode: settings.themeMode,
            theme: AppTheme.light(settings.accentColor),
            darkTheme: AppTheme.dark(settings.accentColor),
            home: DensityScaledApp(
              child: user.hasProfile
                  ? const HomeScreen()
                  : const OnboardingScreen(),
            ),
          );
        },
      ),
    );
  }
}

