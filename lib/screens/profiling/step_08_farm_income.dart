import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/theme/da_colors.dart';
import 'package:da_project_1/screens/profiling/profiling_step_wrapper.dart';
import 'package:da_project_1/models/profiling_data.dart';
import 'package:da_project_1/services/profiling_storage_service.dart';

/// Step 8 of 10 — Farm/Fisheries Income
///
/// Simplified to 3 beneficiary income fields:
///   1. Beneficiary (Farmer) Income
///   2. Spouse Income
///   3. Other Household Members Income
class Step08FarmIncome extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback? onHeaderBack;
  final ProfilingData? currentData;

  const Step08FarmIncome({
    super.key,
    required this.onNext,
    this.onBack,
    this.onHeaderBack,
    this.currentData,
  });

  @override
  State<Step08FarmIncome> createState() => _Step08FarmIncomeState();
}

class _Step08FarmIncomeState extends State<Step08FarmIncome> {
  final ProfilingStorageService _storage = ProfilingStorageService();
  // Simplified Non-Farm/Fisheries income: 3 beneficiary rows
  // each row has a multiline income field plus remarks
  final TextEditingController _beneficiaryIncomeCtrl = TextEditingController();
  final TextEditingController _beneficiaryRemarksCtrl = TextEditingController();
  final TextEditingController _spouseIncomeCtrl = TextEditingController();
  final TextEditingController _spouseRemarksCtrl = TextEditingController();
  final TextEditingController _otherMembersIncomeCtrl = TextEditingController();
  final TextEditingController _otherMembersRemarksCtrl =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _beneficiaryIncomeCtrl.addListener(_autoSaveToCurrentData);
    _beneficiaryRemarksCtrl.addListener(_autoSaveToCurrentData);
    _spouseIncomeCtrl.addListener(_autoSaveToCurrentData);
    _spouseRemarksCtrl.addListener(_autoSaveToCurrentData);
    _otherMembersIncomeCtrl.addListener(_autoSaveToCurrentData);
    _otherMembersRemarksCtrl.addListener(_autoSaveToCurrentData);
    _loadData();
  }

  @override
  void didUpdateWidget(Step08FarmIncome oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep local in-memory state authoritative while this step widget is alive.
    // Avoid reloads on parent rebuilds to prevent accidental field resets.
  }

  void _loadData() {
    if (widget.currentData != null) {
      _beneficiaryIncomeCtrl.text =
          widget.currentData!.beneficiaryNonFarmIncome ?? '';
      _beneficiaryRemarksCtrl.text =
          widget.currentData!.beneficiaryRemarks ?? '';
      _spouseIncomeCtrl.text = widget.currentData!.spouseNonFarmIncome ?? '';
      _spouseRemarksCtrl.text = widget.currentData!.spouseRemarks ?? '';
      _otherMembersIncomeCtrl.text =
          widget.currentData!.otherMembersNonFarmIncome ?? '';
      _otherMembersRemarksCtrl.text =
          widget.currentData!.otherMembersRemarks ?? '';
    }
  }

  void _autoSaveToCurrentData() {
    if (widget.currentData != null) {
      final data = widget.currentData!;
      data.beneficiaryNonFarmIncome = _beneficiaryIncomeCtrl.text.trim();
      data.spouseNonFarmIncome = _spouseIncomeCtrl.text.trim();
      data.otherMembersNonFarmIncome = _otherMembersIncomeCtrl.text.trim();
      data.spouseRemarks = _spouseRemarksCtrl.text.trim();
      data.beneficiaryRemarks = _beneficiaryRemarksCtrl.text.trim();
      data.otherMembersRemarks = _otherMembersRemarksCtrl.text.trim();

      final selectedYear = data.yearCovered?.toString().trim();
      if (selectedYear != null && selectedYear.isNotEmpty) {
        final all = Map<String, dynamic>.from(data.recurrenceByYear ?? {});
        final existingYearRaw = all[selectedYear];
        final existingYear = existingYearRaw is Map
            ? Map<String, dynamic>.from(existingYearRaw)
            : <String, dynamic>{};

        all[selectedYear] = {
          ...existingYear,
          'beneficiaryNonFarmIncome': data.beneficiaryNonFarmIncome,
          'beneficiaryRemarks': data.beneficiaryRemarks,
          'spouseNonFarmIncome': data.spouseNonFarmIncome,
          'spouseRemarks': data.spouseRemarks,
          'otherMembersNonFarmIncome': data.otherMembersNonFarmIncome,
          'otherMembersRemarks': data.otherMembersRemarks,
        };
        data.recurrenceByYear = all;
      }
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
    _beneficiaryIncomeCtrl.dispose();
    _beneficiaryRemarksCtrl.dispose();
    _spouseIncomeCtrl.dispose();
    _spouseRemarksCtrl.dispose();
    _otherMembersIncomeCtrl.dispose();
    _otherMembersRemarksCtrl.dispose();
    super.dispose();
  }

  void _handleNext() {
    _autoSaveToCurrentData();
    FocusScope.of(context).unfocus();
    widget.onNext();
  }

  void _handleBack() {
    _autoSaveToCurrentData();
    FocusScope.of(context).unfocus();
    widget.onBack?.call();
  }

  void _handleHeaderBack() {
    _autoSaveToCurrentData();
    FocusScope.of(context).unfocus();
    if (widget.onHeaderBack != null) {
      widget.onHeaderBack!.call();
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
        ? 18.0
        : isTablet
        ? 16.0
        : 14.0;
    final double labelFieldGap = isLargeTablet ? 8.0 : 6.0;

    return ProfilingStepWrapper(
      currentStep: 9,
      sectionTitle: 'FARM/FISHERIES INCOME',
      onNext: _handleNext,
      onBack: _handleBack,
      onHeaderBack: _handleHeaderBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Beneficiary (Farmer) Income Breakdown', labelSize),
          SizedBox(height: labelFieldGap),
          _remarksField(_beneficiaryIncomeCtrl, hint: 'Enter income breakdown'),
          SizedBox(height: labelFieldGap),
          _label('Beneficiary Remarks', labelSize * 0.85),
          SizedBox(height: labelFieldGap),
          _remarksField(_beneficiaryRemarksCtrl, hint: 'Remarks'),
          SizedBox(height: fieldGap),

          _label('Spouse Income Breakdown', labelSize),
          SizedBox(height: labelFieldGap),
          _remarksField(_spouseIncomeCtrl, hint: 'Enter income breakdown'),
          SizedBox(height: labelFieldGap),
          _label('Spouse Remarks', labelSize * 0.85),
          SizedBox(height: labelFieldGap),
          _remarksField(_spouseRemarksCtrl, hint: 'Remarks'),
          SizedBox(height: fieldGap),

          _label('Other Household Members Income Breakdown', labelSize),
          SizedBox(height: labelFieldGap),
          _remarksField(
            _otherMembersIncomeCtrl,
            hint: 'Enter income breakdown',
          ),
          SizedBox(height: labelFieldGap),
          _label('Other Members Remarks', labelSize * 0.85),
          SizedBox(height: labelFieldGap),
          _remarksField(_otherMembersRemarksCtrl, hint: 'Remarks'),
          SizedBox(height: fieldGap),
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

  Widget _remarksField(TextEditingController controller, {String? hint}) {
    return Container(
      decoration: BoxDecoration(
        color: DAColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.multiline,
        minLines: 3,
        maxLines: null,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
