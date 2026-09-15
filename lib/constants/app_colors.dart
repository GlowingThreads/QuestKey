import 'package:flutter/material.dart';

/// Colour language of the app, taken from the artwork: obsidian and deep
/// amethyst grounds, bronze frames, teal gems, gold highlights.
class AppColors {
  // Grounds
  static const Color obsidian = Color(0xFF0B0718);
  static const Color midnight = Color(0xFF140C2E);
  static const Color amethyst = Color(0xFF3A1C71);
  static const Color amethystBright = Color(0xFF7B3FE4);
  static const Color magenta = Color(0xFFC542F5);

  // Metals and gems
  static const Color bronze = Color(0xFF8C6239);
  static const Color bronzeLight = Color(0xFFC89B5C);
  static const Color gold = Color(0xFFE8C46A);
  static const Color teal = Color(0xFF2EE6C5);
  static const Color arcaneBlue = Color(0xFF4FC3F7);
  static const Color ruby = Color(0xFFE05A5A);

  // Text
  static const Color ink = Color(0xFFF3ECDC);
  static const Color inkMuted = Color(0xFFB8AFC9);
  static const Color parchment = Color(0xFFEFE4C8);

  // ---- Legacy names kept so older widgets keep compiling ----
  static const Color primaryDark = midnight;
  static const Color primaryDarker = obsidian;
  static const Color bgDark = Color(0xCC140C2E);
  static const Color bgDarkTransparent = Color(0x99140C2E);
  static const Color bgOverlay = Color(0xB30B0718);
  static const Color bgPurple = Color(0xB33A1C71);
  static const Color completedGreen = Color(0x991F6B5C);
  static const Color deleteRed = Color(0xB37A1E1E);
  static const Color completeGreen = Color(0xB31F8F86);
  static const Color textPrimary = ink;
  static const Color textSecondary = inkMuted;
  static const Color textTertiary = Color(0xCCF3ECDC);
  static const Color accentGreen = teal;
  static const Color accentGold = gold;
  static const Color accentAmber = gold;
  static const Color accentPurple = amethystBright;
  static const Color borderLight = Color(0x668C6239);
  static const Color borderMedium = Color(0x99C89B5C);
  static const Color borderTeal = Color(0x552EE6C5);
  static const List<Color> xpGradient = [
    amethyst,
    amethystBright,
    magenta,
    gold,
  ];
  static const List<Color> statGradient = [bronze, bronzeLight, gold];
  static const Color shadowPurple = Color(0xE07B3FE4);
  static const Color shadowGold = Color(0x80E8C46A);
  static const Color shadowGreen = teal;
}
