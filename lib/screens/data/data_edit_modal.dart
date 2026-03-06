import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:da_project_1/theme/da_colors.dart';
import 'package:da_project_1/models/profiling_data.dart';
import 'package:da_project_1/services/profiling_storage_service.dart';

class DataEditModal extends StatefulWidget {
  final Map<String, dynamic> profileData;
  final Function(Map<String, dynamic>) onSave;

  const DataEditModal({
    super.key,
    required this.profileData,
    required this.onSave,
  });

  @override
  State<DataEditModal> createState() => _DataEditModalState();
}

class _DataEditModalState extends State<DataEditModal> {
  late Map<String, dynamic> _editedData;
  String _currentUserName = '';

  static const double _refWidth = 393.0;
  static const double _refHeight = 852.0;

  // Personal Info Controllers
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _extensionNameController =
      TextEditingController();
  final TextEditingController _sexController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  // Address Controllers
  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _municipalityController = TextEditingController();
  final TextEditingController _barangayController = TextEditingController();
  final TextEditingController _sitioPurokController = TextEditingController();

  // Other Personal Info Controllers
  final TextEditingController _indigenousGroupController =
      TextEditingController();
  final TextEditingController _pwdController = TextEditingController();
  final TextEditingController _indigenousSpecifyController =
      TextEditingController();
  final TextEditingController _spouseNameController = TextEditingController();

  // Main Commodity Controllers
  final TextEditingController _primaryCommodityController =
      TextEditingController();
  final TextEditingController _secondaryCommodityController =
      TextEditingController();
  final TextEditingController _primarySpecifyController =
      TextEditingController();
  final TextEditingController _secondarySpecifyController =
      TextEditingController();

  // Cooperative Controllers
  final TextEditingController _organizationNameController =
      TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _dateMembershipController =
      TextEditingController();
  final TextEditingController _positionSpecifyController =
      TextEditingController();

  // Recurrence Controllers (Current Year)
  final TextEditingController _recPrimaryController = TextEditingController();
  final TextEditingController _recSecondaryController = TextEditingController();
  final TextEditingController _recPrimarySpecifyController =
      TextEditingController();
  final TextEditingController _recSecondarySpecifyController =
      TextEditingController();
  final TextEditingController _familyMaleController = TextEditingController();
  final TextEditingController _familyFemaleController = TextEditingController();
  final TextEditingController _landTenureshipController =
      TextEditingController();
  final TextEditingController _landTenureshipSpecifyController =
      TextEditingController();
  final TextEditingController _yearsFishingController = TextEditingController();

  // Monthly Income Controllers (inside Recurrence)
  final TextEditingController _agriRelatedController = TextEditingController();
  final TextEditingController _nonAgriRelatedController =
      TextEditingController();
  final TextEditingController _mainSourcesController = TextEditingController();

  // Farm Income Controllers - 3 Beneficiary Income Fields
  final TextEditingController _beneficiaryIncomeCtrl = TextEditingController();
  final TextEditingController _spouseIncomeCtrl = TextEditingController();
  final TextEditingController _spouseRemarksCtrl = TextEditingController();
  final TextEditingController _beneficiaryRemarksCtrl = TextEditingController();
  final TextEditingController _otherMembersIncomeCtrl = TextEditingController();
  final TextEditingController _otherMembersRemarksCtrl =
      TextEditingController();

  void _forceUppercase(TextEditingController controller) {
    final upper = controller.text.toUpperCase();
    if (controller.text == upper) return;
    controller.value = TextEditingValue(
      text: upper,
      selection: TextSelection.collapsed(offset: upper.length),
    );
  }

  void _attachNameUppercaseListeners() {
    final controllers = <TextEditingController>[
      _surnameController,
      _firstNameController,
      _middleNameController,
      _extensionNameController,
      _spouseNameController,
      _organizationNameController,
      _positionSpecifyController,
    ];

    for (final controller in controllers) {
      controller.addListener(() => _forceUppercase(controller));
      _forceUppercase(controller);
    }
  }

  @override
  void initState() {
    super.initState();
    _editedData = Map.from(widget.profileData);
    _loadCurrentUserName();

    final incoming = widget.profileData['data'];
    if (incoming is ProfilingData) {
      final pd = incoming;
      _surnameController.text = pd.surname ?? '';
      _firstNameController.text = pd.firstName ?? '';
      _middleNameController.text = pd.middleName ?? '';
      _extensionNameController.text = pd.extensionName ?? '';
      _sexController.text = pd.sex ?? '';
      _dobController.text = pd.dateOfBirth ?? '';

      _regionController.text = pd.region ?? '';
      _provinceController.text = pd.province ?? '';
      _municipalityController.text = pd.municipality ?? '';
      _barangayController.text = pd.barangay ?? '';
      _sitioPurokController.text = pd.sitioPurok ?? '';

      _indigenousGroupController.text = (pd.isIndigenous == true)
          ? 'Yes'
          : 'No';
      _pwdController.text = (pd.isPWD == true) ? 'Yes' : 'No';
      _indigenousSpecifyController.text = pd.indigenousGroup ?? '';
      _spouseNameController.text = pd.spouseName ?? '';

      _primaryCommodityController.text = pd.primaryCommodity ?? '';
      _secondaryCommodityController.text = pd.secondaryCommodity ?? '';
      _primarySpecifyController.text = pd.primaryCommodityOthers ?? '';
      _secondarySpecifyController.text = pd.secondaryCommodityOthers ?? '';

      _organizationNameController.text = pd.cooperativeName ?? '';
      _positionController.text = pd.cooperativePosition ?? '';
      _dateMembershipController.text = pd.dateOfMembership ?? '';
      _positionSpecifyController.text = pd.cooperativePositionOthers ?? '';

      // Recurrence data (use booleans/texts if present)
      _recPrimaryController.text = (pd.primaryCommodityRecurrence == true)
          ? 'Yes'
          : 'No';
      _recSecondaryController.text = pd.secondaryCommodityRecurrence ?? '';
      _recPrimarySpecifyController.text =
          pd.primaryCommodityRecurrenceOthers ?? '';
      _recSecondarySpecifyController.text =
          pd.secondaryCommodityRecurrenceOthers ?? '';
      _familyMaleController.text = (pd.maleFamilyMembers ?? 0).toString();
      _familyFemaleController.text = (pd.femaleFamilyMembers ?? 0).toString();
      _landTenureshipController.text = pd.landTenureship ?? '';
      _landTenureshipSpecifyController.text = pd.landTenureshipOthers ?? '';
      _yearsFishingController.text = (pd.yearsInFarming ?? 0).toString();

      _agriRelatedController.text = (pd.agriRelatedIncome ?? 0).toString();
      _nonAgriRelatedController.text = (pd.nonAgriRelatedIncome ?? 0)
          .toString();
      _mainSourcesController.text = pd.mainSourcesOfIncome ?? '';

      // Auto-calculate net incomes from receivedTotalPrice and receivedExpenses.
      // calculation only used to derive agri-related value; no fields shown.
      final totalPrice = pd.receivedTotalPrice ?? 0.0;
      final expenses = pd.receivedExpenses ?? 0.0;
      final calculated = (totalPrice - expenses) / 12;
      final safe = calculated > 0 ? calculated : 0.0;
      _agriRelatedController.text = (safe + safe).round().toString();

      _beneficiaryIncomeCtrl.text = pd.beneficiaryNonFarmIncome ?? '';
      _beneficiaryRemarksCtrl.text = pd.beneficiaryRemarks ?? '';
      _spouseIncomeCtrl.text = pd.spouseNonFarmIncome ?? '';
      _spouseRemarksCtrl.text = pd.spouseRemarks ?? '';
      _otherMembersIncomeCtrl.text = pd.otherMembersNonFarmIncome ?? '';
      _otherMembersRemarksCtrl.text = pd.otherMembersRemarks ?? '';
    } else {
      // Fallback dummy values
      _surnameController.text = 'Dela Cruz';
      _firstNameController.text = 'Juan';
      _middleNameController.text = 'Santos';
      _extensionNameController.text = 'JR';
      _sexController.text = 'Male';
      _dobController.text = '11/01/1999';

      _regionController.text = 'IV-A';
      _provinceController.text = 'Batangas';
      _municipalityController.text = 'Lipa City';
      _barangayController.text = 'Sabang';
      _sitioPurokController.text = 'Purok 1';

      _indigenousGroupController.text = 'Yes';
      _pwdController.text = 'Yes';
      _indigenousSpecifyController.text = '___________';
      _spouseNameController.text = '___________';

      _primaryCommodityController.text = 'Others';
      _secondaryCommodityController.text = 'Others';
      _primarySpecifyController.text = '___________';
      _secondarySpecifyController.text = '___________';

      _organizationNameController.text = 'Mahika';
      _positionController.text = 'Others';
      _dateMembershipController.text = '11/12/25';
      _positionSpecifyController.text = '___________';

      // Recurrence data (current year)
      _recPrimaryController.text = 'Others';
      _recSecondaryController.text = 'Others';
      _recPrimarySpecifyController.text = '___________';
      _recSecondarySpecifyController.text = '___________';
      _familyMaleController.text = '2';
      _familyFemaleController.text = '2';
      _landTenureshipController.text = 'Others';
      _landTenureshipSpecifyController.text = '___________';
      _yearsFishingController.text = '5';

      // Monthly Income (inside recurrence)
      _agriRelatedController.text = '25000';
      _nonAgriRelatedController.text = '25000';
      _mainSourcesController.text = 'Farming';

      // Initialize farm income with 3 beneficiary fields
      _beneficiaryIncomeCtrl.text = '';
      _beneficiaryRemarksCtrl.text = '';
      _spouseIncomeCtrl.text = '';
      _spouseRemarksCtrl.text = '';
      _otherMembersIncomeCtrl.text = '';
      _otherMembersRemarksCtrl.text = '';
    }

    _attachNameUppercaseListeners();
  }

  @override
  void dispose() {
    _surnameController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _extensionNameController.dispose();
    _sexController.dispose();
    _dobController.dispose();
    _regionController.dispose();
    _provinceController.dispose();
    _municipalityController.dispose();
    _barangayController.dispose();
    _sitioPurokController.dispose();
    _indigenousGroupController.dispose();
    _pwdController.dispose();
    _indigenousSpecifyController.dispose();
    _spouseNameController.dispose();
    _primaryCommodityController.dispose();
    _secondaryCommodityController.dispose();
    _primarySpecifyController.dispose();
    _secondarySpecifyController.dispose();
    _organizationNameController.dispose();
    _positionController.dispose();
    _dateMembershipController.dispose();
    _positionSpecifyController.dispose();
    _recPrimaryController.dispose();
    _recSecondaryController.dispose();
    _recPrimarySpecifyController.dispose();
    _recSecondarySpecifyController.dispose();
    _familyMaleController.dispose();
    _familyFemaleController.dispose();
    _landTenureshipController.dispose();
    _landTenureshipSpecifyController.dispose();
    _yearsFishingController.dispose();

    _agriRelatedController.dispose();
    _nonAgriRelatedController.dispose();
    _mainSourcesController.dispose();

    _beneficiaryIncomeCtrl.dispose();
    _spouseIncomeCtrl.dispose();
    _spouseRemarksCtrl.dispose();
    _otherMembersIncomeCtrl.dispose();
    _beneficiaryRemarksCtrl.dispose();
    _otherMembersRemarksCtrl.dispose();
    super.dispose();
  }

  double _scale(BuildContext context) {
    final scaleW = (MediaQuery.of(context).size.width / _refWidth).clamp(
      0.5,
      2.0,
    );
    final scaleH = (MediaQuery.of(context).size.height / _refHeight).clamp(
      0.5,
      2.0,
    );
    return min(scaleW, scaleH);
  }

  Future<void> _loadCurrentUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          final firstName = userDoc.data()?['firstName'] ?? 'User';
          final lastName = userDoc.data()?['surname'] ?? '';
          setState(() {
            _currentUserName = '$firstName $lastName'.trim();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user name: $e');
    }
  }

  Future<void> _saveChanges() async {
    final incoming = widget.profileData['data'];
    ProfilingData pd;
    if (incoming is ProfilingData) {
      pd = incoming;
    } else if (incoming is Map<String, dynamic>) {
      pd = ProfilingData(
        saadCommodityType: incoming['saadCommodityType']?.toString(),
        saadCommodities: (incoming['saadCommodities'] as List?)
            ?.whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList(),
        nonSAADCommodityType: incoming['nonSAADCommodityType']?.toString(),
        nonSAADCommodities: (incoming['nonSAADCommodities'] as List?)
            ?.whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList(),
      );
    } else {
      pd = ProfilingData();
    }

    // Update fields from controllers (minimal set)
    pd.surname = _surnameController.text.trim().toUpperCase();
    pd.firstName = _firstNameController.text.trim().toUpperCase();
    pd.middleName = _middleNameController.text.trim().toUpperCase();
    pd.extensionName = _extensionNameController.text.trim().toUpperCase();
    pd.sex = _sexController.text;
    pd.dateOfBirth = _dobController.text;

    pd.region = _regionController.text;
    pd.province = _provinceController.text;
    pd.municipality = _municipalityController.text;
    pd.barangay = _barangayController.text;
    pd.sitioPurok = _sitioPurokController.text;

    pd.isIndigenous = _indigenousGroupController.text.toLowerCase() == 'yes';
    pd.indigenousGroup = _indigenousSpecifyController.text;
    pd.isPWD = _pwdController.text.toLowerCase() == 'yes';
    pd.spouseName = _spouseNameController.text.trim().toUpperCase();

    pd.primaryCommodity = _primaryCommodityController.text;
    pd.primaryCommodityOthers = _primarySpecifyController.text;
    pd.secondaryCommodity = _secondaryCommodityController.text;
    pd.secondaryCommodityOthers = _secondarySpecifyController.text;

    pd.cooperativeName = _organizationNameController.text.trim().toUpperCase();
    pd.cooperativePosition = _positionController.text;
    pd.dateOfMembership = _dateMembershipController.text;
    pd.cooperativePositionOthers = _positionSpecifyController.text
        .trim()
        .toUpperCase();

    pd.primaryCommodityRecurrence =
        _recPrimaryController.text.toLowerCase() == 'yes';
    pd.secondaryCommodityRecurrence = _recSecondaryController.text;
    pd.primaryCommodityRecurrenceOthers = _recPrimarySpecifyController.text;
    pd.secondaryCommodityRecurrenceOthers = _recSecondarySpecifyController.text;
    pd.maleFamilyMembers =
        int.tryParse(_familyMaleController.text) ?? pd.maleFamilyMembers;
    pd.femaleFamilyMembers =
        int.tryParse(_familyFemaleController.text) ?? pd.femaleFamilyMembers;
    pd.landTenureship = _landTenureshipController.text;
    pd.landTenureshipOthers = _landTenureshipSpecifyController.text;
    pd.yearsInFarming =
        int.tryParse(_yearsFishingController.text) ?? pd.yearsInFarming;

    // agriRelated will be recalculated from net incomes below
    // pd.agriRelatedIncome = double.tryParse(_agriRelatedController.text) ?? pd.agriRelatedIncome;
    // Auto-calculate net incomes from receivedTotalPrice and receivedExpenses
    final totalPrice = pd.receivedTotalPrice ?? 0.0;
    final expenses = pd.receivedExpenses ?? 0.0;
    final calculated = (totalPrice - expenses) / 12;
    final safeVal = (calculated > 0 ? calculated : 0.0).roundToDouble();
    pd.saadNetIncome = safeVal;
    pd.nonSAADNetIncome = safeVal;
    pd.agriRelatedIncome = safeVal + safeVal;

    pd.nonAgriRelatedIncome =
        double.tryParse(_nonAgriRelatedController.text) ??
        pd.nonAgriRelatedIncome;
    pd.mainSourcesOfIncome = _mainSourcesController.text;

    pd.beneficiaryNonFarmIncome = _beneficiaryIncomeCtrl.text.trim();
    pd.spouseNonFarmIncome = _spouseIncomeCtrl.text.trim();
    pd.spouseRemarks = _spouseRemarksCtrl.text.trim();
    pd.beneficiaryRemarks = _beneficiaryRemarksCtrl.text.trim();
    pd.otherMembersNonFarmIncome = _otherMembersIncomeCtrl.text.trim();
    pd.otherMembersRemarks = _otherMembersRemarksCtrl.text.trim();

    // Persist updated draft: prefer updating Firestore pending doc first (so ids are assigned),
    // then save locally under the draft_<id> key. If offline, fall back to local save but
    // ensure we reuse any existing ids to avoid creating duplicate drafts.
    final storage = ProfilingStorageService();
    await storage.init();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final result = await storage.saveToPendingCollection(
          pd,
          user.uid,
          onProgress: (stage, progress) {
            debugPrint('🔁 Sync stage: $stage (${progress ?? 0})');
          },
        );
        if (!result.success) {
          debugPrint(
            '⚠️ Remote save failed: ${result.errorMessage}, will persist locally',
          );
        }
      } catch (e) {
        debugPrint('⚠️ Could not sync to pending: $e');
      }
    }

    // Ensure local id uses firebase id if available to prevent autosave duplication
    if ((pd.tempIdLocal == null || pd.tempIdLocal!.isEmpty) &&
        (pd.tempIdFirebase != null && pd.tempIdFirebase!.isNotEmpty)) {
      pd.tempIdLocal = pd.tempIdFirebase;
    }

    // Save locally (do NOT set as current in-progress draft)
    await storage.saveDraftLocally(pd, setAsCurrent: false);

    if (!mounted) return;
    Navigator.pop(context);
    widget.onSave(_editedData);
  }

  @override
  Widget build(BuildContext context) {
    final scale = _scale(context);
    final currentData = _getCurrentProfilingData();
    final mapData = widget.profileData['data'];
    final bool isExistingFarmer =
        currentData?.isExistingFarmer == true ||
        (mapData is Map && mapData['isExistingFarmer'] == true);

    final titleFontSize = 20.0 * scale;
    final sectionTitleFontSize = 16.0 * scale;
    final labelFontSize = 12.0 * scale;
    final headerPaddingH = 16.0 * scale;
    final headerPaddingV = 12.0 * scale;
    final backButtonPadding = 8.0 * scale;
    final backButtonSize = 24.0 * scale;
    final headerTitleSize = 18.0 * scale;
    final contentPadding = 16.0 * scale;
    final cardPadding = 20.0 * scale;
    final cardRadius = 16.0 * scale;
    final bottomPadding = 16.0 * scale;
    final buttonHeight = 48.0 * scale;
    final buttonFontSize = 15.0 * scale;

    return Scaffold(
      backgroundColor: DAColors.lightGrey,
      body: Column(
        children: [
          /// GREEN HEADER
          Container(
            color: DAColors.primaryGreen,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: headerPaddingH,
                  vertical: headerPaddingV,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(backButtonPadding),
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
                    Text(
                      _currentUserName.isEmpty
                          ? 'Edit Profile'
                          : 'Edit Profile - $_currentUserName',
                      style: GoogleFonts.poppins(
                        fontSize: headerTitleSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(width: backButtonSize + backButtonPadding * 2),
                  ],
                ),
              ),
            ),
          ),

          /// SCROLLABLE FORM
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(contentPadding),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(cardRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12 * scale,
                      offset: Offset(0, 4 * scale),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// TITLE
                    Center(
                      child: Text(
                        'Farmers/Fisherfolks Profile',
                        style: GoogleFonts.poppins(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    Container(height: 2 * scale, color: Colors.grey.shade300),
                    SizedBox(height: 20 * scale),

                    /// PERSONAL INFO
                    _buildSectionTitle(
                      'Personal Information',
                      sectionTitleFontSize,
                      scale,
                    ),
                    SizedBox(height: 12 * scale),
                    _buildEditRow(
                      'Surname',
                      _surnameController,
                      'First Name',
                      _firstNameController,
                      labelFontSize,
                      scale,
                      readOnly1: isExistingFarmer,
                      readOnly2: isExistingFarmer,
                    ),
                    SizedBox(height: 12 * scale),
                    _buildEditRow(
                      'Middle Name',
                      _middleNameController,
                      'Extension Name',
                      _extensionNameController,
                      labelFontSize,
                      scale,
                      readOnly1: isExistingFarmer,
                      readOnly2: isExistingFarmer,
                    ),
                    SizedBox(height: 12 * scale),
                    _buildEditRow(
                      'Sex',
                      _sexController,
                      'Date of Birth',
                      _dobController,
                      labelFontSize,
                      scale,
                      readOnly1: isExistingFarmer,
                      readOnly2: isExistingFarmer,
                    ),

                    SizedBox(height: 20 * scale),
                    _buildSectionTitle('Address', sectionTitleFontSize, scale),
                    SizedBox(height: 12 * scale),
                    _buildEditRow(
                      'Region',
                      _regionController,
                      'Province',
                      _provinceController,
                      labelFontSize,
                      scale,
                    ),
                    SizedBox(height: 12 * scale),
                    _buildEditRow(
                      'Municipality',
                      _municipalityController,
                      'Barangay',
                      _barangayController,
                      labelFontSize,
                      scale,
                    ),
                    SizedBox(height: 12 * scale),
                    _buildSingleEditField(
                      'Sitio/Purok',
                      _sitioPurokController,
                      labelFontSize,
                      scale,
                    ),

                    SizedBox(height: 20 * scale),
                    _buildSectionTitle(
                      'Other Personal Information',
                      sectionTitleFontSize,
                      scale,
                    ),
                    SizedBox(height: 12 * scale),
                    _buildEditRow(
                      'Member of Indigenous Group',
                      _indigenousGroupController,
                      'Person with Disability(PWD)',
                      _pwdController,
                      labelFontSize,
                      scale,
                    ),
                    SizedBox(height: 12 * scale),
                    _buildSingleEditField(
                      'If yes, please specify',
                      _indigenousSpecifyController,
                      labelFontSize,
                      scale,
                    ),
                    SizedBox(height: 12 * scale),
                    _buildSingleEditField(
                      'Spouse Name (if applicable)',
                      _spouseNameController,
                      labelFontSize,
                      scale,
                    ),

                    SizedBox(height: 20 * scale),
                    _buildSectionTitle(
                      'Main Commodity',
                      sectionTitleFontSize,
                      scale,
                    ),
                    SizedBox(height: 12 * scale),
                    _buildEditRow(
                      'Primary Commodity',
                      _primaryCommodityController,
                      'Secondary Commodity',
                      _secondaryCommodityController,
                      labelFontSize,
                      scale,
                    ),
                    SizedBox(height: 12 * scale),
                    _buildEditRow(
                      'If yes, please specify',
                      _primarySpecifyController,
                      'If yes, please specify',
                      _secondarySpecifyController,
                      labelFontSize,
                      scale,
                    ),

                    SizedBox(height: 20 * scale),
                    _buildSectionTitle(
                      'SAAD Commodity Details',
                      sectionTitleFontSize,
                      scale,
                    ),
                    SizedBox(height: 12 * scale),
                    _buildCommodityDetailsEditSection(
                      selectedType:
                          _getCurrentProfilingData()?.saadCommodityType,
                      entries: _toCommodityEntryList(
                        _getCurrentProfilingData()?.saadCommodities,
                      ),
                      labelFontSize: labelFontSize,
                      scale: scale,
                    ),

                    SizedBox(height: 20 * scale),
                    _buildSectionTitle(
                      'Non-SAAD Commodity Details',
                      sectionTitleFontSize,
                      scale,
                    ),
                    SizedBox(height: 12 * scale),
                    _buildCommodityDetailsEditSection(
                      selectedType:
                          _getCurrentProfilingData()?.nonSAADCommodityType,
                      entries: _toCommodityEntryList(
                        _getCurrentProfilingData()?.nonSAADCommodities,
                      ),
                      labelFontSize: labelFontSize,
                      scale: scale,
                    ),

                    SizedBox(height: 20 * scale),
                    _buildSectionTitle(
                      'Farmers/Fishers Cooperative',
                      sectionTitleFontSize,
                      scale,
                    ),
                    SizedBox(height: 12 * scale),
                    _buildEditRow(
                      'Organization Name',
                      _organizationNameController,
                      'Position',
                      _positionController,
                      labelFontSize,
                      scale,
                    ),
                    SizedBox(height: 12 * scale),
                    _buildEditRow(
                      'Date of Membership',
                      _dateMembershipController,
                      'If yes, please specify',
                      _positionSpecifyController,
                      labelFontSize,
                      scale,
                    ),

                    SizedBox(height: 20 * scale),
                    _buildSectionTitle(
                      'Recurrence (Current Year)',
                      sectionTitleFontSize,
                      scale,
                    ),
                    SizedBox(height: 12 * scale),

                    // Year display (non-editable, shows current year)
                    Container(
                      padding: EdgeInsets.all(12 * scale),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12 * scale),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        'Year Covered: ${DateTime.now().year}',
                        style: GoogleFonts.poppins(
                          fontSize: labelFontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(height: 12 * scale),

                    _buildEditRow(
                      'Received Primary Commodity',
                      _recPrimaryController,
                      'Received Secondary Commodity',
                      _recSecondaryController,
                      labelFontSize,
                      scale,
                    ),
                    SizedBox(height: 12 * scale),
                    _buildEditRow(
                      'If yes, specify Primary',
                      _recPrimarySpecifyController,
                      'If yes, specify Secondary',
                      _recSecondarySpecifyController,
                      labelFontSize,
                      scale,
                    ),
                    SizedBox(height: 12 * scale),
                    _buildEditRow(
                      'No. of Family Members (Male)',
                      _familyMaleController,
                      'No. of Family Members (Female)',
                      _familyFemaleController,
                      labelFontSize,
                      scale,
                    ),
                    SizedBox(height: 12 * scale),
                    _buildEditRow(
                      'Land Tenureship',
                      _landTenureshipController,
                      'If yes, please specify',
                      _landTenureshipSpecifyController,
                      labelFontSize,
                      scale,
                    ),
                    SizedBox(height: 12 * scale),
                    _buildSingleEditField(
                      'No. of Years Fishing/Farming',
                      _yearsFishingController,
                      labelFontSize,
                      scale,
                    ),

                    SizedBox(height: 16 * scale),
                    // Monthly Income subsection header
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 8 * scale),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8 * scale),
                      ),
                      child: Center(
                        child: Text(
                          'Monthly Family Income',
                          style: GoogleFonts.poppins(
                            fontSize: labelFontSize + 1 * scale,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12 * scale),
                    _buildSingleEditField(
                      'Derived from Non Agri-Related Activities(Gross)',
                      _nonAgriRelatedController,
                      labelFontSize,
                      scale,
                    ),
                    SizedBox(height: 12 * scale),
                    _buildSingleEditField(
                      'Main Sources of Income',
                      _mainSourcesController,
                      labelFontSize,
                      scale,
                    ),

                    SizedBox(height: 20 * scale),
                    _buildSectionTitle(
                      'Farm/Fisheries Income',
                      sectionTitleFontSize,
                      scale,
                    ),
                    SizedBox(height: 12 * scale),
                    _buildFarmIncomeEditSection(labelFontSize, scale),
                  ],
                ),
              ),
            ),
          ),

          /// SAVE BUTTON
          SafeArea(
            top: false,
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.all(bottomPadding),
              child: GestureDetector(
                onTap: _saveChanges,
                child: Container(
                  height: buttonHeight,
                  decoration: BoxDecoration(
                    color: DAColors.primaryGreen,
                    borderRadius: BorderRadius.circular(25 * scale),
                    boxShadow: [
                      BoxShadow(
                        color: DAColors.primaryGreen.withOpacity(0.3),
                        blurRadius: 8 * scale,
                        offset: Offset(0, 3 * scale),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Save Changes',
                      style: GoogleFonts.poppins(
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, double fontSize, double scale) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12 * scale),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8 * scale),
      ),
      child: Center(
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildEditRow(
    String label1,
    TextEditingController controller1,
    String label2,
    TextEditingController controller2,
    double labelFontSize,
    double scale, {
    bool readOnly1 = false,
    bool readOnly2 = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildTextField(
            label1,
            controller1,
            labelFontSize,
            scale,
            readOnly: readOnly1,
          ),
        ),
        SizedBox(width: 12 * scale),
        Expanded(
          child: _buildTextField(
            label2,
            controller2,
            labelFontSize,
            scale,
            readOnly: readOnly2,
          ),
        ),
      ],
    );
  }

  Widget _buildSingleEditField(
    String label,
    TextEditingController controller,
    double labelFontSize,
    double scale,
  ) {
    return _buildTextField(label, controller, labelFontSize, scale);
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    double fontSize,
    double scale, {
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 6 * scale),
        Container(
          decoration: BoxDecoration(
            color: readOnly ? Colors.grey.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(12 * scale),
            border: Border.all(color: Colors.grey.shade300, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6 * scale,
                offset: Offset(0, 2 * scale),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            maxLines: maxLines,
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              color: readOnly ? Colors.grey.shade600 : Colors.black,
            ),
            decoration: InputDecoration(
              hintText: 'Enter $label',
              hintStyle: GoogleFonts.poppins(
                fontSize: fontSize,
                color: Colors.grey.shade400,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12 * scale,
                vertical: maxLines > 1 ? 12 * scale : 14 * scale,
              ),
            ),
          ),
        ),
      ],
    );
  }

  ProfilingData? _getCurrentProfilingData() {
    final incoming = widget.profileData['data'];
    if (incoming is ProfilingData) {
      return incoming;
    }
    if (incoming is Map<String, dynamic>) {
      return ProfilingData(
        isExistingFarmer: incoming['isExistingFarmer'] == true,
        saadCommodityType: incoming['saadCommodityType']?.toString(),
        saadCommodities: (incoming['saadCommodities'] as List?)
            ?.whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList(),
        nonSAADCommodityType: incoming['nonSAADCommodityType']?.toString(),
        nonSAADCommodities: (incoming['nonSAADCommodities'] as List?)
            ?.whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList(),
      );
    }
    return null;
  }

  List<Map<String, dynamic>> _toCommodityEntryList(dynamic entries) {
    if (entries is List) {
      return entries
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  String _safeEntryValue(Map<String, dynamic> entry, String key) {
    final value = entry[key];
    if (value == null) return 'N/A';
    final text = value.toString().trim();
    return text.isEmpty ? 'N/A' : text;
  }

  Widget _buildCommodityDetailsEditSection({
    required String? selectedType,
    required List<Map<String, dynamic>> entries,
    required double labelFontSize,
    required double scale,
  }) {
    final typeText = (selectedType ?? '').trim();

    if (entries.isEmpty) {
      return _buildStaticField(
        'Selected Type',
        '${typeText.isEmpty ? 'N/A' : typeText}\nNo commodity details saved yet.',
        labelFontSize,
        scale,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStaticField(
          'Selected Type',
          typeText.isEmpty ? 'N/A' : typeText,
          labelFontSize,
          scale,
        ),
        SizedBox(height: 10 * scale),
        ...entries.asMap().entries.map((entryItem) {
          final index = entryItem.key;
          final entry = entryItem.value;
          return Padding(
            padding: EdgeInsets.only(bottom: 10 * scale),
            child: _buildCommodityEntryEditCard(
              entryIndex: index,
              selectedType: selectedType,
              entry: entry,
              labelFontSize: labelFontSize,
              scale: scale,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCommodityEntryEditCard({
    required int entryIndex,
    required String? selectedType,
    required Map<String, dynamic> entry,
    required double labelFontSize,
    required double scale,
  }) {
    final savedType = _safeEntryValue(entry, 'type');
    final resolvedType = savedType == 'N/A'
        ? (((selectedType ?? '').trim().isEmpty ? 'N/A' : selectedType!.trim()))
        : savedType;
    final maleCount = _safeEntryValue(entry, 'maleCount');
    final femaleCount = _safeEntryValue(entry, 'femaleCount');
    final hasSexCounts = maleCount != 'N/A' || femaleCount != 'N/A';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12 * scale),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10 * scale),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Entry ${entryIndex + 1}',
            style: GoogleFonts.poppins(
              fontSize: labelFontSize,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 10 * scale),
          _buildStaticInfoRow(
            'Type',
            resolvedType,
            'Commodity',
            _safeEntryValue(entry, 'commodity'),
            labelFontSize,
            scale,
          ),
          _buildStaticInfoRow(
            'Sale Method',
            _safeEntryValue(entry, 'saleMeth'),
            'Product Form',
            _safeEntryValue(entry, 'productForm'),
            labelFontSize,
            scale,
          ),
          _buildStaticInfoRow(
            'Pricing Basis',
            _safeEntryValue(entry, 'pricingBasis'),
            'Unit',
            _safeEntryValue(entry, 'unit'),
            labelFontSize,
            scale,
          ),
          if (hasSexCounts)
            _buildStaticInfoRow(
              'Male Count',
              maleCount,
              'Female Count',
              femaleCount,
              labelFontSize,
              scale,
            ),
          _buildStaticInfoRow(
            'Total Weight',
            _safeEntryValue(entry, 'totalWeight'),
            'Total Amount',
            _safeEntryValue(entry, 'totalAmount'),
            labelFontSize,
            scale,
          ),
          _buildStaticField(
            'Expenses',
            _safeEntryValue(entry, 'expenses'),
            labelFontSize,
            scale,
          ),
          SizedBox(height: 8 * scale),
          _buildStaticField(
            'Remarks',
            _safeEntryValue(entry, 'remarks'),
            labelFontSize,
            scale,
          ),
        ],
      ),
    );
  }

  Widget _buildStaticInfoRow(
    String label1,
    String value1,
    String label2,
    String value2,
    double fontSize,
    double scale,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8 * scale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildStaticField(label1, value1, fontSize, scale)),
          SizedBox(width: 10 * scale),
          Expanded(child: _buildStaticField(label2, value2, fontSize, scale)),
        ],
      ),
    );
  }

  Widget _buildStaticField(
    String label,
    String value,
    double fontSize,
    double scale,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10 * scale),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: GoogleFonts.poppins(
              fontSize: fontSize - 1,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  /// FARM/FISHERIES INCOME - 3 BENEFICIARY INCOME FIELDS WITH REMARKS
  Widget _buildFarmIncomeEditSection(double labelFontSize, double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBeneficiaryIncomeEdit(
          'Beneficiary (Farmer) Income',
          _beneficiaryIncomeCtrl,
          _beneficiaryRemarksCtrl,
          labelFontSize,
          scale,
        ),
        SizedBox(height: 12 * scale),
        _buildBeneficiaryIncomeEdit(
          'Spouse Income',
          _spouseIncomeCtrl,
          _spouseRemarksCtrl,
          labelFontSize,
          scale,
        ),
        SizedBox(height: 12 * scale),
        _buildBeneficiaryIncomeEdit(
          'Other Household Members Income',
          _otherMembersIncomeCtrl,
          _otherMembersRemarksCtrl,
          labelFontSize,
          scale,
        ),
      ],
    );
  }

  Widget _buildBeneficiaryIncomeEdit(
    String title,
    TextEditingController incomeCtrl,
    TextEditingController? remarksCtrl,
    double labelFontSize,
    double scale,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: labelFontSize + 2 * scale,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8 * scale),
        _buildTextField(
          'Income Breakdown',
          incomeCtrl,
          labelFontSize,
          scale,
          maxLines: 3,
        ),
        if (remarksCtrl != null) ...[
          SizedBox(height: 12 * scale),
          _buildTextField(
            'Remarks',
            remarksCtrl,
            labelFontSize,
            scale,
            maxLines: 3,
          ),
        ],
      ],
    );
  }
}
