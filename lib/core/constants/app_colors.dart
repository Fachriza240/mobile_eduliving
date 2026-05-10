import 'package:flutter/material.dart';

/// Sistem warna EduLiving
/// Brand utama : Biru tua (#1E40AF) — sesuai logo web
/// Hunian      : Biru  (#2563EB)
/// Acara       : Hijau (#16A34A)
/// Marketplace : Orange (#F97316)
class AppColors {
  AppColors._();

  // ── BRAND GLOBAL (biru tua) ──────────────────────────
  static const Color primary = Color(0xFF2563EB); // blue-600
  static const Color primaryDark = Color(0xFF1E40AF); // blue-800
  static const Color primaryDeep = Color(0xFF1D4ED8); // blue-700
  static const Color primaryMid = Color(0xFF3B82F6); // blue-500
  static const Color primaryLight = Color(0xFFEFF6FF); // blue-50
  static const Color primarySurface = Color(0xFFDBEAFE); // blue-100

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
  );

  // ── MODUL HUNIAN (biru) ──────────────────────────────
  static const Color residence = Color(0xFF2563EB);
  static const Color residenceDark = Color(0xFF1D4ED8);
  static const Color residenceLight = Color(0xFFEFF6FF);
  static const Color residenceSurface = Color(0xFFDBEAFE);

  static const LinearGradient residenceGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
  );

  // ── MODUL ACARA (hijau) ──────────────────────────────
  static const Color activity = Color(0xFF16A34A);
  static const Color activityDark = Color(0xFF15803D);
  static const Color activityLight = Color(0xFFF0FDF4);
  static const Color activitySurface = Color(0xFFDCFCE7);

  static const LinearGradient activityGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF15803D), Color(0xFF22C55E)],
  );

  // ── MODUL MARKETPLACE (orange) ───────────────────────
  static const Color market = Color(0xFFF97316);
  static const Color marketDark = Color(0xFFEA580C);
  static const Color marketLight = Color(0xFFFFF7ED);
  static const Color marketSurface = Color(0xFFFFEDD5);

  static const LinearGradient marketGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFF97316), Color(0xFFEA580C)],
  );

  // ── NEUTRALS ─────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color border = Color(0xFFE5E7EB);

  // ── TEXT ─────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── SEMANTIC ─────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFEFF6FF);

  // ── NAVBAR ───────────────────────────────────────────
  static const Color navBackground = Color(0xFFFFFFFF);
  static const Color navSelected = Color(0xFF2563EB);
  static const Color navUnselected = Color(0xFF9CA3AF);

  // ── SHADOW ───────────────────────────────────────────
  static const Color shadow = Color(0x0A000000);
}
