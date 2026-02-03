import 'package:flutter/material.dart';
import 'package:da_project_1/theme/da_colors.dart';

/// StepperHeader — Animated line-only progress bar (no dots, no numbers).
///
/// 8 segments separated by small gaps. Completed segments are green,
/// upcoming segments are light grey. Uses AnimatedContainer so each
/// segment smoothly transitions colour when the step advances.
/// A subtle drop-shadow gives the bar some depth.
class StepperHeader extends StatelessWidget {
  /// 1-based current step (1 … totalSteps).
  final int currentStep;
  final int totalSteps;

  const StepperHeader({
    super.key,
    required this.currentStep,
    this.totalSteps = 8,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final isTablet = width > 600;
    final isLargeTablet = width > 900;

    // Responsive values
    final double thickness = isLargeTablet ? 7.0 : isTablet ? 6.0 : 5.0;
    final double radius = thickness / 2;
    final double gap = isLargeTablet ? 6.0 : isTablet ? 5.0 : 4.0;
    final double hPad = isLargeTablet ? 48.0 : isTablet ? 32.0 : width * 0.055;
    final double vPad = isLargeTablet ? 18.0 : isTablet ? 16.0 : 14.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalSteps, (index) {
          final bool filled = (index + 1) <= currentStep;

          return Expanded(
            child: Padding(
              // Gap between each segment (no gap on the very last one's right)
              padding: EdgeInsets.only(right: index < totalSteps - 1 ? gap : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                height: thickness,
                decoration: BoxDecoration(
                  color: filled ? DAColors.primaryGreen : const Color(0xFFD5D5D5),
                  borderRadius: BorderRadius.circular(radius),
                  boxShadow: [
                    BoxShadow(
                      color: filled
                          ? DAColors.primaryGreen.withOpacity(0.30)
                          : Colors.black.withOpacity(0.08),
                      blurRadius: filled ? 6.0 : 3.0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}