import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/theme/da_colors.dart';
// removed unused custom_textfield import
import 'package:da_project_1/screens/profiling/profiling_step_wrapper.dart';
import 'package:da_project_1/models/profiling_data.dart';
import 'package:da_project_1/services/local_commodity_cache.dart';
import 'package:da_project_1/services/profiling_storage_service.dart';

/// Step 6 of 10 — Main Commodity
/// Fields: Primary Commodity (single dropdown), Secondary Commodities (checkboxes, exclude main)
class Step06MainCommodity extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback? onHeaderBack;
  final ProfilingData? currentData;

  const Step06MainCommodity({
    super.key,
    required this.onNext,
    required this.onBack,
    this.onHeaderBack,
    this.currentData,
  });

  @override
  State<Step06MainCommodity> createState() => _Step06MainCommodityState();
}

class _Step06MainCommodityState extends State<Step06MainCommodity> {
  final ProfilingStorageService _storage = ProfilingStorageService();
  String? _primaryCommodity; // Just type name
  Set<String> _selectedSecondaryOptions = {}; // Checkboxes for secondary types
  String?
  _selectedReceivedCommodity; // legacy single value (kept for compatibility)
  String? _receivedPrimary; // new received primary
  Set<String> _receivedSecondaryOptions = {}; // received secondary types

  final TextEditingController _primaryOthersCtrl = TextEditingController();
  final LocalCommodityCache _cache = LocalCommodityCache();
  List<String> _typeOptions = [];

  String _normalizeValue(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    if (normalized.isEmpty) return '';
    return normalized.replaceAll(RegExp(r'\s+'), ' ');
  }

  List<String> _uniqueOptions(Iterable<String?> rawValues) {
    final output = <String>[];
    final seen = <String>{};
    for (final raw in rawValues) {
      final value = raw?.trim() ?? '';
      if (value.isEmpty) continue;
      final key = _normalizeValue(value);
      if (key.isEmpty) continue;
      if (seen.add(key)) {
        output.add(value);
      }
    }
    output.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return output;
  }

  String? _safeSelectedValue(String? selected, List<String> items) {
    if (selected == null || items.isEmpty) return null;
    final selectedKey = _normalizeValue(selected);
    if (selectedKey.isEmpty) return null;
    for (final item in items) {
      if (_normalizeValue(item) == selectedKey) {
        return item;
      }
    }
    return null;
  }

  Set<String> _parseCsvToSet(String? value) {
    if (value == null || value.trim().isEmpty) return <String>{};
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet();
  }

  void _sanitizeReceivedSelections() {
    final primary = _receivedPrimary?.trim();
    if (primary == null || primary.isEmpty) return;
    _receivedSecondaryOptions = _receivedSecondaryOptions
        .where((item) => item.trim() != primary)
        .toSet();
  }

  @override
  void initState() {
    super.initState();
    _primaryOthersCtrl.addListener(_autoSaveToCurrentData);
    _loadData();
    _loadCachedCommodities();
  }

  void _loadCachedCommodities() {
    try {
      _typeOptions = _uniqueOptions(_cache.getTypes());
      _primaryCommodity = _safeSelectedValue(_primaryCommodity, _typeOptions);
      _receivedPrimary = _safeSelectedValue(_receivedPrimary, _typeOptions);
      _selectedSecondaryOptions = _selectedSecondaryOptions
          .map((item) => _safeSelectedValue(item, _typeOptions))
          .whereType<String>()
          .toSet();
      _receivedSecondaryOptions = _receivedSecondaryOptions
          .map((item) => _safeSelectedValue(item, _typeOptions))
          .whereType<String>()
          .toSet();
      debugPrint('📦 Step 6 loaded types: $_typeOptions');
      setState(() {});
    } catch (e) {
      debugPrint('❌ Error loading types: $e');
    }
  }

  void _onPrimarySelected(String? type) {
    setState(() {
      _primaryCommodity = type;
      _autoSaveToCurrentData();
    });
  }

  void _loadData() {
    if (widget.currentData != null) {
      _primaryCommodity = widget.currentData!.primaryCommodity;
      final secondary = widget.currentData!.secondaryCommodity ?? '';
      _selectedSecondaryOptions = secondary.isEmpty
          ? {}
          : secondary.split(',').map((s) => s.trim()).toSet();
      // load received primary/secondary if present, fall back to legacy receivedCommodity
      _receivedPrimary =
          widget.currentData!.receivedPrimaryCommodity ??
          widget.currentData!.receivedCommodity;
      _selectedReceivedCommodity =
          widget.currentData!.receivedCommodity ?? _receivedPrimary;
      final recSec = widget.currentData!.receivedSecondaryCommodity ?? '';
      _receivedSecondaryOptions = _parseCsvToSet(recSec);
      _sanitizeReceivedSelections();
      _primaryOthersCtrl.text =
          widget.currentData!.primaryCommodityOthers ?? '';
    }
  }

  void _autoSaveToCurrentData() {
    if (widget.currentData != null) {
      widget.currentData!.primaryCommodity = _primaryCommodity;
      widget.currentData!.secondaryCommodity = _selectedSecondaryOptions
          .toList()
          .join(', ');
      widget.currentData!.primaryCommodityOthers = _primaryOthersCtrl.text
          .trim();
      // persist both legacy and new fields
      widget.currentData!.receivedCommodity =
          _selectedReceivedCommodity ?? _receivedPrimary;
      widget.currentData!.receivedPrimaryCommodity = _receivedPrimary;
      _sanitizeReceivedSelections();
      widget.currentData!.receivedSecondaryCommodity = _receivedSecondaryOptions
          .toList()
          .join(', ');
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
    _primaryOthersCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(Step06MainCommodity oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep local in-memory state authoritative while this step widget is alive.
    // Avoid reloads on parent rebuilds to prevent accidental field resets.
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

    // For secondary options, filter out the primary commodity
    final secondaryOptions = _typeOptions
        .where((type) => type != _primaryCommodity)
        .toList();

    return ProfilingStepWrapper(
      currentStep: 6,
      sectionTitle: 'Main Commodity',
      onNext: _handleNext,
      onBack: widget.onBack,
      onHeaderBack: _handleHeaderBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PRIMARY COMMODITY TYPE (SIMPLE DROPDOWN)
          _label('Primary Commodity Type', labelSize),
          SizedBox(height: labelFieldGap),
          SizedBox(
            height: fieldHeight,
            child: _shadowedDropdown(
              value: _primaryCommodity,
              hint: 'Select Commodity Type',
              items: _typeOptions,
              onChanged: _onPrimarySelected,
            ),
          ),

          SizedBox(height: fieldGap),

          // SECONDARY COMMODITIES (CHECKBOXES - TYPES ONLY)
          if (secondaryOptions.isNotEmpty) ...[
            _label('Secondary Commodity Types (select multiple)', labelSize),
            SizedBox(height: labelFieldGap),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: secondaryOptions.map((type) {
                final isChecked = _selectedSecondaryOptions.contains(type);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isChecked,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedSecondaryOptions.add(type);
                            } else {
                              _selectedSecondaryOptions.remove(type);
                            }
                            _autoSaveToCurrentData();
                          });
                        },
                        activeColor: DAColors.primaryGreen,
                      ),
                      Expanded(
                        child: Text(
                          type,
                          style: GoogleFonts.poppins(
                            fontSize: labelSize - 2,
                            fontWeight: FontWeight.w500,
                            color: DAColors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: fieldGap),
          ],

          // RECEIVED COMMODITY (Primary + Secondary types)
          _label('Received Commodity — Primary', labelSize),
          SizedBox(height: labelFieldGap),
          SizedBox(
            height: fieldHeight,
            child: _shadowedDropdown(
              value: _receivedPrimary,
              hint: 'Select Received Primary Type',
              items: _typeOptions,
              onChanged: (val) => setState(() {
                _receivedPrimary = val;
                // remove any received secondary that now equals primary
                _receivedSecondaryOptions.remove(val);
                _autoSaveToCurrentData();
              }),
            ),
          ),

          SizedBox(height: fieldGap),

          if (_typeOptions.where((t) => t != _receivedPrimary).isNotEmpty) ...[
            _label(
              'Received Commodity — Secondary Types (select multiple)',
              labelSize,
            ),
            SizedBox(height: labelFieldGap),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _typeOptions.where((t) => t != _receivedPrimary).map((
                type,
              ) {
                final isChecked = _receivedSecondaryOptions.contains(type);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isChecked,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _receivedSecondaryOptions.add(type);
                            } else {
                              _receivedSecondaryOptions.remove(type);
                            }
                            _autoSaveToCurrentData();
                          });
                        },
                        activeColor: DAColors.primaryGreen,
                      ),
                      Expanded(
                        child: Text(
                          type,
                          style: GoogleFonts.poppins(
                            fontSize: labelSize - 2,
                            fontWeight: FontWeight.w500,
                            color: DAColors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: fieldGap),
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

  // (removed unused _shadowedField helper)

  Widget _shadowedDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final uniqueItems = _uniqueOptions(items);
    final safeValue = _safeSelectedValue(value, uniqueItems);
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
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item, overflow: TextOverflow.ellipsis, maxLines: 1),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
