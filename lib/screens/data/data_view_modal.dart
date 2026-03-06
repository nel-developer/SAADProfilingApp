import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/theme/da_colors.dart';
import 'package:da_project_1/screens/data/data_edit_modal.dart';

class DataViewModal extends StatefulWidget {
  final Map<String, dynamic> profileData;
  final String dataStatus;
  final VoidCallback? onEdit;
  final VoidCallback? onSync;
  final VoidCallback? onApprove;
  final VoidCallback? onDecline;

  static const double _refWidth = 393.0;
  static const double _refHeight = 852.0;

  const DataViewModal({
    super.key,
    required this.profileData,
    required this.dataStatus,
    this.onEdit,
    this.onSync,
    this.onApprove,
    this.onDecline,
  });

  @override
  State<DataViewModal> createState() => _DataViewModalState();
}

class _DataViewModalState extends State<DataViewModal> {
  // Track which years are expanded
  final Map<int, bool> _expandedYears = {};

  @override
  void initState() {
    super.initState();
    // Initialize: all years collapsed by default
    final years = _getRelevantYears();
    for (var year in years) {
      _expandedYears[year] = false;
    }
  }

  // Get the ProfilingData from the profileData map
  dynamic _getProfileData() {
    if (widget.profileData['data'] != null) {
      return widget.profileData['data'];
    }
    return null;
  }

  // Get the year from profiling data (yearCovered field)
  List<int> _getRelevantYears() {
    final profileData = _getProfileData();
    if (profileData == null) return [];

    final years = <int>{};

    try {
      final byYear = profileData.recurrenceByYear;
      if (byYear is Map) {
        for (final key in byYear.keys) {
          final parsed = int.tryParse(key.toString().trim());
          if (parsed != null) {
            years.add(parsed);
          }
        }
      }
    } catch (_) {}

    // Get the year from yearCovered field
    final yearCovered = profileData.yearCovered;
    try {
      if (yearCovered is int) {
        years.add(yearCovered);
      } else if (yearCovered is String && yearCovered.trim().isNotEmpty) {
        final year = int.tryParse(yearCovered.trim());
        if (year != null) years.add(year);
      }
    } catch (e) {
      debugPrint('⚠️ Error parsing year: $e');
    }

    if (years.isEmpty) {
      return [DateTime.now().year];
    }

    final sorted = years.toList()..sort((a, b) => b.compareTo(a));
    return sorted;
  }

  void _toggleYear(int year) {
    setState(() {
      _expandedYears[year] = !(_expandedYears[year] ?? false);
    });
  }

  double _scale(BuildContext context) {
    final scaleW = (MediaQuery.of(context).size.width / DataViewModal._refWidth)
        .clamp(0.5, 2.0);
    final scaleH =
        (MediaQuery.of(context).size.height / DataViewModal._refHeight).clamp(
          0.5,
          2.0,
        );
    return min(scaleW, scaleH);
  }

  void _openEditModal(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DataEditModal(
          profileData: widget.profileData,
          onSave: (updatedData) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Profile updated successfully'),
                backgroundColor: DAColors.primaryGreen,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = _scale(context);
    final profileData = _getProfileData();

    final titleFontSize = 20.0 * scale;
    final sectionTitleFontSize = 16.0 * scale;
    final labelFontSize = 12.0 * scale;
    final valueFontSize = 12.0 * scale;
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
    final buttonSpacing = 8.0 * scale;

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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    Text(
                      'View Profile',
                      style: GoogleFonts.poppins(
                        fontSize: headerTitleSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: backButtonSize + backButtonPadding * 2),
                  ],
                ),
              ),
            ),
          ),

          /// SCROLLABLE CONTENT
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
                    _buildInfoRow(
                      'Surname:',
                      _getProfileData()?.surname ?? 'N/A',
                      'First Name:',
                      _getProfileData()?.firstName ?? 'N/A',
                      labelFontSize,
                      valueFontSize,
                      scale,
                    ),
                    _buildInfoRow(
                      'Middle Name:',
                      _getProfileData()?.middleName ?? 'N/A',
                      'Extension Name:',
                      _getProfileData()?.extensionName ?? 'N/A',
                      labelFontSize,
                      valueFontSize,
                      scale,
                    ),
                    _buildInfoRow(
                      'Sex:',
                      profileData?.sex ?? 'N/A',
                      'Date of Birth:',
                      profileData?.dateOfBirth ?? 'N/A',
                      labelFontSize,
                      valueFontSize,
                      scale,
                    ),

                    SizedBox(height: 16 * scale),
                    SizedBox(height: 12 * scale),
                    if ((_getProfileData()?.approverEmail ?? '')
                        .toString()
                        .isNotEmpty)
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 4 * scale),
                          child: Text(
                            'Approved by: ${_getProfileData()?.approverEmail}${_getProfileData()?.approvedAt != null ? ' on ${_getProfileData()!.approvedAt!.toString().split(' ')[0]}' : ''}',
                            style: GoogleFonts.poppins(
                              fontSize: 11 * scale,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    _buildSectionTitle('Address', sectionTitleFontSize, scale),
                    _buildInfoRow(
                      'Region:',
                      _getProfileData()?.region ?? 'N/A',
                      'Province:',
                      _getProfileData()?.province ?? 'N/A',
                      labelFontSize,
                      valueFontSize,
                      scale,
                    ),
                    _buildInfoRow(
                      'Municipality:',
                      _getProfileData()?.municipality ?? 'N/A',
                      'Barangay:',
                      _getProfileData()?.barangay ?? 'N/A',
                      labelFontSize,
                      valueFontSize,
                      scale,
                    ),
                    _buildSingleRow(
                      'Sitio/Purok:',
                      _getProfileData()?.sitioPurok ?? 'N/A',
                      labelFontSize,
                      valueFontSize,
                      scale,
                    ),

                    SizedBox(height: 16 * scale),
                    _buildSectionTitle(
                      'Other Personal Information',
                      sectionTitleFontSize,
                      scale,
                    ),
                    _buildInfoRow(
                      'Member of an Indigenous Group:',
                      _getProfileData()?.isIndigenous == true ? 'Yes' : 'No',
                      'Person with Disability(PWD):',
                      _getProfileData()?.isPWD == true ? 'Yes' : 'No',
                      labelFontSize,
                      valueFontSize,
                      scale,
                    ),
                    // Show indigenous group specification only if indigenous is true
                    if (_getProfileData()?.isIndigenous == true)
                      _buildSingleRow(
                        'If yes, please specify (Indigenous Group):',
                        _getProfileData()?.indigenousGroup ?? '___________',
                        labelFontSize,
                        valueFontSize,
                        scale,
                      ),
                    _buildInfoRow(
                      'Tribe/Ethnicity:',
                      _getProfileData()?.tribeEthnicity ?? 'N/A',
                      'Spouse Name:',
                      _getProfileData()?.spouseName ?? '___________',
                      labelFontSize,
                      valueFontSize,
                      scale,
                    ),

                    SizedBox(height: 16 * scale),
                    _buildSectionTitle(
                      'Recurrence',
                      sectionTitleFontSize,
                      scale,
                    ),
                    // DYNAMIC YEAR DROPDOWNS (last 3 years + current year, descending)
                    // NOW INCLUDES MONTHLY INCOME INSIDE EACH YEAR
                    ..._buildRecurrenceYearsList(
                      labelFontSize,
                      valueFontSize,
                      scale,
                    ),
                  ],
                ),
              ),
            ),
          ),

          /// BOTTOM BUTTONS
          if (_shouldShowButtons())
            SafeArea(
              top: false,
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.fromLTRB(
                  bottomPadding,
                  bottomPadding,
                  bottomPadding,
                  bottomPadding,
                ),
                child: _buildBottomButtons(
                  context,
                  buttonHeight,
                  buttonFontSize,
                  buttonSpacing,
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _shouldShowButtons() {
    return widget.dataStatus == 'Unsync' ||
        widget.dataStatus == 'Pending' ||
        widget.dataStatus == 'Approved';
  }

  // Build the list of recurrence year dropdowns (descending order)
  List<Widget> _buildRecurrenceYearsList(
    double labelSize,
    double valueSize,
    double scale,
  ) {
    final years = _getRelevantYears()
      ..sort((a, b) => b.compareTo(a)); // descending

    return years.map((year) {
      final isExpanded = _expandedYears[year] ?? false;
      return GestureDetector(
        onTap: () => _toggleYear(year),
        child: _buildRecurrenceYear(
          year.toString(),
          labelSize,
          valueSize,
          scale,
          isExpanded: isExpanded,
        ),
      );
    }).toList();
  }

  Widget _buildSectionTitle(String title, double fontSize, double scale) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12 * scale),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 8 * scale),
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
      ),
    );
  }

  Widget _buildInfoRow(
    String label1,
    String value1,
    String label2,
    String value2,
    double labelSize,
    double valueSize,
    double scale,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12 * scale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label1,
                  style: GoogleFonts.poppins(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4 * scale),
                Text(
                  value1,
                  style: GoogleFonts.poppins(
                    fontSize: valueSize,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label2,
                  style: GoogleFonts.poppins(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4 * scale),
                Text(
                  value2,
                  style: GoogleFonts.poppins(
                    fontSize: valueSize,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleRow(
    String label,
    String value,
    double labelSize,
    double valueSize,
    double scale,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: labelSize,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: valueSize,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurrenceYear(
    String year,
    double labelSize,
    double valueSize,
    double scale, {
    bool isExpanded = false,
  }) {
    final profileData = _getProfileData();
    Map<String, dynamic> yearData = {};
    try {
      final byYear = profileData?.recurrenceByYear;
      if (byYear is Map && byYear[year] is Map) {
        yearData = Map<String, dynamic>.from(byYear[year]);
      }
    } catch (_) {}

    String scopedText(String key, String fallback) {
      final value = yearData[key];
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) {
        return text;
      }
      return fallback;
    }

    String scopedFromKeys(List<String> keys, String fallback) {
      for (final key in keys) {
        final value = yearData[key];
        final text = value?.toString().trim();
        if (text != null && text.isNotEmpty) {
          return text;
        }
      }
      return fallback;
    }

    dynamic scopedValueFromKeys(List<String> keys, dynamic fallback) {
      for (final key in keys) {
        final value = yearData[key];
        if (value == null) continue;
        final text = value.toString().trim();
        if (text.isNotEmpty) {
          return value;
        }
      }
      return fallback;
    }

    final maleFamily = scopedText(
      'maleFamilyMembers',
      '${profileData?.numberOfMalesInFamily ?? 0}',
    );
    final femaleFamily = scopedText(
      'femaleFamilyMembers',
      '${profileData?.numberOfFemalesInFamily ?? 0}',
    );
    final landTenureship = scopedText(
      'landTenureship',
      profileData?.landTenureship ?? 'N/A',
    );
    final landTenureshipOthers = scopedText(
      'landTenureshipOthers',
      profileData?.landTenureshipOthers ?? '___________',
    );
    final yearsInFarming = scopedText(
      'yearsInFarming',
      '${profileData?.yearsInFarming ?? 0}',
    );
    final receivedPrimaryCommodity = scopedFromKeys(
      ['receivedPrimaryCommodity', 'receivedCommodity', 'primaryCommodity'],
      (profileData?.receivedPrimaryCommodity ??
              profileData?.receivedCommodity ??
              profileData?.primaryCommodity ??
              'N/A')
          .toString(),
    );
    final receivedSecondaryCommodity = scopedFromKeys(
      ['receivedSecondaryCommodity', 'secondaryCommodity'],
      (profileData?.receivedSecondaryCommodity ??
              profileData?.secondaryCommodity ??
              'N/A')
          .toString(),
    );
    final primaryCommodity = scopedFromKeys([
      'primaryCommodity',
    ], (profileData?.primaryCommodity ?? 'N/A').toString());
    final secondaryCommodity = scopedFromKeys([
      'secondaryCommodity',
    ], (profileData?.secondaryCommodity ?? 'N/A').toString());
    final beneficiaryIncome = scopedFromKeys([
      'beneficiaryNonFarmIncome',
    ], (profileData?.beneficiaryNonFarmIncome ?? '___________').toString());
    final beneficiaryRemarks = scopedFromKeys([
      'beneficiaryRemarks',
    ], (profileData?.beneficiaryRemarks ?? 'N/A').toString());
    final spouseIncome = scopedFromKeys([
      'spouseNonFarmIncome',
    ], (profileData?.spouseNonFarmIncome ?? '___________').toString());
    final spouseRemarks = scopedFromKeys([
      'spouseRemarks',
    ], (profileData?.spouseRemarks ?? 'N/A').toString());
    final otherMembersIncome = scopedFromKeys([
      'otherMembersNonFarmIncome',
    ], (profileData?.otherMembersNonFarmIncome ?? '___________').toString());
    final otherMembersRemarks = scopedFromKeys([
      'otherMembersRemarks',
    ], (profileData?.otherMembersRemarks ?? 'N/A').toString());
    final nonSaadNetIncome = _resolveNonSaadNetIncome(profileData);
    final agriRelatedIncome = scopedValueFromKeys([
      'agriRelatedIncome',
    ], profileData?.agriRelatedIncome);
    final saadNetIncome = scopedValueFromKeys([
      'saadNetIncome',
    ], profileData?.saadNetIncome);
    final nonSaadNetIncomeScoped = scopedValueFromKeys([
      'nonSAADNetIncome',
    ], nonSaadNetIncome);
    final nonAgriRelatedIncome = scopedValueFromKeys([
      'nonAgriRelatedIncome',
    ], profileData?.nonAgriRelatedIncome);
    final mainSourcesOfIncome = scopedFromKeys([
      'mainSourcesOfIncome',
    ], profileData?.mainSourcesOfIncome ?? 'N/A');
    final cooperativeName = scopedFromKeys([
      'cooperativeName',
    ], (profileData?.cooperativeName ?? 'N/A').toString());
    final cooperativePosition = scopedFromKeys([
      'cooperativePosition',
    ], (profileData?.cooperativePosition ?? 'N/A').toString());
    final dateOfMembership = scopedFromKeys([
      'dateOfMembership',
    ], (profileData?.dateOfMembership ?? 'N/A').toString());
    final cooperativePositionOthers = scopedFromKeys([
      'cooperativePositionOthers',
    ], (profileData?.cooperativePositionOthers ?? '___________').toString());
    final isOtherCoopPosition =
        cooperativePosition.trim().toLowerCase() == 'other';
    final saadEntries = _toCommodityEntryList(profileData?.saadCommodities);
    final nonSaadEntries = _toCommodityEntryList(
      profileData?.nonSAADCommodities,
    );

    return Container(
      margin: EdgeInsets.only(bottom: 12 * scale),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8 * scale),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12 * scale),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: isExpanded
                  ? BorderRadius.only(
                      topLeft: Radius.circular(8 * scale),
                      topRight: Radius.circular(8 * scale),
                    )
                  : BorderRadius.circular(8 * scale),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  year,
                  style: GoogleFonts.poppins(
                    fontSize: valueSize + 2 * scale,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
          if (isExpanded && profileData != null)
            Padding(
              padding: EdgeInsets.all(12 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Year Covered: $year',
                    style: GoogleFonts.poppins(fontSize: labelSize),
                  ),
                  SizedBox(height: 8 * scale),
                  _buildInfoRow(
                    'Organization Name:',
                    cooperativeName,
                    'Position:',
                    cooperativePosition,
                    labelSize - 1 * scale,
                    valueSize - 1 * scale,
                    scale,
                  ),
                  _buildSingleRow(
                    'Date of Membership:',
                    dateOfMembership,
                    labelSize - 1 * scale,
                    valueSize - 1 * scale,
                    scale,
                  ),
                  if (isOtherCoopPosition)
                    _buildSingleRow(
                      'If Other Position, specify:',
                      cooperativePositionOthers,
                      labelSize - 1 * scale,
                      valueSize - 1 * scale,
                      scale,
                    ),
                  _buildInfoRow(
                    'Main Primary Commodity:',
                    primaryCommodity,
                    'Main Secondary Commodity:',
                    secondaryCommodity,
                    labelSize - 1 * scale,
                    valueSize - 1 * scale,
                    scale,
                  ),
                  _buildInfoRow(
                    'Received Primary Commodity:',
                    receivedPrimaryCommodity,
                    'Received Secondary Commodity:',
                    receivedSecondaryCommodity,
                    labelSize - 1 * scale,
                    valueSize - 1 * scale,
                    scale,
                  ),
                  // No remarks are shown for recurrence (no fields exist); if a recurrence-specify field exists
                  if ((profileData.primaryCommodityRecurrenceOthers ?? '')
                      .toString()
                      .isNotEmpty)
                    _buildSingleRow(
                      'If Primary Received Other, specify:',
                      profileData.primaryCommodityRecurrenceOthers ??
                          '___________',
                      labelSize - 1 * scale,
                      valueSize - 1 * scale,
                      scale,
                    ),
                  if ((profileData.secondaryCommodityRecurrenceOthers ?? '')
                      .toString()
                      .isNotEmpty)
                    _buildSingleRow(
                      'If Secondary Received Other, specify:',
                      profileData.secondaryCommodityRecurrenceOthers ??
                          '___________',
                      labelSize - 1 * scale,
                      valueSize - 1 * scale,
                      scale,
                    ),
                  _buildSingleRow(
                    'No. of Family Members:\nMale: $maleFamily     Female: $femaleFamily',
                    '',
                    labelSize - 1 * scale,
                    valueSize - 1 * scale,
                    scale,
                  ),
                  _buildInfoRow(
                    'Land Tenureship:',
                    landTenureship,
                    'If Other, specify:',
                    landTenureshipOthers,
                    labelSize - 1 * scale,
                    valueSize - 1 * scale,
                    scale,
                  ),
                  Text(
                    'No of Years Farming/Fishing: $yearsInFarming',
                    style: GoogleFonts.poppins(fontSize: labelSize),
                  ),

                  SizedBox(height: 12 * scale),

                  // MONTHLY FAMILY INCOME
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 6 * scale),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6 * scale),
                    ),
                    child: Center(
                      child: Text(
                        'Monthly Family Income',
                        style: GoogleFonts.poppins(
                          fontSize: labelSize,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8 * scale),
                  _buildInfoRow(
                    'From Agri-Related (Gross):',
                    _formatPesoWhole(agriRelatedIncome),
                    'SAAD Net Income:',
                    _formatPesoWhole(saadNetIncome),
                    labelSize - 1 * scale,
                    valueSize - 1 * scale,
                    scale,
                  ),
                  _buildInfoRow(
                    'Non-SAAD Net Income:',
                    _formatPesoWhole(nonSaadNetIncomeScoped),
                    'From Non-Agri (Gross):',
                    _formatPesoWhole(nonAgriRelatedIncome),
                    labelSize - 1 * scale,
                    valueSize - 1 * scale,
                    scale,
                  ),
                  _buildSingleRow(
                    'Main Sources:',
                    mainSourcesOfIncome,
                    labelSize - 1 * scale,
                    valueSize - 1 * scale,
                    scale,
                  ),
                  SizedBox(height: 10 * scale),
                  _buildCommodityDetailsSection(
                    sectionTitle: 'SAAD Commodity Details',
                    entries: saadEntries,
                    labelSize: labelSize,
                    valueSize: valueSize,
                    scale: scale,
                  ),
                  SizedBox(height: 8 * scale),
                  _buildCommodityDetailsSection(
                    sectionTitle: 'Non-SAAD Commodity Details',
                    entries: nonSaadEntries,
                    labelSize: labelSize,
                    valueSize: valueSize,
                    scale: scale,
                  ),
                  SizedBox(height: 10 * scale),
                  _buildMultilineField(
                    'Beneficiary (Farmer) Income Breakdown:',
                    beneficiaryIncome,
                    labelSize - 1 * scale,
                    valueSize - 1 * scale,
                    scale,
                  ),
                  SizedBox(height: 8 * scale),
                  _buildMultilineField(
                    'Beneficiary Remarks:',
                    beneficiaryRemarks,
                    labelSize - 1 * scale,
                    valueSize - 1 * scale,
                    scale,
                  ),
                  SizedBox(height: 8 * scale),
                  _buildMultilineField(
                    'Spouse Income Breakdown:',
                    spouseIncome,
                    labelSize - 1 * scale,
                    valueSize - 1 * scale,
                    scale,
                  ),
                  SizedBox(height: 8 * scale),
                  _buildMultilineField(
                    'Spouse Remarks:',
                    spouseRemarks,
                    labelSize - 1 * scale,
                    valueSize - 1 * scale,
                    scale,
                  ),
                  SizedBox(height: 8 * scale),
                  _buildMultilineField(
                    'Other Household Members Income Breakdown:',
                    otherMembersIncome,
                    labelSize - 1 * scale,
                    valueSize - 1 * scale,
                    scale,
                  ),
                  SizedBox(height: 8 * scale),
                  _buildMultilineField(
                    'Other Members Remarks:',
                    otherMembersRemarks,
                    labelSize - 1 * scale,
                    valueSize - 1 * scale,
                    scale,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatPesoWhole(dynamic value) {
    if (value == null) return '₱0';
    if (value is num) return '₱${value.round()}';
    final parsed = num.tryParse(value.toString().replaceAll(',', '').trim());
    return '₱${(parsed ?? 0).round()}';
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '').trim()) ?? 0.0;
  }

  double _calculateMonthlyNetFromEntries(dynamic entries) {
    if (entries is! List || entries.isEmpty) return 0.0;
    double monthlyTotal = 0.0;
    for (final item in entries) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final totalAmount = _toDouble(map['totalAmount']);
      final expenses = _toDouble(map['expenses']);
      final net = totalAmount - expenses;
      if (net > 0) {
        monthlyTotal += net / 12;
      }
    }
    return monthlyTotal.roundToDouble();
  }

  double _resolveNonSaadNetIncome(dynamic profileData) {
    final stored = _toDouble(profileData?.nonSAADNetIncome);
    if (stored > 0) return stored;
    return _calculateMonthlyNetFromEntries(profileData?.nonSAADCommodities);
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

  String _safeEntryValueFromKeys(
    Map<String, dynamic> entry,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = entry[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return 'N/A';
  }

  Widget _buildCommodityDetailsSection({
    required String sectionTitle,
    required List<Map<String, dynamic>> entries,
    required double labelSize,
    required double valueSize,
    required double scale,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 6 * scale),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(6 * scale),
          ),
          child: Center(
            child: Text(
              sectionTitle,
              style: GoogleFonts.poppins(
                fontSize: labelSize,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
        ),
        SizedBox(height: 8 * scale),
        if (entries.isEmpty)
          _buildMultilineField(
            'Entries:',
            'No commodity details saved yet.',
            labelSize - 1 * scale,
            valueSize - 1 * scale,
            scale,
          )
        else
          ...List.generate(entries.length, (index) {
            return Padding(
              padding: EdgeInsets.only(bottom: 10 * scale),
              child: _buildCommodityEntryCard(
                entryIndex: index,
                entry: entries[index],
                labelSize: labelSize,
                valueSize: valueSize,
                scale: scale,
              ),
            );
          }),
      ],
    );
  }

  Widget _buildCommodityEntryCard({
    required int entryIndex,
    required Map<String, dynamic> entry,
    required double labelSize,
    required double valueSize,
    required double scale,
  }) {
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
              fontSize: labelSize,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 10 * scale),
          _buildInfoRow(
            'Type:',
            _safeEntryValue(entry, 'type'),
            'Commodity:',
            _safeEntryValueFromKeys(entry, [
              'commodity',
              'commodityName',
              'item',
            ]),
            labelSize - 1 * scale,
            valueSize - 1 * scale,
            scale,
          ),
          _buildInfoRow(
            'Sale Method:',
            _safeEntryValueFromKeys(entry, ['saleMeth', 'saleMethod']),
            'Product Form:',
            _safeEntryValueFromKeys(entry, ['productForm', 'product']),
            labelSize - 1 * scale,
            valueSize - 1 * scale,
            scale,
          ),
          _buildInfoRow(
            'Pricing Basis:',
            _safeEntryValueFromKeys(entry, ['pricingBasis', 'pricing']),
            'Unit:',
            _safeEntryValue(entry, 'unit'),
            labelSize - 1 * scale,
            valueSize - 1 * scale,
            scale,
          ),
          if (hasSexCounts)
            _buildInfoRow(
              'Male Count:',
              maleCount,
              'Female Count:',
              femaleCount,
              labelSize - 1 * scale,
              valueSize - 1 * scale,
              scale,
            ),
          _buildInfoRow(
            'Total Weight:',
            _safeEntryValueFromKeys(entry, ['totalWeight', 'weight']),
            'Total Amount:',
            _safeEntryValueFromKeys(entry, ['totalAmount', 'amount']),
            labelSize - 1 * scale,
            valueSize - 1 * scale,
            scale,
          ),
          _buildSingleRow(
            'Expenses:',
            _safeEntryValueFromKeys(entry, ['expenses', 'expense']),
            labelSize - 1 * scale,
            valueSize - 1 * scale,
            scale,
          ),
          _buildSingleRow(
            'Remarks:',
            _safeEntryValueFromKeys(entry, [
              'remarks',
              'remark',
              'comments',
              'note',
              'notes',
            ]),
            labelSize - 1 * scale,
            valueSize - 1 * scale,
            scale,
          ),
        ],
      ),
    );
  }

  Widget _buildMultilineField(
    String label,
    String value,
    double labelSize,
    double valueSize,
    double scale,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12 * scale),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8 * scale),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: labelSize,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          if (value.isNotEmpty) ...[
            SizedBox(height: 8 * scale),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: valueSize,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomButtons(
    BuildContext context,
    double buttonHeight,
    double buttonFontSize,
    double buttonSpacing,
  ) {
    final profileData = _getProfileData();
    final isExistingUnsync =
        widget.dataStatus == 'Unsync' && profileData?.isExistingFarmer == true;

    // UNSYNC: Edit + Sync
    if (widget.dataStatus == 'Unsync') {
      if (isExistingUnsync) {
        return Row(
          children: [
            Expanded(
              child: _buildButton(
                'Sync',
                DAColors.primaryGreen,
                widget.onSync ?? () {},
                buttonHeight,
                buttonFontSize,
              ),
            ),
          ],
        );
      }

      return Row(
        children: [
          Expanded(
            child: _buildButton(
              'Edit',
              const Color(0xFF0066CC),
              () => _openEditModal(context),
              buttonHeight,
              buttonFontSize,
            ),
          ),
          SizedBox(width: buttonSpacing),
          Expanded(
            child: _buildButton(
              'Sync',
              DAColors.primaryGreen,
              widget.onSync ?? () {},
              buttonHeight,
              buttonFontSize,
            ),
          ),
        ],
      );
    }

    // PENDING: Approve + Edit + Decline
    if (widget.dataStatus == 'Pending') {
      return Row(
        children: [
          Expanded(
            child: _buildButton(
              'Approve',
              DAColors.primaryGreen,
              widget.onApprove ?? () {},
              buttonHeight,
              buttonFontSize,
            ),
          ),
          SizedBox(width: buttonSpacing),
          Expanded(
            child: _buildButton(
              'Edit',
              const Color(0xFF0066CC),
              () => _openEditModal(context),
              buttonHeight,
              buttonFontSize,
            ),
          ),
          SizedBox(width: buttonSpacing),
          Expanded(
            child: _buildButton(
              'Decline',
              DAColors.red,
              widget.onDecline ?? () {},
              buttonHeight,
              buttonFontSize,
            ),
          ),
        ],
      );
    }

    // APPROVED: View only (no buttons)
    return const SizedBox.shrink();
  }

  Widget _buildButton(
    String label,
    Color color,
    VoidCallback onTap,
    double height,
    double fontSize,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
