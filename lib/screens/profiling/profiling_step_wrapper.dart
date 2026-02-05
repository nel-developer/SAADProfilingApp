import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/theme/da_colors.dart';
import 'package:da_project_1/widgets/green_header_section.dart';
import 'package:da_project_1/widgets/stepper_header.dart';
import 'package:da_project_1/screens/profiling/step_01_personal_info.dart';
import 'package:da_project_1/screens/profiling/step_02_address_info.dart';
import 'package:da_project_1/screens/profiling/step_03_other_personal.dart';
import 'package:da_project_1/screens/profiling/step_04_main_commodity.dart';
import 'package:da_project_1/screens/profiling/step_05_recurrence.dart';
import 'package:da_project_1/screens/profiling/step_06_monthly_income.dart';
import 'package:da_project_1/screens/profiling/step_07_farm_income.dart';
import 'package:da_project_1/screens/profiling/step_08_signature.dart';

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

      case 3:
        return Step03OtherPersonal(
          onNext: _goToNextStep,
          onBack: _goToPreviousStep,
          onHeaderBack: _goToHome,
        );

      case 4:
        return Step04MainCommodity(
          onNext: _goToNextStep,
          onBack: _goToPreviousStep,
          onHeaderBack: _goToHome,
        );

      case 5:
        return Step05Recurrence(
          onNext: _goToNextStep,
          onBack: _goToPreviousStep,
          onHeaderBack: _goToHome,
        );

      case 6:
        return Step06MonthlyIncome(
          onNext: _goToNextStep,
          onBack: _goToPreviousStep,
          onHeaderBack: _goToHome,
        );

      case 7:
        return Step07FarmIncome(
          onNext: _goToNextStep,
          onBack: _goToPreviousStep,
          onHeaderBack: _goToHome,
        );

      case 8:
        return Step08Signature(
          onNext: _submitForm, // Final step — submits form
          onBack: _goToPreviousStep,
          onHeaderBack: _goToHome,
        );

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
  late Animation<double> _headerOpacityAnim;
  late Animation<double> _headerSlideAnim;
  late Animation<double> _leafLeftAnim;
  late Animation<double> _leafRightAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Header animations (like AccountsScreen)
    _headerOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _headerSlideAnim = Tween<double>(begin: -40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _leafLeftAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _leafRightAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.1, 0.6, curve: Curves.easeOut),
      ),
    );

    // Form body animations
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.3, 0.9, curve: Curves.easeOut)),
    );
    _slideAnim = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.3, 1.0, curve: Curves.easeOut)),
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

    // Responsive breakpoints
    final isTablet = width > 600;
    final isLargeTablet = width > 900;

    // Header sizing
    final headerHeight = height * (isLargeTablet ? 0.18 : isTablet ? 0.22 : 0.28);
    final titleFontSize = isLargeTablet ? 36.0 : isTablet ? 30.0 : width * 0.065;
    final subtitleFontSize = isLargeTablet ? 14.0 : isTablet ? 12.0 : width * 0.03;
    final backButtonSize = isTablet ? 28.0 : 24.0;

    // Content sizing
    final contentHPad = width * 0.06;
    final sectionTitleSize = isLargeTablet ? 20.0 : isTablet ? 18.0 : 17.0;
    final sectionSpacing = isTablet ? 18.0 : 14.0;

    // Bottom buttons
    final bottomPad = isTablet ? 28.0 : 24.0;
    final nextHeight = isLargeTablet ? 56.0 : isTablet ? 52.0 : 50.0;
    final nextFontSize = isLargeTablet ? 18.0 : isTablet ? 17.0 : 16.0;
    final backFontSize = isLargeTablet ? 15.0 : isTablet ? 14.0 : 13.0;

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
                GreenHeaderSection(
                  leafLeftAnimation: _leafLeftAnim,
                  leafRightAnimation: _leafRightAnim,
                  customHeight: headerHeight,
                ),

                // HEADER CONTENT with animations
                AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _headerOpacityAnim.value.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, _headerSlideAnim.value),
                        child: child!,
                      ),
                    );
                  },
                  child: Container(
                    height: headerHeight,
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.06,
                      vertical: height * 0.025,
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Row(
                        children: [
                          /// BACK BUTTON
                          GestureDetector(
                            onTap: widget.onHeaderBack ??
                                () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_back,
                                color: DAColors.primaryGreen,
                                size: backButtonSize,
                              ),
                            ),
                          ),

                          const Spacer(),

                          /// TITLE & SUBTITLE (CENTERED)
                          Expanded(
                            flex: 3,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Profiling',
                                  style: GoogleFonts.poppins(
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1.2,
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.visible,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Farmers/Fisherfolks Profiling Form',
                                  style: GoogleFonts.poppins(
                                    fontSize: subtitleFontSize,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white.withOpacity(0.9),
                                    height: 1.3,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.visible,
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          /// INVISIBLE SPACER FOR CENTERING
                          SizedBox(width: isTablet ? 52 : 48),
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
                      DAColors.primaryGreen.withOpacity(0.5),
                    ),
                    thickness: MaterialStateProperty.all(4.0),
                    radius: const Radius.circular(8),
                  ),
                ),
                child: Scrollbar(
                  thumbVisibility: true,
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
                        SizedBox(height: sectionSpacing),

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
            padding: EdgeInsets.fromLTRB(
              contentHPad,
              12.0,
              contentHPad,
              bottomPad,
            ),
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
                      borderRadius: BorderRadius.circular(26),
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
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 24,
                        ),
                        child: Text(
                          'Back',
                          style: GoogleFonts.poppins(
                            fontSize: backFontSize,
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