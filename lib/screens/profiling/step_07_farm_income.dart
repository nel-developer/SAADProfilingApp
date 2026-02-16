import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/theme/da_colors.dart';
import 'package:da_project_1/screens/profiling/profiling_step_wrapper.dart';
import 'package:da_project_1/models/profiling_data.dart';

/// Step 5 of 8 — Farm/Fisheries Income
///
/// Sections:
///   1. Rice/Corn — expandable income field + expandable remarks field
///   2. HVC — expandable income field + expandable remarks field
///   3. Livestock — expandable income field + expandable remarks field
///   4. Fishing — expandable income field + expandable remarks field
///   5. Non-Farm Fisheries — expandable income field + expandable remarks field
///
/// All fields are multiline and auto-expand as user types.
class Step07FarmIncome extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback? onHeaderBack;
  final ProfilingData? currentData;

  const Step07FarmIncome({
    super.key,
    required this.onNext,
    this.onBack,
    this.onHeaderBack,
    this.currentData,
  });

  @override
  State<Step07FarmIncome> createState() => _Step07FarmIncomeState();
}

class _Step07FarmIncomeState extends State<Step07FarmIncome> {
  // Controllers for Rice/Corn
  final TextEditingController _riceIncomeCtrl = TextEditingController();
  final TextEditingController _riceRemarksCtrl = TextEditingController();
  
  // Controllers for HVC
  final TextEditingController _hvcIncomeCtrl = TextEditingController();
  final TextEditingController _hvcRemarksCtrl = TextEditingController();
  
  // Controllers for Livestock
  final TextEditingController _livestockIncomeCtrl = TextEditingController();
  final TextEditingController _livestockRemarksCtrl = TextEditingController();
  
  // Controllers for Fishing
  final TextEditingController _fishingIncomeCtrl = TextEditingController();
  final TextEditingController _fishingRemarksCtrl = TextEditingController();
  
  // Controllers for Non-Farm Fisheries
  final TextEditingController _nonFarmFisheriesIncomeCtrl = TextEditingController();
  final TextEditingController _nonFarmFisheriesRemarksCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Add listeners only once in initState to prevent duplicates
    _riceIncomeCtrl.addListener(_autoSaveToCurrentData);
    _riceRemarksCtrl.addListener(_autoSaveToCurrentData);
    _hvcIncomeCtrl.addListener(_autoSaveToCurrentData);
    _hvcRemarksCtrl.addListener(_autoSaveToCurrentData);
    _livestockIncomeCtrl.addListener(_autoSaveToCurrentData);
    _livestockRemarksCtrl.addListener(_autoSaveToCurrentData);
    _fishingIncomeCtrl.addListener(_autoSaveToCurrentData);
    _fishingRemarksCtrl.addListener(_autoSaveToCurrentData);
    _nonFarmFisheriesIncomeCtrl.addListener(_autoSaveToCurrentData);
    _nonFarmFisheriesRemarksCtrl.addListener(_autoSaveToCurrentData);
    _loadData();
  }

  @override
  void didUpdateWidget(Step07FarmIncome oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload data when returning to this step via back button
    _loadData();
  }

  void _loadData() {
    if (widget.currentData != null) {
      _riceIncomeCtrl.text = widget.currentData!.riceIncomeField ?? '';
      _riceRemarksCtrl.text = widget.currentData!.riceRemarks ?? '';
      
      _hvcIncomeCtrl.text = widget.currentData!.hvcIncomeField ?? '';
      _hvcRemarksCtrl.text = widget.currentData!.hvcRemarks ?? '';
      
      _livestockIncomeCtrl.text = widget.currentData!.livestockIncomeField ?? '';
      _livestockRemarksCtrl.text = widget.currentData!.livestockRemarks ?? '';
      
      _fishingIncomeCtrl.text = widget.currentData!.fishingIncomeField ?? '';
      _fishingRemarksCtrl.text = widget.currentData!.fishingRemarks ?? '';
      
      _nonFarmFisheriesIncomeCtrl.text = widget.currentData!.nonFarmFisheriesIncomeField ?? '';
      _nonFarmFisheriesRemarksCtrl.text = widget.currentData!.nonFarmFisheriesRemarks ?? '';
    }
  }

  void _autoSaveToCurrentData() {
    if (widget.currentData != null) {
      widget.currentData!.riceIncomeField = _riceIncomeCtrl.text.trim();
      widget.currentData!.riceRemarks = _riceRemarksCtrl.text.trim();
      
      widget.currentData!.hvcIncomeField = _hvcIncomeCtrl.text.trim();
      widget.currentData!.hvcRemarks = _hvcRemarksCtrl.text.trim();
      
      widget.currentData!.livestockIncomeField = _livestockIncomeCtrl.text.trim();
      widget.currentData!.livestockRemarks = _livestockRemarksCtrl.text.trim();
      
      widget.currentData!.fishingIncomeField = _fishingIncomeCtrl.text.trim();
      widget.currentData!.fishingRemarks = _fishingRemarksCtrl.text.trim();
      
      widget.currentData!.nonFarmFisheriesIncomeField = _nonFarmFisheriesIncomeCtrl.text.trim();
      widget.currentData!.nonFarmFisheriesRemarks = _nonFarmFisheriesRemarksCtrl.text.trim();
    }
  }

  @override
  void dispose() {
    _riceIncomeCtrl.dispose();
    _riceRemarksCtrl.dispose();
    _hvcIncomeCtrl.dispose();
    _hvcRemarksCtrl.dispose();
    _livestockIncomeCtrl.dispose();
    _livestockRemarksCtrl.dispose();
    _fishingIncomeCtrl.dispose();
    _fishingRemarksCtrl.dispose();
    _nonFarmFisheriesIncomeCtrl.dispose();
    _nonFarmFisheriesRemarksCtrl.dispose();
    super.dispose();
  }

  void _handleNext() {
    // Save without per-step validation (final validation happens on submit)
    if (widget.currentData != null) {
      widget.currentData!.riceIncomeField = _riceIncomeCtrl.text.trim();
      widget.currentData!.riceRemarks = _riceRemarksCtrl.text.trim();
      
      widget.currentData!.hvcIncomeField = _hvcIncomeCtrl.text.trim();
      widget.currentData!.hvcRemarks = _hvcRemarksCtrl.text.trim();
      
      widget.currentData!.livestockIncomeField = _livestockIncomeCtrl.text.trim();
      widget.currentData!.livestockRemarks = _livestockRemarksCtrl.text.trim();
      
      widget.currentData!.fishingIncomeField = _fishingIncomeCtrl.text.trim();
      widget.currentData!.fishingRemarks = _fishingRemarksCtrl.text.trim();
      
      widget.currentData!.nonFarmFisheriesIncomeField = _nonFarmFisheriesIncomeCtrl.text.trim();
      widget.currentData!.nonFarmFisheriesRemarks = _nonFarmFisheriesRemarksCtrl.text.trim();
    }
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width > 600;
    final isLargeTablet = width > 900;

    final double labelSize = isLargeTablet ? 16.0 : isTablet ? 15.0 : 14.0;
    final double sectionGap = isLargeTablet ? 32.0 : isTablet ? 28.0 : 24.0;
    final double fieldGap = isLargeTablet ? 18.0 : isTablet ? 16.0 : 14.0;
    final double labelFieldGap = isLargeTablet ? 8.0 : 6.0;

    return ProfilingStepWrapper(
      currentStep: 5,
      sectionTitle: 'FARM/FISHERIES INCOME',
      onNext: _handleNext,
      onBack: widget.onBack,
      onHeaderBack: widget.onHeaderBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ══════════════════════════════════════════════════════════
          // 1. RICE/CORN SECTION
          // ══════════════════════════════════════════════════════════
          _buildCommoditySection(
            commodityName: 'Rice/Corn',
            incomeController: _riceIncomeCtrl,
            remarksController: _riceRemarksCtrl,
            labelSize: labelSize,
            labelFieldGap: labelFieldGap,
            fieldGap: fieldGap,
          ),

          SizedBox(height: sectionGap),

          // ══════════════════════════════════════════════════════════
          // 2. HVC SECTION
          // ══════════════════════════════════════════════════════════
          _buildCommoditySection(
            commodityName: 'HVC',
            incomeController: _hvcIncomeCtrl,
            remarksController: _hvcRemarksCtrl,
            labelSize: labelSize,
            labelFieldGap: labelFieldGap,
            fieldGap: fieldGap,
          ),

          SizedBox(height: sectionGap),

          // ══════════════════════════════════════════════════════════
          // 3. LIVESTOCK SECTION
          // ══════════════════════════════════════════════════════════
          _buildCommoditySection(
            commodityName: 'Livestock',
            incomeController: _livestockIncomeCtrl,
            remarksController: _livestockRemarksCtrl,
            labelSize: labelSize,
            labelFieldGap: labelFieldGap,
            fieldGap: fieldGap,
          ),

          SizedBox(height: sectionGap),

          // ══════════════════════════════════════════════════════════
          // 4. FISHING SECTION
          // ══════════════════════════════════════════════════════════
          _buildCommoditySection(
            commodityName: 'Fishing',
            incomeController: _fishingIncomeCtrl,
            remarksController: _fishingRemarksCtrl,
            labelSize: labelSize,
            labelFieldGap: labelFieldGap,
            fieldGap: fieldGap,
          ),

          SizedBox(height: sectionGap),

          // ══════════════════════════════════════════════════════════
          // 5. NON-FARM FISHERIES SECTION
          // ══════════════════════════════════════════════════════════
          _buildCommoditySection(
            commodityName: 'Non-Farm Fisheries',
            incomeController: _nonFarmFisheriesIncomeCtrl,
            remarksController: _nonFarmFisheriesRemarksCtrl,
            labelSize: labelSize,
            labelFieldGap: labelFieldGap,
            fieldGap: fieldGap,
          ),
        ],
      ),
    );
  }

  /// Build a complete commodity section with commodity name, income field, and remarks field
  Widget _buildCommoditySection({
    required String commodityName,
    required TextEditingController incomeController,
    required TextEditingController remarksController,
    required double labelSize,
    required double labelFieldGap,
    required double fieldGap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Commodity Name Label
        _label(commodityName, labelSize),
        SizedBox(height: labelFieldGap),

        // Income Field
        _label('Income Breakdown', labelSize * 0.85),
        SizedBox(height: labelFieldGap),
        _expandableField(
          controller: incomeController,
          hint: 'Enter Income Breakdown',
          minLines: 3,
          keyboardType: TextInputType.multiline,
        ),

        SizedBox(height: fieldGap),

        // Remarks Field
        _label('Remarks', labelSize * 0.85),
        SizedBox(height: labelFieldGap),
        _expandableField(
          controller: remarksController,
          hint: 'Enter Remarks',
          minLines: 5,
          keyboardType: TextInputType.multiline,
        ),
      ],
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

  /// Expandable multiline text field (auto-grows as user types)
  /// minLines = starting height, maxLines = null means unlimited expansion
  Widget _expandableField({
    required TextEditingController controller,
    required String hint,
    required int minLines,
    TextInputType? keyboardType,
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
      child: TextField(
        controller: controller,
        keyboardType: keyboardType ?? TextInputType.text,
        minLines: minLines, // Starting height (e.g. 3 or 5 lines)
        maxLines: null, // Unlimited — auto-expands as user types
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            color: Colors.grey.shade400,
            fontSize: 15,
          ),
          filled: true,
          fillColor: DAColors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
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
          fontSize: 15,
          color: DAColors.black,
        ),
      ),
    );
  }
}