import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/theme/da_colors.dart';
import 'package:da_project_1/widgets/custom_textfield.dart';
import 'package:da_project_1/screens/profiling/profiling_step_wrapper.dart';
import 'package:da_project_1/models/profiling_data.dart';

/// Step 6 of 8 — Recurrence
///
/// Fields:
///   • No. of Family Members (Male + Female in 1 row)
///   • No. of Years Fishing/Farming
///   • Land Tenureship (radio: Owned, Co-Owned, Rent/Lease, Other + conditional text)
///   • Secondary Commodity (multi-select checkboxes + conditional text)
///   • Year Covered
///   • Received Commodity (single-select dropdown + conditional text)
class Step05Recurrence extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback? onHeaderBack;
  final ProfilingData? currentData;

  const Step05Recurrence({
    super.key,
    required this.onNext,
    this.onBack,
    this.onHeaderBack,
    this.currentData,
  });

  @override
  State<Step05Recurrence> createState() => _Step05RecurrenceState();
}

class _Step05RecurrenceState extends State<Step05Recurrence> {
  // ── Controllers ──
  final TextEditingController _maleCtrl = TextEditingController();
  final TextEditingController _femaleCtrl = TextEditingController();
  final TextEditingController _yearsCtrl = TextEditingController();
  String? _selectedYear; // Year dropdown (dynamic: current year to +3 years)

  // ── Land Tenureship ──
  String? _selectedTenure; // 'Owned', 'Co-Owned', 'Rent/Lease', 'Other'
  final TextEditingController _tenureOtherCtrl = TextEditingController();

  // ── Secondary Commodity (dropdown) ──
  String? _secSelected; // 'Rice', 'Corn', etc.
  final TextEditingController _secOtherCtrl = TextEditingController();

  // ── Received Commodity (single-select) ──
  String? _recSelected; // 'Rice', 'Corn', etc.
  final TextEditingController _recOtherCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Add listeners only once in initState to prevent duplicates
    _maleCtrl.addListener(_autoSaveToCurrentData);
    _femaleCtrl.addListener(_autoSaveToCurrentData);
    _yearsCtrl.addListener(_autoSaveToCurrentData);
    _tenureOtherCtrl.addListener(_autoSaveToCurrentData);
    _secOtherCtrl.addListener(_autoSaveToCurrentData);
    _recOtherCtrl.addListener(_autoSaveToCurrentData);
    _loadData();
  }

  @override
  void didUpdateWidget(Step05Recurrence oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload data when returning to this step via back button
    _loadData();
  }

  void _loadData() {
    if (widget.currentData != null) {
      _maleCtrl.text = widget.currentData!.maleFamilyMembers?.toString() ?? '';
      _femaleCtrl.text = widget.currentData!.femaleFamilyMembers?.toString() ?? '';
      _yearsCtrl.text = widget.currentData!.yearsInFarming?.toString() ?? '';
      _selectedTenure = widget.currentData!.landTenureship;
      _tenureOtherCtrl.text = widget.currentData!.landTenureshipOthers ?? '';
      _secSelected = widget.currentData!.secondaryCommodityRecurrence;
      _secOtherCtrl.text = widget.currentData!.secondaryCommodityRecurrenceOthers ?? '';
      _selectedYear = widget.currentData!.yearCovered?.toString();
      _recSelected = widget.currentData!.receivedCommodity;
      _recOtherCtrl.text = widget.currentData!.receivedCommodityOthers ?? '';
    }
  }

  void _autoSaveToCurrentData() {
    if (widget.currentData != null) {
      widget.currentData!.maleFamilyMembers = int.tryParse(_maleCtrl.text);
      widget.currentData!.femaleFamilyMembers = int.tryParse(_femaleCtrl.text);
      widget.currentData!.yearsInFarming = int.tryParse(_yearsCtrl.text);
      widget.currentData!.landTenureship = _selectedTenure;
      widget.currentData!.landTenureshipOthers = _tenureOtherCtrl.text.trim();
      widget.currentData!.secondaryCommodityRecurrence = _secSelected;
      widget.currentData!.secondaryCommodityRecurrenceOthers = _secOtherCtrl.text.trim();
      widget.currentData!.yearCovered = int.tryParse(_selectedYear ?? '');
      widget.currentData!.receivedCommodity = _recSelected;
      widget.currentData!.receivedCommodityOthers = _recOtherCtrl.text.trim();
    }
  }

  @override
  void dispose() {
    _maleCtrl.dispose();
    _femaleCtrl.dispose();
    _yearsCtrl.dispose();
    _tenureOtherCtrl.dispose();
    _secOtherCtrl.dispose();
    _recOtherCtrl.dispose();
    super.dispose();
  }

  void _handleNext() {
    // No step-level validation; all validation happens at final submit
    // Save data to shared currentData before proceeding
    if (widget.currentData != null) {
      widget.currentData!.maleFamilyMembers = int.tryParse(_maleCtrl.text);
      widget.currentData!.femaleFamilyMembers = int.tryParse(_femaleCtrl.text);
      widget.currentData!.yearsInFarming = int.tryParse(_yearsCtrl.text);
      widget.currentData!.landTenureship = _selectedTenure;
      widget.currentData!.landTenureshipOthers = _tenureOtherCtrl.text.trim();
      widget.currentData!.secondaryCommodityRecurrence = _secSelected;
      widget.currentData!.secondaryCommodityRecurrenceOthers = _secOtherCtrl.text.trim();
      widget.currentData!.yearCovered = int.tryParse(_selectedYear!);
      widget.currentData!.receivedCommodity = _recSelected;
      widget.currentData!.receivedCommodityOthers = _recOtherCtrl.text.trim();
    }
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width > 600;
    final isLargeTablet = width > 900;

    final double labelSize = isLargeTablet ? 16.0 : isTablet ? 15.0 : 14.0;
    final double fieldGap = isLargeTablet ? 22.0 : isTablet ? 18.0 : 14.0;
    final double labelFieldGap = isLargeTablet ? 8.0 : 6.0;
    final double fieldHeight = isLargeTablet ? 54.0 : isTablet ? 50.0 : 44.0;

    return ProfilingStepWrapper(
      currentStep: 6,
      sectionTitle: 'Recurrence',
      onNext: _handleNext,
      onBack: widget.onBack,
      onHeaderBack: widget.onHeaderBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ══════════════════════════════════════════════════════════
          // 1. NO. OF FAMILY MEMBERS (MALE + FEMALE in 1 row)
          // ══════════════════════════════════════════════════════════
          _label('No. of Family Members', labelSize),
          SizedBox(height: labelFieldGap),
          Row(
            children: [
              // MALE
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Male',
                      style: GoogleFonts.poppins(
                        fontSize: labelSize - 2,
                        fontWeight: FontWeight.w600,
                        color: DAColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: fieldHeight,
                      child: _shadowedField(
                        controller: _maleCtrl,
                        hint: 'Enter No. of Male',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: isLargeTablet ? 16.0 : 12.0),
              // FEMALE
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Female',
                      style: GoogleFonts.poppins(
                        fontSize: labelSize - 2,
                        fontWeight: FontWeight.w600,
                        color: DAColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: fieldHeight,
                      child: _shadowedField(
                        controller: _femaleCtrl,
                        hint: 'Enter No. of Female',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: fieldGap),

          // ══════════════════════════════════════════════════════════
          // 2. NO. OF YEARS FISHING/FARMING
          // ══════════════════════════════════════════════════════════
          _label('No. of Years Fishing/Farming', labelSize),
          SizedBox(height: labelFieldGap),
          SizedBox(
            height: fieldHeight,
            child: _shadowedField(
              controller: _yearsCtrl,
              hint: 'Enter Years Fishing/Farming',
              keyboardType: TextInputType.number,
            ),
          ),

          SizedBox(height: fieldGap),

          // ══════════════════════════════════════════════════════════
          // 3. LAND TENURESHIP (radio buttons + conditional)
          // ══════════════════════════════════════════════════════════
          _label('Land Tenureship', labelSize),
          SizedBox(height: labelFieldGap),
          // Radio options
          _radioOption('Owned', labelSize - 2),
          _radioOption('Co-Owned', labelSize - 2),
          _radioOption('Rent/Lease', labelSize - 2),
          _radioOption('Other', labelSize - 2),

          // Conditional "if others, please specify:"
          if (_selectedTenure == 'Other') ...[
            const SizedBox(height: 6),
            Text(
              'if others, please specify:',
              style: GoogleFonts.poppins(
                fontSize: labelSize - 3,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: fieldHeight,
              child: _shadowedField(
                controller: _tenureOtherCtrl,
                hint: 'Enter Other Commodity',
              ),
            ),
          ],

          SizedBox(height: fieldGap),

          // ══════════════════════════════════════════════════════════
          // 4. YEAR COVERED (Dynamic Dropdown)
          // ══════════════════════════════════════════════════════════
          _label('Year Covered', labelSize),
          SizedBox(height: labelFieldGap),
          SizedBox(
            height: fieldHeight,
            child: _buildYearDropdown(),
          ),

          SizedBox(height: fieldGap),

          // ══════════════════════════════════════════════════════════
          // 5. RECEIVED COMMODITY (dropdown)
          // ══════════════════════════════════════════════════════════
          _label('Received Commodity', labelSize),
          SizedBox(height: labelFieldGap),
          SizedBox(
            height: fieldHeight,
            child: _shadowedDropdown(
              value: _recSelected,
              hint: 'Enter Primary Commodity',
              items: ['Rice', 'Corn', 'HVC', 'Livestock', 'Poultry', 'Fisheries', 'Others'],
              onChanged: (val) => setState(() { _recSelected = val; _autoSaveToCurrentData(); }),
            ),
          ),

          // Conditional text for "Others"
          if (_recSelected == 'Others') ...[
            const SizedBox(height: 6),
            Text(
              'if others, please specify:',
              style: GoogleFonts.poppins(
                fontSize: labelSize - 3,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: fieldHeight,
              child: _shadowedField(
                controller: _recOtherCtrl,
                hint: 'Enter Other Commodity',
              ),
            ),
          ],

          SizedBox(height: fieldGap),

          // ══════════════════════════════════════════════════════════
          // 6. SECONDARY COMMODITY (dropdown)
          // ══════════════════════════════════════════════════════════
          _label('Secondary Commodity', labelSize),
          SizedBox(height: labelFieldGap),
          SizedBox(
            height: fieldHeight,
            child: _shadowedDropdown(
              value: _secSelected,
              hint: 'Enter Secondary Commodity',
              items: ['Rice', 'Corn', 'HVC', 'Livestock', 'Poultry', 'Fisheries', 'Others'],
              onChanged: (val) => setState(() { _secSelected = val; _autoSaveToCurrentData(); }),
            ),
          ),

          // Conditional text for "Others"
          if (_secSelected == 'Others') ...[
            const SizedBox(height: 6),
            Text(
              'if others, please specify:',
              style: GoogleFonts.poppins(
                fontSize: labelSize - 3,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: fieldHeight,
              child: _shadowedField(
                controller: _secOtherCtrl,
                hint: 'Enter Other Commodity',
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _label(String text, double size) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: DAColors.black,
      ),
    );
  }

  Widget _shadowedField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: CustomTextField(
        controller: controller,
        hintText: hint,
        keyboardType: keyboardType,
      ),
    );
  }

  // ── Radio button option ──
  Widget _radioOption(String label, double fontSize) {
    final bool isSelected = _selectedTenure == label;
    return GestureDetector(
      onTap: () => setState(() { _selectedTenure = label; _autoSaveToCurrentData(); }),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? DAColors.primaryGreen : Colors.grey.shade400,
                  width: 2,
                ),
                color: Colors.white,
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: DAColors.primaryGreen,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dropdown with shadow (matching step_04 style) ──
  Widget _shadowedDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: DAColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            color: Colors.grey.shade400,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: DAColors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: DAColors.primaryGreen, width: 2),
          ),
        ),
        style: GoogleFonts.poppins(
          color: DAColors.black,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        dropdownColor: DAColors.white,
        icon: Icon(
          Icons.arrow_drop_down,
          color: DAColors.black,
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  List<String> _getAvailableYears() {
    final currentYear = DateTime.now().year;
    return List.generate(4, (index) => (currentYear + index).toString());
  }

  Widget _buildYearDropdown() {
    final years = _getAvailableYears();

    return Container(
      decoration: BoxDecoration(
        color: DAColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: DropdownButtonFormField(
        initialValue: _selectedYear,
        decoration: InputDecoration(
          hintText: 'Select Year',
          hintStyle: GoogleFonts.poppins(
            color: Colors.grey.shade400,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: DAColors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: DAColors.primaryGreen, width: 2),
          ),
        ),
        style: GoogleFonts.poppins(
          color: DAColors.black,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        dropdownColor: DAColors.white,
        icon: Icon(Icons.arrow_drop_down, color: DAColors.black),
        items: years.map((String year) => DropdownMenuItem<String>(value: year, child: Text(year))).toList(),
        onChanged: (String? value) => setState(() { _selectedYear = value; _autoSaveToCurrentData(); }),
      ),
    );
  }
}
