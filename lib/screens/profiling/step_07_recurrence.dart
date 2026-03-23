import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/theme/da_colors.dart';
import 'package:da_project_1/widgets/custom_textfield.dart';
import 'package:da_project_1/screens/profiling/profiling_step_wrapper.dart';
import 'package:da_project_1/models/profiling_data.dart';

/// Step 8 of 11 — Recurrence
///
/// Fields:
///   • No. of Family Members (Male + Female in 1 row)
///   • No. of Years Fishing/Farming
///   • Land Tenureship (radio: Owned, Co-Owned, Rent/Lease, Other + conditional text)
///   • Year Covered
class Step07Recurrence extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback? onHeaderBack;
  final ProfilingData? currentData;

  const Step07Recurrence({
    super.key,
    required this.onNext,
    this.onBack,
    this.onHeaderBack,
    this.currentData,
  });

  @override
  State<Step07Recurrence> createState() => _Step07RecurrenceState();
}

class _Step07RecurrenceState extends State<Step07Recurrence> {
  // ── Controllers ──
  final TextEditingController _maleCtrl = TextEditingController();
  final TextEditingController _femaleCtrl = TextEditingController();
  final TextEditingController _yearsCtrl = TextEditingController();
  String? _selectedYear; // Year dropdown (dynamic: current year to +3 years)
  bool _isLoadingYearData = false;

  // ── Land Tenureship ──
  String? _selectedTenure; // 'Owned', 'Co-Owned', 'Rent/Lease', 'Other'
  final TextEditingController _tenureOtherCtrl = TextEditingController();

  // ── Secondary Commodity (dropdown) ──
  // Secondary commodity removed from this step per UX change.

  @override
  void initState() {
    super.initState();
    _maleCtrl.addListener(_autoSaveToCurrentData);
    _femaleCtrl.addListener(_autoSaveToCurrentData);
    _yearsCtrl.addListener(_autoSaveToCurrentData);
    _tenureOtherCtrl.addListener(_autoSaveToCurrentData);
    // secondary commodity listeners removed
    _loadData();
  }

  @override
  void didUpdateWidget(Step07Recurrence oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep local in-memory state authoritative while this step widget is alive.
    // Avoid reloads on parent rebuilds to prevent accidental field resets.
  }

  int? _toNullableInt(String text) {
    final normalized = text.replaceAll(',', '').trim();
    if (normalized.isEmpty) return null;
    return int.tryParse(normalized);
  }

  String? _normalizeTenure(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return null;
    final lower = raw.toLowerCase();
    if (lower == 'owned') return 'Owned';
    if (lower == 'co-owned' || lower == 'co owned') return 'Co-Owned';
    if (lower == 'rent/lease' || lower == 'rent' || lower == 'lease') {
      return 'Rent/Lease';
    }
    if (lower == 'other' || lower == 'others') return 'Other';
    return raw;
  }

  void _loadData() {
    if (widget.currentData != null) {
      final preferredYear =
          widget.currentData!.yearCovered?.toString() ??
          DateTime.now().year.toString();
      final availableYears = _getAvailableYears();

      if (availableYears.contains(preferredYear)) {
        _selectedYear = preferredYear;
      } else if (availableYears.isNotEmpty) {
        _selectedYear = availableYears.first;
      } else {
        _selectedYear = null;
      }

      if (_selectedYear != null && _selectedYear!.trim().isNotEmpty) {
        _loadYearDataIntoFields(
          _selectedYear!,
          saveCurrentYearBeforeLoad: false,
        );
      }
    }
  }

  Map<String, dynamic> _getYearEntry(String year) {
    final source = widget.currentData?.recurrenceByYear;
    if (source == null) return <String, dynamic>{};
    final raw = source[year];
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return <String, dynamic>{};
  }

  Map<String, dynamic> _getLatestYearEntry(
    Map<String, dynamic> allYears,
    String excludeYear,
  ) {
    final keys = allYears.keys.where((key) => key != excludeYear).toList();
    if (keys.isEmpty) return <String, dynamic>{};

    keys.sort((a, b) {
      final ai = int.tryParse(a.trim()) ?? -1;
      final bi = int.tryParse(b.trim()) ?? -1;
      return bi.compareTo(ai);
    });

    for (final key in keys) {
      final raw = allYears[key];
      if (raw is Map && raw.isNotEmpty) {
        return Map<String, dynamic>.from(raw);
      }
    }

    return <String, dynamic>{};
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString().trim());
  }

  void _loadYearDataIntoFields(
    String year, {
    bool saveCurrentYearBeforeLoad = true,
  }) {
    if (widget.currentData == null) return;

    if (saveCurrentYearBeforeLoad) {
      _autoSaveToCurrentData();
    }

    _isLoadingYearData = true;
    final entry = _getYearEntry(year);

    if (entry.isNotEmpty) {
      _maleCtrl.text = _toInt(entry['maleFamilyMembers'])?.toString() ?? '';
      _femaleCtrl.text = _toInt(entry['femaleFamilyMembers'])?.toString() ?? '';
      _yearsCtrl.text = _toInt(entry['yearsInFarming'])?.toString() ?? '';
      _selectedTenure = _normalizeTenure(entry['landTenureship']?.toString());
      _tenureOtherCtrl.text = (entry['landTenureshipOthers'] ?? '').toString();
    } else {
      _maleCtrl.text = widget.currentData!.maleFamilyMembers?.toString() ?? '';
      _femaleCtrl.text =
          widget.currentData!.femaleFamilyMembers?.toString() ?? '';
      _yearsCtrl.text = widget.currentData!.yearsInFarming?.toString() ?? '';
      _selectedTenure = _normalizeTenure(widget.currentData!.landTenureship);
      _tenureOtherCtrl.text = widget.currentData!.landTenureshipOthers ?? '';
    }

    _isLoadingYearData = false;
  }

  void _autoSaveToCurrentData() {
    if (_isLoadingYearData || widget.currentData == null) return;

    final data = widget.currentData!;
    final year = _selectedYear?.trim();

    final male = _toNullableInt(_maleCtrl.text);
    final female = _toNullableInt(_femaleCtrl.text);
    final years = _toNullableInt(_yearsCtrl.text);
    final land = _selectedTenure;
    final landOther = _tenureOtherCtrl.text.trim();

    data.maleFamilyMembers = male;
    data.femaleFamilyMembers = female;
    data.yearsInFarming = years;
    data.landTenureship = land;
    data.landTenureshipOthers = landOther;
    data.yearCovered = _toNullableInt(_selectedYear ?? '');

    if (year != null && year.isNotEmpty) {
      final all = Map<String, dynamic>.from(data.recurrenceByYear ?? {});
      final existingYearRaw = all[year];
      final existingYear = existingYearRaw is Map
          ? Map<String, dynamic>.from(existingYearRaw)
          : <String, dynamic>{};
      final latestYear = _getLatestYearEntry(all, year);

      dynamic withFallback(dynamic currentValue, String key) {
        if (currentValue != null) return currentValue;
        final existingValue = existingYear[key];
        if (existingValue != null) return existingValue;
        return latestYear[key];
      }

      all[year] = {
        ...existingYear,
        'maleFamilyMembers': male,
        'femaleFamilyMembers': female,
        'yearsInFarming': years,
        'landTenureship': land,
        'landTenureshipOthers': landOther,
        'saadCommodityType': withFallback(
          data.saadCommodityType,
          'saadCommodityType',
        ),
        'saadCommodities': withFallback(
          data.saadCommodities,
          'saadCommodities',
        ),
        'nonSAADCommodityType': withFallback(
          data.nonSAADCommodityType,
          'nonSAADCommodityType',
        ),
        'nonSAADCommodities': withFallback(
          data.nonSAADCommodities,
          'nonSAADCommodities',
        ),
        'cooperativeName': withFallback(
          data.cooperativeName,
          'cooperativeName',
        ),
        'hasOrganization': withFallback(
          data.hasOrganization,
          'hasOrganization',
        ),
        'cooperativePosition': withFallback(
          data.cooperativePosition,
          'cooperativePosition',
        ),
        'dateOfMembership': withFallback(
          data.dateOfMembership,
          'dateOfMembership',
        ),
        'cooperativePositionOthers': withFallback(
          data.cooperativePositionOthers,
          'cooperativePositionOthers',
        ),
        'primaryCommodity': withFallback(
          data.primaryCommodity,
          'primaryCommodity',
        ),
        'secondaryCommodity': withFallback(
          data.secondaryCommodity,
          'secondaryCommodity',
        ),
        'receivedPrimaryCommodity':
            withFallback(
              data.receivedPrimaryCommodity ?? data.receivedCommodity,
              'receivedPrimaryCommodity',
            ) ??
            withFallback(data.receivedCommodity, 'receivedCommodity'),
        'receivedSecondaryCommodity': withFallback(
          data.receivedSecondaryCommodity,
          'receivedSecondaryCommodity',
        ),
      };
      data.recurrenceByYear = all;
    }
  }

  @override
  void deactivate() {
    _autoSaveToCurrentData();
    super.deactivate();
  }

  @override
  void dispose() {
    _autoSaveToCurrentData();
    _maleCtrl.dispose();
    _femaleCtrl.dispose();
    _yearsCtrl.dispose();
    _tenureOtherCtrl.dispose();
    // secondary commodity controller disposed elsewhere (removed)
    super.dispose();
  }

  void _handleNext() {
    _autoSaveToCurrentData();
    widget.onNext();
  }

  void _handleBack() {
    FocusScope.of(context).unfocus();
    _autoSaveToCurrentData();
    widget.onBack?.call();
  }

  void _handleHeaderBack() {
    FocusScope.of(context).unfocus();
    _autoSaveToCurrentData();
    if (widget.onHeaderBack != null) {
      widget.onHeaderBack!();
    } else {
      widget.onBack?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width > 600;
    final isLargeTablet = width > 900;

    final double labelSize = isLargeTablet
        ? 16.0
        : isTablet
        ? 15.0
        : 14.0;
    final double fieldGap = isLargeTablet
        ? 22.0
        : isTablet
        ? 18.0
        : 14.0;
    final double labelFieldGap = isLargeTablet ? 8.0 : 6.0;
    final double fieldHeight = isLargeTablet
        ? 54.0
        : isTablet
        ? 50.0
        : 44.0;

    return ProfilingStepWrapper(
      currentStep: 8,
      sectionTitle: 'Recurrence',
      onNext: _handleNext,
      onBack: _handleBack,
      onHeaderBack: _handleHeaderBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('No. of Family Members', labelSize),
          SizedBox(height: labelFieldGap),
          Row(
            children: [
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

          _label('Land Tenureship', labelSize),
          SizedBox(height: labelFieldGap),
          _radioOption('Owned', labelSize - 2),
          _radioOption('Co-Owned', labelSize - 2),
          _radioOption('Rent/Lease', labelSize - 2),
          _radioOption('Other', labelSize - 2),

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
                hint: 'Enter Other Tenureship',
              ),
            ),
          ],

          SizedBox(height: fieldGap),

          _label('Year Covered', labelSize),
          SizedBox(height: labelFieldGap),
          SizedBox(height: fieldHeight, child: _buildYearDropdown()),

          SizedBox(height: fieldGap),

          // Secondary commodity removed from this step per UX change.
        ],
      ),
    );
  }

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
        onChanged: (_) => _autoSaveToCurrentData(),
      ),
    );
  }

  Widget _radioOption(String label, double fontSize) {
    final bool isSelected = _selectedTenure == label;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedTenure = label;
        _autoSaveToCurrentData();
      }),
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
                  color: isSelected
                      ? DAColors.primaryGreen
                      : Colors.grey.shade400,
                  width: 2,
                ),
                color: Colors.white,
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
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

  List<String> _getAvailableYears() {
    final currentYear = DateTime.now().year;
    final years = List.generate(
      6,
      (index) => (currentYear - 3 + index).toString(),
    );
    if (_selectedYear != null && _selectedYear!.trim().isNotEmpty) {
      if (!years.contains(_selectedYear)) {
        years.add(_selectedYear!);
      }
    }
    years.sort();
    return years;
  }

  Widget _buildYearDropdown() {
    final years = _getAvailableYears();
    final selectedYearForDropdown = years.contains(_selectedYear)
        ? _selectedYear
        : null;

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
        initialValue: selectedYearForDropdown,
        decoration: InputDecoration(
          hintText: 'Select Year',
          hintStyle: GoogleFonts.poppins(
            color: Colors.grey.shade400,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: DAColors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
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
        items: years
            .map(
              (String year) =>
                  DropdownMenuItem<String>(value: year, child: Text(year)),
            )
            .toList(),
        onChanged: (String? value) => setState(() {
          if (value != null && value.trim().isNotEmpty) {
            _loadYearDataIntoFields(value);
          }
          _selectedYear = value;
          _autoSaveToCurrentData();
        }),
      ),
    );
  }
}
