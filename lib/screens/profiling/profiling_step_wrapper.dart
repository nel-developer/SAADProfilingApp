import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/theme/da_colors.dart';
import 'package:da_project_1/widgets/green_header_section.dart';
import 'package:da_project_1/widgets/stepper_header.dart';
import 'package:da_project_1/screens/profiling/step_01_personal_info.dart';
import 'package:da_project_1/screens/profiling/step_02_address_info.dart';
// Import other steps as you create them
// import 'package:da_project_1/screens/profiling/step_03_other_personal.dart';
// etc...

// ════════════════════════════════════════════════════════════════════════════
// PROFILING FLOW - Main Entry Point
// ════════════════════════════════════════════════════════════════════════════

/// ProfilingFlow - Parent widget that manages all 8 profiling steps
class ProfilingFlow extends StatefulWidget {
  const ProfilingFlow({super.key});

  @override
  State<ProfilingFlow> createState() => _ProfilingFlowState();
}

class _ProfilingFlowState extends State<ProfilingFlow> {
  int _currentStep = 1;

  void _goToNextStep() {
    if (_currentStep < 8) {
      setState(() {
        _currentStep++;
      });
    } else {
      _submitForm();
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _goToHome() {
    Navigator.pop(context);
  }

  void _submitForm() {
    // TODO: Handle form submission (Step 8)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: const Text('Profiling form submitted!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentStep) {
      case 1:
        return Step01PersonalInfo(
          onNext: _goToNextStep,
          onHeaderBack: _goToHome,
        );
      
      case 2:
        return Step02AddressInfo(
          onNext: _goToNextStep,
          onBack: _goToPreviousStep,
          onHeaderBack: _goToHome,
        );
      
      // Add other steps as you create them
      // case 3:
      //   return Step03OtherPersonal(
      //     onNext: _goToNextStep,
      //     onBack: _goToPreviousStep,
      //     onHeaderBack: _goToHome,
      //   );
      
      default:
        return Step01PersonalInfo(
          onNext: _goToNextStep,
          onHeaderBack: _goToHome,
        );
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PROFILING STEP WRAPPER - Shared Layout for All Steps
// ════════════════════════════════════════════════════════════════════════════

/// ProfilingStepWrapper
///
/// Shared animated layout shell for every profiling step.
///
/// Structure (top → bottom):
///   1. Green header   — leaf bg + back arrow + "Profiling" title + subtitle
///   2. StepperHeader  — animated line progress bar (8 segments)
///   3. Scrollable body — section title + child form (fade+slide in)
///   4. Pinned bottom  — Next button (+ optional Back on step ≥ 2)
///
/// Uses DAColors & DATextStyles throughout.  Form body fades + slides up on build.
class ProfilingStepWrapper extends StatefulWidget {
  final int currentStep;
  final String sectionTitle;
  final Widget child;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback? onHeaderBack;

  const ProfilingStepWrapper({
    super.key,
    required this.currentStep,
    required this.sectionTitle,
    required this.child,
    required this.onNext,
    this.onBack,
    this.onHeaderBack,
  });

  @override
  State<ProfilingStepWrapper> createState() => _ProfilingStepWrapperState();
}

class _ProfilingStepWrapperState extends State<ProfilingStepWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.8, curve: Curves.easeOut)),
    );
    _slideAnim = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.9, curve: Curves.easeOut)),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    final isTablet = width > 600;
    final isLargeTablet = width > 900;

    // ── header ──
    final double headerHeight = height * (isLargeTablet ? 0.22 : isTablet ? 0.25 : 0.30);
    final double titleFontSize = isLargeTablet ? 42.0 : isTablet ? 34.0 : width * 0.075;
    final double subtitleFontSize = isLargeTablet ? 16.0 : isTablet ? 14.0 : width * 0.035;

    // ── body ──
    final double contentHPad = isLargeTablet ? 48.0 : isTablet ? 32.0 : width * 0.055;
    final double sectionTitleSize = isLargeTablet ? 24.0 : isTablet ? 20.0 : 18.0;

    // ── bottom ──
    final double bottomPad = isLargeTablet ? 36.0 : isTablet ? 28.0 : 24.0;
    final double nextHeight = isLargeTablet ? 58.0 : isTablet ? 52.0 : 50.0;
    final double nextFontSize = isLargeTablet ? 20.0 : isTablet ? 18.0 : 17.0;
    final double nextRadius = isLargeTablet ? 30.0 : isTablet ? 28.0 : 26.0;

    return Scaffold(
      backgroundColor: DAColors.lightGrey,
      body: Column(
        children: [
          // ==============================================================
          // 1. GREEN HEADER
          // ==============================================================
          SizedBox(
            height: headerHeight,
            child: Stack(
              children: [
                GreenHeaderSection(customHeight: headerHeight),

                // Back arrow - positioned at TOP LEFT, overlapping header
                Positioned(
                  left: contentHPad,
                  top: isLargeTablet ? 32.0 : isTablet ? 26.0 : 22.0,
                  child: SafeArea(
                    bottom: false,
                    child: GestureDetector(
                      onTap: widget.onHeaderBack ?? () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(12), // ← Padding inside circle
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9), // ← Slight transparency
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: DAColors.primaryGreen,
                          size: isLargeTablet ? 28 : isTablet ? 24 : 22, // ← Responsive icon size
                        ),
                      ),
                    ),
                  ),
                ),

                // Title + subtitle - centered
                Positioned.fill(
                  child: SafeArea(
                    bottom: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Profiling',
                            style: GoogleFonts.poppins(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w800,
                              color: DAColors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Farmers/Fisherfolks Profiling Form',
                            style: GoogleFonts.poppins(
                              fontSize: subtitleFontSize,
                              fontWeight: FontWeight.w400,
                              color: DAColors.white.withOpacity(0.88),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ==============================================================
          // 2. ANIMATED LINE PROGRESS BAR
          // ==============================================================
          StepperHeader(currentStep: widget.currentStep),

          // ==============================================================
          // 3. SCROLLABLE FORM BODY  — fade + slide up on entry
          // ==============================================================
          Expanded(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnim.value.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, _slideAnim.value),
                    child: child!,
                  ),
                );
              },
              child: Theme(
                data: Theme.of(context).copyWith(
                  scrollbarTheme: ScrollbarThemeData(
                    thumbColor: MaterialStateProperty.all(
                      DAColors.primaryGreen.withOpacity(0.5), // ← Light green!
                    ),
                    thickness: MaterialStateProperty.all(4.0),
                    radius: const Radius.circular(8),
                  ),
                ),
                child: Scrollbar(
                  thumbVisibility: true, // ← Always show scrollbar
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: contentHPad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // section title
                        Text(
                          widget.sectionTitle,
                          style: GoogleFonts.poppins(
                            fontSize: sectionTitleSize,
                            fontWeight: FontWeight.w800,
                            color: DAColors.black,
                          ),
                        ),
                        SizedBox(height: isLargeTablet ? 20.0 : 16.0),

                        // form fields (child)
                        widget.child,

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ==============================================================
          // 4. PINNED BOTTOM  — Next + optional Back
          // ==============================================================
          Container(
            color: DAColors.lightGrey,
            padding: EdgeInsets.fromLTRB(contentHPad, 12.0, contentHPad, bottomPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── NEXT ──
                GestureDetector(
                  onTap: widget.onNext,
                  child: Container(
                    height: nextHeight,
                    decoration: BoxDecoration(
                      color: DAColors.orange,
                      borderRadius: BorderRadius.circular(nextRadius),
                      boxShadow: [
                        BoxShadow(
                          color: DAColors.orange.withOpacity(0.40),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.currentStep < 8 ? 'Next' : 'Submit',
                        style: GoogleFonts.poppins(
                          fontSize: nextFontSize,
                          fontWeight: FontWeight.w700,
                          color: DAColors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── BACK (step ≥ 2 only) — centred vertically in remaining gap ──
                if (widget.onBack != null) ...[
                  const SizedBox(height: 18),
                  Center(
                    child: GestureDetector(
                      onTap: widget.onBack,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 24),
                        child: Text(
                          'Back',
                          style: GoogleFonts.poppins(
                            fontSize: isLargeTablet ? 15.0 : 14.0,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}