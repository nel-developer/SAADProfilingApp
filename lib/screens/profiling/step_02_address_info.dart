import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/theme/da_colors.dart';
import 'package:da_project_1/widgets/custom_textfield.dart';
import 'package:da_project_1/screens/profiling/profiling_step_wrapper.dart';
import 'package:da_project_1/models/profiling_data.dart';
import 'package:da_project_1/services/location_service.dart';

/// Step 2 of 8 — Address Information
/// Fields: Region, Province, Municipality/City, Barangay, Sitio/Purok, Date of Birth, Sex
class Step02AddressInfo extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback? onHeaderBack;
  final ProfilingData? currentData;

  const Step02AddressInfo({
    super.key,
    required this.onNext,
    required this.onBack,
    this.onHeaderBack,
    this.currentData,
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

  // Location data structures
  final LocationService _locationService = LocationService();
  List<String> _regions = [];
  List<String> _provinces = [];
  List<String> _municipalities = [];
  List<String> _barangays = [];
  
  bool _locationsLoaded = false;

  @override
  void initState() {
    super.initState();
    // Add listeners only once in initState to prevent duplicates
    _regionCtrl.addListener(_autoSaveToCurrentData);
    _provinceCtrl.addListener(_autoSaveToCurrentData);
    _municipalityCtrl.addListener(_autoSaveToCurrentData);
    _barangayCtrl.addListener(_autoSaveToCurrentData);
    _sitioPurokCtrl.addListener(_autoSaveToCurrentData);
    _dateOfBirthCtrl.addListener(_autoSaveToCurrentData);
    _loadDataAndPopulateDropdowns();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Populate dependent dropdowns if region was already selected
    // (happens after initState or when returning to this step)
    if (_regionCtrl.text.isNotEmpty && _regions.isNotEmpty && _provinces.isEmpty) {
      _populateDropdownsForCurrentData();
    }
  }

  @override
  void didUpdateWidget(Step02AddressInfo oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload data when returning to this step via back button
    _loadDataAndPopulateDropdowns();
  }

  void _loadDataAndPopulateDropdowns() {
    // Prefill from shared currentData if available
    if (widget.currentData != null) {
      _regionCtrl.text = widget.currentData!.region ?? '';
      _provinceCtrl.text = widget.currentData!.province ?? '';
      _municipalityCtrl.text = widget.currentData!.municipality ?? '';
      _barangayCtrl.text = widget.currentData!.barangay ?? '';
      _sitioPurokCtrl.text = widget.currentData!.sitioPurok ?? '';
      _dateOfBirthCtrl.text = widget.currentData!.dateOfBirth ?? '';
      _selectedSex = widget.currentData!.sex;
    }
    
    // If regions are loaded, populate the dropdowns
    if (_regions.isNotEmpty) {
      _populateDropdownsForCurrentData();
    }
  }

  void _autoSaveToCurrentData() {
    if (widget.currentData != null) {
      widget.currentData!.region = _regionCtrl.text.trim();
      widget.currentData!.province = _provinceCtrl.text.trim();
      widget.currentData!.municipality = _municipalityCtrl.text.trim();
      widget.currentData!.barangay = _barangayCtrl.text.trim();
      widget.currentData!.sitioPurok = _sitioPurokCtrl.text.trim();
      widget.currentData!.dateOfBirth = _dateOfBirthCtrl.text.trim();
      widget.currentData!.sex = _selectedSex;
    }
  }

  void _populateDropdownsForCurrentData() {
    if (_regionCtrl.text.isEmpty) return;
    
    // Get provinces for the selected region
    _provinces = _locationService.getProvinces(_regionCtrl.text);

    if (_provinceCtrl.text.isNotEmpty && _provinces.contains(_provinceCtrl.text)) {
      // Get municipalities for the selected province
      _municipalities = _locationService.getMunicipalities(_regionCtrl.text, _provinceCtrl.text);

      if (_municipalityCtrl.text.isNotEmpty && _municipalities.contains(_municipalityCtrl.text)) {
        // Get barangays for the selected municipality
        _barangays = _locationService.getBarangays(_regionCtrl.text, _provinceCtrl.text, _municipalityCtrl.text);
      }
    }
  }

  Future<void> _loadLocations() async {
    try {
      await _locationService.loadLocations();
      setState(() {
        _regions = _locationService.getRegions();
        // After loading locations, populate dropdowns if we have currentData
        _loadDataAndPopulateDropdowns();
      });
    } catch (e) {
      debugPrint('❌ Error loading locations: $e');
    }
  }

  void _onRegionChanged(String? regionName) {
    if (regionName == null) return;

    setState(() {
      _regionCtrl.text = regionName;
      _provinceCtrl.clear();
      _municipalityCtrl.clear();
      _barangayCtrl.clear();
      _provinces = _locationService.getProvinces(regionName);
      _municipalities = [];
      _barangays = [];
    });
  }

  void _onProvinceChanged(String? provinceName) {
    if (provinceName == null || _regionCtrl.text.isEmpty) return;

    setState(() {
      _provinceCtrl.text = provinceName;
      _municipalityCtrl.clear();
      _barangayCtrl.clear();
      _municipalities = _locationService.getMunicipalities(_regionCtrl.text, provinceName);
      _barangays = [];
    });
  }

  void _onMunicipalityChanged(String? municipalityName) {
    if (municipalityName == null || _regionCtrl.text.isEmpty || _provinceCtrl.text.isEmpty) return;

    setState(() {
      _municipalityCtrl.text = municipalityName;
      _barangayCtrl.clear();
      _barangays = _locationService.getBarangays(_regionCtrl.text, _provinceCtrl.text, municipalityName);
    });
  }

  void _onBarangayChanged(String? barangayName) {
    if (barangayName == null) return;
    setState(() {
      _barangayCtrl.text = barangayName;
    });
  }

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

    // Lazy-load locations on first build (not in initState to avoid blocking UI)
    if (!_locationsLoaded && mounted) {
      _locationsLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadLocations();
      });
    }

    return ProfilingStepWrapper(
      currentStep: 2,
      sectionTitle: 'Address',
      onNext: _handleNext,
      onBack: widget.onBack,
      onHeaderBack: widget.onHeaderBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Region dropdown
          _label('Region', labelSize),
          SizedBox(height: labelFieldGap),
          SizedBox(
            height: fieldHeight,
            child: _shadowedDropdown(
              value: _regionCtrl.text.isEmpty ? null : _regionCtrl.text,
              hint: 'Select Region',
              items: _regions,
              onChanged: _onRegionChanged,
            ),
          ),
          SizedBox(height: fieldGap),

          // Province dropdown
          _label('Province', labelSize),
          SizedBox(height: labelFieldGap),
          SizedBox(
            height: fieldHeight,
            child: _shadowedDropdown(
              value: _provinceCtrl.text.isEmpty ? null : _provinceCtrl.text,
              hint: 'Select Province',
              items: _provinces,
              onChanged: _onProvinceChanged,
            ),
          ),
          SizedBox(height: fieldGap),

          // Municipality/City dropdown
          _label('Municipality/City', labelSize),
          SizedBox(height: labelFieldGap),
          SizedBox(
            height: fieldHeight,
            child: _shadowedDropdown(
              value: _municipalityCtrl.text.isEmpty ? null : _municipalityCtrl.text,
              hint: 'Select Municipality/City',
              items: _municipalities,
              onChanged: _onMunicipalityChanged,
            ),
          ),
          SizedBox(height: fieldGap),

          // Barangay dropdown
          _label('Barangay', labelSize),
          SizedBox(height: labelFieldGap),
          SizedBox(
            height: fieldHeight,
            child: _shadowedDropdown(
              value: _barangayCtrl.text.isEmpty ? null : _barangayCtrl.text,
              hint: 'Select Barangay',
              items: _barangays,
              onChanged: _onBarangayChanged,
            ),
          ),
          SizedBox(height: fieldGap),

          // Sitio/Purok text field
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

          // Date of Birth
          _label('Date of Birth', labelSize),
          SizedBox(height: labelFieldGap),
          SizedBox(
            height: fieldHeight,
            child: _shadowedDateField(
              controller: _dateOfBirthCtrl,
              hint: 'Select Date of Birth',
              onTap: () => _selectDate(context),
            ),
          ),
          SizedBox(height: fieldGap),

          // Sex dropdown
          _label('Sex', labelSize),
          SizedBox(height: labelFieldGap),
          SizedBox(
            height: fieldHeight,
            child: _shadowedDropdown(
              value: _selectedSex,
              hint: 'Select Sex',
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

  void _handleNext() {
    // All fields on this step are optional; validation happens at final submit only

    // Write back to currentData
    if (widget.currentData != null) {
      widget.currentData!.region = _regionCtrl.text.trim();
      widget.currentData!.province = _provinceCtrl.text.trim();
      widget.currentData!.municipality = _municipalityCtrl.text.trim();
      widget.currentData!.barangay = _barangayCtrl.text.trim();
      widget.currentData!.sitioPurok = _sitioPurokCtrl.text.trim();
      widget.currentData!.dateOfBirth = _dateOfBirthCtrl.text.trim();
      widget.currentData!.sex = _selectedSex;
    }

    widget.onNext();
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