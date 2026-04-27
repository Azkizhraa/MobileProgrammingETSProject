import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class T {
  // ITS-inspired palette — deep teal + warm gold on off-white
  static const Color bg = Color(0xFFF4F6F0);
  static const Color card = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF0D5C63);    // deep teal
  static const Color accent = Color(0xFFE9A84C);     // warm gold
  static const Color inCCWS = Color(0xFF198754);     // green
  static const Color notInCCWS = Color(0xFF6C757D);  // grey
  static const Color ink = Color(0xFF1C2B2D);
  static const Color muted = Color(0xFF7A8C8E);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: accent,
          surface: card,
        ),
        textTheme: GoogleFonts.dmSansTextTheme().copyWith(
          displayLarge: GoogleFonts.dmSerifDisplay(
              fontSize: 30, fontWeight: FontWeight.w400, color: ink),
          titleLarge: GoogleFonts.dmSans(
              fontSize: 18, fontWeight: FontWeight.w700, color: ink),
          titleMedium: GoogleFonts.dmSans(
              fontSize: 15, fontWeight: FontWeight.w600, color: ink),
          bodyLarge:
              GoogleFonts.dmSans(fontSize: 14, color: ink),
          bodyMedium:
              GoogleFonts.dmSans(fontSize: 13, color: muted),
          labelSmall: GoogleFonts.dmSans(
              fontSize: 11, fontWeight: FontWeight.w500, color: muted),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.dmSans(
              fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        cardTheme: CardThemeData (
          color: card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: GoogleFonts.dmSans(
                fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: card,
          selectedItemColor: primary,
          unselectedItemColor: muted,
        ),
      );
}
