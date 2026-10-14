import 'package:flutter/material.dart';

/// One design system for the whole app: an agricultural green primary, a
/// warm harvest accent, rounded cards, 48 dp minimum touch targets and
/// slightly larger body text for outdoor readability.
class AppTheme {
  AppTheme._();

  static const Color seed = Color(0xFF2E7D32); // agricultural green
  static const Color harvest = Color(0xFFF2A93B); // warm accent for highlights

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    final isDark = brightness == Brightness.dark;
    final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: brightness);
    return base.copyWith(
      scaffoldBackgroundColor: isDark ? const Color(0xFF111511) : const Color(0xFFF6F8F1),
      textTheme: base.textTheme.copyWith(
        bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 15, height: 1.35),
        titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: isDark ? const Color(0xFF111511) : const Color(0xFFF6F8F1),
        titleTextStyle: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? scheme.surfaceContainer : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.5)),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      listTileTheme: const ListTileThemeData(minVerticalPadding: 10),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.all(
          base.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(shape: const StadiumBorder()),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
