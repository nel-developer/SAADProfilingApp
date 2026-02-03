import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// StatusBadge - Reusable badge for status indicators
/// Used for Active/Inactive, Admin/Profiler/Moderator badges
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool isOutline;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.isOutline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isOutline ? Colors.white : color.withOpacity(0.15),
        border: isOutline ? Border.all(color: color, width: 2) : null,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}