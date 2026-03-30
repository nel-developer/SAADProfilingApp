import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:da_project_1/models/commodity_data.dart';
import 'package:da_project_1/services/local_commodity_cache.dart';

/// CommodityService — Manages commodity data in Firestore
/// Provides CRUD operations for admin commodity management
class CommodityService {
  static final CommodityService _instance = CommodityService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  static const String _collectionName = 'commodities';

  CommodityService._internal();

  factory CommodityService() {
    return _instance;
  }

  String _normalizeKeyPart(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    if (normalized.isEmpty) return '';
    return normalized.replaceAll(RegExp(r'\s+'), ' ');
  }

  String _compositeCommodityKey(CommodityData data) {
    return [
      _normalizeKeyPart(data.type),
      _normalizeKeyPart(data.commodity),
      _normalizeKeyPart(data.saleMeth),
      _normalizeKeyPart(data.productForm),
      _normalizeKeyPart(data.pricingBasis),
      _normalizeKeyPart(data.unit),
    ].join('|');
  }

  DateTime _latestTimestamp(CommodityData data) {
    return data.updatedAt ??
        data.createdAt ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  CommodityData _mergeDuplicateCommodity(CommodityData a, CommodityData b) {
    final winner = _latestTimestamp(a).isAfter(_latestTimestamp(b)) ? a : b;
    final loser = identical(winner, a) ? b : a;
    return winner.copyWith(
      maleRequired: (a.maleRequired == true) || (b.maleRequired == true),
      femaleRequired: (a.femaleRequired == true) || (b.femaleRequired == true),
      totalWeightRequired:
          (a.totalWeightRequired == true) || (b.totalWeightRequired == true),
      totalPriceRequired:
          (a.totalPriceRequired == true) || (b.totalPriceRequired == true),
      expensesRequired:
          (a.expensesRequired == true) || (b.expensesRequired == true),
      remarks: (winner.remarks ?? '').trim().isNotEmpty
          ? winner.remarks
          : loser.remarks,
      updatedAt: _latestTimestamp(winner),
    );
  }

  DateTime? _parseDynamicTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _compositeMapKey(Map<String, dynamic> data) {
    return [
      _normalizeKeyPart(data['type'] as String?),
      _normalizeKeyPart(data['commodity'] as String?),
      _normalizeKeyPart(data['saleMeth'] as String?),
      _normalizeKeyPart(data['productForm'] as String?),
      _normalizeKeyPart(data['pricingBasis'] as String?),
      _normalizeKeyPart(data['unit'] as String?),
    ].join('|');
  }

  Future<void> _ensureCommodityAdminAccess() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('No user logged in.');
    }

    final userDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get(const GetOptions(source: Source.server));
    final role = (userDoc.data()?['role'] as String?)?.toLowerCase();

    if (role != 'admin') {
      throw Exception('Only admins can manage commodities.');
    }
  }

  List<CommodityData> _defaultCommodityFallback() {
    final now = DateTime.now();
    return [
      CommodityData(
        type: 'Livestock',
        commodity: 'Swine',
        saleMeth: 'Live Animal',
        productForm: 'Weaner',
        pricingBasis: 'Per Head',
        unit: 'Head',
        maleRequired: true,
        femaleRequired: true,
        totalWeightRequired: false,
        totalPriceRequired: false,
        expensesRequired: false,
        createdAt: now,
        updatedAt: now,
      ),
      CommodityData(
        type: 'Poultry',
        commodity: 'Chicken',
        saleMeth: 'Live Animal',
        productForm: 'Live weight',
        pricingBasis: 'Per Kilogram',
        unit: 'Kilograms',
        maleRequired: false,
        femaleRequired: false,
        totalWeightRequired: false,
        totalPriceRequired: false,
        expensesRequired: false,
        createdAt: now,
        updatedAt: now,
      ),
      CommodityData(
        type: 'High Value Crops',
        commodity: 'Any Vegetable',
        saleMeth: 'Fresh Produce',
        productForm: 'Fresh Produce',
        pricingBasis: 'Per Kilogram',
        unit: 'Kilograms',
        maleRequired: false,
        femaleRequired: false,
        totalWeightRequired: false,
        totalPriceRequired: false,
        expensesRequired: false,
        createdAt: now,
        updatedAt: now,
      ),
      CommodityData(
        type: 'Corn',
        commodity: 'Corn',
        saleMeth: 'Fresh Produce',
        productForm: 'Shelled Corn',
        pricingBasis: 'Per Kilogram',
        unit: 'Kilograms',
        maleRequired: false,
        femaleRequired: false,
        totalWeightRequired: false,
        totalPriceRequired: false,
        expensesRequired: false,
        createdAt: now,
        updatedAt: now,
      ),
      CommodityData(
        type: 'Rice',
        commodity: 'Rice',
        saleMeth: 'Fresh Produce',
        productForm: 'Palay',
        pricingBasis: 'Per Kilogram',
        unit: 'Kilograms',
        maleRequired: false,
        femaleRequired: false,
        totalWeightRequired: false,
        totalPriceRequired: false,
        expensesRequired: false,
        createdAt: now,
        updatedAt: now,
      ),
      CommodityData(
        type: 'Others',
        commodity: 'Others',
        saleMeth: 'Direct Sale',
        productForm: 'Mixed Produce',
        pricingBasis: 'Per Unit',
        unit: 'Unit',
        maleRequired: false,
        femaleRequired: false,
        totalWeightRequired: false,
        totalPriceRequired: false,
        expensesRequired: false,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  Future<List<CommodityData>> _loadFallbackAndCache() async {
    final fallback = _defaultCommodityFallback();
    final cache = LocalCommodityCache();
    await cache.saveCommodities(fallback);
    debugPrint(
      '✅ Loaded built-in commodity fallback (${fallback.length} items)',
    );
    return fallback;
  }

  /// Create a new commodity
  Future<String> addCommodity(CommodityData data) async {
    try {
      await _ensureCommodityAdminAccess();
      final now = DateTime.now();
      data.createdAt = now;
      data.updatedAt = now;

      final docRef = await _firestore
          .collection(_collectionName)
          .add(data.toFirestore());
      debugPrint('✅ Commodity added: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error adding commodity: $e');
      rethrow;
    }
  }

  /// Get all commodities (with offline caching)
  Future<List<CommodityData>> getAllCommodities() async {
    try {
      // Fetch all documents and sort client-side to avoid composite index requirement
      final snapshot = await _firestore.collection(_collectionName).get();

      final rawCommodities = <CommodityData>[];
      for (final doc in snapshot.docs) {
        try {
          final data = CommodityData.fromFirestore(doc.data(), doc.id);
          rawCommodities.add(data);
        } catch (e) {
          debugPrint('⚠️ Failed to parse commodity ${doc.id}: $e');
        }
      }

      final dedupedByKey = <String, CommodityData>{};
      for (final commodity in rawCommodities) {
        final key = _compositeCommodityKey(commodity);
        final existing = dedupedByKey[key];
        if (existing == null) {
          dedupedByKey[key] = commodity;
        } else {
          dedupedByKey[key] = _mergeDuplicateCommodity(existing, commodity);
        }
      }

      final commodities = dedupedByKey.values.toList();

      // Sort by type, then commodity, then saleMeth, then productForm
      commodities.sort((a, b) {
        final typeCmp = (a.type ?? '').compareTo(b.type ?? '');
        if (typeCmp != 0) return typeCmp;
        final commCmp = (a.commodity ?? '').compareTo(b.commodity ?? '');
        if (commCmp != 0) return commCmp;
        final saleCmp = (a.saleMeth ?? '').compareTo(b.saleMeth ?? '');
        if (saleCmp != 0) return saleCmp;
        return (a.productForm ?? '').compareTo(b.productForm ?? '');
      });

      final removedCount = rawCommodities.length - commodities.length;
      debugPrint(
        '✅ Loaded ${commodities.length} commodities (client-sorted, removed $removedCount duplicate entries in-memory)',
      );

      // Cache to local storage for offline use
      try {
        final cache = LocalCommodityCache();
        await cache.saveCommodities(commodities);
      } catch (e) {
        debugPrint('⚠️ Failed to cache commodities: $e');
      }

      return commodities;
    } catch (e) {
      debugPrint('❌ Error loading commodities: $e');
      final cached = LocalCommodityCache().getAllCached();
      if (cached.isNotEmpty) {
        debugPrint('✅ Returning cached commodities (${cached.length} items)');
        return cached;
      }

      // Final fallback for first-login/non-admin-denied scenario
      return _loadFallbackAndCache();
    }
  }

  /// Get commodities by category (primary commodity)
  Future<List<CommodityData>> getCommoditiesByCategory(String category) async {
    try {
      // Avoid requiring a composite index by fetching matches and sorting client-side
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('commodity', isEqualTo: category)
          .get();

      final commodities = <CommodityData>[];
      for (final doc in snapshot.docs) {
        try {
          final data = CommodityData.fromFirestore(doc.data(), doc.id);
          commodities.add(data);
        } catch (e) {
          debugPrint('⚠️ Failed to parse commodity ${doc.id}: $e');
        }
      }

      commodities.sort(
        (a, b) => (a.productForm ?? '').compareTo(b.productForm ?? ''),
      );
      debugPrint(
        '✅ Loaded ${commodities.length} commodities for category: $category (client-sorted)',
      );
      return commodities;
    } catch (e) {
      debugPrint('❌ Error loading commodities by category: $e');
      return [];
    }
  }

  /// Update a commodity
  Future<bool> updateCommodity(String docId, CommodityData data) async {
    try {
      await _ensureCommodityAdminAccess();
      data.updatedAt = DateTime.now();

      await _firestore
          .collection(_collectionName)
          .doc(docId)
          .update(data.toFirestore());
      debugPrint('✅ Commodity updated: $docId');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating commodity: $e');
      return false;
    }
  }

  /// Delete a commodity
  Future<bool> deleteCommodity(String docId) async {
    try {
      await _ensureCommodityAdminAccess();
      await _firestore.collection(_collectionName).doc(docId).delete();
      debugPrint('✅ Commodity deleted: $docId');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting commodity: $e');
      return false;
    }
  }

  /// Get unique commodity categories
  Future<List<String>> getUniqueCommodities() async {
    try {
      final snapshot = await _firestore.collection(_collectionName).get();
      final categories = <String>{};

      for (final doc in snapshot.docs) {
        try {
          final commodity = doc.data()['commodity'] as String?;
          if (commodity != null && commodity.isNotEmpty) {
            categories.add(commodity);
          }
        } catch (_) {}
      }

      final sorted = categories.toList()..sort();
      debugPrint('✅ Found ${sorted.length} unique commodity categories');
      return sorted;
    } catch (e) {
      debugPrint('❌ Error getting unique commodities: $e');
      return [];
    }
  }

  /// Delete duplicate commodity documents in Firestore (admin only)
  /// Duplicate key: type + commodity + saleMeth + productForm + pricingBasis + unit
  /// Returns number of deleted documents.
  Future<int> deleteDuplicateCommodities() async {
    try {
      await _ensureCommodityAdminAccess();

      final snapshot = await _firestore.collection(_collectionName).get();
      final docsByKey = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
      final mergedFlagsByKeeper = <String, Map<String, bool>>{};
      final deleteIds = <String>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final key = _compositeMapKey(data);
        final existing = docsByKey[key];

        if (existing == null) {
          docsByKey[key] = doc;
          mergedFlagsByKeeper[doc.id] = {
            'maleRequired': data['maleRequired'] == true,
            'femaleRequired': data['femaleRequired'] == true,
            'totalWeightRequired': data['totalWeightRequired'] == true,
            'totalPriceRequired': data['totalPriceRequired'] == true,
            'expensesRequired': data['expensesRequired'] == true,
          };
          continue;
        }

        final existingData = existing.data();
        final existingTs =
            _parseDynamicTimestamp(existingData['updatedAt']) ??
            _parseDynamicTimestamp(existingData['createdAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final currentTs =
            _parseDynamicTimestamp(data['updatedAt']) ??
            _parseDynamicTimestamp(data['createdAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0);

        QueryDocumentSnapshot<Map<String, dynamic>> keeper = existing;
        QueryDocumentSnapshot<Map<String, dynamic>> duplicate = doc;
        if (currentTs.isAfter(existingTs)) {
          keeper = doc;
          duplicate = existing;
          docsByKey[key] = doc;
        }

        final keeperFlags =
            mergedFlagsByKeeper[keeper.id] ??
            {
              'maleRequired': false,
              'femaleRequired': false,
              'totalWeightRequired': false,
              'totalPriceRequired': false,
              'expensesRequired': false,
            };
        keeperFlags['maleRequired'] =
            keeperFlags['maleRequired'] == true ||
            (existingData['maleRequired'] == true) ||
            (data['maleRequired'] == true);
        keeperFlags['femaleRequired'] =
            keeperFlags['femaleRequired'] == true ||
            (existingData['femaleRequired'] == true) ||
            (data['femaleRequired'] == true);
        keeperFlags['totalWeightRequired'] =
            keeperFlags['totalWeightRequired'] == true ||
            (existingData['totalWeightRequired'] == true) ||
            (data['totalWeightRequired'] == true);
        keeperFlags['totalPriceRequired'] =
            keeperFlags['totalPriceRequired'] == true ||
            (existingData['totalPriceRequired'] == true) ||
            (data['totalPriceRequired'] == true);
        keeperFlags['expensesRequired'] =
            keeperFlags['expensesRequired'] == true ||
            (existingData['expensesRequired'] == true) ||
            (data['expensesRequired'] == true);
        mergedFlagsByKeeper[keeper.id] = keeperFlags;

        deleteIds.add(duplicate.id);
      }

      if (deleteIds.isEmpty) {
        debugPrint('✅ No duplicate commodities found in Firestore');
        return 0;
      }

      var batch = _firestore.batch();
      var opCount = 0;

      for (final entry in docsByKey.entries) {
        final keeper = entry.value;
        final flags = mergedFlagsByKeeper[keeper.id];
        if (flags == null) continue;

        batch.update(keeper.reference, {
          'maleRequired': flags['maleRequired'] == true,
          'femaleRequired': flags['femaleRequired'] == true,
          'totalWeightRequired': flags['totalWeightRequired'] == true,
          'totalPriceRequired': flags['totalPriceRequired'] == true,
          'expensesRequired': flags['expensesRequired'] == true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        opCount++;
        if (opCount >= 450) {
          await batch.commit();
          batch = _firestore.batch();
          opCount = 0;
        }
      }

      for (final id in deleteIds) {
        batch.delete(_firestore.collection(_collectionName).doc(id));
        opCount++;
        if (opCount >= 450) {
          await batch.commit();
          batch = _firestore.batch();
          opCount = 0;
        }
      }

      if (opCount > 0) {
        await batch.commit();
      }

      debugPrint(
        '✅ Deleted ${deleteIds.length} duplicate commodity document(s)',
      );
      return deleteIds.length;
    } catch (e) {
      debugPrint('❌ Error deleting duplicate commodities: $e');
      rethrow;
    }
  }

  /// Clear all commodities (admin reset)
  Future<bool> clearAllCommodities() async {
    try {
      await _ensureCommodityAdminAccess();
      // Delete all from Firestore
      final snapshot = await _firestore.collection(_collectionName).get();
      for (final doc in snapshot.docs) {
        await _firestore.collection(_collectionName).doc(doc.id).delete();
      }

      // Clear local cache
      try {
        final cache = LocalCommodityCache();
        await cache.clearCache();
      } catch (e) {
        debugPrint('⚠️ Failed to clear local cache: $e');
      }

      debugPrint('✅ All commodities cleared (Firestore + local cache)');
      return true;
    } catch (e) {
      debugPrint('❌ Error clearing commodities: $e');
      return false;
    }
  }

  /// Bootstrap: One-time sync from Firestore to local cache (on first login if online)
  /// Returns true if bootstrap succeeded or cache already populated, false if failed
  Future<bool> bootstrapCacheIfEmpty() async {
    try {
      final cache = LocalCommodityCache();

      // Check if cache already has data
      final cached = cache.getAllCached();
      if (cached.isNotEmpty) {
        debugPrint('✅ Cache already populated (${cached.length} items)');
        return true;
      }

      debugPrint('📥 Cache empty. Bootstrapping from Firestore...');

      // Fetch all commodities from Firestore
      final snapshot = await _firestore.collection(_collectionName).get();
      final commodities = <CommodityData>[];

      for (final doc in snapshot.docs) {
        try {
          final data = CommodityData.fromFirestore(doc.data(), doc.id);
          commodities.add(data);
        } catch (e) {
          debugPrint('⚠️ Failed to parse commodity ${doc.id}: $e');
        }
      }

      if (commodities.isEmpty) {
        debugPrint('⚠️ No commodities found in Firestore');
        return false;
      }

      // Sort by type, then commodity, then saleMeth, then productForm
      commodities.sort((a, b) {
        final typeCmp = (a.type ?? '').compareTo(b.type ?? '');
        if (typeCmp != 0) return typeCmp;
        final commCmp = (a.commodity ?? '').compareTo(b.commodity ?? '');
        if (commCmp != 0) return commCmp;
        final saleCmp = (a.saleMeth ?? '').compareTo(b.saleMeth ?? '');
        if (saleCmp != 0) return saleCmp;
        return (a.productForm ?? '').compareTo(b.productForm ?? '');
      });

      // Save to local cache
      await cache.saveCommodities(commodities);
      debugPrint(
        '✅ Bootstrap complete: ${commodities.length} commodities cached',
      );
      return true;
    } catch (e) {
      debugPrint('❌ Bootstrap failed: $e');
      final cached = LocalCommodityCache().getAllCached();
      if (cached.isNotEmpty) {
        return true;
      }

      try {
        await _loadFallbackAndCache();
        return true;
      } catch (fallbackError) {
        debugPrint('❌ Fallback bootstrap failed: $fallbackError');
        return false;
      }
    }
  }
}
