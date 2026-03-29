import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextStyle get _base =>
      GoogleFonts.nunito();

  // ── DISPLAY ──────────────────────────
  // Hero numbers, greeting headline
  static TextStyle get displayXL =>
      _base.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        height: 1.1,
      );

  static TextStyle get displayLG =>
      _base.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.15,
      );

  static TextStyle get displaySM =>
      _base.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        height: 1.2,
      );

  // ── HEADLINE ─────────────────────────
  // Section titles, card headers
  static TextStyle get headlineMD =>
      _base.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.3,
      );

  static TextStyle get headlineSM =>
      _base.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.35,
      );

  // ── TITLE ────────────────────────────
  // Task names, list items
  static TextStyle get titleMD =>
      _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.4,
      );

  static TextStyle get titleSM =>
      _base.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.4,
      );

  static TextStyle get titleLG =>
      _base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.35,
      );

  // ── BODY ─────────────────────────────
  // Descriptions, notes
  static TextStyle get bodyMD =>
      _base.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.6,
      );

  static TextStyle get bodySM =>
      _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.55,
      );

  // ── LABEL ────────────────────────────
  // Buttons, badges, metadata
  static TextStyle get labelLG =>
      _base.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        height: 1.4,
      );

  static TextStyle get labelMD =>
      _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.4,
      );

  // ── CAPTION ──────────────────────────
  // Timestamps, metadata, dim text
  static TextStyle get caption =>
      _base.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.4,
      );

  // ── MICRO ────────────────────────────
  // Section headers, badges
  static TextStyle get micro =>
      _base.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        height: 1.3,
      );

  // ── MONOSPACE ────────────────────────
  // Redeem codes only
  static TextStyle get mono =>
      GoogleFonts.jetBrainsMono(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 2.5,
        height: 1.4,
      );

  // Backwards compat aliases
  static TextStyle get body => bodyMD;
  static TextStyle get headline => headlineMD;
  
  static TextStyle get displayLarge => displayXL;
  static TextStyle get displayMedium => displayLG;
  static TextStyle get headlineSmall => headlineSM;
  static TextStyle get titleMedium => titleMD;
  static TextStyle get titleSmall => titleSM;
  static TextStyle get bodyLarge => bodyMD;
  static TextStyle get bodyMedium => bodyMD;
  static TextStyle get labelLarge => labelLG;
  static TextStyle get labelMedium => labelMD;
  static TextStyle get labelSmall => caption;
  static TextStyle get title1 => displayLG;
  static TextStyle get taskTitle => displayLG;
  static TextStyle get callout => bodyMD;

  static TextStyle get bodySemibold => labelLG;
  static TextStyle get sectionHeader => micro;
  static TextStyle get metadata => caption;
  static TextStyle get title2 => headlineSM;
}
