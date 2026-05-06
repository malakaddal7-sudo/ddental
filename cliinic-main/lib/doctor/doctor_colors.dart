import 'package:flutter/material.dart';

class DC {
  // ─────────────────────────────
  // BACKGROUND  (matches patient AppColors theme)
  // ─────────────────────────────
  static const Color bg = Color(0xFF0A0F1E);
  static const Color surface = Color(0xFF0F1A33);
  static const Color card = Color(0xFF0F1A33);

  static const LinearGradient bgGrad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0A0F1E),
      Color(0xFF0E1730),
    ],
  );

  // ─────────────────────────────
  // BORDERS
  // ─────────────────────────────
  static const Color border = Color(0xFF1A2A44);
  static const Color borderFaint = Color(0xFF0F1A33);

  // ─────────────────────────────
  // MAIN COLORS  (cyan/teal like patient)
  // ─────────────────────────────
  static const Color green = Color(0xFF10D7C8);      // neonTeal — matches patient accent
  static const Color greenGlow = Color(0x1A10D7C8);  // teal glow

  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF2EF3FF);        // neonCyan — matches patient info color

  // ─────────────────────────────
  // TEXT
  // ─────────────────────────────
  static const Color text = Color(0xFFEAF2FF);
  static const Color textSub = Color(0xFFA7B4D3);
  static const Color textMuted = Color(0xFFA7B4D3);

  // ─────────────────────────────
  // CARD STYLE
  // ─────────────────────────────
  static final BoxDecoration cardDecoration = BoxDecoration(
    color: card,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: border),
  );
}