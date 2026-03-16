import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/theme/da_colors.dart';
import 'package:da_project_1/widgets/custom_textfield.dart';
import 'package:da_project_1/screens/profiling/profiling_step_wrapper.dart';
import 'package:da_project_1/models/profiling_data.dart';
import 'package:da_project_1/services/profiling_storage_service.dart';

/// Step 7 — Farmers/Fishers Cooperative
class Step07Cooperative extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback? onHeaderBack;
  final ProfilingData? currentData;

  const Step07Cooperative({
    super.key,
    required this.onNext,
    required this.onBack,
    this.onHeaderBack,
    this.currentData,
  });

  @override
  State<Step07Cooperative> createState() => _Step07CooperativeState();
}

class _Step07CooperativeState extends State<Step07Cooperative> {
  final ProfilingStorageService _storage = ProfilingStorageService();
  final TextEditingController _organizationCtrl = TextEditingController();
  final TextEditingController _membershipDateCtrl = TextEditingController();
  final TextEditingController _positionOtherCtrl = TextEditingController();
  bool _hasOrganization = false;
  String? _selectedPosition;
  static const List<String> _positionOptions = <String>[
    'President',
    'Vice President',
    'Member',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _organizationCtrl.addListener(() => _handleNameChange(_organizationCtrl));
    _membershipDateCtrl.addListener(_autoSaveToCurrentData);
    _positionOtherCtrl.addListener(() => _handleNameChange(_positionOtherCtrl));
    _loadData();
  }

  void _forceUppercase(TextEditingController controller) {
    final upper = controller.text.toUpperCase();
    if (controller.text == upper) return;
    controller.value = TextEditingValue(
      text: upper,
      selection: TextSelection.collapsed(offset: upper.length),
    );
  }

  void _handleNameChange(TextEditingController controller) {
    _forceUppercase(controller);
    _autoSaveToCurrentData();
  }

  @override
  void didUpdateWidget(covariant Step07Cooperative oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  void _loadData() {
    final data = widget.currentData;
    if (data == null) return;

    _organizationCtrl.text = data.cooperativeName ?? '';
    _membershipDateCtrl.text = data.dateOfMembership ?? '';
    _forceUppercase(_organizationCtrl);
    _hasOrganization = data.hasOrganization == true;

    // Legacy compatibility: treat existing cooperative details as "Yes".
    if (!_hasOrganization &&
        (_organizationCtrl.text.trim().isNotEmpty ||
            (data.cooperativePosition ?? '').trim().isNotEmpty ||
            _membershipDateCtrl.text.trim().isNotEmpty ||
            (data.cooperativePositionOthers ?? '').trim().isNotEmpty)) {
      _hasOrganization = true;
    }

    final rawPosition = (data.cooperativePosition ?? '').trim();
    final normalized = _normalizePosition(rawPosition);
    _selectedPosition = normalized;

    if (normalized == 'Other') {
      _positionOtherCtrl.text = (data.cooperativePositionOthers ?? '').trim();
      if (_positionOtherCtrl.text.isEmpty &&
          rawPosition.isNotEmpty &&
          !_positionOptions.any((option) => option == rawPosition)) {
        _positionOtherCtrl.text = rawPosition;
      }
    } else {
      _positionOtherCtrl.text = (data.cooperativePositionOthers ?? '').trim();
    }
    _forceUppercase(_positionOtherCtrl);
  }

  String? _normalizePosition(String? value) {
    final raw = (value ?? '').trim().toLowerCase();
    if (raw.isEmpty) return null;
    if (raw == 'president') return 'President';
    if (raw == 'vice president' || raw == 'vice-president') {
      return 'Vice President';
    }
    if (raw == 'member') return 'Member';
    if (raw == 'other') return 'Other';
    return 'Other';
  }

  void _autoSaveToCurrentData() {
    final data = widget.currentData;
    if (data == null) return;

    final organization = _hasOrganization
        ? _organizationCtrl.text.trim().toUpperCase()
        : '';
    final position = _hasOrganization ? (_selectedPosition?.trim() ?? '') : '';
    final membershipDate = _hasOrganization
        ? _membershipDateCtrl.text.trim()
        : '';
    final positionOther = (_hasOrganization && position == 'Other')
        ? _positionOtherCtrl.text.trim().toUpperCase()
        : '';

    data.hasOrganization = _hasOrganization;
    data.cooperativeName = organization;
    data.cooperativePosition = position;
    data.dateOfMembership = membershipDate;
    data.cooperativePositionOthers = positionOther;

    final selectedYear = data.yearCovered?.toString();
    if (selectedYear != null && selectedYear.isNotEmpty) {
      final all = Map<String, dynamic>.from(data.recurrenceByYear ?? {});
      final existingYearRaw = all[selectedYear];
      final existingYear = existingYearRaw is Map
          ? Map<String, dynamic>.from(existingYearRaw)
          : <String, dynamic>{};

      all[selectedYear] = {
        ...existingYear,
        'hasOrganization': _hasOrganization,
        'cooperativeName': organization,
        'cooperativePosition': position,
        'dateOfMembership': membershipDate,
        'cooperativePositionOthers': positionOther,
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
    _organizationCtrl.dispose();
    _membershipDateCtrl.dispose();
    _positionOtherCtrl.dispose();
    super.dispose();
  }

  void _handleNext() {
    _autoSaveToCurrentData();
    widget.onNext();
  }

  void _handleHeaderBack() {
    _autoSaveToCurrentData();
    if (widget.onHeaderBack != null) {
      widget.onHeaderBack!();
    } else {
      widget.onBack();
    }
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  DateTime? _parseDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return DateTime.tryParse(trimmed);
  }

  Future<void> _pickMembershipDate() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final initial = _parseDate(_membershipDateCtrl.text) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 1, 12, 31),
    );

    if (picked == null) return;

    setState(() {
      _membershipDateCtrl.text = _formatDate(picked);
      _autoSaveToCurrentData();
    });
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
      currentStep: 7,
      sectionTitle: 'Farmers/Fishers Cooperative',
      onNext: _handleNext,
      onBack: widget.onBack,
      onHeaderBack: _handleHeaderBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Do you have an organization?', labelSize),
          SizedBox(height: labelFieldGap),
          _yesNoOption(
            label: 'Yes',
            selected: _hasOrganization,
            fontSize: labelSize - 1,
            onTap: () {
              setState(() {
                _hasOrganization = true;
                _autoSaveToCurrentData();
              });
            },
          ),
          _yesNoOption(
            label: 'No',
            selected: !_hasOrganization,
            fontSize: labelSize - 1,
            onTap: () {
              setState(() {
                _hasOrganization = false;
                _organizationCtrl.clear();
                _membershipDateCtrl.clear();
                _positionOtherCtrl.clear();
                _selectedPosition = null;
                _autoSaveToCurrentData();
              });
            },
          ),

          if (_hasOrganization) ...[
            SizedBox(height: fieldGap),
            _label('Organization Name', labelSize),
            SizedBox(height: labelFieldGap),
            SizedBox(
              height: fieldHeight,
              child: _shadowedField(
                controller: _organizationCtrl,
                hint: 'Enter organization name',
              ),
            ),

            SizedBox(height: fieldGap),

            _label('Position', labelSize),
            SizedBox(height: labelFieldGap),
            Column(
              children: _positionOptions.map((option) {
                final isSelected = _selectedPosition == option;
                return _checkboxOption(
                  label: option,
                  selected: isSelected,
                  fontSize: labelSize - 1,
                  onTap: () {
                    setState(() {
                      _selectedPosition = option;
                      if (option != 'Other') {
                        _positionOtherCtrl.clear();
                      }
                      _autoSaveToCurrentData();
                    });
                  },
                );
              }).toList(),
            ),

            SizedBox(height: fieldGap),

            _label('Date of Membership', labelSize),
            SizedBox(height: labelFieldGap),
            SizedBox(
              height: fieldHeight,
              child: _shadowedField(
                controller: _membershipDateCtrl,
                hint: 'Select date of membership',
                readOnly: true,
                onTap: _pickMembershipDate,
              ),
            ),

            SizedBox(height: fieldGap),

            if (_selectedPosition == 'Other') ...[
              _label('If Other Position, specify', labelSize),
              SizedBox(height: labelFieldGap),
              SizedBox(
                height: fieldHeight,
                child: _shadowedField(
                  controller: _positionOtherCtrl,
                  hint: 'Enter other position',
                ),
              ),
            ],
          ],
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
    bool readOnly = false,
    VoidCallback? onTap,
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
        readOnly: readOnly,
        onTap: onTap,
        onChanged: (_) => _autoSaveToCurrentData(),
      ),
    );
  }

  Widget _yesNoOption({
    required String label,
    required bool selected,
    required double fontSize,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? DAColors.primaryGreen
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: DAColors.primaryGreen,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: DAColors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _checkboxOption({
    required String label,
    required bool selected,
    required double fontSize,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: selected
                      ? DAColors.primaryGreen
                      : Colors.grey.shade400,
                  width: 2,
                ),
                color: selected ? DAColors.primaryGreen : Colors.white,
              ),
              child: selected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: DAColors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
