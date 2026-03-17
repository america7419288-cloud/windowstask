import 'package:flutter/physics.dart';

class AppSprings {
  // Gentle — sidebar transitions, panel slides
  static const gentle = SpringDescription(
    mass: 1.0,
    stiffness: 200,
    damping: 20,
  );

  // Snappy — button presses, checkbox, toggles
  static const snappy = SpringDescription(
    mass: 0.8,
    stiffness: 400,
    damping: 22,
  );

  // Bouncy — task add, completion celebration
  static const bouncy = SpringDescription(
    mass: 0.9,
    stiffness: 350,
    damping: 14,
  );

  // Smooth — page transitions, panel open/close
  static const smooth = SpringDescription(
    mass: 1.2,
    stiffness: 180,
    damping: 24,
  );
}

// Helper to get duration from spring (approximate)
Duration springDuration(SpringDescription s) =>
    Duration(milliseconds: (1000 / (s.stiffness / s.mass)).round().clamp(200, 600));
