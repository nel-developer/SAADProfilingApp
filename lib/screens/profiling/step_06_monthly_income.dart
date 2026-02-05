import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/theme/da_colors.dart';
import 'package:da_project_1/widgets/custom_textfield.dart';
import 'package:da_project_1/screens/profiling/profiling_step_wrapper.dart';

/// Step 6 of 8 — Monthly Family Income
///
/// Fields:
///   • Derived from Agri-Related Activities Only (Gross)
///   • SAAD Net Income
///   • Derived from Non Agri-Related Activities Only (Gross)
///   • Main Sources of Income
class Step06MonthlyIncome extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback? onHeaderBack;

  const Step06MonthlyIncome({
    super.key,
    required this.onNext,
    this.onBack,
    this.onHeaderBack,
  });

  @override
  State<Step06MonthlyIncome> createState() => _Step06MonthlyIncomeState();
}

class _Step06MonthlyIncomeState extends State<Step06MonthlyIncome> {
  final TextEditingController _agriRelatedCtrl = TextEditingController();
  final TextEditingController _saadNetCtrl = TextEditingController();
  final TextEditingController _nonAgriRelatedCtrl = TextEditingController();
  final TextEditingController _mainSourcesCtrl = TextEditingController();

  @override
  void dispose() {
    _agriRelatedCtrl.dispose();
    _saadNetCtrl.dispose();
    _nonAgriRelatedCtrl.dispose();
    _mainSourcesCtrl.dispose();
    super.dispose();
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
      sectionTitle: 'Monthly Family Income',
      onNext: widget.onNext,
      onBack: widget.onBack,
      onHeaderBack: widget.onHeaderBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ══════════════════════════════════════════════════════════
          // 1. DERIVED FROM AGRI-RELATED ACTIVITIES ONLY (GROSS)
          // ══════════════════════════════════════════════════════════
          _label('Derived from Agri-Related Activities Only (Gross)', labelSize),
          SizedBox(height: labelFieldGap),
          SizedBox(
            height: fieldHeight,
            child: _shadowedField(
              controller: _agriRelatedCtrl,
              hint: 'Enter Amount',
              keyboardType: TextInputType.number,
            ),
          ),

          SizedBox(height: fieldGap),

          // ══════════════════════════════════════════════════════════
          // 2. SAAD NET INCOME
          // ══════════════════════════════════════════════════════════
          _label('SAAD Net Income', labelSize),
          SizedBox(height: labelFieldGap),
          SizedBox(
            height: fieldHeight,
            child: _shadowedField(
              controller: _saadNetCtrl,
              hint: 'Enter Amount',
              keyboardType: TextInputType.number,
            ),
          ),

          SizedBox(height: fieldGap),

          // ══════════════════════════════════════════════════════════
          // 3. DERIVED FROM NON AGRI-RELATED ACTIVITIES ONLY (GROSS)
          // ══════════════════════════════════════════════════════════
          _label('Derived from Non Agri-Related Activities Only (Gross)', labelSize),
          SizedBox(height: labelFieldGap),
          SizedBox(
            height: fieldHeight,
            child: _shadowedField(
              controller: _nonAgriRelatedCtrl,
              hint: 'Enter Amount',
              keyboardType: TextInputType.number,
            ),
          ),

          SizedBox(height: fieldGap),

          // ══════════════════════════════════════════════════════════
          // 4. MAIN SOURCES OF INCOME
          // ══════════════════════════════════════════════════════════
          _label('Main Sources of Income', labelSize),
          SizedBox(height: labelFieldGap),
          SizedBox(
            height: fieldHeight,
            child: _shadowedField(
              controller: _mainSourcesCtrl,
              hint: 'Enter Amount',
              keyboardType: TextInputType.number,
            ),
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
}