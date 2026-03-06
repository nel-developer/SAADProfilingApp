import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/theme/da_colors.dart';
import 'package:da_project_1/widgets/custom_textfield.dart';
import 'package:da_project_1/screens/profiling/profiling_step_wrapper.dart';
import 'package:da_project_1/models/profiling_data.dart';
import 'package:da_project_1/services/profiling_storage_service.dart';

/// Step 1 of 8 — Personal Information
/// Fields: First Name, Middle Name, Surname, Extension Name
class Step01PersonalInfo extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onHeaderBack;
  final ProfilingData? currentData;

  const Step01PersonalInfo({
    super.key,
    required this.onNext,
    this.onHeaderBack,
    this.currentData,
  });

  @override
  State<Step01PersonalInfo> createState() => _Step01PersonalInfoState();
}

class _Step01PersonalInfoState extends State<Step01PersonalInfo> {
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _middleNameCtrl = TextEditingController();
  final TextEditingController _surnameCtrl = TextEditingController();
  final TextEditingController _saadSearchCtrl = TextEditingController();
  final ProfilingStorageService _storage = ProfilingStorageService();
  String? _selectedExtension;
  bool _isExistingFarmer = false;
  bool _loadingExistingFarmers = false;
  String? _selectedExistingSaadId;
  List<ProfilingData> _existingFarmers = [];
  final List<String> _extensionOptions = const [
    'Junior',
    'Senior',
    'The first',
    'The second',
    'The third',
    'The fourth',
    'The fifth',
    'The sixth',
    'The seventh',
    'The eighth',
    'The ninth',
    'The tenth',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadExistingFarmers();
    // Add listeners only once in initState to prevent duplicates
    _firstNameCtrl.addListener(() => _handleNameChange(_firstNameCtrl));
    _middleNameCtrl.addListener(() => _handleNameChange(_middleNameCtrl));
    _surnameCtrl.addListener(() => _handleNameChange(_surnameCtrl));
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

  void _loadData() {
    // Prefill from shared currentData if available
    if (widget.currentData != null) {
      _isExistingFarmer = widget.currentData!.isExistingFarmer == true;
      _firstNameCtrl.text = widget.currentData!.firstName ?? '';
      _middleNameCtrl.text = widget.currentData!.middleName ?? '';
      _surnameCtrl.text = widget.currentData!.surname ?? '';
      _selectedExistingSaadId =
          widget.currentData!.selectedExistingSaadId ??
          widget.currentData!.saadIdNo;
      _saadSearchCtrl.text = _selectedExistingSaadId ?? '';
      final savedExtension = widget.currentData!.extensionName?.trim();
      _selectedExtension =
          (savedExtension != null && _extensionOptions.contains(savedExtension))
          ? savedExtension
          : null;
      _forceUppercase(_firstNameCtrl);
      _forceUppercase(_middleNameCtrl);
      _forceUppercase(_surnameCtrl);
    }
  }

  Future<void> _loadExistingFarmers() async {
    if (!mounted) return;
    setState(() {
      _loadingExistingFarmers = true;
    });

    await _storage.init();
    final farmers = await _storage.loadExistingFarmersForPrefill();
    if (!mounted) return;

    final uniqueBySaad = <String, ProfilingData>{};
    for (final farmer in farmers) {
      final saadId = farmer.saadIdNo?.trim() ?? '';
      if (saadId.isEmpty) continue;
      uniqueBySaad.putIfAbsent(saadId, () => farmer);
    }

    final list = uniqueBySaad.values.toList()
      ..sort((a, b) {
        final aId = a.saadIdNo?.trim() ?? '';
        final bId = b.saadIdNo?.trim() ?? '';
        return aId.compareTo(bId);
      });

    setState(() {
      _existingFarmers = list;
      _loadingExistingFarmers = false;
    });
  }

  void _applyExistingFarmer(ProfilingData selected) {
    if (widget.currentData == null) return;

    _firstNameCtrl.text = selected.firstName ?? '';
    _middleNameCtrl.text = selected.middleName ?? '';
    _surnameCtrl.text = selected.surname ?? '';
    final savedExtension = selected.extensionName?.trim();
    _selectedExtension =
        (savedExtension != null && _extensionOptions.contains(savedExtension))
        ? savedExtension
        : null;
    _forceUppercase(_firstNameCtrl);
    _forceUppercase(_middleNameCtrl);
    _forceUppercase(_surnameCtrl);

    final target = widget.currentData!;
    target.isExistingFarmer = true;
    target.selectedExistingSaadId = selected.saadIdNo;
    target.saadIdNo = selected.saadIdNo;
    target.rsbsaFishrIdNo = selected.rsbsaFishrIdNo;

    target.firstName = selected.firstName;
    target.middleName = selected.middleName;
    target.surname = selected.surname;
    target.extensionName = selected.extensionName;

    target.region = selected.region;
    target.province = selected.province;
    target.municipality = selected.municipality;
    target.barangay = selected.barangay;
    target.sitioPurok = selected.sitioPurok;
    target.dateOfBirth = selected.dateOfBirth;
    target.sex = selected.sex;
    target.isIndigenous = selected.isIndigenous;
    target.isPWD = selected.isPWD;
    target.spouseName = selected.spouseName;
  }

  @override
  void didUpdateWidget(Step01PersonalInfo oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload data when returning to this step or when currentData changes
    _loadData();
  }

  void _autoSaveToCurrentData() {
    if (widget.currentData != null) {
      widget.currentData!.isExistingFarmer = _isExistingFarmer;
      widget.currentData!.selectedExistingSaadId = _selectedExistingSaadId;
      widget.currentData!.firstName = _firstNameCtrl.text.trim().toUpperCase();
      widget.currentData!.middleName = _middleNameCtrl.text
          .trim()
          .toUpperCase();
      widget.currentData!.surname = _surnameCtrl.text.trim().toUpperCase();
      widget.currentData!.extensionName = _selectedExtension?.toUpperCase();
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _surnameCtrl.dispose();
    _saadSearchCtrl.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    // Persist latest typed values before this step is removed from view
    // (e.g., leaving to Home from header back).
    _autoSaveToCurrentData();
    super.deactivate();
  }

  void _handleHeaderBack() {
    _autoSaveToCurrentData();
    if (widget.onHeaderBack != null) {
      widget.onHeaderBack!();
    }
  }

  List<String> _filteredExistingSaadIds() {
    final all =
        _existingFarmers
            .map((farmer) => farmer.saadIdNo?.trim() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    final query = _saadSearchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return all;
    return all.where((id) => id.toLowerCase().contains(query)).toList();
  }

  void _handleNext() {
    // Validate required fields (middle name & extension are exempt)
    // Save without per-step validation (final validation happens on submit)

    if (_isExistingFarmer &&
        (_selectedExistingSaadId == null ||
            _selectedExistingSaadId!.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select SAAD I.D No. for Existing Farmer.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Save data to shared currentData before proceeding
    if (widget.currentData != null) {
      widget.currentData!.isExistingFarmer = _isExistingFarmer;
      widget.currentData!.selectedExistingSaadId = _selectedExistingSaadId;
      widget.currentData!.firstName = _firstNameCtrl.text.trim().toUpperCase();
      widget.currentData!.middleName = _middleNameCtrl.text
          .trim()
          .toUpperCase();
      widget.currentData!.surname = _surnameCtrl.text.trim().toUpperCase();
      widget.currentData!.extensionName = _selectedExtension?.toUpperCase();
    }
    widget.onNext();
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
    // Phone = compact, tablet+ = a bit taller
    final double fieldHeight = isLargeTablet
        ? 54.0
        : isTablet
        ? 50.0
        : 44.0;

    return ProfilingStepWrapper(
      currentStep: 1,
      sectionTitle: 'Personal Information',
      onNext: _handleNext,
      onBack: null,
      onHeaderBack: _handleHeaderBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Profiling Type', labelSize),
          SizedBox(height: labelFieldGap),
          SizedBox(
            height: fieldHeight,
            child: _shadowedDropdown(
              value: _isExistingFarmer ? 'Existing Farmer' : 'New Farmer',
              hint: 'Select Profiling Type',
              items: const ['New Farmer', 'Existing Farmer'],
              onChanged: (value) {
                setState(() {
                  _isExistingFarmer = value == 'Existing Farmer';
                  if (!_isExistingFarmer) {
                    _selectedExistingSaadId = null;
                    if (widget.currentData != null) {
                      widget.currentData!.isExistingFarmer = false;
                      widget.currentData!.selectedExistingSaadId = null;
                    }
                  }
                });
                _autoSaveToCurrentData();
              },
            ),
          ),

          if (_isExistingFarmer) ...[
            SizedBox(height: fieldGap),
            _label('Search SAAD I.D No.', labelSize),
            SizedBox(height: labelFieldGap),
            SizedBox(
              height: fieldHeight,
              child: _shadowedField(
                controller: _saadSearchCtrl,
                hint: 'Type SAAD I.D No.',
                readOnly: _loadingExistingFarmers,
                onChanged: (_) {
                  setState(() {});
                },
              ),
            ),
            SizedBox(height: fieldGap),
            _label('Select Existing Farmer (SAAD I.D No.)', labelSize),
            SizedBox(height: labelFieldGap),
            SizedBox(
              height: fieldHeight,
              child: _shadowedDropdown(
                value: _selectedExistingSaadId,
                hint: _loadingExistingFarmers
                    ? 'Loading existing farmers...'
                    : 'Select SAAD I.D No.',
                items: _filteredExistingSaadIds(),
                onChanged: _loadingExistingFarmers
                    ? (_) {}
                    : (value) {
                        if (value == null || value.trim().isEmpty) return;
                        final selected = _existingFarmers
                            .where((f) => (f.saadIdNo?.trim() ?? '') == value)
                            .toList();
                        if (selected.isEmpty) return;

                        setState(() {
                          _selectedExistingSaadId = value;
                          _saadSearchCtrl.text = value;
                          _applyExistingFarmer(selected.first);
                        });
                        _autoSaveToCurrentData();
                      },
              ),
            ),
            SizedBox(height: 10),
            _buildExistingBasicInfo(labelSize - 1, valueSize: labelSize - 1),
          ],

          if (!_isExistingFarmer) ...[
            SizedBox(height: fieldGap),

            _label('First Name', labelSize),
            SizedBox(height: labelFieldGap),
            SizedBox(
              height: fieldHeight,
              child: _shadowedField(
                controller: _firstNameCtrl,
                hint: 'Enter First Name',
                readOnly: false,
              ),
            ),

            SizedBox(height: fieldGap),

            _label('Middle Name', labelSize),
            SizedBox(height: labelFieldGap),
            SizedBox(
              height: fieldHeight,
              child: _shadowedField(
                controller: _middleNameCtrl,
                hint: 'Enter Middle Name',
                readOnly: false,
              ),
            ),

            SizedBox(height: fieldGap),

            _label('Surname', labelSize),
            SizedBox(height: labelFieldGap),
            SizedBox(
              height: fieldHeight,
              child: _shadowedField(
                controller: _surnameCtrl,
                hint: 'Enter Surname',
                readOnly: false,
              ),
            ),

            SizedBox(height: fieldGap),

            _label('Extension Name', labelSize),
            SizedBox(height: labelFieldGap),
            SizedBox(
              height: fieldHeight,
              child: _shadowedDropdown(
                value: _selectedExtension,
                hint: 'Select Extension Name',
                items: _extensionOptions,
                enabled: true,
                onChanged: (value) {
                  setState(() {
                    _selectedExtension = value;
                  });
                  _autoSaveToCurrentData();
                },
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
  // TextField wrapped in a Container that gives it a deeper shadow.
  // CustomTextField already has a white bg + rounded corners so we just
  // overlay the shadow via the outer Container's decoration.
  // ---------------------------------------------------------------------------
  Widget _shadowedField({
    required TextEditingController controller,
    required String hint,
    bool readOnly = false,
    ValueChanged<String>? onChanged,
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
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildExistingBasicInfo(
    double labelSize, {
    required double valueSize,
  }) {
    if (!_isExistingFarmer) return const SizedBox.shrink();
    final data = widget.currentData;

    String textOf(String? value) {
      final text = value?.trim() ?? '';
      return text.isEmpty ? 'N/A' : text;
    }

    String yesNo(bool? value) => value == true ? 'Yes' : 'No';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fetched Farmer Basic Information',
            style: GoogleFonts.poppins(
              fontSize: labelSize,
              fontWeight: FontWeight.w700,
              color: DAColors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'RSBSA/FISHR ID No.: ${textOf(data?.rsbsaFishrIdNo)}',
            style: GoogleFonts.poppins(fontSize: valueSize),
          ),
          Text(
            'SAAD I.D No.: ${textOf(data?.saadIdNo)}',
            style: GoogleFonts.poppins(fontSize: valueSize),
          ),
          Text(
            'First Name: ${textOf(data?.firstName)}',
            style: GoogleFonts.poppins(fontSize: valueSize),
          ),
          Text(
            'Surname: ${textOf(data?.surname)}',
            style: GoogleFonts.poppins(fontSize: valueSize),
          ),
          Text(
            'Middle Name: ${textOf(data?.middleName)}',
            style: GoogleFonts.poppins(fontSize: valueSize),
          ),
          Text(
            'Extension: ${textOf(data?.extensionName)}',
            style: GoogleFonts.poppins(fontSize: valueSize),
          ),
          Text(
            'Address: ${textOf(data?.sitioPurok)}, ${textOf(data?.barangay)}, ${textOf(data?.municipality)}, ${textOf(data?.province)}, ${textOf(data?.region)}',
            style: GoogleFonts.poppins(fontSize: valueSize),
          ),
          Text(
            'Date of Birth: ${textOf(data?.dateOfBirth)}',
            style: GoogleFonts.poppins(fontSize: valueSize),
          ),
          Text(
            'Sex: ${textOf(data?.sex)}',
            style: GoogleFonts.poppins(fontSize: valueSize),
          ),
          Text(
            'Member of Indigenous Group: ${yesNo(data?.isIndigenous)}',
            style: GoogleFonts.poppins(fontSize: valueSize),
          ),
          Text(
            'Person with Disability (PWD): ${yesNo(data?.isPWD)}',
            style: GoogleFonts.poppins(fontSize: valueSize),
          ),
          Text(
            'Name of Spouse: ${textOf(data?.spouseName)}',
            style: GoogleFonts.poppins(fontSize: valueSize),
          ),
        ],
      ),
    );
  }

  Widget _shadowedDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool enabled = true,
  }) {
    final uniqueItems = items.toSet().toList();
    final safeValue = (value != null && uniqueItems.contains(value))
        ? value
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
        initialValue: safeValue,
        decoration: InputDecoration(
          hintText: hint,
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
        items: uniqueItems.map((String item) {
          return DropdownMenuItem<String>(value: item, child: Text(item));
        }).toList(),
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}
