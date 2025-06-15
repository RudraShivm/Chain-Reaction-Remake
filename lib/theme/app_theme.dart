import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static Color primaryColor = Colors.black;
  static Color secondaryColorBlue = const Color.fromARGB(255, 0, 50, 92);
  static Color secondaryColorRed = const Color.fromARGB(255, 80, 16, 11);
  static Color blueOrbColor = const Color.fromARGB(255, 230, 229, 229);
  static Color blueBoxColor = const Color.fromARGB(255, 63, 103, 235);
  static Color redOrbColor = const Color.fromARGB(255, 46, 46, 46);
  static Color redBoxColor = const Color.fromARGB(255, 228, 67, 67);
  static Color backgroundGradientStart = Color.fromARGB(255, 11, 18, 21);
  static Color backgroundGradientBlueEnd = secondaryColorBlue.withOpacity(0.01);
  static Color backgroundGradientRedEnd = secondaryColorRed.withOpacity(0.01);

  static ThemeData get theme => ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: GoogleFonts.latoTextTheme().apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor.withOpacity(0.9),
      elevation: 0,
      titleTextStyle: GoogleFonts.oxanium(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
  );
}