import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/theme/da_colors.dart';

class DATextStyles {
  // HEADINGS
  static TextStyle get heading1 => GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: DAColors.white,
      );

  static TextStyle get heading2 => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: DAColors.white,
      );

  static TextStyle get heading3 => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: DAColors.black,
      );

  // SUBTITLES
  static TextStyle get subtitle1 => GoogleFonts.poppins(
        fontSize: 14,
        color: DAColors.white,
      );

  static TextStyle get subtitle2 => GoogleFonts.poppins(
        fontSize: 14,
        color: DAColors.black,
      );

  // BODY
  static TextStyle get body1 => GoogleFonts.poppins(
        fontSize: 16,
        color: DAColors.black,
      );

  static TextStyle get body2 => GoogleFonts.poppins(
        fontSize: 14,
        color: DAColors.black,
      );

  // BUTTON
  static TextStyle get button => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: DAColors.white,
      );

  // CARD
  static TextStyle get cardName => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: DAColors.black,
      );

  static TextStyle get cardSubtitle => GoogleFonts.poppins(
        fontSize: 14,
        color: Colors.grey,
      );

  static TextStyle get cardDate => GoogleFonts.poppins(
        fontSize: 12,
        color: Colors.grey,
      );
}