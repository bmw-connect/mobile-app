import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Apple-system-inspired palette. One instance per brightness; resolve the
/// active one with [AppColors.of] so every widget follows the phone's theme.
class AppColors {
  const AppColors._({
    required this.bg,
    required this.card,
    required this.cardAlt,
    required this.separator,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.airplay,
    required this.bluetooth,
    required this.success,
    required this.warning,
    required this.error,
    required this.vuGreen,
    required this.vuYellow,
    required this.vuRed,
  });

  /// Screen background (systemGroupedBackground).
  final Color bg;

  /// Grouped card / cell background.
  final Color card;

  /// Inset fills inside cards: slider tracks, text fields, chips.
  final Color cardAlt;

  final Color separator;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  /// Single app tint (system blue).
  final Color accent;

  final Color airplay;
  final Color bluetooth;
  final Color success;
  final Color warning;
  final Color error;
  final Color vuGreen;
  final Color vuYellow;
  final Color vuRed;

  static const light = AppColors._(
    bg: Color(0xFFF2F2F7),
    card: Color(0xFFFFFFFF),
    cardAlt: Color(0xFFEAEAEF),
    separator: Color(0xFFE3E3E8),
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0xFF85858B),
    textTertiary: Color(0xFFB9B9BE),
    accent: Color(0xFF007AFF),
    airplay: Color(0xFF32ADE6),
    bluetooth: Color(0xFF5856D6),
    success: Color(0xFF34C759),
    warning: Color(0xFFFF9500),
    error: Color(0xFFFF3B30),
    vuGreen: Color(0xFF34C759),
    vuYellow: Color(0xFFFFCC00),
    vuRed: Color(0xFFFF3B30),
  );

  static const dark = AppColors._(
    bg: Color(0xFF000000),
    card: Color(0xFF1C1C1E),
    cardAlt: Color(0xFF2C2C2E),
    separator: Color(0xFF38383A),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF98989F),
    textTertiary: Color(0xFF636367),
    accent: Color(0xFF0A84FF),
    airplay: Color(0xFF64D2FF),
    bluetooth: Color(0xFF5E5CE6),
    success: Color(0xFF30D158),
    warning: Color(0xFFFF9F0A),
    error: Color(0xFFFF453A),
    vuGreen: Color(0xFF30D158),
    vuYellow: Color(0xFFFFD60A),
    vuRed: Color(0xFFFF453A),
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

ThemeData buildAppTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final c = dark ? AppColors.dark : AppColors.light;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: c.bg,
    splashFactory: NoSplash.splashFactory,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: Colors.white,
      secondary: c.accent,
      onSecondary: Colors.white,
      error: c.error,
      onError: Colors.white,
      surface: c.card,
      onSurface: c.textPrimary,
      outline: c.separator,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      foregroundColor: c.textPrimary,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: dark
          ? SystemUiOverlayStyle.light.copyWith(systemNavigationBarColor: c.bg)
          : SystemUiOverlayStyle.dark.copyWith(systemNavigationBarColor: c.bg),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.card,
      indicatorColor: c.accent.withValues(alpha: 0.14),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: c.accent, size: 22);
        }
        return IconThemeData(color: c.textSecondary, size: 22);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            color: c.accent,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          );
        }
        return TextStyle(color: c.textSecondary, fontSize: 11);
      }),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    textTheme: TextTheme(
      // iOS large title.
      displaySmall: TextStyle(
        color: c.textPrimary,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      ),
      titleLarge: TextStyle(
        color: c.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
      titleMedium: TextStyle(
        color: c.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        color: c.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: TextStyle(color: c.textPrimary, fontSize: 15),
      bodySmall: TextStyle(color: c.textSecondary, fontSize: 13),
      labelSmall: TextStyle(
        color: c.textSecondary,
        fontSize: 11,
        letterSpacing: 0.6,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: c.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: DividerThemeData(
      color: c.separator,
      thickness: 0.5,
      space: 0,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.success : c.cardAlt),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.cardAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.accent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      labelStyle: TextStyle(color: c.textSecondary),
      hintStyle: TextStyle(color: c.textTertiary),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        side: BorderSide(color: c.separator),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.accent,
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
    ),
  );
}
