import 'package:flutter/material.dart';
import 'package:da_project_1/theme/da_colors.dart';

/// GreenHeaderSection - Reusable green header background with leaf decorations
/// 
/// FINAL PERFECT VERSION:
/// - Phone: Leaves DON'T overlap (stay at edges)
/// - Tablet/Large: Leaves STRETCH towards center
/// - Fully responsive, no conflicts
/// - 3.png on LEFT, 2.png on RIGHT
class GreenHeaderSection extends StatelessWidget {
  final Animation<double>? leafLeftAnimation;
  final Animation<double>? leafRightAnimation;
  final double? customHeight;

  const GreenHeaderSection({
    super.key,
    this.leafLeftAnimation,
    this.leafRightAnimation,
    this.customHeight,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    // Detect screen type
    final isTablet = width > 600;
    final isLargeTablet = width > 900;

    // Calculate responsive header height
    final headerHeight = customHeight ?? 
        (height * (isLargeTablet ? 0.18 : isTablet ? 0.22 : 0.28));

    // CRITICAL FIX: Different sizes for phone vs tablet
    final leafWidth = isLargeTablet
        ? width * 0.85  // Large tablet: 85% - stretches to center
        : isTablet
            ? width * 0.75  // Tablet: 75% - good coverage
            : width * 0.50; // PHONE: 50% ONLY - prevents overlap! ✅

    final leafOverflow = isLargeTablet
        ? width * 0.12  
        : isTablet
            ? width * 0.10  
            : width * 0.05; // PHONE: Less overflow

    return ClipRRect(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(width * 0.08),
        bottomRight: Radius.circular(width * 0.08),
      ),
      child: SizedBox(
        height: headerHeight,
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            /// GREEN HEADER BACKGROUND
            Container(
              height: headerHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                color: DAColors.primaryGreen,
              ),
            ),

            /// LEFT LEAF (3.png)
            Positioned(
              left: -leafOverflow,
              top: -headerHeight * 0.05,
              bottom: 0,
              child: SizedBox(
                width: leafWidth,
                child: _buildLeafWithAnimation(
                  leafLeftAnimation,
                  'assets/images/3.png',
                  Alignment.centerLeft,
                  isTablet,
                  true,
                ),
              ),
            ),

            /// RIGHT LEAF (2.png)
            Positioned(
              right: -leafOverflow,
              top: -headerHeight * 0.05,
              bottom: 0,
              child: SizedBox(
                width: leafWidth,
                child: _buildLeafWithAnimation(
                  leafRightAnimation,
                  'assets/images/2.png',
                  Alignment.centerRight,
                  isTablet,
                  false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeafWithAnimation(
    Animation<double>? animation,
    String assetPath,
    Alignment alignment,
    bool isTablet,
    bool isLeft,
  ) {
    final leafImage = Image.asset(
      assetPath,
      fit: BoxFit.contain,
      alignment: alignment,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.green.withOpacity(0.15),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.eco,
                  size: isTablet ? 80 : 60,
                  color: Colors.green.shade700,
                ),
                const SizedBox(height: 4),
                Text(
                  isLeft ? 'LEFT\n3.png' : 'RIGHT\n2.png',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (animation != null) {
      return AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          // Clamp animation value to prevent errors
          final clampedValue = animation.value.clamp(0.0, 1.0);
          return Opacity(
            opacity: clampedValue,
            child: child!,
          );
        },
        child: leafImage,
      );
    }

    return leafImage;
  }
}