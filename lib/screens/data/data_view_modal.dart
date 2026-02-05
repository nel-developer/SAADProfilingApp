import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/theme/da_colors.dart';
import 'package:da_project_1/screens/data/data_edit_modal.dart';

class DataViewModal extends StatelessWidget {
  final Map<String, dynamic> profileData;
  final String userRole;
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
    required this.userRole,
    required this.dataStatus,
    this.onEdit,
    this.onSync,
    this.onApprove,
    this.onDecline,
  });

  double _scale(BuildContext context) {
    final scaleW =
        (MediaQuery.of(context).size.width / _refWidth).clamp(0.5, 2.0);
    final scaleH =
        (MediaQuery.of(context).size.height / _refHeight).clamp(0.5, 2.0);
    return min(scaleW, scaleH);
  }

  void _openEditModal(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DataEditModal(
          profileData: profileData,
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
                      'Dela Cruz',
                      'First Name:',
                      'Juan',
                      labelFontSize,
                      valueFontSize,
                      scale,
                    ),
                    _buildInfoRow(
                      'Middle Name:',
                      'Santos',
                      'Extension Name:',
                      'JR',
                      labelFontSize,
                      valueFontSize,
                      scale,
                    ),
                    _buildInfoRow(
                      'Sex:',
                      'Male',
                      'Date of Birth:',
                      '11/01/1999',
                      labelFontSize,
                      valueFontSize,
                      scale,
                    ),

                    SizedBox(height: 16 * scale),
                    _buildSectionTitle('Address', sectionTitleFontSize, scale),
                    _buildInfoRow(
                      'Region:',
                      'IV-A',
                      'Province:',
                      'Batangas',
                      labelFontSize,
                      valueFontSize,
                      scale,
                    ),
                    _buildInfoRow(
                      'Municipality:',
                      'Lipa City',
                      'Barangay:',
                      'Sabang',
                      labelFontSize,
                      valueFontSize,
                      scale,
                    ),
                    _buildSingleRow(
                      'Sitio/Purok:',
                      'Purok 1',
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
                      'Yes',
                      'Person with Disability(PWD):',
                      'Yes',
                      labelFontSize,
                      valueFontSize,
                      scale,
                    ),
                    _buildInfoRow(
                      'If yes, please specify:',
                      '___________',
                      'Spouse Name:',
                      '___________',
                      labelFontSize,
                      valueFontSize,
                      scale,
                    ),

                    SizedBox(height: 16 * scale),
                    _buildSectionTitle('Main Commodity', sectionTitleFontSize, scale),
                    _buildInfoRow(
                      'Primary Commodity:',
                      'Others',
                      'Secondary Commodity:',
                      'Others',
                      labelFontSize,
                      valueFontSize,
                      scale,
                    ),
                    _buildInfoRow(
                      'If yes, please specify:',
                      '___________',
                      'If yes, please specify:',
                      '___________',
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
                      'Mahika',
                      'Position:',
                      'Others',
                      labelFontSize,
                      valueFontSize,
                      scale,
                    ),
                    _buildInfoRow(
                      'Date of Membership:',
                      '11/12/25',
                      'If yes, please specify:',
                      '___________',
                      labelFontSize,
                      valueFontSize,
                      scale,
                    ),

                    SizedBox(height: 16 * scale),
                    _buildSectionTitle('Recurrence', sectionTitleFontSize, scale),
                    _buildRecurrenceYear('2025', labelFontSize, valueFontSize, scale),
                    _buildRecurrenceYear('2026', labelFontSize, valueFontSize, scale, isExpanded: true),

                    SizedBox(height: 16 * scale),
                    _buildSectionTitle(
                      'Monthly Family Income',
                      sectionTitleFontSize,
                      scale,
                    ),
                    _buildInfoRow(
                      'Derived from Agri-Related Activities(Gross)',
                      '₱25,000',
                      'SAAD Net Income',
                      '₱25,000',
                      labelFontSize,
                      valueFontSize,
                      scale,
                    ),
                    _buildInfoRow(
                      'Derived from Non Agri-Related Activities(Gross)',
                      '₱25,000',
                      'Main Sources of Income',
                      '₱25,000',
                      labelFontSize,
                      valueFontSize,
                      scale,
                    ),

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
    return dataStatus == 'Unsync' || dataStatus == 'Pending' || dataStatus == 'Approved';
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
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8 * scale),
                topRight: Radius.circular(8 * scale),
              ),
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
          if (isExpanded)
            Padding(
              padding: EdgeInsets.all(12 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Year Covered: 2026', style: GoogleFonts.poppins(fontSize: labelSize)),
                  SizedBox(height: 8 * scale),
                  _buildInfoRow(
                    'Received Primary Commodity:',
                    'Others',
                    'Received Secondary Commodity:',
                    'Others',
                    labelSize - 1 * scale,
                    valueSize - 1 * scale,
                    scale,
                  ),
                  _buildInfoRow(
                    'If yes, please specify:',
                    '___________',
                    'If yes, please specify:',
                    '___________',
                    labelSize - 1 * scale,
                    valueSize - 1 * scale,
                    scale,
                  ),
                  _buildSingleRow(
                    'No. of Family Members:\nMale : 2     Female : 2',
                    '',
                    labelSize - 1 * scale,
                    valueSize - 1 * scale,
                    scale,
                  ),
                  _buildInfoRow(
                    'Land Tenureship:',
                    'Others',
                    'If yes, please specify:',
                    '___________',
                    labelSize - 1 * scale,
                    valueSize - 1 * scale,
                    scale,
                  ),
                  Text(
                    'No of Years Fishing/Farming: 5',
                    style: GoogleFonts.poppins(fontSize: labelSize),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// PRIMARY COMMODITY
        Text(
          'Primary Commodity',
          style: GoogleFonts.poppins(
            fontSize: labelSize + 2 * scale,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8 * scale),

        _buildMultilineField(
          'Amount:',
          '₱25,000\n+₱25,000\n₱25,000',
          labelSize,
          valueSize,
          scale,
        ),
        SizedBox(height: 8 * scale),

        _buildMultilineField(
          'Remarks:',
          '',
          labelSize,
          valueSize,
          scale,
        ),

        SizedBox(height: 20 * scale),

        /// SECONDARY COMMODITY
        Text(
          'Secondary Commodity',
          style: GoogleFonts.poppins(
            fontSize: labelSize + 2 * scale,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8 * scale),

        _buildMultilineField(
          'Amount:',
          '₱25,000\n+₱25,000\n₱25,000',
          labelSize,
          valueSize,
          scale,
        ),
        SizedBox(height: 8 * scale),

        _buildMultilineField(
          'Remarks:',
          '',
          labelSize,
          valueSize,
          scale,
        ),
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
    if (dataStatus == 'Unsync') {
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
              onSync ?? () {},
              buttonHeight,
              buttonFontSize,
            ),
          ),
        ],
      );
    }

    // PENDING: Approve + Edit + Decline
    if (dataStatus == 'Pending') {
      return Row(
        children: [
          Expanded(
            child: _buildButton(
              'Approve',
              DAColors.primaryGreen,
              onApprove ?? () {},
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
              onDecline ?? () {},
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