import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/theme/da_colors.dart';
import 'package:da_project_1/widgets/custom_textfield.dart';
import 'package:da_project_1/screens/profiling/profiling_step_wrapper.dart';

/// Step 2 of 8 — Address Information
/// Fields: Region, Province, Municipality/City, Barangay, Sitio/Purok, Date of Birth, Sex
class Step02AddressInfo extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback? onHeaderBack;

  const Step02AddressInfo({
    super.key,
    required this.onNext,
    required this.onBack,
    this.onHeaderBack,
  });

  @override
  State<Step02AddressInfo> createState() => _Step02AddressInfoState();
}

class _Step02AddressInfoState extends State<Step02AddressInfo> {
  final TextEditingController _regionCtrl = TextEditingController();
  final TextEditingController _provinceCtrl = TextEditingController();
  final TextEditingController _municipalityCtrl = TextEditingController();
  final TextEditingController _barangayCtrl = TextEditingController();
  final TextEditingController _sitioPurokCtrl = TextEditingController();
  final TextEditingController _dateOfBirthCtrl = TextEditingController();
  
  String? _selectedSex;
  final List<String> _sexOptions = ['Male', 'Female'];

  @override
  void dispose() {
    _regionCtrl.dispose();
    _provinceCtrl.dispose();
    _municipalityCtrl.dispose();
    _barangayCtrl.dispose();
    _sitioPurokCtrl.dispose();
    _dateOfBirthCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: DAColors.primaryGreen,
              onPrimary: DAColors.white,
              onSurface: DAColors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: DAColors.primaryGreen,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _dateOfBirthCtrl.text = 
            '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
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
      currentStep: 2,
      sectionTitle: 'Address',
      onNext: widget.onNext,
      onBack: widget.onBack,
      onHeaderBack: widget.onHeaderBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─────────────────────────────────────────────────────────
          // REGION
          // ─────────────────────────────────────────────────────────
          _label('Region', labelSize),
          SizedBox(height: labelFieldGap),
          SizedBox(
            height: fieldHeight,
            child: _shadowedField(
              controller: _regionCtrl,
              hint: 'Enter Region',
            ),
          ),

          SizedBox(height: fieldGap),

          // ─────────────────────────────────────────────────────────
          // PROVINCE
          // ─────────────────────────────────────────────────────────
          _label('Province', labelSize),
          SizedBox(height: labelFieldGap),
          SizedBox(
            height: fieldHeight,
            child: _shadowedField(
              controller: _provinceCtrl,
              hint: 'Enter Province',
            ),
          ),

          SizedBox(height: fieldGap),

          // ─────────────────────────────────────────────────────────
          // MUNICIPALITY/CITY
          // ─────────────────────────────────────────────────────────
          _label('Municipality/City', labelSize),
          SizedBox(height: labelFieldGap),
          SizedBox(
            height: fieldHeight,
            child: _shadowedField(
              controller: _municipalityCtrl,
              hint: 'Enter Municipality/City',
            ),
          ),

          SizedBox(height: fieldGap),

          // ─────────────────────────────────────────────────────────
          // BARANGAY
          // ─────────────────────────────────────────────────────────
          _label('Barangay', labelSize),
          SizedBox(height: labelFieldGap),
          SizedBox(
            height: fieldHeight,
            child: _shadowedField(
              controller: _barangayCtrl,
              hint: 'Enter Barangay',
            ),
          ),

          SizedBox(height: fieldGap),

          // ─────────────────────────────────────────────────────────
          // SITIO/PUROK
          // ─────────────────────────────────────────────────────────
          _label('Sitio/Purok', labelSize),
          SizedBox(height: labelFieldGap),
          SizedBox(
            height: fieldHeight,
            child: _shadowedField(
              controller: _sitioPurokCtrl,
              hint: 'Enter Sitio/Purok',
            ),
          ),

          SizedBox(height: fieldGap),

          // ─────────────────────────────────────────────────────────
          // DATE OF BIRTH (with calendar icon)
          // ─────────────────────────────────────────────────────────
          _label('Date of Birth', labelSize),
          SizedBox(height: labelFieldGap),
          SizedBox(
            height: fieldHeight,
            child: _shadowedDateField(
              controller: _dateOfBirthCtrl,
              hint: 'Enter Date of Birth',
              onTap: () => _selectDate(context),
            ),
          ),

          SizedBox(height: fieldGap),

          // ─────────────────────────────────────────────────────────
          // SEX (dropdown)
          // ─────────────────────────────────────────────────────────
          _label('Sex', labelSize),
          SizedBox(height: labelFieldGap),
          SizedBox(
            height: fieldHeight,
            child: _shadowedDropdown(
              value: _selectedSex,
              hint: 'Enter Sex',
              items: _sexOptions,
              onChanged: (value) {
                setState(() {
                  _selectedSex = value;
                });
              },
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
  // TextField wrapped in a Container that gives it a deeper shadow.
  // Same exact shadow as Step 1 for consistency.
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
  // Date Field with calendar icon - tappable to open date picker
  // ---------------------------------------------------------------------------
  Widget _shadowedDateField({
    required TextEditingController controller,
    required String hint,
    required VoidCallback onTap,
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
      child: GestureDetector(
        onTap: onTap,
        child: AbsorbPointer(
          child: CustomTextField(
            controller: controller,
            hintText: hint,
            suffixIcon: Icons.calendar_today,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dropdown wrapped in shadow container
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
}