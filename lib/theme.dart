import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ghar Alert ka design system: gehra raat jaisa background, hara = surakshit,
/// laal = khatra. Har screen inhi rangon aur spacing se bani hai.
class C {
  static const bg = Color(0xFF0A0E14);
  static const surface = Color(0xFF121822);
  static const surface2 = Color(0xFF1A2230);
  static const border = Color(0xFF243044);
  static const text = Color(0xFFE8EDF5);
  static const muted = Color(0xFF8A97AB);
  static const faint = Color(0xFF5B6779);

  static const safe = Color(0xFF22C55E);
  static const safeDeep = Color(0xFF15803D);
  static const danger = Color(0xFFFF4D4F);
  static const dangerDeep = Color(0xFFB91C1C);
  static const warn = Color(0xFFF5A524);
  static const brand = Color(0xFF7C8CFF);
  static const info = Color(0xFF38BDF8);

  static const safeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F3D26), Color(0xFF0B2219)],
  );
  static const dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4A1015), Color(0xFF220A0D)],
  );
  static const offGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3A2A0E), Color(0xFF1E1609)],
  );
}

class Sp {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const radius = 20.0;
  static const radiusS = 14.0;
}

ThemeData buildTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: C.bg,
    colorScheme: const ColorScheme.dark(
      primary: C.brand,
      onPrimary: Colors.white,
      secondary: C.safe,
      error: C.danger,
      surface: C.surface,
      onSurface: C.text,
      outline: C.border,
    ),
  );

  final text = GoogleFonts.manropeTextTheme(base.textTheme).apply(
    bodyColor: C.text,
    displayColor: C.text,
  );

  return base.copyWith(
    textTheme: text.copyWith(
      headlineMedium: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
      headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      bodyMedium: text.bodyMedium?.copyWith(color: C.text, height: 1.4),
      bodySmall: text.bodySmall?.copyWith(color: C.muted, height: 1.35),
      labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: C.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: C.text),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: C.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: C.brand.withValues(alpha: 0.18),
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontSize: 11.5,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
            color: s.contains(WidgetState.selected) ? C.text : C.muted,
          )),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? C.brand : C.muted,
          )),
    ),
    cardTheme: CardThemeData(
      color: C.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Sp.radius),
        side: const BorderSide(color: C.border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: C.brand,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sp.radiusS)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: C.text,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: C.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sp.radiusS)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : C.muted),
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? C.safe : C.surface2),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    dividerTheme: const DividerThemeData(color: C.border, thickness: 1, space: 1),
    listTileTheme: const ListTileThemeData(iconColor: C.muted),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: C.surface2,
      contentTextStyle: const TextStyle(color: C.text, fontWeight: FontWeight.w600),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sp.radiusS)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: C.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Sp.radius)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: C.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.surface2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Sp.radiusS),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: C.faint),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: C.surface2,
      selectedColor: C.brand.withValues(alpha: 0.22),
      side: const BorderSide(color: C.border),
      labelStyle: const TextStyle(color: C.text, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
    }),
  );
}
