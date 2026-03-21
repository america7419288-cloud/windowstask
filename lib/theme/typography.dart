import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextStyle get _base => GoogleFonts.inter();

  // ── DISPLAY — daily headers, hero text ───────────
  static TextStyle get displayLarge => _base.copyWith(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.02 * 36,
    height: 1.1,
  );

  static TextStyle get displayMedium => _base.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.02 * 28,
    height: 1.15,
  );

  // ── HEADLINE — section titles ────────────────────
  static TextStyle get headlineSmall => _base.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.01 * 20,
    height: 1.2,
  );

  // ── TITLE — task names (workhorse) ───────────────
  static TextStyle get titleMedium => _base.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.01 * 15,
    height: 1.4,
  );

  static TextStyle get titleSmall => _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.4,
  );

  // ── BODY — descriptions, notes ───────────────────
  static TextStyle get bodyLarge => _base.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.6,
  );

  static TextStyle get bodyMedium => _base.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.55,
  );

  // ── LABEL — metadata, chips, badges ──────────────
  static TextStyle get labelLarge => _base.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.02 * 12,
    height: 1.4,
  );

  static TextStyle get labelMedium => _base.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.02 * 11,
    height: 1.4,
  );

  static TextStyle get labelSmall => _base.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.04 * 10,
    height: 1.4,
  );

  // ── CAPTION — timestamps, secondary metadata ─────
  static TextStyle get caption => _base.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.4,
  );

  // ── MICRO — chips, tags, badges ──────────────────
  static TextStyle get micro => _base.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.03 * 10,
    height: 1.3,
  );

  // ── BACKWARD COMPATIBILITY ALIASES ───────────────
  static TextStyle get body => bodyMedium;
  static TextStyle get bodySemibold =>
      bodyMedium.copyWith(fontWeight: FontWeight.w600);
  static TextStyle get headline => headlineSmall;
  static TextStyle get title1 => displayMedium;
  static TextStyle get title2 => headlineSmall;
  static TextStyle get callout => bodyMedium;
  static TextStyle get calloutMedium =>
      bodyMedium.copyWith(fontWeight: FontWeight.w500);
  static TextStyle get calloutSemibold =>
      bodyMedium.copyWith(fontWeight: FontWeight.w600);
  static TextStyle get taskTitle => titleMedium.copyWith(
    fontWeight: FontWeight.w600,
  );
  static TextStyle get sectionHeader => labelLarge.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.08,
    color: const Color(0xFF94A3B8),
  );
  static TextStyle get metadata => caption;
  static TextStyle get largeTitle => displayLarge;
}
