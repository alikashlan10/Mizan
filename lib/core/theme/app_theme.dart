import 'package:flutter/material.dart';
import 'package:mizan/core/theme/app_colors.dart';

/// The app's single (dark) theme, built from [AppColors].
ThemeData buildAppTheme() {
  const scheme = ColorScheme.dark(
    primary: AppColors.primary,
    onPrimary: AppColors.textPrimary,
    primaryContainer: AppColors.primaryMuted,
    onPrimaryContainer: AppColors.textPrimary,
    secondary: AppColors.primaryBright,
    onSecondary: AppColors.background,
    secondaryContainer: AppColors.primaryMuted,
    onSecondaryContainer: AppColors.textPrimary,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    surfaceContainerLowest: AppColors.background,
    surfaceContainerLow: AppColors.surface,
    surfaceContainer: AppColors.surfaceRaised,
    surfaceContainerHigh: AppColors.surfaceRaised,
    surfaceContainerHighest: AppColors.surfaceRaised,
    outline: AppColors.textMuted,
    outlineVariant: AppColors.outline,
    error: AppColors.critical,
    onError: AppColors.background,
    errorContainer: AppColors.critical,
    onErrorContainer: AppColors.background,
  );

  final base = ThemeData(
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primaryMuted,
      surfaceTintColor: Colors.transparent,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.outline),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.surfaceRaised,
      contentTextStyle: TextStyle(color: AppColors.textPrimary),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
