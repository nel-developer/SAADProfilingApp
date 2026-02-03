import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/theme/da_colors.dart';
import 'package:da_project_1/widgets/custom_textfield.dart';
import 'package:da_project_1/screens/profiling/profiling_step_wrapper.dart';

/// Step 1 of 8 — Personal Information
/// Fields: First Name, Middle Name, Surname, Extension Name
class Step01PersonalInfo extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onHeaderBack;

  const Step01PersonalInfo({
    super.key,
    required this.onNext,
    this.onHeaderBack,
  });

  @override
  State<Step01PersonalInfo> createState() => _Step01PersonalInfoState();
}

class _Step01PersonalInfoState extends State<Step01PersonalInfo> {
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _middleNameCtrl = TextEditingController();
  final TextEditingController _surnameCtrl = TextEditingController();
  final TextEditingController _extensionCtrl = TextEditingController();

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _surnameCtrl.dispose();
    _extensionCtrl.dispose();
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
    // Phone = compact, tablet+ = a bit taller
    final double fieldHeight = isLargeTablet ? 54.0 : isTablet ? 50.0 : 44.0;

    return ProfilingStepWrapper(
      currentStep: 1,
      sectionTitle: 'Personal Information',
      onNext: widget.onNext,
      onBack: null,
      onHeaderBack: widget.onHeaderBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('First Name', labelSize),
          SizedBox(height: labelFieldGap),
          SizedBox(
            height: fieldHeight,
            child: _shadowedField(controller: _firstNameCtrl, hint: 'Enter First Name'),
          ),

          SizedBox(height: fieldGap),

          _label('Middle Name', labelSize),
          SizedBox(height: labelFieldGap),
          SizedBox(
            height: fieldHeight,
            child: _shadowedField(controller: _middleNameCtrl, hint: 'Enter Middle Name'),
          ),

          SizedBox(height: fieldGap),

          _label('Surname', labelSize),
          SizedBox(height: labelFieldGap),
          SizedBox(
            height: fieldHeight,
            child: _shadowedField(controller: _surnameCtrl, hint: 'Enter Surname'),
          ),

          SizedBox(height: fieldGap),

          _label('Extension Name', labelSize),
          SizedBox(height: labelFieldGap),
          SizedBox(
            height: fieldHeight,
            child: _shadowedField(controller: _extensionCtrl, hint: 'Enter Extension Name'),
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
  // CustomTextField already has a white bg + rounded corners so we just
  // overlay the shadow via the outer Container's decoration.
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
}