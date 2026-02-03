import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/theme/da_colors.dart';

/// HomeTile - Reusable tile component for home screen
/// Responsive and scales perfectly for all screen sizes
/// FIXED: Opacity clamped to prevent assertion errors
class HomeTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? route;
  final VoidCallback? onTap;
  final Animation<double>? animation;

  const HomeTile({
    super.key,
    required this.label,
    required this.icon,
    this.route,
    this.onTap,
    this.animation,
  });

  @override
  Widget build(BuildContext context) {
    Widget tile = GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else if (route != null) {
          Navigator.pushNamed(context, route!);
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Get tile dimensions for responsive sizing
          final size = constraints.maxWidth;
          
          // Calculate responsive values
          final iconSize = size * 0.35; // Icon is 35% of tile size
          final fontSize = size * 0.16; // Font is 16% of tile size
          final spacing = size * 0.08; // Spacing is 8% of tile size
          final borderRadius = size * 0.15; // Border radius is 15% of tile size

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: DAColors.primaryGreen,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: iconSize,
                  color: Colors.white,
                ),
                SizedBox(height: spacing),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: size * 0.08),
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Apply animation if provided - WITH CLAMPING TO FIX ERROR
    if (animation != null) {
      return AnimatedBuilder(
        animation: animation!,
        builder: (context, child) {
          // CRITICAL FIX: Clamp animation value to 0.0-1.0
          final clampedValue = animation!.value.clamp(0.0, 1.0);
          
          return Opacity(
            opacity: clampedValue, // Use clamped value
            child: Transform.scale(
              scale: clampedValue, // Use clamped value
              child: tile,
            ),
          );
        },
      );
    }

    return tile;
  }
}