import 'package:flutter/material.dart';

import '../models/task.dart';

/// Semantic colors that are not part of the Material [ColorScheme].
///
/// Each color has a darker shade for light mode and a lighter shade for
/// dark mode so text stays readable on both backgrounds.
class AppColors {
  const AppColors._();

  static Color success(Brightness brightness) {
    return brightness == Brightness.light
        ? Colors.green.shade700
        : Colors.green.shade300;
  }

  static Color warning(Brightness brightness) {
    return brightness == Brightness.light
        ? Colors.orange.shade900
        : Colors.orange.shade300;
  }

  static Color danger(Brightness brightness) {
    return brightness == Brightness.light
        ? Colors.red.shade700
        : Colors.red.shade300;
  }

  static Color priority(TaskPriority priority, Brightness brightness) {
    return switch (priority) {
      TaskPriority.low => success(brightness),
      TaskPriority.medium => warning(brightness),
      TaskPriority.high => danger(brightness),
    };
  }
}
