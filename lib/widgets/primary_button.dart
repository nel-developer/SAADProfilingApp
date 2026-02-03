import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// PrimaryButton - Reusable CTA button
/// Used for Accept, Decline, Edit, and other action buttons
class PrimaryButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;
  final bool isSmall;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
    this.fontSize,
    this.padding,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ??
            EdgeInsets.symmetric(
              horizontal: isSmall ? 20 : 24,
              vertical: isSmall ? 8 : 14,
            ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: fontSize ?? (isSmall ? 13 : 16),
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}