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
  final TextEditingController _extensionNameController = TextEditingController();
  final TextEditingController _sexController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  // Address Controllers
  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _municipalityController = TextEditingController();
  final TextEditingController _barangayController = TextEditingController();
  final TextEditingController _sitioPurokController = TextEditingController();

  // Other Personal Info Controllers
  final TextEditingController _indigenousGroupController = TextEditingController();
  final TextEditingController _pwdController = TextEditingController();
  final TextEditingController _indigenousSpecifyController = TextEditingController();
  final TextEditingController _spouseNameController = TextEditingController();

  // Main Commodity Controllers
  final TextEditingController _primaryCommodityController = TextEditingController();
  final TextEditingController _secondaryCommodityController = TextEditingController();
  final TextEditingController _primarySpecifyController = TextEditingController();
  final TextEditingController _secondarySpecifyController = TextEditingController();

  // Cooperative Controllers
  final TextEditingController _organizationNameController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _dateMembershipController = TextEditingController();
  final TextEditingController _positionSpecifyController = TextEditingController();

  // Recurrence Controllers (Current Year)
  final TextEditingController _recPrimaryController = TextEditingController();
  final TextEditingController _recSecondaryController = TextEditingController();
  final TextEditingController _recPrimarySpecifyController = TextEditingController();
  final TextEditingController _recSecondarySpecifyController = TextEditingController();
  final TextEditingController _familyMaleController = TextEditingController();
  final TextEditingController _familyFemaleController = TextEditingController();
  final TextEditingController _landTenureshipController = TextEditingController();
  final TextEditingController _landTenureshipSpecifyController = TextEditingController();
  final TextEditingController _yearsFishingController = TextEditingController();

  // Monthly Income Controllers (inside Recurrence)
  final TextEditingController _agriRelatedController = TextEditingController();
  final TextEditingController _saadNetIncomeController = TextEditingController();
  final TextEditingController _nonAgriRelatedController = TextEditingController();
  final TextEditingController _mainSourcesController = TextEditingController();

  // Farm Income Controllers - 1 MULTILINE EACH
  // Specific commodity farm income controllers
  final TextEditingController _riceIncomeController = TextEditingController();
  final TextEditingController _riceRemarksController = TextEditingController();
  final TextEditingController _hvcIncomeController = TextEditingController();
  final TextEditingController _hvcRemarksController = TextEditingController();
  final TextEditingController _livestockIncomeController = TextEditingController();
  final TextEditingController _livestockRemarksController = TextEditingController();
  final TextEditingController _fishingIncomeController = TextEditingController();
  final TextEditingController _fishingRemarksController = TextEditingController();
  final TextEditingController _nonFarmFisheriesIncomeController = TextEditingController();
  final TextEditingController _nonFarmFisheriesRemarksController = TextEditingController();

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

      _indigenousGroupController.text = (pd.isIndigenous == true) ? 'Yes' : 'No';
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
      _recPrimaryController.text = (pd.primaryCommodityRecurrence == true) ? 'Yes' : 'No';
      _recSecondaryController.text = pd.secondaryCommodityRecurrence ?? '';
      _recPrimarySpecifyController.text = pd.primaryCommodityRecurrenceOthers ?? '';
      _recSecondarySpecifyController.text = pd.secondaryCommodityRecurrenceOthers ?? '';
      _familyMaleController.text = (pd.maleFamilyMembers ?? 0).toString();
      _familyFemaleController.text = (pd.femaleFamilyMembers ?? 0).toString();
      _landTenureshipController.text = pd.landTenureship ?? '';
      _landTenureshipSpecifyController.text = pd.landTenureshipOthers ?? '';
      _yearsFishingController.text = (pd.yearsInFarming ?? 0).toString();

      _agriRelatedController.text = (pd.agriRelatedIncome ?? 0).toString();
      _saadNetIncomeController.text = (pd.saadNetIncome ?? 0).toString();
      _nonAgriRelatedController.text = (pd.nonAgriRelatedIncome ?? 0).toString();
      _mainSourcesController.text = pd.mainSourcesOfIncome ?? '';

      _riceIncomeController.text = pd.riceIncomeField ?? '';
      _riceRemarksController.text = pd.riceRemarks ?? '';
      _hvcIncomeController.text = pd.hvcIncomeField ?? '';
      _hvcRemarksController.text = pd.hvcRemarks ?? '';
      _livestockIncomeController.text = pd.livestockIncomeField ?? '';
      _livestockRemarksController.text = pd.livestockRemarks ?? '';
      _fishingIncomeController.text = pd.fishingIncomeField ?? '';
      _fishingRemarksController.text = pd.fishingRemarks ?? '';
      _nonFarmFisheriesIncomeController.text = pd.nonFarmFisheriesIncomeField ?? '';
      _nonFarmFisheriesRemarksController.text = pd.nonFarmFisheriesRemarks ?? '';
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
      _saadNetIncomeController.text = '25000';
      _nonAgriRelatedController.text = '25000';
      _mainSourcesController.text = 'Farming';

      // Initialize farm income with MULTILINE data for specific commodities
      _riceIncomeController.text = '25000';
      _riceRemarksController.text = '';
      _hvcIncomeController.text = '0';
      _hvcRemarksController.text = '';
      _livestockIncomeController.text = '0';
      _livestockRemarksController.text = '';
      _fishingIncomeController.text = '0';
      _fishingRemarksController.text = '';
      _nonFarmFisheriesIncomeController.text = '0';
      _nonFarmFisheriesRemarksController.text = '';
    }
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

    _riceIncomeController.dispose();
    _riceRemarksController.dispose();
    _hvcIncomeController.dispose();
    _hvcRemarksController.dispose();
    _livestockIncomeController.dispose();
    _livestockRemarksController.dispose();
    _fishingIncomeController.dispose();
    _fishingRemarksController.dispose();
    _nonFarmFisheriesIncomeController.dispose();
    _nonFarmFisheriesRemarksController.dispose();
    super.dispose();
  }

  double _scale(BuildContext context) {
    final scaleW =
        (MediaQuery.of(context).size.width / _refWidth).clamp(0.5, 2.0);
    final scaleH =
        (MediaQuery.of(context).size.height / _refHeight).clamp(0.5, 2.0);
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
    } else {
      pd = ProfilingData();
    }

    // Update fields from controllers (minimal set)
    pd.surname = _surnameController.text;
    pd.firstName = _firstNameController.text;
    pd.middleName = _middleNameController.text;
    pd.extensionName = _extensionNameController.text;
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
    pd.spouseName = _spouseNameController.text;

    pd.primaryCommodity = _primaryCommodityController.text;
    pd.primaryCommodityOthers = _primarySpecifyController.text;
    pd.secondaryCommodity = _secondaryCommodityController.text;
    pd.secondaryCommodityOthers = _secondarySpecifyController.text;

    pd.cooperativeName = _organizationNameController.text;
    pd.cooperativePosition = _positionController.text;
    pd.dateOfMembership = _dateMembershipController.text;
    pd.cooperativePositionOthers = _positionSpecifyController.text;

    pd.primaryCommodityRecurrence = _recPrimaryController.text.toLowerCase() == 'yes';
    pd.secondaryCommodityRecurrence = _recSecondaryController.text;
    pd.primaryCommodityRecurrenceOthers = _recPrimarySpecifyController.text;
    pd.secondaryCommodityRecurrenceOthers = _recSecondarySpecifyController.text;
    pd.maleFamilyMembers = int.tryParse(_familyMaleController.text) ?? pd.maleFamilyMembers;
    pd.femaleFamilyMembers = int.tryParse(_familyFemaleController.text) ?? pd.femaleFamilyMembers;
    pd.landTenureship = _landTenureshipController.text;
    pd.landTenureshipOthers = _landTenureshipSpecifyController.text;
    pd.yearsInFarming = int.tryParse(_yearsFishingController.text) ?? pd.yearsInFarming;

    pd.agriRelatedIncome = double.tryParse(_agriRelatedController.text) ?? pd.agriRelatedIncome;
    pd.saadNetIncome = double.tryParse(_saadNetIncomeController.text) ?? pd.saadNetIncome;
    pd.nonAgriRelatedIncome = double.tryParse(_nonAgriRelatedController.text) ?? pd.nonAgriRelatedIncome;
    pd.mainSourcesOfIncome = _mainSourcesController.text;

    pd.riceIncomeField = _riceIncomeController.text;
    pd.riceRemarks = _riceRemarksController.text;
    pd.hvcIncomeField = _hvcIncomeController.text;
    pd.hvcRemarks = _hvcRemarksController.text;
    pd.livestockIncomeField = _livestockIncomeController.text;
    pd.livestockRemarks = _livestockRemarksController.text;
    pd.fishingIncomeField = _fishingIncomeController.text;
    pd.fishingRemarks = _fishingRemarksController.text;
    pd.nonFarmFisheriesIncomeField = _nonFarmFisheriesIncomeController.text;
    pd.nonFarmFisheriesRemarks = _nonFarmFisheriesRemarksController.text;

    // Persist updated draft: prefer updating Firestore pending doc first (so ids are assigned),
    // then save locally under the draft_<id> key. If offline, fall back to local save but
    // ensure we reuse any existing ids to avoid creating duplicate drafts.
    final storage = ProfilingStorageService();
    await storage.init();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final success = await storage.saveToPendingCollection(pd, user.uid, onProgress: (stage, progress) {
          debugPrint('🔁 Sync stage: $stage (${progress ?? 0})');
        });
        if (!success) {
          debugPrint('⚠️ Remote save returned false, will persist locally');
        }
      } catch (e) {
        debugPrint('⚠️ Could not sync to pending: $e');
      }
    }

    // Ensure local id uses firebase id if available to prevent autosave duplication
    if ((pd.tempIdLocal == null || pd.tempIdLocal!.isEmpty) && (pd.tempIdFirebase != null && pd.tempIdFirebase!.isNotEmpty)) {
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
                    Container(
                      height: 2 * scale,
                      color: Colors.grey.shade300,
                    ),
                    SizedBox(height: 20 * scale),

                    /// PERSONAL INFO
                    _buildSectionTitle('Personal Information', sectionTitleFontSize, scale),
                    SizedBox(height: 12 * scale),
                    _buildEditRow(
                      'Surname',
                      _surnameController,
                      'First Name',
                      _firstNameController,
                      labelFontSize,
                      scale,
                    ),
                    SizedBox(height: 12 * scale),
                    _buildEditRow(
                      'Middle Name',
                      _middleNameController,
                      'Extension Name',
                      _extensionNameController,
                      labelFontSize,
                      scale,
                    ),
                    SizedBox(height: 12 * scale),
                    _buildEditRow(
                      'Sex',
                      _sexController,
                      'Date of Birth',
                      _dobController,
                      labelFontSize,
                      scale,
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
                    _buildSectionTitle('Other Personal Information', sectionTitleFontSize, scale),
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
                    _buildSectionTitle('Main Commodity', sectionTitleFontSize, scale),
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
                    _buildSectionTitle('Farmers/Fishers Cooperative', sectionTitleFontSize, scale),
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
                    _buildSectionTitle('Recurrence (Current Year)', sectionTitleFontSize, scale),
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
                    _buildEditRow(
                      'Derived from Agri-Related Activities(Gross)',
                      _agriRelatedController,
                      'SAAD Net Income',
                      _saadNetIncomeController,
                      labelFontSize,
                      scale,
                    ),
                    SizedBox(height: 12 * scale),
                    _buildEditRow(
                      'Derived from Non Agri-Related Activities(Gross)',
                      _nonAgriRelatedController,
                      'Main Sources of Income',
                      _mainSourcesController,
                      labelFontSize,
                      scale,
                    ),

                    SizedBox(height: 20 * scale),
                    _buildSectionTitle('Farm/Fisheries Income', sectionTitleFontSize, scale),
                    SizedBox(height: 12 * scale),
                    _buildFarmIncomeEditSection(labelFontSize, scale),
                  ],
                ),
              ),
            ),
          ),

          /// SAVE BUTTON
          Container(
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
    double scale,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildTextField(label1, controller1, labelFontSize, scale),
        ),
        SizedBox(width: 12 * scale),
        Expanded(
          child: _buildTextField(label2, controller2, labelFontSize, scale),
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
            color: Colors.white,
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
            maxLines: maxLines,
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              color: Colors.black,
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

  /// SIMPLIFIED FARM INCOME - 1 MULTILINE FIELD EACH
  Widget _buildFarmIncomeEditSection(double labelFontSize, double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCommodityEdit('Rice / Corn', _riceIncomeController, _riceRemarksController, labelFontSize, scale),
        SizedBox(height: 12 * scale),
        _buildCommodityEdit('HVC', _hvcIncomeController, _hvcRemarksController, labelFontSize, scale),
        SizedBox(height: 12 * scale),
        _buildCommodityEdit('Livestock', _livestockIncomeController, _livestockRemarksController, labelFontSize, scale),
        SizedBox(height: 12 * scale),
        _buildCommodityEdit('Fishing', _fishingIncomeController, _fishingRemarksController, labelFontSize, scale),
        SizedBox(height: 12 * scale),
        _buildCommodityEdit('Non-Farm Fisheries', _nonFarmFisheriesIncomeController, _nonFarmFisheriesRemarksController, labelFontSize, scale),
      ],
    );
  }

  Widget _buildCommodityEdit(String title, TextEditingController incomeCtrl, TextEditingController remarksCtrl, double labelFontSize, double scale) {
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
        _buildTextField('Amount (one per line)', incomeCtrl, labelFontSize, scale, maxLines: 5),
        SizedBox(height: 12 * scale),
        _buildTextField('Remarks', remarksCtrl, labelFontSize, scale, maxLines: 3),
      ],
    );
  }
}