import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/theme/da_colors.dart';
import 'package:da_project_1/widgets/custom_textfield.dart';
import 'package:da_project_1/screens/profiling/profiling_step_wrapper.dart';
import 'package:da_project_1/models/profiling_data.dart';

/// Step 4 of 8 — Main Commodity
/// Fields: Primary Commodity (dropdown), Secondary Commodity (dropdown)
/// Both have "Others" option with conditional text field
class Step04MainCommodity extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback? onHeaderBack;
  final ProfilingData? currentData;

  const Step04MainCommodity({
    super.key,
    required this.onNext,
    required this.onBack,
    this.onHeaderBack,
    this.currentData,
  });

  @override
  State<Step04MainCommodity> createState() => _Step04MainCommodityState();
}

class _Step04MainCommodityState extends State<Step04MainCommodity> {
  String? _primaryCommodity;
  List<String> _secondaryCommodities = []; // Multi-select for secondary
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
  void initState() {
    super.initState();
    // Add listeners only once in initState to prevent duplicates
    _primaryOthersCtrl.addListener(_autoSaveToCurrentData);
    _secondaryOthersCtrl.addListener(_autoSaveToCurrentData);
    _loadData();
  }

  void _loadData() {
    if (widget.currentData != null) {
      _primaryCommodity = widget.currentData!.primaryCommodity;
      // Parse comma-separated secondary commodities
      final secondary = widget.currentData!.secondaryCommodity ?? '';
      _secondaryCommodities = secondary.isEmpty ? [] : secondary.split(',').map((s) => s.trim()).toList();
      _primaryOthersCtrl.text = widget.currentData!.primaryCommodityOthers ?? '';
      _secondaryOthersCtrl.text = widget.currentData!.secondaryCommodityOthers ?? '';
    }
  }

  void _autoSaveToCurrentData() {
    if (widget.currentData != null) {
      widget.currentData!.primaryCommodity = _primaryCommodity;
      widget.currentData!.secondaryCommodity = _secondaryCommodities.join(', ');
      widget.currentData!.primaryCommodityOthers = _primaryOthersCtrl.text.trim();
      widget.currentData!.secondaryCommodityOthers = _secondaryOthersCtrl.text.trim();
    }
  }

  @override
  void dispose() {
    _primaryOthersCtrl.dispose();
    _secondaryOthersCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(Step04MainCommodity oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload data when returning to this step via back button
    _loadData();
  }

  void _handleNext() {
    // No step-level validation; all validation happens at final submit
    // Save data to shared currentData before proceeding
    if (widget.currentData != null) {
      widget.currentData!.primaryCommodity = _primaryCommodity;
      // Store as comma-separated string
      widget.currentData!.secondaryCommodity = _secondaryCommodities.join(', ');
      widget.currentData!.primaryCommodityOthers = _primaryOthersCtrl.text.trim();
      widget.currentData!.secondaryCommodityOthers = _secondaryOthersCtrl.text.trim();
    }
    widget.onNext();
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
      onNext: _handleNext,
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
                  _autoSaveToCurrentData();
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
          // SECONDARY COMMODITY (MULTI-SELECT)
          // ─────────────────────────────────────────────────────────
          _label('Secondary Commodity (select one or more)', labelSize),
          SizedBox(height: labelFieldGap),
          _buildSecondaryMultiSelect(labelSize),

          // Conditional "Others" text field for Secondary
          if (_secondaryCommodities.contains('Others')) ...[
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

  // Get secondary commodity options (exclude primary commodity)
  List<String> _getSecondaryOptions() {
    if (_primaryCommodity == null || _primaryCommodity!.isEmpty) {
      return _commodityOptions;
    }
    return _commodityOptions.where((item) => item != _primaryCommodity).toList();
  }

  // Multi-select widget for secondary commodities
  Widget _buildSecondaryMultiSelect(double labelSize) {
    final secondaryOptions = _getSecondaryOptions();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: secondaryOptions.map((item) {
            final isSelected = _secondaryCommodities.contains(item);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _secondaryCommodities.remove(item);
                  } else {
                    _secondaryCommodities.add(item);
                  }
                  // Clear "Others" field if "Others" is deselected
                  if (item == 'Others' && !_secondaryCommodities.contains('Others')) {
                    _secondaryOthersCtrl.clear();
                  }
                  _autoSaveToCurrentData();
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Checkbox(
                      value: isSelected,
                      onChanged: (_) {
                        setState(() {
                          if (isSelected) {
                            _secondaryCommodities.remove(item);
                          } else {
                            _secondaryCommodities.add(item);
                          }
                          if (item == 'Others' && !_secondaryCommodities.contains('Others')) {
                            _secondaryOthersCtrl.clear();
                          }
                          _autoSaveToCurrentData();
                        });
                      },
                      activeColor: DAColors.primaryGreen,
                    ),
                    SizedBox(width: 12),
                    Text(
                      item,
                      style: GoogleFonts.poppins(
                        fontSize: labelSize - 2,
                        fontWeight: FontWeight.w400,
                        color: DAColors.black,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
