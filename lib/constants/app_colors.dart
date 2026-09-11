import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primaryDark = Color.fromARGB(255, 29, 17, 62);
  static const Color primaryDarker = Color.fromARGB(255, 20, 12, 46);

  // Background colors
  static const Color bgDark = Color.fromARGB(128, 0, 0, 0);
  static const Color bgDarkTransparent = Color.fromARGB(100, 29, 17, 62);
  static const Color bgOverlay = Color.fromARGB(128, 2, 2, 2);
  static const Color bgPurple = Color.fromARGB(128, 128, 0, 128);

  // Status colors
  static const Color completedGreen = Color.fromARGB(128, 23, 135, 81);
  static const Color deleteRed = Color.fromARGB(128, 139, 21, 12);
  static const Color completeGreen = Color.fromARGB(128, 86, 183, 118);

  // Text colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textTertiary = Color.fromARGB(199, 255, 255, 255);

  // Accent colors
  static const Color accentGreen = Color.fromARGB(255, 59, 251, 148);
  static const Color accentGold = Color.fromARGB(255, 255, 191, 0);
  static const Color accentAmber = Colors.amberAccent;
  static const Color accentPurple = Colors.deepPurple;

  // Border colors
  static const Color borderLight = Colors.white24;
  static const Color borderMedium = Color.fromARGB(100, 255, 255, 255);
  static const Color borderTeal = Color.fromARGB(60, 22, 255, 174);

  // Gradient colors
  static const List<Color> xpGradient = [
    Color.fromARGB(255, 98, 0, 234),
    Color.fromARGB(255, 186, 104, 200),
    Color.fromARGB(255, 255, 171, 255),
    Color.fromARGB(255, 255, 255, 255),
  ];

  static const List<Color> statGradient = [
    Colors.redAccent,
    Colors.deepOrange,
    Colors.orange,
    Colors.yellowAccent,
    Colors.white70,
  ];

  // Shadow colors
  static const Color shadowPurple = Color.fromARGB(225, 230, 112, 251);
  static const Color shadowGold = Color.fromARGB(128, 255, 191, 0);
  static const Color shadowGreen = Colors.lightGreenAccent;
}
