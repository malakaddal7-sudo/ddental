import 'package:flutter/material.dart';

class AppColors {
  // ── Backgrounds ──────────────────────────────────────────────────────────
  static const Color bg0 = Color(0xFF0A0F1E);
  static const Color bg1 = Color(0xFF0E1730);
  static const Color panel = Color(0xFF0F1A33);
  static const Color panel2 = Color(0xFF0D162D);

  /// Alias used by patient screens (notifications, profile, etc.)
  static const Color bg = bg0;

  /// Top app-bar / surface background — slightly lighter than bg
  static const Color surface = Color(0xFF0D1528);

  /// Card background
  static const Color card = Color(0xFF111D36);

  // ── Borders / dividers ───────────────────────────────────────────────────
  static const Color border = Color(0xFF1A2A44);
  static const Color stroke = Color(0xFF1A2A44); // kept for legacy callers

  // ── Accent — cyan / teal ─────────────────────────────────────────────────
  static const Color neonCyan = Color(0xFF2EF3FF);
  static const Color neonTeal = Color(0xFF10D7C8);
  static const Color tealDeep = Color(0xFF0A7E8D);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const Color text = Color(0xFFEAF2FF);

  /// Secondary / sub text
  static const Color textSub = Color(0xFFCBD8F0);
  static const Color textMuted = Color(0xFFA7B4D3);

  // ── Semantic colours ──────────────────────────────────────────────────────
  static const Color danger = Color(0xFFFF4C6A);
  static const Color success = Color(0xFF00E5A0);
  static const Color warning = Color(0xFFFFB300);
  static const Color info = Color(0xFF29B6F6);

  // ── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [bg0, bg1],
  );

  static LinearGradient accentGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [neonTeal, tealDeep],
  );

  static const LinearGradient registerBgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color.fromARGB(255, 27, 38, 69), Color.fromARGB(255, 27, 40, 71)],
  );

  // ── Decorations ──────────────────────────────────────────────────────────
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: panel.withOpacity(0.85),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: neonCyan.withOpacity(0.18), width: 0.8),
  );
}
