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
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/store_service.dart';
import 'theme/app_theme.dart';
import 'widgets/layout/density_scaled_app.dart';

class TaskiApp extends StatelessWidget {
  final UserProvider userProvider;
  final TaskProvider taskProvider;

  const TaskiApp({
    super.key,
    required this.userProvider,
    required this.taskProvider,
  });

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
        ChangeNotifierProvider.value(value: userProvider),
        ChangeNotifierProxyProvider<UserProvider, TaskProvider>(
          create: (_) => taskProvider,
          update: (_, user, tasks) => tasks!..userProvider = user,
        ),
        ChangeNotifierProvider(create: (_) => StoreService.instance..fetchStore()),
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

