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
  final bool isEnabled;
  final VoidCallback? onDisabledTap;

  const HomeTile({
    super.key,
    required this.label,
    required this.icon,
    this.route,
    this.onTap,
    this.animation,
    this.isEnabled = true,
    this.onDisabledTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget tile = GestureDetector(
      onTap: () {
        if (!isEnabled) {
          if (onDisabledTap != null) {
            onDisabledTap!();
          }
          return;
        }
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
              color: isEnabled ? DAColors.primaryGreen : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isEnabled ? 0.1 : 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
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
                if (!isEnabled)
                  Positioned.fill(
                    child: Center(
                      child: Icon(
                        Icons.lock,
                        size: iconSize * 0.8,
                        color: Colors.white.withOpacity(0.7),
                      ),
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