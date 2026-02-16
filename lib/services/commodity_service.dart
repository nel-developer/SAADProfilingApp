import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:da_project_1/models/commodity_data.dart';

/// CommodityService — Manages commodity data in Firestore
/// Provides CRUD operations for admin commodity management
class CommodityService {
  static final CommodityService _instance = CommodityService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'commodities';

  CommodityService._internal();

  factory CommodityService() {
    return _instance;
  }

  /// Create a new commodity
  Future<String> addCommodity(CommodityData data) async {
    try {
      final now = DateTime.now();
      data.createdAt = now;
      data.updatedAt = now;

      final docRef = await _firestore.collection(_collectionName).add(data.toFirestore());
      debugPrint('✅ Commodity added: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error adding commodity: $e');
      rethrow;
    }
  }

  /// Get all commodities
  Future<List<CommodityData>> getAllCommodities() async {
    try {
      // Fetch all documents and sort client-side to avoid composite index requirement
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

      debugPrint('✅ Loaded ${commodities.length} commodities (client-sorted)');
      return commodities;
    } catch (e) {
      debugPrint('❌ Error loading commodities: $e');
      return [];
    }
  }

  /// Get commodities by category (primary commodity)
  Future<List<CommodityData>> getCommoditiesByCategory(String category) async {
    try {
      // Avoid requiring a composite index by fetching matches and sorting client-side
      final snapshot = await _firestore.collection(_collectionName).where('commodity', isEqualTo: category).get();

      final commodities = <CommodityData>[];
      for (final doc in snapshot.docs) {
        try {
          final data = CommodityData.fromFirestore(doc.data(), doc.id);
          commodities.add(data);
        } catch (e) {
          debugPrint('⚠️ Failed to parse commodity ${doc.id}: $e');
        }
      }

      commodities.sort((a, b) => (a.productForm ?? '').compareTo(b.productForm ?? ''));
      debugPrint('✅ Loaded ${commodities.length} commodities for category: $category (client-sorted)');
      return commodities;
    } catch (e) {
      debugPrint('❌ Error loading commodities by category: $e');
      return [];
    }
  }

  /// Update a commodity
  Future<bool> updateCommodity(String docId, CommodityData data) async {
    try {
      data.updatedAt = DateTime.now();

      await _firestore.collection(_collectionName).doc(docId).update(data.toFirestore());
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

  /// Clear all commodities (admin reset)
  Future<bool> clearAllCommodities() async {
    try {
      final snapshot = await _firestore.collection(_collectionName).get();
      for (final doc in snapshot.docs) {
        await _firestore.collection(_collectionName).doc(doc.id).delete();
      }
      debugPrint('✅ All commodities cleared');
      return true;
    } catch (e) {
      debugPrint('❌ Error clearing commodities: $e');
      return false;
    }
  }
}
