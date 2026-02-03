import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/theme/da_colors.dart';
import 'package:da_project_1/widgets/custom_textfield.dart';
import 'package:da_project_1/screens/profiling/profiling_step_wrapper.dart';

/// Step 3 of 8 — Other Personal Information
/// Fields: Indigenous Group (Yes/No + Dropdown), PWD (Yes/No), Spouse Name
class Step03OtherPersonal extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback? onHeaderBack;

  const Step03OtherPersonal({
    super.key,
    required this.onNext,
    required this.onBack,
    this.onHeaderBack,
  });

  @override
  State<Step03OtherPersonal> createState() => _Step03OtherPersonalState();
}

class _Step03OtherPersonalState extends State<Step03OtherPersonal> {
  bool? _isIndigenous; // null = not selected, true = Yes, false = No
  bool? _isPWD; // null = not selected, true = Yes, false = No
  String? _selectedIndigenousGroup;
  final TextEditingController _spouseNameCtrl = TextEditingController();

  final List<String> _indigenousGroups = [
    'Aeta',
    'Igorot',
    'Lumad',
    'Mangyan',
    'Moro',
    'Tagalog',
    'Other',
  ];

  @override
  void dispose() {
    _spouseNameCtrl.dispose();
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
    final double radioSize = isLargeTablet ? 28.0 : isTablet ? 26.0 : 24.0; // ← Bigger!
    final double radioTextSize = isLargeTablet ? 17.0 : isTablet ? 16.0 : 15.0; // ← Bigger!

    return ProfilingStepWrapper(
      currentStep: 3,
      sectionTitle: 'Other Personal Information',
      onNext: widget.onNext,
      onBack: widget.onBack,
      onHeaderBack: widget.onHeaderBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─────────────────────────────────────────────────────────
          // MEMBER OF AN INDIGENOUS GROUP
          // ─────────────────────────────────────────────────────────
          _label('Member of an Indigenous Group:', labelSize),
          SizedBox(height: labelFieldGap),

          // Yes/No Radio Buttons
          Row(
            children: [
              _radioOption(
                label: 'Yes',
                value: true,
                groupValue: _isIndigenous,
                onChanged: (value) {
                  setState(() {
                    _isIndigenous = value;
                  });
                },
                radioSize: radioSize,
                textSize: radioTextSize,
              ),
              SizedBox(width: width * 0.06), // ← More spacing
              _radioOption(
                label: 'No',
                value: false,
                groupValue: _isIndigenous,
                onChanged: (value) {
                  setState(() {
                    _isIndigenous = value;
                    if (value == false) {
                      _selectedIndigenousGroup = null; // Clear selection
                    }
                  });
                },
                radioSize: radioSize,
                textSize: radioTextSize,
              ),
            ],
          ),

          // Conditional dropdown if "Yes" is selected
          if (_isIndigenous == true) ...[
            SizedBox(height: labelFieldGap + 4),
            Text(
              'if yes, please specify:',
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
              child: _shadowedDropdown(
                value: _selectedIndigenousGroup,
                hint: 'Member of Indigenous Group',
                items: _indigenousGroups,
                onChanged: (value) {
                  setState(() {
                    _selectedIndigenousGroup = value;
                  });
                },
              ),
            ),
          ],

          SizedBox(height: fieldGap),

          // ─────────────────────────────────────────────────────────
          // PERSON WITH DISABILITY (PWD)
          // ─────────────────────────────────────────────────────────
          _label('Person with Disability (PWD)', labelSize),
          SizedBox(height: labelFieldGap),

          // Yes/No Radio Buttons
          Row(
            children: [
              _radioOption(
                label: 'Yes',
                value: true,
                groupValue: _isPWD,
                onChanged: (value) {
                  setState(() {
                    _isPWD = value;
                  });
                },
                radioSize: radioSize,
                textSize: radioTextSize,
              ),
              SizedBox(width: width * 0.06), // ← More spacing
              _radioOption(
                label: 'No',
                value: false,
                groupValue: _isPWD,
                onChanged: (value) {
                  setState(() {
                    _isPWD = value;
                  });
                },
                radioSize: radioSize,
                textSize: radioTextSize,
              ),
            ],
          ),

          SizedBox(height: fieldGap),

          // ─────────────────────────────────────────────────────────
          // NAME OF THE SPOUSE
          // ─────────────────────────────────────────────────────────
          Row(
            children: [
              _label('Name of the Spouse ', labelSize),
              Text(
                '(if married)(LN, FN, MI)',
                style: GoogleFonts.poppins(
                  fontSize: labelSize - 2,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          SizedBox(height: labelFieldGap),
          SizedBox(
            height: fieldHeight,
            child: _shadowedField(
              controller: _spouseNameCtrl,
              hint: 'Enter Spouse Name',
            ),
          ),
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
  // Radio button option with green checkmark when selected
  // Enhanced with shadow, better spacing, and tap feedback
  // ---------------------------------------------------------------------------
  Widget _radioOption({
    required String label,
    required bool value,
    required bool? groupValue,
    required ValueChanged<bool?> onChanged,
    required double radioSize,
    required double textSize,
  }) {
    final isSelected = groupValue == value;

    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? DAColors.primaryGreen.withOpacity(0.08) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: radioSize,
              height: radioSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? DAColors.primaryGreen : Colors.white,
                border: Border.all(
                  color: isSelected ? DAColors.primaryGreen : Colors.grey.shade400,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected 
                        ? DAColors.primaryGreen.withOpacity(0.3)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: isSelected ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: Colors.white,
                      size: radioSize * 0.65,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: textSize,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? DAColors.primaryGreen : DAColors.black,
              ),
            ),
          ],
        ),
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