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
import 'package:da_project_1/models/profiling_data.dart';
import 'package:da_project_1/services/profiling_storage_service.dart';

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// PROFILING FLOW - Main Entry Point
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

/// ProfilingFlow - Parent widget that manages all 8 profiling steps
class ProfilingFlow extends StatefulWidget {
  const ProfilingFlow({super.key});

  @override
  State<ProfilingFlow> createState() => _ProfilingFlowState();
}

class _ProfilingFlowState extends State<ProfilingFlow> {
  int _currentStep = 1;
  ProfilingData _currentData = ProfilingData();
  final ProfilingStorageService _storage = ProfilingStorageService();
  bool _formSubmittedSuccessfully = false; // Track if form was submitted

  @override
  void initState() {
    super.initState();
    _loadDraftIfExists();
    // Do NOT auto-generate temp ID on flow open — only when saving to Firestore
  }

  @override
  void dispose() {
    // NEVER auto-delete draft on dispose
    // User data is precious - keep it even if they navigate away
    // Only delete if user explicitly taps "Cancel" button
    if (_formSubmittedSuccessfully) {
      debugPrint('✅ Form submitted successfully - draft will be shown as local unsync');
    }
    super.dispose();
  }

  // Temp ID generation removed — only set when saving to Firestore pending collection

  Future<void> _loadDraftIfExists() async {
    try {
      final draft = await _storage.loadDraftLocally();
      if (!mounted) return;
      if (draft != null) {
        setState(() {
          _currentData = draft;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading draft: $e');
    }
  }

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
    // User clicked home button — ask if they want to keep or discard draft
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard Draft?'),
        content: const Text('Your unsaved data will be deleted. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Keep Draft'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await _storage.deleteDraftLocally();
                debugPrint('✅ Draft deleted by user request');
                if (!mounted) return;
                Navigator.pop(context);
              } catch (e) {
                debugPrint('⚠️ Error deleting draft: $e');
                if (!mounted) return;
                Navigator.pop(context);
              }
            },
            child: const Text('Discard', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    // Centralized final validation before saving
    final missing = <int, List<String>>{};

    void addMissing(int step, String label) {
      missing.putIfAbsent(step, () => []).add(label);
    }

    // Step 1 - Personal Info
    if (_currentData.firstName == null || _currentData.firstName!.trim().isEmpty) addMissing(1, 'First Name');
    if (_currentData.middleName == null || _currentData.middleName!.trim().isEmpty) addMissing(1, 'Middle Name');
    if (_currentData.surname == null || _currentData.surname!.trim().isEmpty) addMissing(1, 'Surname');
    // extensionName is exempt
    if (_currentData.dateOfBirth == null || _currentData.dateOfBirth!.trim().isEmpty) addMissing(1, 'Date of Birth');
    if (_currentData.sex == null || _currentData.sex!.trim().isEmpty) addMissing(1, 'Sex');

    // Step 2 - Address (optional)
    // Address fields are intentionally optional; do not block submission if empty.

    // Step 3 - Other Personal
    if (_currentData.isIndigenous == null) addMissing(3, 'Is Indigenous');
    if ((_currentData.isIndigenous ?? false) && (_currentData.indigenousGroup == null || _currentData.indigenousGroup!.trim().isEmpty)) addMissing(3, 'Indigenous Group');
    if (_currentData.isPWD == null) addMissing(3, 'Is PWD');
    // spouseName is exempt (not required)
    if (_currentData.tribeEthnicity == null || _currentData.tribeEthnicity!.trim().isEmpty) addMissing(3, 'Tribe / Ethnicity');

    // Step 4 - Main Commodity
    if (_currentData.primaryCommodity == null || _currentData.primaryCommodity!.trim().isEmpty) addMissing(4, 'Primary Commodity');
    if (_currentData.secondaryCommodity == null || _currentData.secondaryCommodity!.trim().isEmpty) addMissing(4, 'Secondary Commodity');

    // Step 5 - Farm/Fisheries Income (no required breakdown fields; optional)

    // Step 6 - Recurrence
    if (_currentData.maleFamilyMembers == null) addMissing(6, 'No. of Male Family Members');
    if (_currentData.femaleFamilyMembers == null) addMissing(6, 'No. of Female Family Members');
    if (_currentData.yearsInFarming == null) addMissing(6, 'Years in Farming');
    if (_currentData.landTenureship == null || _currentData.landTenureship!.trim().isEmpty) addMissing(6, 'Land Tenureship');
    if (_currentData.landTenureship == 'Other' && (_currentData.landTenureshipOthers == null || _currentData.landTenureshipOthers!.trim().isEmpty)) addMissing(6, 'Land Tenureship (Other)');
    if (_currentData.secondaryCommodityRecurrence == null || _currentData.secondaryCommodityRecurrence!.trim().isEmpty) addMissing(6, 'Secondary Commodity (Recurrence)');
    if (_currentData.yearCovered == null) addMissing(6, 'Year Covered');
    if (_currentData.receivedCommodity == null || _currentData.receivedCommodity!.trim().isEmpty) addMissing(6, 'Received Commodity');

    // Step 7 - Monthly Income
    if (_currentData.agriRelatedIncome == null) addMissing(7, 'Agri-Related Income');
    if (_currentData.saadNetIncome == null) addMissing(7, 'SAAD Net Income');
    if (_currentData.nonAgriRelatedIncome == null) addMissing(7, 'Non-Agri Related Income');
    if (_currentData.mainSourcesOfIncome == null || _currentData.mainSourcesOfIncome!.trim().isEmpty) addMissing(7, 'Main Sources of Income');

    // Step 8 - Signature
    if (_currentData.idType == null || _currentData.idType!.trim().isEmpty) addMissing(8, 'ID Type');
    if (_currentData.idFrontImagePath == null || _currentData.idFrontImagePath!.trim().isEmpty) addMissing(8, 'ID Front Photo');
    if (_currentData.idBackImagePath == null || _currentData.idBackImagePath!.trim().isEmpty) addMissing(8, 'ID Back Photo');
    if (_currentData.farmerPhotoPath == null || _currentData.farmerPhotoPath!.trim().isEmpty) addMissing(8, 'Farmer Photo');
    if ((_currentData.signatureImagePath == null || _currentData.signatureImagePath!.trim().isEmpty) && (_currentData.signatureImage == null)) addMissing(8, 'Signature');

    if (missing.isNotEmpty) {
      // Build a grouped message showing step and fields
      final buffer = StringBuffer();
      missing.forEach((step, fields) {
        buffer.writeln('Step $step:');
        for (final f in fields) {
          buffer.writeln(' • $f');
        }
        buffer.writeln();
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cannot Submit — Missing Fields'),
          content: SingleChildScrollView(child: Text(buffer.toString())),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
      return; // Prevent submission
    }

    // All required fields present — proceed to save
    _currentData.createdAt = _currentData.createdAt ?? DateTime.now();

    // Show staged progress dialog
    String stageLabel = 'Preparing...';
    double stageValue = 0.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              LinearProgressIndicator(value: stageValue <= 0 ? null : stageValue),
              const SizedBox(height: 16),
              Text(stageLabel, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 12),
            ],
          ),
        );
      }),
    );

    try {
      // Save locally only (do NOT auto-sync to Firestore). Keep setAsCurrent=false
      // so this saved profile is treated as an Unsync entry and not the current in-progress draft.
      await _storage.saveDraftLocally(_currentData, setAsCurrent: false);
      debugPrint('✅ Saved locally (Unsync): ${_currentData.farmerFolderName}');

      if (!mounted) return;
      Navigator.pop(context); // Close progress dialog

      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Saved Locally'),
          content: const Text('Profile saved locally as Unsync. You can sync later from the Data screen.'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // Close dialog
                // Mark as successfully submitted so dispose() won't delete it
                _formSubmittedSuccessfully = true;
                // Reset form for new entry and navigate back
                if (!mounted) return;
                setState(() {
                  _currentData = ProfilingData();
                  _currentStep = 1;
                });
                if (!mounted) return;
                Navigator.pop(context); // Go back to previous screen
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close progress dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving form: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build only the current step widget (lazy loading for performance)
    // Shared _currentData object persists all entered data across step navigation
    Widget currentStepWidget;
    
    switch (_currentStep) {
      case 1:
        currentStepWidget = Step01PersonalInfo(
          onNext: _goToNextStep,
          onHeaderBack: _goToHome,
          currentData: _currentData,
        );
        break;
      case 2:
        currentStepWidget = Step02AddressInfo(
          onNext: _goToNextStep,
          onBack: _goToPreviousStep,
          onHeaderBack: _goToHome,
          currentData: _currentData,
        );
        break;
      case 3:
        currentStepWidget = Step03OtherPersonal(
          onNext: _goToNextStep,
          onBack: _goToPreviousStep,
          onHeaderBack: _goToHome,
          currentData: _currentData,
        );
        break;
      case 4:
        currentStepWidget = Step04MainCommodity(
          onNext: _goToNextStep,
          onBack: _goToPreviousStep,
          onHeaderBack: _goToHome,
          currentData: _currentData,
        );
        break;
      case 5:
        currentStepWidget = Step05Recurrence(
          onNext: _goToNextStep,
          onBack: _goToPreviousStep,
          onHeaderBack: _goToHome,
          currentData: _currentData,
        );
        break;
      case 6:
        currentStepWidget = Step06MonthlyIncome(
          onNext: _goToNextStep,
          onBack: _goToPreviousStep,
          onHeaderBack: _goToHome,
          currentData: _currentData,
        );
        break;
      case 7:
        currentStepWidget = Step07FarmIncome(
          onNext: _goToNextStep,
          onBack: _goToPreviousStep,
          onHeaderBack: _goToHome,
          currentData: _currentData,
        );
        break;
      case 8:
        currentStepWidget = Step08Signature(
          onNext: _submitForm,
          onBack: _goToPreviousStep,
          onHeaderBack: _goToHome,
          currentData: _currentData,
        );
        break;
      default:
        currentStepWidget = Step01PersonalInfo(
          onNext: _goToNextStep,
          onHeaderBack: _goToHome,
          currentData: _currentData,
        );
    }

    return currentStepWidget;
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// PROFILING STEP WRAPPER - Shared Layout for All Steps
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

/// ProfilingStepWrapper
///
/// Shared animated layout shell for every profiling step.
///
/// Structure (top â†’ bottom):
///   1. Green header   â€” leaf bg + back arrow + "Profiling" title + subtitle
///   2. StepperHeader  â€” animated line progress bar (8 segments)
///   3. Scrollable body â€” section title + child form (fade+slide in)
///   4. Pinned bottom  â€” Next button (+ optional Back on step â‰¥ 2)
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
          // 3. SCROLLABLE FORM BODY  â€” fade + slide up on entry
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
                    thumbColor: WidgetStateProperty.all(
                      DAColors.primaryGreen.withOpacity(0.5),
                    ),
                    thickness: WidgetStateProperty.all(4.0),
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
          // 4. PINNED BOTTOM  â€” Next + optional Back
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
                // â”€â”€ NEXT â”€â”€
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

                // â”€â”€ BACK (step â‰¥ 2 only) â€” centred vertically in remaining gap â”€â”€
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
