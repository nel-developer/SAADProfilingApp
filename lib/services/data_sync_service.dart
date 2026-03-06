import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

class DataSyncService {
  static final DataSyncService _instance = DataSyncService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _syncQueueBoxName = 'sync_queue';

  bool _isSyncing = false;

  factory DataSyncService() {
    return _instance;
  }

  DataSyncService._internal();

  /// Initialize Hive box for sync queue
  Future<void> initialize() async {
    try {
      if (!Hive.isBoxOpen(_syncQueueBoxName)) {
        await Hive.openBox<Map<String, dynamic>>(_syncQueueBoxName);
      }
    } catch (e) {
      // Fail silently
      return;
    }
  }

  /// Queue profiling data for sync (stores locally)
  Future<void> queueProfilingData({
    required String uid,
    required Map<String, dynamic> profilingData,
  }) async {
    try {
      final box = Hive.box<Map<String, dynamic>>(_syncQueueBoxName);
      final timestamp = DateTime.now().toIso8601String();
      final key = 'profiling_${uid}_$timestamp';

      await box.put(key, {
        'uid': uid,
        'data': profilingData,
        'timestamp': timestamp,
        'synced': false,
      });
    } catch (e) {
      // Fail silently — data will be retried later
      return;
    }
  }

  /// Start listening for connectivity changes and sync when online
  /// NOTE: This is intentionally empty — sync is now manual via user action
  void startSyncListener() {
    // Auto-sync disabled. User manually clicks "Sync" button to sync data.
  }

  /// Sync all queued profiling data to Firestore (MANUAL SYNC)
  /// Call this when user clicks "Sync" button on data page
  Future<Map<String, dynamic>> syncQueuedData() async {
    if (_isSyncing) return {'success': false, 'message': 'Sync already in progress'};

    _isSyncing = true;
    int synced = 0;
    int failed = 0;

    try {
      final box = Hive.box<Map<String, dynamic>>(_syncQueueBoxName);

      if (box.isEmpty) {
        _isSyncing = false;
        return {'success': true, 'synced': 0, 'failed': 0, 'message': 'No data to sync'};
      }

      // Get all unsynced items
      final entries = box.toMap().entries.toList();

      for (final entry in entries) {
        final key = entry.key as String;
        final item = entry.value;

        if (item['synced'] == true) continue;

        try {
          final uid = item['uid'] as String?;
          final data = item['data'] as Map<String, dynamic>?;

          if (uid == null || data == null) {
            // Invalid item — remove
            await box.delete(key);
            failed++;
            continue;
          }

          // Upload to Firestore
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('profilingData')
              .add({
            ...data,
            'syncedAt': FieldValue.serverTimestamp(),
          });

          // Mark as synced
          final syncedItem = Map<String, dynamic>.from(item);
          syncedItem['synced'] = true;
          await box.put(key, syncedItem);
          synced++;
        } catch (e) {
          // Log error but continue with next item
          print('Error syncing item $key: $e');
          failed++;
          // Don't mark as synced — retry next time
        }
      }

      // Optionally clean up old synced items after some time
      await _cleanupOldSyncedItems(box);

      return {
        'success': true,
        'synced': synced,
        'failed': failed,
        'message': 'Synced $synced item(s). Failed: $failed'
      };
    } catch (e) {
      print('Error during sync: $e');
      return {
        'success': false,
        'message': 'Sync failed: $e'
      };
    } finally {
      _isSyncing = false;
    }
  }

  /// Clean up synced items older than 7 days
  Future<void> _cleanupOldSyncedItems(
      Box<Map<String, dynamic>> box) async {
    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      final entries = box.toMap().entries.toList();
      for (final entry in entries) {
        final item = entry.value;

        if (item['synced'] != true) continue;

        final timestampStr = item['timestamp'] as String?;
        if (timestampStr == null) continue;

        final timestamp = DateTime.parse(timestampStr);
        if (timestamp.isBefore(sevenDaysAgo)) {
          await box.delete(entry.key);
        }
      }
    } catch (e) {
      // Fail silently
      return;
    }
  }

  /// Get count of unsynced items
  Future<int> getUnsyncedCount() async {
    try {
      final box = Hive.box<Map<String, dynamic>>(_syncQueueBoxName);
      int count = 0;
      for (final item in box.values) {
        if (item['synced'] != true) {
          count++;
        }
      }
      return count;
    } catch (e) {
      return 0;
    }
  }

  /// Clear sync queue (for testing)
  Future<void> clearQueue() async {
    try {
      final box = Hive.box<Map<String, dynamic>>(_syncQueueBoxName);
      await box.clear();
    } catch (e) {
      return;
    }
  }
}
