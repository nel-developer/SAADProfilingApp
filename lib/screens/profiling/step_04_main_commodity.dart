import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/theme/da_colors.dart';
import 'package:da_project_1/widgets/custom_textfield.dart';
import 'package:da_project_1/screens/profiling/profiling_step_wrapper.dart';

/// Step 4 of 8 — Main Commodity
/// Fields: Primary Commodity (dropdown), Secondary Commodity (dropdown)
/// Both have "Others" option with conditional text field
class Step04MainCommodity extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback? onHeaderBack;

  const Step04MainCommodity({
    super.key,
    required this.onNext,
    required this.onBack,
    this.onHeaderBack,
  });

  @override
  State<Step04MainCommodity> createState() => _Step04MainCommodityState();
}

class _Step04MainCommodityState extends State<Step04MainCommodity> {
  String? _primaryCommodity;
  String? _secondaryCommodity;
  final TextEditingController _primaryOthersCtrl = TextEditingController();
  final TextEditingController _secondaryOthersCtrl = TextEditingController();

  final List<String> _commodityOptions = [
    'Rice',
    'Corn',
    'HVC',
    'Livestock',
    'Poultry',
    'Fisheries',
    'Others',
  ];

  @override
  void dispose() {
    _primaryOthersCtrl.dispose();
    _secondaryOthersCtrl.dispose();
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
      currentStep: 4,
      sectionTitle: 'Main Commodity',
      onNext: widget.onNext,
      onBack: widget.onBack,
      onHeaderBack: widget.onHeaderBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─────────────────────────────────────────────────────────
          // PRIMARY COMMODITY
          // ─────────────────────────────────────────────────────────
          _label('Primary', labelSize),
          SizedBox(height: labelFieldGap),
          SizedBox(
            height: fieldHeight,
            child: _shadowedDropdown(
              value: _primaryCommodity,
              hint: 'Enter Primary Commodity',
              items: _commodityOptions,
              onChanged: (value) {
                setState(() {
                  _primaryCommodity = value;
                  if (value != 'Others') {
                    _primaryOthersCtrl.clear();
                  }
                });
              },
            ),
          ),

          // Conditional "Others" text field for Primary
          if (_primaryCommodity == 'Others') ...[
            SizedBox(height: labelFieldGap + 4),
            Text(
              'if others, please specify:',
              style: GoogleFonts.poppins(
                fontSize: labelSize - 2,
                fontWeight: FontWeight.w400,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: labelFieldGap),
            SizedBox(
              height: fieldHeight,
              child: _shadowedField(
                controller: _primaryOthersCtrl,
                hint: 'Enter Other Commodity',
              ),
            ),
          ],

          SizedBox(height: fieldGap),

          // ─────────────────────────────────────────────────────────
          // SECONDARY COMMODITY
          // ─────────────────────────────────────────────────────────
          _label('Secondary Commodity', labelSize),
          SizedBox(height: labelFieldGap),
          SizedBox(
            height: fieldHeight,
            child: _shadowedDropdown(
              value: _secondaryCommodity,
              hint: 'Enter Secondary Commodity',
              items: _commodityOptions,
              onChanged: (value) {
                setState(() {
                  _secondaryCommodity = value;
                  if (value != 'Others') {
                    _secondaryOthersCtrl.clear();
                  }
                });
              },
            ),
          ),

          // Conditional "Others" text field for Secondary
          if (_secondaryCommodity == 'Others') ...[
            SizedBox(height: labelFieldGap + 4),
            Text(
              'if others, please specify:',
              style: GoogleFonts.poppins(
                fontSize: labelSize - 2,
                fontWeight: FontWeight.w400,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: labelFieldGap),
            SizedBox(
              height: fieldHeight,
              child: _shadowedField(
                controller: _secondaryOthersCtrl,
                hint: 'Enter Other Commodity',
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bold label
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // TextField with shadow
  // ---------------------------------------------------------------------------
  Widget _shadowedField({
    required TextEditingController controller,
    required String hint,
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
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dropdown with shadow
  // ---------------------------------------------------------------------------
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
        value: value,
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
}