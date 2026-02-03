import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/theme/da_colors.dart';


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
          final size = constraints.maxWidth;

          // Proportional values WITH hard caps so they don't blow up
          final iconSize   = (size * 0.28).clamp(28.0, 48.0);
          final fontSize   = (size * 0.12).clamp(12.0, 18.0);
          final spacing    = (size * 0.05).clamp(4.0, 10.0);
          final borderRadius = (size * 0.18).clamp(12.0, 24.0);

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
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  /// Icon + Label column
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: iconSize,
                        color: Colors.white,
                      ),
                      SizedBox(height: spacing),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: size * 0.05),
                        child: Text(
                          label,
                          style: GoogleFonts.poppins(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  /// Lock overlay (disabled state)
                  if (!isEnabled)
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(borderRadius),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.lock,
                          size: iconSize * 0.7,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );

    /// Animation wrapper
    if (animation != null) {
      return AnimatedBuilder(
        animation: animation!,
        builder: (context, child) {
          final clampedValue = animation!.value.clamp(0.0, 1.0);
          return Opacity(
            opacity: clampedValue,
            child: Transform.scale(
              scale: clampedValue,
              child: tile,
            ),
          );
        },
      );
    }

    return tile;
  }
}