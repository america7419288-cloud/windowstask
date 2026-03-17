import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

/// Wraps the app content and overrides textScaler from SettingsProvider.fontScale
class DensityScaledApp extends StatelessWidget {
  final Widget child;
  const DensityScaledApp({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final scale = context.watch<SettingsProvider>().fontScale;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale),
      ),
      child: child,
    );
  }
}
