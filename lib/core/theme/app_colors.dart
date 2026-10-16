import 'package:flutter/material.dart';

/// Every colour the app uses. Change a value here to restyle the whole app;
/// widgets must not hard-code colours of their own.
///
/// Keep PROJECT.md's colour table in step with this file.
abstract final class AppColors {
  // Surfaces, darkest to lightest.
  static const background = Color(0xFF0A1222);
  static const surface = Color(0xFF101B30);
  static const surfaceRaised = Color(0xFF16243D);
  static const outline = Color(0xFF263654);

  // Brand blues.
  static const primary = Color(0xFF3B82F6);
  static const primaryBright = Color(0xFF60A5FA);
  static const primaryMuted = Color(0xFF1D3A6B);

  // Text.
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB4C2DA);
  static const textMuted = Color(0xFF7F8FAB);

  // Status. Reserved for state; never used as a chart series colour.
  static const good = Color(0xFF0CA30C);
  static const warning = Color(0xFFFAB219);
  static const critical = Color(0xFFE66767);

  // Chart series. Each trio was checked for colour-blind separation and
  // contrast against [surfaceRaised]; re-check before changing one.
  static const chartProtein = Color(0xFF3987E5);
  static const chartCarbs = Color(0xFFD95926);
  static const chartFat = Color(0xFF199E70);
  static const chartResting = Color(0xFFC98500);
  static const chartActivity = Color(0xFFD55181);
  static const chartExercise = Color(0xFF9085E9);

  // The two sides of a two-food comparison, checked as a pair against
  // [surfaceRaised]. Amber sits near [chartResting], which never appears on
  // the comparison screen.
  static const compareA = Color(0xFF3987E5);
  static const compareB = Color(0xFFC4861A);

  /// The unfilled part of a ring or meter.
  static const chartTrack = outline;
}
