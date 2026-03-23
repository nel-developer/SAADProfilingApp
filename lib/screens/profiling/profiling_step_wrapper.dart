import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/theme/da_colors.dart';
import 'package:da_project_1/widgets/green_header_section.dart';
import 'package:da_project_1/widgets/stepper_header.dart';
import 'package:da_project_1/screens/profiling/step_01_personal_info.dart';
import 'package:da_project_1/screens/profiling/step_02_address_info.dart';
import 'package:da_project_1/screens/profiling/step_03_other_personal.dart';
import 'package:da_project_1/screens/profiling/step_04_saad_income.dart';
import 'package:da_project_1/screens/profiling/step_05_nonsaad_commodities.dart';
import 'package:da_project_1/screens/profiling/step_06_main_commodity.dart';
import 'package:da_project_1/screens/profiling/step_07_cooperative.dart';
import 'package:da_project_1/screens/profiling/step_07_recurrence.dart';
import 'package:da_project_1/screens/profiling/step_08_farm_income.dart';
import 'package:da_project_1/screens/profiling/step_09_monthly_income.dart';
import 'package:da_project_1/screens/profiling/step_10_signature.dart';
import 'package:da_project_1/models/profiling_data.dart';
import 'package:da_project_1/services/profiling_storage_service.dart';

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// PROFILING FLOW - Main Entry Point
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

/// ProfilingFlow - Parent widget that manages all 11 profiling steps
class ProfilingFlow extends StatefulWidget {
  const ProfilingFlow({super.key});

  @override
  State<ProfilingFlow> createState() => _ProfilingFlowState();
}

class _ProfilingFlowState extends State<ProfilingFlow>
    with WidgetsBindingObserver {
  // In-memory session store: persists across navigation within the same app session.
  // Replaces async disk/prefs draft — no spinner, no disk writes on back-navigation.
  static ProfilingData? _sessionData;
  static int _sessionStep = 1;
  static Set<int> _sessionInitializedSteps = {1};

  int _currentStep = 1;
  ProfilingData _currentData = ProfilingData();
  final ProfilingStorageService _storage = ProfilingStorageService();
  bool _formSubmittedSuccessfully = false; // Track if form was submitted
  final Set<int> _initializedSteps = {1};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Restore in-memory session synchronously — step widgets build with full data
    if (_sessionData != null) {
      _currentData = _sessionData!;
      _currentStep = _sessionStep;
      _initializedSteps
        ..clear()
        ..addAll(_sessionInitializedSteps);
    } else {
      // First open — seed session with the fresh ProfilingData object
      _sessionData = _currentData;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // NEVER auto-delete draft on dispose
    // User data is precious - keep it even if they navigate away
    // Only delete if user explicitly taps "Cancel" button
    if (_formSubmittedSuccessfully) {
      debugPrint(
        '✅ Form submitted successfully - draft will be shown as local unsync',
      );
    }
    super.dispose();
  }

  // Temp ID generation removed — only set when saving to Firestore pending collection

  void _persistCurrentDraft() {
    _sessionData = _currentData;
    _sessionStep = _currentStep;
    _sessionInitializedSteps = Set<int>.from(_initializedSteps);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _persistCurrentDraft();
    }
  }

  int _resolveNextStep(int currentStep) {
    final isExistingFarmer = _currentData.isExistingFarmer == true;
    if (!isExistingFarmer) {
      return (currentStep + 1).clamp(1, 11);
    }

    // Existing farmer recurrence flow: skip Address and Other Personal.
    if (currentStep == 1) return 4;
    return (currentStep + 1).clamp(1, 11);
  }

  int _resolvePreviousStep(int currentStep) {
    final isExistingFarmer = _currentData.isExistingFarmer == true;
    if (!isExistingFarmer) {
      return (currentStep - 1).clamp(1, 11);
    }

    // Existing farmer recurrence flow: skip Address and Other Personal.
    if (currentStep == 4) return 1;
    return (currentStep - 1).clamp(1, 11);
  }

  void _goToNextStep() {
    _persistCurrentDraft();
    if (_currentStep < 11) {
      final nextStep = _resolveNextStep(_currentStep);
      setState(() {
        _currentStep = nextStep;
        _initializedSteps.add(nextStep);
      });
    } else {
      _submitForm();
    }
  }

  void _goToPreviousStep() {
    _persistCurrentDraft();
    if (_currentStep > 1) {
      final previousStep = _resolvePreviousStep(_currentStep);
      setState(() {
        _currentStep = previousStep;
        _initializedSteps.add(previousStep);
      });
    }
  }

  Future<bool> _confirmLeaveProfiling() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave Profiling?'),
        content: const Text(
          'Are you sure you want to leave profiling? Your current inputs will be kept as a draft.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _persistCurrentDraft();
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Yes, Leave'),
          ),
        ],
      ),
    );

    return shouldExit == true;
  }

  /// Clears session so the next profiling open always starts with a fresh form.
  void _clearSession() {
    _sessionData = null;
    _sessionStep = 1;
    _sessionInitializedSteps = {1};
  }

  Future<bool> _handleSystemBack() async {
    if (_currentStep > 1) {
      _goToPreviousStep();
      return false;
    }

    final shouldExit = await _confirmLeaveProfiling();
    if (!shouldExit) {
      return false;
    }

    _persistCurrentDraft();
    return true;
  }

  Widget _buildStepWidget(int step) {
    switch (step) {
      case 1:
        return Step01PersonalInfo(
          key: const ValueKey('profiling-step-1'),
          onNext: _goToNextStep,
          onHeaderBack: _goToHome,
          currentData: _currentData,
        );
      case 2:
        return Step02AddressInfo(
          key: const ValueKey('profiling-step-2'),
          onNext: _goToNextStep,
          onBack: _goToPreviousStep,
          onHeaderBack: _goToHome,
          currentData: _currentData,
        );
      case 3:
        return Step03OtherPersonal(
          key: const ValueKey('profiling-step-3'),
          onNext: _goToNextStep,
          onBack: _goToPreviousStep,
          onHeaderBack: _goToHome,
          currentData: _currentData,
        );
      case 4:
        return Step04SAAdIncome(
          key: const ValueKey('profiling-step-4'),
          onNext: _goToNextStep,
          onBack: _goToPreviousStep,
          onHeaderBack: _goToHome,
          currentData: _currentData,
        );
      case 5:
        return Step05NonSAADCommodities(
          key: const ValueKey('profiling-step-5'),
          onNext: _goToNextStep,
          onBack: _goToPreviousStep,
          onHeaderBack: _goToHome,
          currentData: _currentData,
        );
      case 6:
        return Step06MainCommodity(
          key: const ValueKey('profiling-step-6'),
          onNext: _goToNextStep,
          onBack: _goToPreviousStep,
          onHeaderBack: _goToHome,
          currentData: _currentData,
        );
      case 7:
        return Step07Cooperative(
          key: const ValueKey('profiling-step-7'),
          onNext: _goToNextStep,
          onBack: _goToPreviousStep,
          onHeaderBack: _goToHome,
          currentData: _currentData,
        );
      case 8:
        return Step07Recurrence(
          key: const ValueKey('profiling-step-8'),
          onNext: _goToNextStep,
          onBack: _goToPreviousStep,
          onHeaderBack: _goToHome,
          currentData: _currentData,
        );
      case 9:
        return Step08FarmIncome(
          key: const ValueKey('profiling-step-9'),
          onNext: _goToNextStep,
          onBack: _goToPreviousStep,
          onHeaderBack: _goToHome,
          currentData: _currentData,
        );
      case 10:
        return Step09MonthlyIncome(
          key: const ValueKey('profiling-step-10'),
          onNext: _goToNextStep,
          onBack: _goToPreviousStep,
          onHeaderBack: _goToHome,
          currentData: _currentData,
        );
      case 11:
        return Step10Signature(
          key: const ValueKey('profiling-step-11'),
          onNext: _submitForm,
          onBack: _goToPreviousStep,
          onHeaderBack: _goToHome,
          currentData: _currentData,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _goToHome() async {
    final shouldExit = await _confirmLeaveProfiling();

    if (shouldExit != true || !mounted) return;

    _persistCurrentDraft();
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _submitForm() async {
    // Centralized final validation before saving
    final missing = <int, List<String>>{};
    final isExistingFarmer = _currentData.isExistingFarmer == true;

    void addMissing(int step, String label) {
      missing.putIfAbsent(step, () => []).add(label);
    }

    // Step 1 - Personal Info
    if (isExistingFarmer) {
      final selectedExistingSaadId =
          _currentData.selectedExistingSaadId?.trim() ?? '';
      final saadIdNo = _currentData.saadIdNo?.trim() ?? '';
      if (selectedExistingSaadId.isEmpty && saadIdNo.isEmpty) {
        addMissing(1, 'Existing Farmer (SAAD I.D No.)');
      }
    } else {
      if (_currentData.firstName == null ||
          _currentData.firstName!.trim().isEmpty) {
        addMissing(1, 'First Name');
      }
      // middleName is exempt
      if (_currentData.surname == null ||
          _currentData.surname!.trim().isEmpty) {
        addMissing(1, 'Surname');
      }
      // extensionName is exempt
      if (_currentData.dateOfBirth == null ||
          _currentData.dateOfBirth!.trim().isEmpty) {
        addMissing(1, 'Date of Birth');
      }
      if (_currentData.sex == null || _currentData.sex!.trim().isEmpty) {
        addMissing(1, 'Sex');
      }
    }

    // Step 2 - Address (optional)
    // Address fields are intentionally optional; do not block submission if empty.

    // Step 3 - Other Personal
    if (!isExistingFarmer) {
      if (_currentData.isIndigenous == null) addMissing(3, 'Is Indigenous');
      if ((_currentData.isIndigenous ?? false) &&
          (_currentData.indigenousGroup == null ||
              _currentData.indigenousGroup!.trim().isEmpty)) {
        addMissing(3, 'Indigenous Group');
      }
      if (_currentData.isPWD == null) addMissing(3, 'Is PWD');
      if (_currentData.maritalStatus == null ||
          _currentData.maritalStatus!.trim().isEmpty) {
        addMissing(3, 'Marital Status');
      }
      // spouseName is exempt (not required)
      if (_currentData.tribeEthnicity == null ||
          _currentData.tribeEthnicity!.trim().isEmpty) {
        addMissing(3, 'Tribe / Ethnicity');
      }
    }

    // Step 4 - SAAD Commodity Type (dropdown required)
    if (_currentData.saadCommodityType == null ||
        _currentData.saadCommodityType!.trim().isEmpty) {
      addMissing(4, 'SAAD Commodity Type');
    }

    // Step 5 - Non-SAAD Commodity Type (dropdown required)
    if (_currentData.nonSAADCommodityType == null ||
        _currentData.nonSAADCommodityType!.trim().isEmpty) {
      addMissing(5, 'Non-SAAD Commodity Type');
    }

    // Step 6 - Main Commodity
    if (!isExistingFarmer) {
      if (_currentData.primaryCommodity == null ||
          _currentData.primaryCommodity!.trim().isEmpty) {
        addMissing(6, 'Primary Commodity');
      }
      if (_currentData.secondaryCommodity == null ||
          _currentData.secondaryCommodity!.trim().isEmpty) {
        addMissing(6, 'Secondary Commodity');
      }
    }

    // Step 8 - Recurrence
    if (_currentData.maleFamilyMembers == null) {
      addMissing(8, 'No. of Male Family Members');
    }
    if (_currentData.femaleFamilyMembers == null) {
      addMissing(8, 'No. of Female Family Members');
    }
    if (_currentData.yearsInFarming == null) addMissing(8, 'Years in Farming');
    if (_currentData.landTenureship == null ||
        _currentData.landTenureship!.trim().isEmpty) {
      addMissing(8, 'Land Tenureship');
    }
    if (_currentData.landTenureship == 'Other' &&
        (_currentData.landTenureshipOthers == null ||
            _currentData.landTenureshipOthers!.trim().isEmpty)) {
      addMissing(8, 'Land Tenureship (Other)');
    }
    if (_currentData.yearCovered == null) addMissing(8, 'Year Covered');
    // Received Commodity is optional.

    // Step 10 - Monthly Income
    if (!isExistingFarmer) {
      if (_currentData.agriRelatedIncome == null) {
        addMissing(10, 'Agri-Related Income');
      }
      if (_currentData.nonAgriRelatedIncome == null) {
        addMissing(10, 'Non-Agri Related Income');
      }
      if (_currentData.mainSourcesOfIncome == null ||
          _currentData.mainSourcesOfIncome!.trim().isEmpty) {
        addMissing(10, 'Main Sources of Income');
      }
    }

    // Step 9 - Farm/Fisheries Income (no required breakdown fields; optional)

    // Step 11 - Signature / Images
    if (!isExistingFarmer) {
      if (_currentData.farmerPhotoPath == null ||
          _currentData.farmerPhotoPath!.trim().isEmpty) {
        addMissing(11, 'Farmer Photo');
      }
    }
    if ((_currentData.signatureImagePath == null ||
            _currentData.signatureImagePath!.trim().isEmpty) &&
        (_currentData.signatureImage == null)) {
      addMissing(11, 'Signature');
    }

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
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
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
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: stageValue <= 0 ? null : stageValue,
                ),
                const SizedBox(height: 16),
                Text(stageLabel, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );

    try {
      _currentData.status = 'Unsync';
      _currentData.draftStep = null;
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
          content: const Text(
            'Profile saved locally as Unsync. You can sync later from the Data screen.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Close dialog
                // Clear static session so next profiling starts fresh
                _sessionData = null;
                _sessionStep = 1;
                _sessionInitializedSteps = {1};
                _formSubmittedSuccessfully = true;
                // Reset form for new entry and navigate back
                if (!mounted) return;
                setState(() {
                  _currentData = ProfilingData();
                  _currentStep = 1;
                  _initializedSteps
                    ..clear()
                    ..add(1);
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving form: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _initializedSteps.add(_currentStep);
    final stepWidgets = List<Widget>.generate(11, (i) {
      final step = i + 1;
      if (!_initializedSteps.contains(step)) {
        return const SizedBox.shrink();
      }
      return _buildStepWidget(step);
    });

    final index = (_currentStep - 1).clamp(0, stepWidgets.length - 1);
    return WillPopScope(
      onWillPop: _handleSystemBack,
      child: IndexedStack(index: index, children: stepWidgets),
    );
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
        curve: const Interval(0.3, 0.9, curve: Curves.easeOut),
      ),
    );
    _slideAnim = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
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
    final headerHeight =
        height *
        (isLargeTablet
            ? 0.18
            : isTablet
            ? 0.22
            : 0.28);
    final titleFontSize = isLargeTablet
        ? 36.0
        : isTablet
        ? 30.0
        : width * 0.065;
    final subtitleFontSize = isLargeTablet
        ? 14.0
        : isTablet
        ? 12.0
        : width * 0.03;
    final backButtonSize = isTablet ? 28.0 : 24.0;

    // Content sizing
    final contentHPad = width * 0.06;
    final sectionTitleSize = isLargeTablet
        ? 20.0
        : isTablet
        ? 18.0
        : 17.0;
    final sectionSpacing = isTablet ? 18.0 : 14.0;

    // Bottom buttons
    final bottomPad = isTablet ? 28.0 : 24.0;
    final safeBottomInset = MediaQuery.of(context).padding.bottom;
    final nextHeight = isLargeTablet
        ? 56.0
        : isTablet
        ? 52.0
        : 50.0;
    final nextFontSize = isLargeTablet
        ? 18.0
        : isTablet
        ? 17.0
        : 16.0;
    final backFontSize = isLargeTablet
        ? 15.0
        : isTablet
        ? 14.0
        : 13.0;

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
                            onTap:
                                widget.onHeaderBack ??
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
          StepperHeader(currentStep: widget.currentStep, totalSteps: 11),

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
                  thumbVisibility: false,
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
              bottomPad + safeBottomInset,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // â”€â”€ NEXT â”€â”€
                GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    widget.onNext();
                  },
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
                        widget.currentStep < 11 ? 'Next' : 'Submit',
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
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        widget.onBack?.call();
                      },
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
