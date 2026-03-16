import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppShortcuts {
  AppShortcuts._();

  static final Map<ShortcutActivator, String> shortcuts = {
    const SingleActivator(LogicalKeyboardKey.keyN, control: true): 'newTask',
    const SingleActivator(LogicalKeyboardKey.keyF, control: true): 'search',
    const SingleActivator(LogicalKeyboardKey.comma, control: true): 'settings',
    const SingleActivator(LogicalKeyboardKey.keyZ, control: true): 'undo',
    const SingleActivator(LogicalKeyboardKey.escape): 'escape',
    const SingleActivator(LogicalKeyboardKey.space): 'toggleComplete',
    const SingleActivator(LogicalKeyboardKey.delete): 'delete',
    const SingleActivator(LogicalKeyboardKey.arrowUp): 'navigateUp',
    const SingleActivator(LogicalKeyboardKey.arrowDown): 'navigateDown',
    const SingleActivator(LogicalKeyboardKey.enter): 'confirm',
  };
}
