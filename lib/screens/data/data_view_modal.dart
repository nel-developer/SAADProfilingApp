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
    
    // Get the year from yearCovered field
    final yearCovered = profileData.yearCovered;
    if (yearCovered == null) {
      // Fallback to current year if not set
      return [DateTime.now().year];
    }
    
    try {
      // Handle both string and int types
      if (yearCovered is int) {
        return [yearCovered];
      } else if (yearCovered is String) {
        if (yearCovered.isEmpty) {
          return [DateTime.now().year];
        }
        final year = int.parse(yearCovered);
        return [year];
      }
      return [DateTime.now().year];
    } catch (e) {
      debugPrint('⚠️ Error parsing year: $e');
      return [DateTime.now().year];
    }
  }

  void _toggleYear(int year) {
    setState(() {
      _expandedYears[year] = !(_expandedYears[year] ?? false);
    });
  }

  double _scale(BuildContext context) {
    final scaleW =
        (MediaQuery.of(context).size.width / DataViewModal._refWidth).clamp(0.5, 2.0);
    final scaleH =
        (MediaQuery.of(context).size.height / DataViewModal._refHeight).clamp(0.5, 2.0);
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
                    Container(
                      height: 2 * scale,
                      color: Colors.grey.shade300,
                    ),
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
                      _getProfileData()?.sex ?? 'N/A',
                      'Date of Birth:',
                      _getProfileData()?.dateOfBirth ?? 'N/A',
                      labelFontSize,
                      valueFontSize,
                      scale,
                    ),

                    SizedBox(height: 16 * scale),
                    SizedBox(height: 12 * scale),
                    if ((_getProfileData()?.approverEmail ?? '').toString().isNotEmpty)
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 4 * scale),
                          child: Text(
                            'Approved by: ${_getProfileData()?.approverEmail}${_getProfileData()?.approvedAt != null ? ' on ${_getProfileData()!.approvedAt!.toString().split(' ')[0]}' : ''}',
                            style: GoogleFonts.poppins(fontSize: 11 * scale, color: Colors.grey.shade600),
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
                    _buildSectionTitle('Main Commodity', sectionTitleFontSize, scale),
                    _buildInfoRow(
                      'Primary Commodity:',
                      _getProfileData()?.primaryCommodity ?? 'N/A',
                      'Secondary Commodity:',
                      _getProfileData()?.secondaryCommodity ?? 'N/A',
                      labelFontSize,
                      valueFontSize,
                      scale,
                    ),
                    // Show "If Other, please specify" only when an "others" value exists
                    if ((_getProfileData()?.primaryCommodityOthers ?? '').toString().isNotEmpty)
                      _buildSingleRow(
                        'If Primary is Other, specify:',
                        _getProfileData()?.primaryCommodityOthers ?? '___________',
                        labelFontSize,
                        valueFontSize,
                        scale,
                      ),
                    if ((_getProfileData()?.secondaryCommodityOthers ?? '').toString().isNotEmpty)
                      _buildSingleRow(
                        'If Secondary is Other, specify:',
                        _getProfileData()?.secondaryCommodityOthers ?? '___________',
                        labelFontSize,
                        valueFontSize,
                        scale,
                      ),

                    SizedBox(height: 16 * scale),
                    _buildSectionTitle(
                      'Farmers/Fishers Cooperative',
                      sectionTitleFontSize,
                      scale,
                    ),
                    _buildInfoRow(
                      'Organization Name:',
                      _getProfileData()?.cooperativeName ?? 'N/A',
                      'Position:',
                      _getProfileData()?.cooperativePosition ?? 'N/A',
                      labelFontSize,
                      valueFontSize,
                      scale,
                    ),
                    _buildInfoRow(
                      'Date of Membership:',
                      _getProfileData()?.dateOfMembership ?? 'N/A',
                      'If Other Position, specify:',
                      _getProfileData()?.cooperativePositionOthers ?? '___________',
                      labelFontSize,
                      valueFontSize,
                      scale,
                    ),

                    SizedBox(height: 16 * scale),
                    _buildSectionTitle('Recurrence', sectionTitleFontSize, scale),
                    // DYNAMIC YEAR DROPDOWNS (last 3 years + current year, descending)
                    // NOW INCLUDES MONTHLY INCOME INSIDE EACH YEAR
                    ..._buildRecurrenceYearsList(labelFontSize, valueFontSize, scale),

                    SizedBox(height: 16 * scale),
                    _buildSectionTitle(
                      'Farm/Fisheries Income',
                      sectionTitleFontSize,
                      scale,
                    ),
                    _buildFarmIncomeMultiline(labelFontSize, valueFontSize, scale),
                  ],
                ),
              ),
            ),
          ),

          /// BOTTOM BUTTONS
          if (_shouldShowButtons())
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(bottomPadding),
              child: _buildBottomButtons(context, buttonHeight, buttonFontSize, buttonSpacing),
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
  List<Widget> _buildRecurrenceYearsList(double labelSize, double valueSize, double scale) {
    final years = _getRelevantYears()..sort((a, b) => b.compareTo(a)); // descending
    
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

  Widget _buildRecurrenceYear(String year, double labelSize, double valueSize, double scale, {bool isExpanded = false}) {
    final profileData = _getProfileData();
    
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
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
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
                  Text('Year Covered: $year', style: GoogleFonts.poppins(fontSize: labelSize)),
                  SizedBox(height: 8 * scale),
                  _buildInfoRow(
                    'Received Primary Commodity:',
                    profileData.primaryCommodityRecurrence == true ? 'Yes' : 'No',
                    'Received Secondary Commodity:',
                    profileData.secondaryCommodityRecurrence == true ? 'Yes' : 'No',
                    labelSize - 1 * scale,
                    valueSize - 1 * scale,
                    scale,
                  ),
                  // No remarks are shown for recurrence (no fields exist); if a recurrence-specify field exists
                  if ((profileData.primaryCommodityRecurrenceOthers ?? '').toString().isNotEmpty)
                    _buildSingleRow(
                      'If Primary Received Other, specify:',
                      profileData.primaryCommodityRecurrenceOthers ?? '___________',
                      labelSize - 1 * scale,
                      valueSize - 1 * scale,
                      scale,
                    ),
                  if ((profileData.secondaryCommodityRecurrenceOthers ?? '').toString().isNotEmpty)
                    _buildSingleRow(
                      'If Secondary Received Other, specify:',
                      profileData.secondaryCommodityRecurrenceOthers ?? '___________',
                      labelSize - 1 * scale,
                      valueSize - 1 * scale,
                      scale,
                    ),
                  _buildSingleRow(
                    'No. of Family Members:\nMale: ${profileData.numberOfMalesInFamily ?? 0}     Female: ${profileData.numberOfFemalesInFamily ?? 0}',
                    '',
                    labelSize - 1 * scale,
                    valueSize - 1 * scale,
                    scale,
                  ),
                  _buildInfoRow(
                    'Land Tenureship:',
                    profileData.landTenureship ?? 'N/A',
                    'If Other, specify:',
                    profileData.landTenureshipOthers ?? '___________',
                    labelSize - 1 * scale,
                    valueSize - 1 * scale,
                    scale,
                  ),
                  Text(
                    'No of Years Farming/Fishing: ${profileData.yearsInFarming ?? 0}',
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
                    '₱${profileData.agriRelatedIncome ?? 0}',
                    'SAAD Net Income:',
                    '₱${profileData.saadNetIncome ?? 0}',
                    labelSize - 1 * scale,
                    valueSize - 1 * scale,
                    scale,
                  ),
                  _buildInfoRow(
                    'From Non-Agri (Gross):',
                    '₱${profileData.nonAgriRelatedIncome ?? 0}',
                    'Main Sources:',
                    profileData.mainSourcesOfIncome ?? 'N/A',
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

  /// MULTILINE FARM INCOME DISPLAY - 1 FIELD FOR AMOUNTS, 1 FOR REMARKS
  Widget _buildFarmIncomeMultiline(double labelSize, double valueSize, double scale) {
    final profileData = _getProfileData();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCommodityDisplay('Rice / Corn', profileData?.riceIncomeField, profileData?.riceRemarks, labelSize, valueSize, scale),
        SizedBox(height: 12 * scale),
        _buildCommodityDisplay('HVC', profileData?.hvcIncomeField, profileData?.hvcRemarks, labelSize, valueSize, scale),
        SizedBox(height: 12 * scale),
        _buildCommodityDisplay('Livestock', profileData?.livestockIncomeField, profileData?.livestockRemarks, labelSize, valueSize, scale),
        SizedBox(height: 12 * scale),
        _buildCommodityDisplay('Fishing', profileData?.fishingIncomeField, profileData?.fishingRemarks, labelSize, valueSize, scale),
        SizedBox(height: 12 * scale),
        _buildCommodityDisplay('Non-Farm Fisheries', profileData?.nonFarmFisheriesIncomeField, profileData?.nonFarmFisheriesRemarks, labelSize, valueSize, scale),
      ],
    );
  }

  Widget _buildCommodityDisplay(String title, String? amount, String? remarks, double labelSize, double valueSize, double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: labelSize + 2 * scale,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8 * scale),
        _buildMultilineField('Amount:', amount ?? '___________', labelSize, valueSize, scale),
        SizedBox(height: 8 * scale),
        _buildMultilineField('Remarks:', remarks ?? '___________', labelSize, valueSize, scale),
      ],
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

  Widget _buildBottomButtons(BuildContext context, double buttonHeight, double buttonFontSize, double buttonSpacing) {
    // UNSYNC: Edit + Sync
    if (widget.dataStatus == 'Unsync') {
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

  Widget _buildButton(String label, Color color, VoidCallback onTap, double height, double fontSize) {
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