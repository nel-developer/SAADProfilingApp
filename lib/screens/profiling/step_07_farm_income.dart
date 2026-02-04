import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/theme/da_colors.dart';
import 'package:da_project_1/screens/profiling/profiling_step_wrapper.dart';

/// Step 7 of 8 — Farm/Fisheries Income
///
/// Sections:
///   1. Primary Commodity — expandable amount field + expandable remarks field
///   2. Secondary Commodity — expandable amount field + expandable remarks field
///
/// All fields are multiline and auto-expand as user types.
class Step07FarmIncome extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback? onHeaderBack;

  const Step07FarmIncome({
    super.key,
    required this.onNext,
    this.onBack,
    this.onHeaderBack,
  });

  @override
  State<Step07FarmIncome> createState() => _Step07FarmIncomeState();
}

class _Step07FarmIncomeState extends State<Step07FarmIncome> {
  final TextEditingController _primaryAmountCtrl = TextEditingController();
  final TextEditingController _primaryRemarksCtrl = TextEditingController();
  final TextEditingController _secondaryAmountCtrl = TextEditingController();
  final TextEditingController _secondaryRemarksCtrl = TextEditingController();

  @override
  void dispose() {
    _primaryAmountCtrl.dispose();
    _primaryRemarksCtrl.dispose();
    _secondaryAmountCtrl.dispose();
    _secondaryRemarksCtrl.dispose();
    super.dispose();
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
      currentStep: 7,
      sectionTitle: 'FARM/FISHERIES INCOME',
      onNext: widget.onNext,
      onBack: widget.onBack,
      onHeaderBack: widget.onHeaderBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ══════════════════════════════════════════════════════════
          // 1. PRIMARY COMMODITY SECTION
          // ══════════════════════════════════════════════════════════
          _label('Primary Commodity', labelSize),
          SizedBox(height: labelFieldGap),
          
          // Primary Amount (expandable)
          _expandableField(
            controller: _primaryAmountCtrl,
            hint: 'Enter Amount',
            minLines: 3,
            keyboardType: TextInputType.multiline,
          ),

          SizedBox(height: fieldGap),

          // Primary Remarks (expandable)
          _label('Remarks', labelSize),
          SizedBox(height: labelFieldGap),
          _expandableField(
            controller: _primaryRemarksCtrl,
            hint: 'Enter Remarks',
            minLines: 5,
            keyboardType: TextInputType.multiline,
          ),

          SizedBox(height: sectionGap),

          // ══════════════════════════════════════════════════════════
          // 2. SECONDARY COMMODITY SECTION
          // ══════════════════════════════════════════════════════════
          _label('Secondary Commodity', labelSize),
          SizedBox(height: labelFieldGap),
          
          // Secondary Amount (expandable)
          _expandableField(
            controller: _secondaryAmountCtrl,
            hint: 'Enter Amount',
            minLines: 3,
            keyboardType: TextInputType.multiline,
          ),

          SizedBox(height: fieldGap),

          // Secondary Remarks (expandable)
          _label('Remarks', labelSize),
          SizedBox(height: labelFieldGap),
          _expandableField(
            controller: _secondaryRemarksCtrl,
            hint: 'Enter Remarks',
            minLines: 5,
            keyboardType: TextInputType.multiline,
          ),
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