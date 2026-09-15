import 'package:flutter/material.dart';
import 'package:quest_key/constants/app_colors.dart';
import 'package:quest_key/constants/app_dimens.dart';

/// Typography helpers. Cinzel (variable weight) for display, Spectral for
/// reading text. Both are bundled under assets/fonts.
class AppFonts {
  AppFonts._();

  static const String displayFamily = 'Cinzel';
  static const String bodyFamily = 'Spectral';

  static TextStyle heading({
    double size = 24,
    Color color = AppColors.ink,
    FontWeight weight = FontWeight.w700,
    double letterSpacing = 1.2,
  }) => TextStyle(
    fontFamily: displayFamily,
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: 1.15,
  );

  /// Small caps-like label (Cinzel is all caps by design).
  static TextStyle label({
    double size = 11,
    Color color = AppColors.bronzeLight,
    FontWeight weight = FontWeight.w600,
  }) => TextStyle(
    fontFamily: displayFamily,
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: 1.6,
  );

  static TextStyle body({
    double size = 15,
    Color color = AppColors.ink,
    FontWeight weight = FontWeight.w400,
    FontStyle style = FontStyle.normal,
    double height = 1.4,
  }) => TextStyle(
    fontFamily: AppFonts.bodyFamily,
    fontSize: size,
    fontWeight: weight,
    fontStyle: style,
    color: color,
    height: height,
  );
}

/// Single theme for the whole app.
class AppTheme {
  AppTheme._();

  static const ColorScheme scheme = ColorScheme.dark(
    primary: AppColors.amethystBright,
    onPrimary: AppColors.ink,
    secondary: AppColors.gold,
    onSecondary: AppColors.obsidian,
    tertiary: AppColors.teal,
    surface: AppColors.midnight,
    onSurface: AppColors.ink,
    error: AppColors.ruby,
  );

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      fontFamily: AppFonts.bodyFamily,
    );

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: color, width: width),
        );

    final text = base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
      fontFamily: AppFonts.bodyFamily,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.obsidian,
      splashFactory: InkSparkle.splashFactory,
      textTheme: text.copyWith(
        headlineMedium: AppFonts.heading(size: 28),
        headlineSmall: AppFonts.heading(size: 22),
        titleLarge: AppFonts.heading(size: 18, letterSpacing: 0.8),
        titleMedium: AppFonts.body(size: 17, weight: FontWeight.w600),
        bodyLarge: AppFonts.body(size: 16),
        bodyMedium: AppFonts.body(size: 15),
        bodySmall: AppFonts.body(size: 13, color: AppColors.inkMuted),
        labelSmall: AppFonts.label(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.obsidian.withValues(alpha: 0.55),
        labelStyle: AppFonts.body(size: 14, color: AppColors.inkMuted),
        floatingLabelStyle: AppFonts.label(size: 12, color: AppColors.gold),
        hintStyle: AppFonts.body(
          size: 14,
          color: AppColors.inkMuted.withValues(alpha: 0.6),
          style: FontStyle.italic,
        ),
        prefixIconColor: AppColors.bronzeLight,
        border: border(AppColors.bronze),
        enabledBorder: border(AppColors.bronze),
        focusedBorder: border(AppColors.gold, 1.4),
        errorBorder: border(AppColors.ruby),
        focusedErrorBorder: border(AppColors.ruby, 1.4),
        errorStyle: AppFonts.body(size: 12, color: AppColors.ruby),
        errorMaxLines: 2,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.gold,
          textStyle: AppFonts.label(size: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.bronze),
          textStyle: AppFonts.label(size: 12, color: AppColors.ink),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.midnight,
        contentTextStyle: AppFonts.body(size: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: const BorderSide(color: AppColors.bronze),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.midnight,
        titleTextStyle: AppFonts.heading(size: 18, letterSpacing: 0.8),
        contentTextStyle: AppFonts.body(size: 15, color: AppColors.inkMuted),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.bronze),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? AppColors.gold
                  : AppColors.inkMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? AppColors.amethyst
                  : AppColors.obsidian,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(AppColors.bronze),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.midnight,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.bronze),
        ),
        textStyle: AppFonts.body(size: 13),
      ),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: AppColors.midnight,
        headerBackgroundColor: AppColors.amethyst,
      ),
      timePickerTheme: const TimePickerThemeData(
        backgroundColor: AppColors.midnight,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.amethyst,
        foregroundColor: AppColors.gold,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
