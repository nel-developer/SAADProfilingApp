import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:da_project_1/theme/da_colors.dart';
import 'package:da_project_1/screens/profiling/profiling_step_wrapper.dart';
import 'package:da_project_1/models/profiling_data.dart';
import 'package:da_project_1/services/local_commodity_cache.dart';
import 'package:da_project_1/services/commodity_service.dart';

/// Step 4 of 10 — SAAD Commodity Type
/// Fields: Commodity Type (dropdown)
class Step04SAAdIncome extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback? onHeaderBack;
  final ProfilingData? currentData;

  const Step04SAAdIncome({
    super.key,
    required this.onNext,
    required this.onBack,
    this.onHeaderBack,
    this.currentData,
  });

  @override
  State<Step04SAAdIncome> createState() => _Step04SAAdIncomeState();
}

// Dynamic form model for additional commodity entries
class _CommodityForm {
  String? type;
  String? commodity;
  String? saleMeth;
  String? productForm;
  String? pricingBasis;
  String? unit;

  // option lists
  List<String> commodityOptions = [];
  List<String> saleMethOptions = [];
  List<String> productFormOptions = [];
  List<String> pricingBasisOptions = [];
  List<String> unitOptions = [];

  // requirement flags
  bool maleRequired = false;
  bool femaleRequired = false;
  bool totalWeightRequired = false;
  bool totalAmountRequired = false;
  bool expensesRequired = false;

  // controllers
  final TextEditingController maleCtrl = TextEditingController();
  final TextEditingController femaleCtrl = TextEditingController();
  final TextEditingController weightCtrl = TextEditingController();
  final TextEditingController amountCtrl = TextEditingController();
  final TextEditingController expensesCtrl = TextEditingController();
  final TextEditingController remarksCtrl = TextEditingController();

  void dispose() {
    maleCtrl.dispose();
    femaleCtrl.dispose();
    weightCtrl.dispose();
    amountCtrl.dispose();
    expensesCtrl.dispose();
    remarksCtrl.dispose();
  }
}

class _Step04SAAdIncomeState extends State<Step04SAAdIncome> {
  String? _selectedType;
  String? _selectedCommodity;
  String? _selectedSaleMeth;
  String? _selectedProductForm;
  String? _selectedPricingBasis;
  String? _selectedUnit;

  // Field requirement flags
  bool _maleRequired = false;
  bool _femaleRequired = false;
  bool _totalWeightRequired = false;
  bool _totalAmountRequired = false;
  bool _expensesRequired = false;

  // Text controllers for input fields
  final TextEditingController _maleCountCtrl = TextEditingController();
  final TextEditingController _femaleCountCtrl = TextEditingController();
  final TextEditingController _weightCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _expensesCtrl = TextEditingController();
  final TextEditingController _remarksCtrl = TextEditingController();

  // List to store added commodities
  List<Map<String, dynamic>> _addedCommodities = [];
  // Additional dynamic forms created by "Add Another"
  final List<_CommodityForm> _additionalForms = [];

  final LocalCommodityCache _cache = LocalCommodityCache();
  List<String> _typeOptions = [];
  List<String> _commodityOptions = [];
  List<String> _saleMethOptions = [];
  List<String> _productFormOptions = [];
  List<String> _pricingBasisOptions = [];
  List<String> _unitOptions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadCachedCommodities();

    // listen to text controllers so any change is auto-saved
    _maleCountCtrl.addListener(_autoSaveToCurrentData);
    _femaleCountCtrl.addListener(_autoSaveToCurrentData);
    _weightCtrl.addListener(_autoSaveToCurrentData);
    _amountCtrl.addListener(_autoSaveToCurrentData);
    _expensesCtrl.addListener(_autoSaveToCurrentData);
    _remarksCtrl.addListener(_autoSaveToCurrentData);
  }

  void _loadCachedCommodities() async {
    try {
      // Ensure cache is initialized (returns early if already done)
      await _cache.init();

      // Get the types
      var types = _cache.getTypes();
      debugPrint('📦 Step 4 loaded ${types.length} types from cache: $types');

      if (types.isEmpty) {
        debugPrint(
          '⚠️ No commodity types found in local cache. Bootstrapping from Firestore...',
        );
        final bootstrapped = await CommodityService().bootstrapCacheIfEmpty();
        if (bootstrapped) {
          types = _cache.getTypes();
          debugPrint(
            '✅ Step 4 bootstrap loaded ${types.length} type(s): $types',
          );
        } else {
          debugPrint(
            '❌ Step 4 bootstrap failed or Firestore has no commodities.',
          );
        }
      }

      if (mounted) {
        setState(() {
          _typeOptions = types;
        });
        // After cache is ready, restore any saved full entries from currentData
        _restoreSavedEntries();
      }
    } catch (e) {
      debugPrint('❌ Error loading cached types: $e');
      if (mounted) {
        setState(() {
          _typeOptions = [];
        });
      }
    }
  }

  void _restoreSavedEntries() {
    if (widget.currentData == null) return;
    final saved = widget.currentData!.saadCommodities ?? [];
    if (saved.isEmpty) {
      // keep existing behavior (persisted type only)
      _selectedType = widget.currentData!.saadCommodityType;
      return;
    }

    // Use the last entry as the current form, others as added list
    final last = Map<String, dynamic>.from(saved.last);
    final rest = saved.length > 1
        ? saved.sublist(0, saved.length - 1)
        : <Map<String, dynamic>>[];
    _addedCommodities = rest.map((e) => Map<String, dynamic>.from(e)).toList();

    setState(() {
      _selectedType = last['type'] as String?;
      _commodityOptions = _selectedType != null
          ? _cache.getCommoditiesForType(_selectedType!)
          : [];
      _selectedCommodity = last['commodity'] as String?;
      _saleMethOptions = (_selectedType != null && _selectedCommodity != null)
          ? _cache.getSaleMethodsForCommodity(
              _selectedType!,
              _selectedCommodity!,
            )
          : [];
      _selectedSaleMeth = last['saleMeth'] as String?;
      _productFormOptions =
          (_selectedType != null &&
              _selectedCommodity != null &&
              _selectedSaleMeth != null)
          ? _cache.getProductFormsForSaleMethod(
              _selectedType!,
              _selectedCommodity!,
              _selectedSaleMeth!,
            )
          : [];
      _selectedProductForm = last['productForm'] as String?;
      if (_selectedType != null &&
          _selectedCommodity != null &&
          _selectedSaleMeth != null &&
          _selectedProductForm != null) {
        _pricingBasisOptions = _cache.getPricingBasisForCombo(
          _selectedType!,
          _selectedCommodity!,
          _selectedSaleMeth!,
          _selectedProductForm!,
        );
        _unitOptions = _cache.getUnitsForCombo(
          _selectedType!,
          _selectedCommodity!,
          _selectedSaleMeth!,
          _selectedProductForm!,
        );
        final commodityData = _cache.getCommodityDataForCombo(
          _selectedType!,
          _selectedCommodity!,
          _selectedSaleMeth!,
          _selectedProductForm!,
        );
        if (commodityData != null) {
          _maleRequired = commodityData.maleRequired ?? false;
          _femaleRequired = commodityData.femaleRequired ?? false;
          _totalWeightRequired = commodityData.totalWeightRequired ?? false;
          _totalAmountRequired = commodityData.totalPriceRequired ?? false;
          _expensesRequired = commodityData.expensesRequired ?? false;
        }
      }
      // also restore pricing basis and unit from saved entry
      _selectedPricingBasis = last['pricingBasis'] as String?;
      _selectedUnit = last['unit'] as String?;

      _maleCountCtrl.text = (last['maleCount'] ?? '') as String;
      _femaleCountCtrl.text = (last['femaleCount'] ?? '') as String;
      _weightCtrl.text = (last['totalWeight'] ?? '') as String;
      _amountCtrl.text = (last['totalAmount'] ?? '') as String;
      _expensesCtrl.text = (last['expenses'] ?? '') as String;
      _remarksCtrl.text = (last['remarks'] ?? '') as String;
    });
  }

  void _onTypeSelected(String? type) {
    setState(() {
      _selectedType = type;
      _selectedCommodity = null;
      _selectedSaleMeth = null;
      _selectedProductForm = null;
      _selectedPricingBasis = null;
      _selectedUnit = null;
      _productFormOptions = [];
      _pricingBasisOptions = [];
      _unitOptions = [];

      final commodities = type != null
          ? _cache.getCommoditiesForType(type)
          : <String>[];
      _commodityOptions = commodities;

      // Auto-select when only one commodity exists (ex: Corn)
      if (_selectedType != null && commodities.length == 1) {
        _selectedCommodity = commodities.first;
        _saleMethOptions = _cache.getSaleMethodsForCommodity(
          _selectedType!,
          _selectedCommodity!,
        );
      } else {
        _saleMethOptions = [];
      }
      _autoSaveToCurrentData();
    });
  }

  void _onCommoditySelected(String? commodity) {
    setState(() {
      _selectedCommodity = commodity;
      _selectedSaleMeth = null;
      _selectedProductForm = null;
      _selectedPricingBasis = null;
      _selectedUnit = null;
      _saleMethOptions = (_selectedType != null && commodity != null)
          ? _cache.getSaleMethodsForCommodity(_selectedType!, commodity)
          : [];
      _productFormOptions = [];
      _pricingBasisOptions = [];
      _unitOptions = [];
      _autoSaveToCurrentData();
    });
  }

  void _onSaleMethSelected(String? sale) {
    setState(() {
      _selectedSaleMeth = sale;
      _selectedProductForm = null;
      _selectedPricingBasis = null;
      _selectedUnit = null;
      _productFormOptions =
          (_selectedType != null && _selectedCommodity != null && sale != null)
          ? _cache.getProductFormsForSaleMethod(
              _selectedType!,
              _selectedCommodity!,
              sale,
            )
          : [];
      _pricingBasisOptions = [];
      _unitOptions = [];
      _autoSaveToCurrentData();
    });
  }

  void _onProductFormSelected(String? form) {
    setState(() {
      _selectedProductForm = form;
      _selectedPricingBasis = null;
      _selectedUnit = null;
      // Load pricing basis and units for this combo
      if (_selectedType != null &&
          _selectedCommodity != null &&
          _selectedSaleMeth != null &&
          form != null) {
        _pricingBasisOptions = _cache.getPricingBasisForCombo(
          _selectedType!,
          _selectedCommodity!,
          _selectedSaleMeth!,
          form,
        );
        _unitOptions = _cache.getUnitsForCombo(
          _selectedType!,
          _selectedCommodity!,
          _selectedSaleMeth!,
          form,
        );

        if (_pricingBasisOptions.length == 1) {
          _selectedPricingBasis = _pricingBasisOptions.first;
        }
        if (_unitOptions.length == 1) {
          _selectedUnit = _unitOptions.first;
        }

        // Load requirement flags from the commodity data
        final commodityData = _cache.getCommodityDataForCombo(
          _selectedType!,
          _selectedCommodity!,
          _selectedSaleMeth!,
          form,
        );
        if (commodityData != null) {
          _maleRequired = commodityData.maleRequired ?? false;
          _femaleRequired = commodityData.femaleRequired ?? false;
          _totalWeightRequired = commodityData.totalWeightRequired ?? false;
          _totalAmountRequired = commodityData.totalPriceRequired ?? false;
          _expensesRequired = commodityData.expensesRequired ?? false;

          if (!_maleRequired) {
            _maleCountCtrl.clear();
          }
          if (!_femaleRequired) {
            _femaleCountCtrl.clear();
          }
        }
      } else {
        _pricingBasisOptions = [];
        _unitOptions = [];
      }
      _autoSaveToCurrentData();
    });
  }

  void _onPricingBasisSelected(String? basis) {
    setState(() {
      _selectedPricingBasis = basis;
      if (_selectedType != null &&
          _selectedCommodity != null &&
          _selectedSaleMeth != null &&
          _selectedProductForm != null) {
        final commodityData = _cache.getCommodityDataForCombo(
          _selectedType!,
          _selectedCommodity!,
          _selectedSaleMeth!,
          _selectedProductForm!,
          pricingBasis: _selectedPricingBasis,
          unit: _selectedUnit,
        );
        if (commodityData != null) {
          _maleRequired = commodityData.maleRequired ?? false;
          _femaleRequired = commodityData.femaleRequired ?? false;
          _totalWeightRequired = commodityData.totalWeightRequired ?? false;
          _totalAmountRequired = commodityData.totalPriceRequired ?? false;
          _expensesRequired = commodityData.expensesRequired ?? false;
          if (!_maleRequired) _maleCountCtrl.clear();
          if (!_femaleRequired) _femaleCountCtrl.clear();
        }
      }
      _autoSaveToCurrentData();
    });
  }

  void _onUnitSelected(String? unit) {
    setState(() {
      _selectedUnit = unit;
      if (_selectedType != null &&
          _selectedCommodity != null &&
          _selectedSaleMeth != null &&
          _selectedProductForm != null) {
        final commodityData = _cache.getCommodityDataForCombo(
          _selectedType!,
          _selectedCommodity!,
          _selectedSaleMeth!,
          _selectedProductForm!,
          pricingBasis: _selectedPricingBasis,
          unit: _selectedUnit,
        );
        if (commodityData != null) {
          _maleRequired = commodityData.maleRequired ?? false;
          _femaleRequired = commodityData.femaleRequired ?? false;
          _totalWeightRequired = commodityData.totalWeightRequired ?? false;
          _totalAmountRequired = commodityData.totalPriceRequired ?? false;
          _expensesRequired = commodityData.expensesRequired ?? false;
          if (!_maleRequired) _maleCountCtrl.clear();
          if (!_femaleRequired) _femaleCountCtrl.clear();
        }
      }
      _autoSaveToCurrentData();
    });
  }

  /// Delete an entry from the list
  void _deleteEntry(int index) {
    setState(() {
      _addedCommodities.removeAt(index);
    });
  }

  void _loadData() {
    if (widget.currentData != null) {
      _selectedType = widget.currentData!.saadCommodityType;
    }
  }

  void _autoSaveToCurrentData() {
    if (widget.currentData != null) {
      // preserve type field for legacy behavior
      widget.currentData!.saadCommodityType = _selectedType;

      // compose a map for the current (unfinished) entry
      final Map<String, dynamic> current = {};
      final resolvedCurrentUnit =
          (_selectedUnit != null && _selectedUnit!.trim().isNotEmpty)
          ? _selectedUnit
          : (_unitOptions.isNotEmpty ? _unitOptions.first : null);
      if (_selectedType != null) current['type'] = _selectedType;
      if (_selectedCommodity != null) current['commodity'] = _selectedCommodity;
      if (_selectedSaleMeth != null) current['saleMeth'] = _selectedSaleMeth;
      if (_selectedProductForm != null) {
        current['productForm'] = _selectedProductForm;
      }
      if (_selectedPricingBasis != null) {
        current['pricingBasis'] = _selectedPricingBasis;
      }
      if (resolvedCurrentUnit != null) current['unit'] = resolvedCurrentUnit;
      if (_maleRequired) current['maleCount'] = _maleCountCtrl.text;
      if (_femaleRequired) current['femaleCount'] = _femaleCountCtrl.text;
      current['totalWeight'] = _weightCtrl.text;
      current['totalAmount'] = _amountCtrl.text;
      current['expenses'] = _expensesCtrl.text;
      current['remarks'] = _remarksCtrl.text;

      // combine with previously added entries and any dynamic forms
      final List<Map<String, dynamic>> allEntries = [];
      allEntries.addAll(_addedCommodities);
      for (final form in _additionalForms) {
        if (form.type != null) {
          final entry = <String, dynamic>{'type': form.type};
          final resolvedFormUnit =
              (form.unit != null && form.unit!.trim().isNotEmpty)
              ? form.unit
              : (form.unitOptions.isNotEmpty ? form.unitOptions.first : null);
          if (form.commodity != null) entry['commodity'] = form.commodity;
          if (form.saleMeth != null) entry['saleMeth'] = form.saleMeth;
          if (form.productForm != null) entry['productForm'] = form.productForm;
          if (form.pricingBasisOptions.isNotEmpty) {
            entry['pricingBasis'] = form.pricingBasisOptions.isNotEmpty
                ? form.pricingBasisOptions.first
                : null;
          }
          entry['unit'] = resolvedFormUnit;
          if (form.maleRequired) entry['maleCount'] = form.maleCtrl.text;
          if (form.femaleRequired) entry['femaleCount'] = form.femaleCtrl.text;
          entry['totalWeight'] = form.weightCtrl.text;
          entry['totalAmount'] = form.amountCtrl.text;
          entry['expenses'] = form.expensesCtrl.text;
          entry['remarks'] = form.remarksCtrl.text;
          allEntries.add(entry);
        }
      }
      if (_selectedType != null) {
        // only add current if some selection exists
        allEntries.add(current);
      }

      widget.currentData!.saadCommodities = allEntries;
    }
  }

  @override
  void didUpdateWidget(Step04SAAdIncome oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only load saved data when there is no user input on the page
    final hasInput =
        _selectedType != null ||
        _selectedCommodity != null ||
        _selectedSaleMeth != null ||
        _selectedProductForm != null ||
        _maleCountCtrl.text.isNotEmpty ||
        _femaleCountCtrl.text.isNotEmpty ||
        _weightCtrl.text.isNotEmpty ||
        _amountCtrl.text.isNotEmpty ||
        _expensesCtrl.text.isNotEmpty ||
        _remarksCtrl.text.isNotEmpty ||
        _addedCommodities.isNotEmpty;
    if (!hasInput) {
      _loadData();
    }
  }

  @override
  void dispose() {
    _maleCountCtrl.dispose();
    _femaleCountCtrl.dispose();
    _weightCtrl.dispose();
    _amountCtrl.dispose();
    _expensesCtrl.dispose();
    _remarksCtrl.dispose();
    for (final f in _additionalForms) {
      f.dispose();
    }
    super.dispose();
  }

  void _handleNext() {
    // Combine added full entries + additional dynamic forms + current form (if filled)
    final List<Map<String, dynamic>> allEntries = [];
    allEntries.addAll(_addedCommodities);
    // add additional dynamic forms
    for (final form in _additionalForms) {
      if (form.type != null) {
        final entry = <String, dynamic>{'type': form.type};
        final resolvedFormUnit =
            (form.unit != null && form.unit!.trim().isNotEmpty)
            ? form.unit
            : (form.unitOptions.isNotEmpty ? form.unitOptions.first : null);
        if (form.commodity != null) entry['commodity'] = form.commodity;
        if (form.saleMeth != null) entry['saleMeth'] = form.saleMeth;
        if (form.productForm != null) entry['productForm'] = form.productForm;
        if (form.pricingBasisOptions.isNotEmpty) {
          entry['pricingBasis'] = form.pricingBasisOptions.isNotEmpty
              ? form.pricingBasisOptions.first
              : null;
        }
        entry['unit'] = resolvedFormUnit;
        if (form.maleRequired) entry['maleCount'] = form.maleCtrl.text;
        if (form.femaleRequired) entry['femaleCount'] = form.femaleCtrl.text;
        entry['totalWeight'] = form.weightCtrl.text;
        entry['totalAmount'] = form.amountCtrl.text;
        entry['expenses'] = form.expensesCtrl.text;
        entry['remarks'] = form.remarksCtrl.text;
        allEntries.add(entry);
      }
    }
    // include current form
    if (_selectedType != null) {
      final resolvedCurrentUnit =
          (_selectedUnit != null && _selectedUnit!.trim().isNotEmpty)
          ? _selectedUnit
          : (_unitOptions.isNotEmpty ? _unitOptions.first : null);
      final current = <String, dynamic>{'type': _selectedType};
      if (_selectedCommodity != null) current['commodity'] = _selectedCommodity;
      if (_selectedSaleMeth != null) current['saleMeth'] = _selectedSaleMeth;
      if (_selectedProductForm != null) {
        current['productForm'] = _selectedProductForm;
      }
      current['pricingBasis'] = _selectedPricingBasis;
      current['unit'] = resolvedCurrentUnit;
      if (_maleRequired) current['maleCount'] = _maleCountCtrl.text;
      if (_femaleRequired) current['femaleCount'] = _femaleCountCtrl.text;
      current['totalWeight'] = _weightCtrl.text;
      current['totalAmount'] = _amountCtrl.text;
      current['expenses'] = _expensesCtrl.text;
      current['remarks'] = _remarksCtrl.text;
      allEntries.add(current);
    }

    if (widget.currentData != null) {
      widget.currentData!.saadCommodityType = _selectedType;
      widget.currentData!.saadCommodities = allEntries;
    }
    widget.onNext();
  }

  void _handleBack() {
    _autoSaveToCurrentData();
    widget.onBack();
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

    return ProfilingStepWrapper(
      currentStep: 4,
      sectionTitle: 'SAAD Commodity Type',
      onNext: _handleNext,
      onBack: _handleBack,
      onHeaderBack: _handleHeaderBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type and Commodity side-by-side (2 columns)
          Row(
            children: [
              // Type (left column)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Type', labelSize),
                    SizedBox(height: labelFieldGap),
                    SizedBox(
                      height: fieldHeight,
                      child: _shadowedDropdown(
                        value: _selectedType,
                        hint: 'Select Type',
                        items: _typeOptions,
                        onChanged: _onTypeSelected,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: fieldGap),
              // Commodity (right column)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Commodity', labelSize),
                    SizedBox(height: labelFieldGap),
                    SizedBox(
                      height: fieldHeight,
                      child: _shadowedDropdown(
                        value: _selectedCommodity,
                        hint: 'Select Commodity',
                        items: _commodityOptions,
                        onChanged: _onCommoditySelected,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Sale Method and Product Form (side-by-side, 2 columns)
          if (_saleMethOptions.isNotEmpty ||
              _productFormOptions.isNotEmpty) ...[
            SizedBox(height: labelFieldGap),
            Row(
              children: [
                if (_saleMethOptions.isNotEmpty)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Sale Method', labelSize - 1),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: fieldHeight,
                          child: _shadowedDropdown(
                            value: _selectedSaleMeth,
                            hint: 'Select Sale Method',
                            items: _saleMethOptions,
                            onChanged: _onSaleMethSelected,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_saleMethOptions.isNotEmpty &&
                    _productFormOptions.isNotEmpty)
                  SizedBox(width: fieldGap),
                if (_productFormOptions.isNotEmpty)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Product Form', labelSize - 1),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: fieldHeight,
                          child: _shadowedDropdown(
                            value: _selectedProductForm,
                            hint: 'Select Product Form',
                            items: _productFormOptions,
                            onChanged: _onProductFormSelected,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
          // Pricing Basis and Unit side-by-side
          if (_selectedProductForm != null &&
              _pricingBasisOptions.isNotEmpty) ...[
            SizedBox(height: labelFieldGap),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Pricing Basis', labelSize - 1),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: fieldHeight,
                        child: _shadowedDropdown(
                          value: _selectedPricingBasis,
                          hint: 'Select Pricing Basis',
                          items: _pricingBasisOptions,
                          onChanged: _onPricingBasisSelected,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_unitOptions.isNotEmpty) ...[
                  SizedBox(width: fieldGap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Unit', labelSize - 1),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: fieldHeight,
                          child: _shadowedDropdown(
                            value: _selectedUnit,
                            hint: 'Select Unit',
                            items: _unitOptions,
                            onChanged: _onUnitSelected,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
          // Data input fields (always show after product form selected)
          if (_selectedProductForm != null) ...[
            SizedBox(height: fieldGap),
            if (_maleRequired || _femaleRequired) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Male Count', labelSize - 1),
                        const SizedBox(height: 6),
                        _textField(
                          hintText: _maleRequired
                              ? 'Number of males (required)'
                              : 'Number of males',
                          onChanged: (val) {},
                          fieldHeight: fieldHeight,
                          controller: _maleCountCtrl,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: fieldGap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Female Count', labelSize - 1),
                        const SizedBox(height: 6),
                        _textField(
                          hintText: _femaleRequired
                              ? 'Number of females (required)'
                              : 'Number of females',
                          onChanged: (val) {},
                          fieldHeight: fieldHeight,
                          controller: _femaleCountCtrl,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: labelFieldGap),
            ],
            // Total Weight and Total Amount side-by-side
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Total Weight', labelSize - 1),
                      const SizedBox(height: 6),
                      _textField(
                        hintText: _totalWeightRequired
                            ? 'Total weight (required)'
                            : 'Total weight',
                        onChanged: (val) {},
                        fieldHeight: fieldHeight,
                        controller: _weightCtrl,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: fieldGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Total Amount', labelSize - 1),
                      const SizedBox(height: 6),
                      _textField(
                        hintText: _totalAmountRequired
                            ? 'Total amount (required)'
                            : 'Total amount',
                        onChanged: (val) {},
                        fieldHeight: fieldHeight,
                        controller: _amountCtrl,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: labelFieldGap),
            // Expenses and Remarks side-by-side
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Expenses', labelSize - 1),
                      const SizedBox(height: 6),
                      _textField(
                        hintText: _expensesRequired
                            ? 'Expenses (required)'
                            : 'Expenses',
                        onChanged: (val) {},
                        fieldHeight: fieldHeight,
                        controller: _expensesCtrl,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: fieldGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Remarks', labelSize - 1),
                      const SizedBox(height: 6),
                      _textField(
                        hintText: 'Remarks/notes',
                        onChanged: (val) {},
                        fieldHeight: fieldHeight,
                        controller: _remarksCtrl,
                        numericOnly: false,
                        multiline: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Add Another Commodity Button — create a full blank form
            SizedBox(height: fieldGap),
            GestureDetector(
              onTap: () {
                setState(() {
                  final f = _CommodityForm();
                  _additionalForms.add(f);
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: DAColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DAColors.primaryGreen, width: 2),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle,
                      color: DAColors.primaryGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add Another Commodity',
                      style: GoogleFonts.poppins(
                        fontSize: labelSize - 1,
                        fontWeight: FontWeight.w600,
                        color: DAColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Display dynamic additional forms
            if (_additionalForms.isNotEmpty) ...[
              SizedBox(height: fieldGap),
              _label('Additional Commodities', labelSize),
              SizedBox(height: fieldGap * 0.5),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _additionalForms.length,
                itemBuilder: (context, idx) {
                  final form = _additionalForms[idx];
                  return Container(
                    margin: EdgeInsets.only(bottom: fieldGap * 0.5),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: DAColors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Type', labelSize - 1),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    height: fieldHeight,
                                    child: _shadowedDropdown(
                                      value: form.type,
                                      hint: 'Select Type',
                                      items: _typeOptions,
                                      onChanged: (val) {
                                        setState(() {
                                          form.type = val;
                                          form.commodity = null;
                                          form.saleMeth = null;
                                          form.productForm = null;
                                          form.commodityOptions = val != null
                                              ? _cache.getCommoditiesForType(
                                                  val,
                                                )
                                              : [];
                                          form.saleMethOptions = [];
                                          form.productFormOptions = [];
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: fieldGap),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Commodity', labelSize - 1),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    height: fieldHeight,
                                    child: _shadowedDropdown(
                                      value: form.commodity,
                                      hint: 'Select Commodity',
                                      items: form.commodityOptions,
                                      onChanged: (val) {
                                        setState(() {
                                          form.commodity = val;
                                          form.saleMeth = null;
                                          form.productForm = null;
                                          form.saleMethOptions =
                                              (form.type != null && val != null)
                                              ? _cache
                                                    .getSaleMethodsForCommodity(
                                                      form.type!,
                                                      val,
                                                    )
                                              : [];
                                          form.productFormOptions = [];
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (form.saleMethOptions.isNotEmpty ||
                            form.productFormOptions.isNotEmpty) ...[
                          SizedBox(height: labelFieldGap),
                          Row(
                            children: [
                              if (form.saleMethOptions.isNotEmpty)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _label('Sale Method', labelSize - 1),
                                      const SizedBox(height: 6),
                                      SizedBox(
                                        height: fieldHeight,
                                        child: _shadowedDropdown(
                                          value: form.saleMeth,
                                          hint: 'Select Sale Method',
                                          items: form.saleMethOptions,
                                          onChanged: (val) {
                                            setState(() {
                                              form.saleMeth = val;
                                              form.productForm = null;
                                              form.productFormOptions =
                                                  (form.type != null &&
                                                      form.commodity != null &&
                                                      val != null)
                                                  ? _cache
                                                        .getProductFormsForSaleMethod(
                                                          form.type!,
                                                          form.commodity!,
                                                          val,
                                                        )
                                                  : [];
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (form.saleMethOptions.isNotEmpty &&
                                  form.productFormOptions.isNotEmpty)
                                SizedBox(width: fieldGap),
                              if (form.productFormOptions.isNotEmpty)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _label('Product Form', labelSize - 1),
                                      const SizedBox(height: 6),
                                      SizedBox(
                                        height: fieldHeight,
                                        child: _shadowedDropdown(
                                          value: form.productForm,
                                          hint: 'Select Product Form',
                                          items: form.productFormOptions,
                                          onChanged: (val) {
                                            setState(() {
                                              form.productForm = val;
                                              if (form.type != null &&
                                                  form.commodity != null &&
                                                  form.saleMeth != null &&
                                                  val != null) {
                                                form.pricingBasisOptions = _cache
                                                    .getPricingBasisForCombo(
                                                      form.type!,
                                                      form.commodity!,
                                                      form.saleMeth!,
                                                      val,
                                                    );
                                                form.unitOptions = _cache
                                                    .getUnitsForCombo(
                                                      form.type!,
                                                      form.commodity!,
                                                      form.saleMeth!,
                                                      val,
                                                    );
                                                final commodityData = _cache
                                                    .getCommodityDataForCombo(
                                                      form.type!,
                                                      form.commodity!,
                                                      form.saleMeth!,
                                                      val,
                                                    );
                                                if (commodityData != null) {
                                                  form.maleRequired =
                                                      commodityData
                                                          .maleRequired ??
                                                      false;
                                                  form.femaleRequired =
                                                      commodityData
                                                          .femaleRequired ??
                                                      false;
                                                  form.totalWeightRequired =
                                                      commodityData
                                                          .totalWeightRequired ??
                                                      false;
                                                  form.totalAmountRequired =
                                                      commodityData
                                                          .totalPriceRequired ??
                                                      false;
                                                  form.expensesRequired =
                                                      commodityData
                                                          .expensesRequired ??
                                                      false;

                                                  if (!form.maleRequired) {
                                                    form.maleCtrl.clear();
                                                  }
                                                  if (!form.femaleRequired) {
                                                    form.femaleCtrl.clear();
                                                  }
                                                }
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                        if (form.productForm != null) ...[
                          SizedBox(height: fieldGap),
                          if (form.maleRequired || form.femaleRequired) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _label('Male Count', labelSize - 1),
                                      const SizedBox(height: 6),
                                      _textField(
                                        hintText: form.maleRequired
                                            ? 'Number of males (required)'
                                            : 'Number of males',
                                        onChanged: (v) {},
                                        fieldHeight: fieldHeight,
                                        controller: form.maleCtrl,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: fieldGap),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _label('Female Count', labelSize - 1),
                                      const SizedBox(height: 6),
                                      _textField(
                                        hintText: form.femaleRequired
                                            ? 'Number of females (required)'
                                            : 'Number of females',
                                        onChanged: (v) {},
                                        fieldHeight: fieldHeight,
                                        controller: form.femaleCtrl,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: labelFieldGap),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _label('Total Weight', labelSize - 1),
                                    const SizedBox(height: 6),
                                    _textField(
                                      hintText: form.totalWeightRequired
                                          ? 'Total weight (required)'
                                          : 'Total weight',
                                      onChanged: (v) {},
                                      fieldHeight: fieldHeight,
                                      controller: form.weightCtrl,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: fieldGap),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _label('Total Amount', labelSize - 1),
                                    const SizedBox(height: 6),
                                    _textField(
                                      hintText: form.totalAmountRequired
                                          ? 'Total amount (required)'
                                          : 'Total amount',
                                      onChanged: (v) {},
                                      fieldHeight: fieldHeight,
                                      controller: form.amountCtrl,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: labelFieldGap),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _label('Expenses', labelSize - 1),
                                    const SizedBox(height: 6),
                                    _textField(
                                      hintText: form.expensesRequired
                                          ? 'Expenses (required)'
                                          : 'Expenses',
                                      onChanged: (v) {},
                                      fieldHeight: fieldHeight,
                                      controller: form.expensesCtrl,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: fieldGap),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _label('Remarks', labelSize - 1),
                                    const SizedBox(height: 6),
                                    _textField(
                                      hintText: 'Remarks/notes',
                                      onChanged: (v) {},
                                      fieldHeight: fieldHeight,
                                      controller: form.remarksCtrl,
                                      numericOnly: false,
                                      multiline: true,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: Icon(Icons.delete, color: DAColors.red),
                            onPressed: () => setState(() {
                              _additionalForms.removeAt(idx);
                            }),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],

            // Display added commodities
            if (_addedCommodities.isNotEmpty) ...[
              SizedBox(height: fieldGap),
              _label('Added Commodities', labelSize),
              SizedBox(height: fieldGap * 0.5),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _addedCommodities.length,
                itemBuilder: (context, index) {
                  final commodity = _addedCommodities[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: fieldGap * 0.5),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: DAColors.lightGrey,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: DAColors.primaryGreen,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${commodity['type']} / ${commodity['commodity']}',
                                style: GoogleFonts.poppins(
                                  fontSize: labelSize - 2,
                                  fontWeight: FontWeight.w600,
                                  color: DAColors.black,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '${commodity['productForm']} (${commodity['unit']})',
                                style: GoogleFonts.poppins(
                                  fontSize: labelSize - 3,
                                  color: Colors.grey,
                                ),
                              ),
                              if ((commodity['maleCount'] as String)
                                      .isNotEmpty ||
                                  (commodity['femaleCount'] as String)
                                      .isNotEmpty ||
                                  (commodity['weight'] as String).isNotEmpty ||
                                  (commodity['amount'] as String).isNotEmpty)
                                SizedBox(height: 4),
                              if ((commodity['maleCount'] as String)
                                      .isNotEmpty ||
                                  (commodity['femaleCount'] as String)
                                      .isNotEmpty ||
                                  (commodity['weight'] as String).isNotEmpty ||
                                  (commodity['amount'] as String).isNotEmpty)
                                Text(
                                  'M: ${commodity['maleCount']} F: ${commodity['femaleCount']} W: ${commodity['weight']} A: ${commodity['amount']}',
                                  style: GoogleFonts.poppins(
                                    fontSize: labelSize - 3,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: DAColors.red),
                          onPressed: () => _deleteEntry(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
          SizedBox(height: fieldGap),
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

  Widget _textField({
    required String hintText,
    required ValueChanged<String> onChanged,
    required double fieldHeight,
    TextEditingController? controller,
    bool numericOnly = true,
    bool multiline = false,
  }) {
    return Container(
      height: multiline ? null : fieldHeight,
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
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: multiline
            ? TextInputType.multiline
            : numericOnly
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        inputFormatters: (numericOnly && !multiline)
            ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
            : null,
        minLines: multiline ? 3 : 1,
        maxLines: multiline ? null : 1,
        decoration: InputDecoration(
          hintText: hintText,
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
      ),
    );
  }

  Widget _shadowedDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final normalizedItems = <String>[];
    final seen = <String>{};
    for (final raw in items) {
      final item = raw.trim();
      if (item.isEmpty) continue;
      if (seen.add(item)) {
        normalizedItems.add(item);
      }
    }

    final normalizedValue = value?.trim();
    final safeValue =
        (normalizedValue != null && normalizedItems.contains(normalizedValue))
        ? normalizedValue
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
        isExpanded: true,
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
        menuMaxHeight: 320,
        selectedItemBuilder: (context) {
          return normalizedItems.map((item) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(item, maxLines: 1, overflow: TextOverflow.ellipsis),
            );
          }).toList();
        },
        items: normalizedItems.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item, maxLines: 1, overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
