import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:da_project_1/models/commodity_data.dart';

/// LocalCommodityCache — Caches commodity data locally for offline use
class LocalCommodityCache {
  static final LocalCommodityCache _instance = LocalCommodityCache._internal();

  static const String _commodityKey = 'cached_commodities';
  late SharedPreferences _prefs;
  List<CommodityData> _cache = [];
  bool _isInitialized = false;

  String _norm(String? value) {
    final raw = (value ?? '').trim().toLowerCase();
    if (raw.isEmpty) return '';
    final collapsed = raw.replaceAll(RegExp(r'\s+'), ' ');
    if (collapsed == 'per kilo' || collapsed == 'per kg') {
      return 'per kilogram';
    }
    return collapsed;
  }

  bool _eq(String? left, String? right) => _norm(left) == _norm(right);

  LocalCommodityCache._internal();

  factory LocalCommodityCache() {
    return _instance;
  }

  /// Initialize cache with SharedPreferences
  Future<void> init() async {
    if (_isInitialized) return;
    _prefs = await SharedPreferences.getInstance();
    _loadFromStorage();
    _isInitialized = true;
  }

  /// Save commodities to local storage
  Future<void> saveCommodities(List<CommodityData> commodities) async {
    try {
      _cache = commodities;
      final jsonList = commodities
          .map((c) => jsonEncode(c.toFirestore()))
          .toList();
      await _prefs.setStringList(_commodityKey, jsonList);
    } catch (e) {
      print('❌ Error saving commodities to cache: $e');
    }
  }

  /// Load commodities from local storage
  void _loadFromStorage() {
    try {
      final jsonList = _prefs.getStringList(_commodityKey) ?? [];
      _cache = jsonList
          .map(
            (json) => CommodityData.fromFirestore(
              jsonDecode(json) as Map<String, dynamic>,
              '',
            ),
          )
          .toList();
      print('✅ Loaded ${_cache.length} commodities from cache');
    } catch (e) {
      print('❌ Error loading commodities from cache: $e');
      _cache = [];
    }
  }

  /// Get all cached commodities
  List<CommodityData> getAllCached() => _cache;

  List<String> _cleanUnique(Iterable<String?> values) {
    final unique = <String>[];
    final seen = <String>{};
    for (final raw in values) {
      final value = raw?.trim() ?? '';
      if (value.isEmpty) continue;
      if (seen.add(value)) {
        unique.add(value);
      }
    }
    unique.sort();
    return unique;
  }

  /// Get unique types
  List<String> getTypes() {
    final types = _cleanUnique(_cache.map((c) => c.type));
    print('✅ Cached types: $types (${types.length} unique)');
    return types;
  }

  /// Get commodities for a type
  ///
  /// Some datasets use the same value for `type` and `commodity`
  /// (for example: type=Corn, commodity=Corn). We keep those values so
  /// the commodity dropdown is still populated and the next dropdowns appear.
  List<String> getCommoditiesForType(String type) => _cleanUnique(
    _cache.where((c) => _eq(c.type, type)).map((c) => c.commodity),
  );

  /// Get sale methods for commodity
  List<String> getSaleMethodsForCommodity(String type, String commodity) =>
      _cleanUnique(
        _cache
            .where((c) => _eq(c.type, type) && _eq(c.commodity, commodity))
            .map((c) => c.saleMeth),
      );

  /// Get product forms for sale method
  List<String> getProductFormsForSaleMethod(
    String type,
    String commodity,
    String saleMethod,
  ) => _cleanUnique(
    _cache
        .where(
          (c) =>
              _eq(c.type, type) &&
              _eq(c.commodity, commodity) &&
              _eq(c.saleMeth, saleMethod),
        )
        .map((c) => c.productForm),
  );

  /// Get pricing bases for a specific combo
  List<String> getPricingBasisForCombo(
    String type,
    String commodity,
    String saleMethod,
    String productForm,
  ) => _cleanUnique(
    _cache
        .where(
          (c) =>
              _eq(c.type, type) &&
              _eq(c.commodity, commodity) &&
              _eq(c.saleMeth, saleMethod) &&
              _eq(c.productForm, productForm),
        )
        .map((c) => c.pricingBasis),
  );

  /// Get units for a specific combo
  List<String> getUnitsForCombo(
    String type,
    String commodity,
    String saleMethod,
    String productForm,
  ) => _cleanUnique(
    _cache
        .where(
          (c) =>
              _eq(c.type, type) &&
              _eq(c.commodity, commodity) &&
              _eq(c.saleMeth, saleMethod) &&
              _eq(c.productForm, productForm),
        )
        .map((c) => c.unit),
  );

  /// Get commodity data object for a specific combo (to access requirement flags)
  CommodityData? getCommodityDataForCombo(
    String type,
    String commodity,
    String saleMethod,
    String productForm, {
    String? pricingBasis,
    String? unit,
  }) {
    final matches = _cache.where((c) {
      final comboMatch =
          _eq(c.type, type) &&
          _eq(c.commodity, commodity) &&
          _eq(c.saleMeth, saleMethod) &&
          _eq(c.productForm, productForm);
      if (!comboMatch) return false;
      if (pricingBasis != null && pricingBasis.trim().isNotEmpty) {
        if (!_eq(c.pricingBasis, pricingBasis)) return false;
      }
      if (unit != null && unit.trim().isNotEmpty) {
        if (!_eq(c.unit, unit)) return false;
      }
      return true;
    }).toList();

    if (matches.isEmpty) {
      return null;
    }

    final first = matches.first;
    final aggregated = CommodityData(
      id: first.id,
      type: first.type,
      commodity: first.commodity,
      saleMeth: first.saleMeth,
      productForm: first.productForm,
      pricingBasis: first.pricingBasis,
      unit: first.unit,
      maleRequired: matches.any((m) => m.maleRequired == true),
      femaleRequired: matches.any((m) => m.femaleRequired == true),
      totalWeightRequired: matches.any((m) => m.totalWeightRequired == true),
      totalPriceRequired: matches.any((m) => m.totalPriceRequired == true),
      expensesRequired: matches.any((m) => m.expensesRequired == true),
      remarks: first.remarks,
      createdAt: first.createdAt,
      updatedAt: first.updatedAt,
    );
    return aggregated;
  }

  /// Get pricing bases
  List<String> getPricingBases() =>
      _cleanUnique(_cache.map((c) => c.pricingBasis));

  /// Get units
  List<String> getUnits() => _cleanUnique(_cache.map((c) => c.unit));

  /// Clear cache
  Future<void> clearCache() async {
    _cache = [];
    await _prefs.remove(_commodityKey);
  }
}
