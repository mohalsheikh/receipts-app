import 'package:flutter/material.dart';

ThemeData buildModernTheme() {
  const primaryBlue = Color(0xFF2563EB);
  const neutral50 = Color(0xFFFAFAFA);
  const neutral100 = Color(0xFFF5F5F5);
  const neutral200 = Color(0xFFE5E7EB);
  const neutral300 = Color(0xFFD1D5DB);
  const neutral600 = Color(0xFF4B5563);
  const neutral700 = Color(0xFF374151);
  const neutral900 = Color(0xFF111827);

  final scheme =
      ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
        primary: primaryBlue,
      ).copyWith(
        surface: Colors.white,
        surfaceContainerLowest: neutral50,
        onSurfaceVariant: neutral600,
        outlineVariant: neutral200,
        secondaryContainer: neutral100,
        tertiary: const Color(0xFF60A5FA),
        tertiaryContainer: const Color(0xFFEFF6FF),
        onTertiaryContainer: primaryBlue,
      );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: neutral50,
    fontFamily: 'SF Pro',
  );

  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: neutral900,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(color: neutral900),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryBlue,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: neutral100,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: neutral300),
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: neutral300),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primaryBlue),
        borderRadius: BorderRadius.circular(12),
      ),
      labelStyle: TextStyle(color: neutral700),
      hintStyle: TextStyle(color: neutral600),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    ),
    chipTheme: ChipThemeData(
      shape: StadiumBorder(side: BorderSide(color: neutral200)),
      backgroundColor: neutral100,
      selectedColor: scheme.tertiaryContainer,
      labelStyle: TextStyle(color: neutral700, fontWeight: FontWeight.w600),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
  );
}
