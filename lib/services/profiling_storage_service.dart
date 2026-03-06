import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:da_project_1/models/profiling_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:da_project_1/services/image_storage_service.dart';

/// Stages emitted during a sync/save operation so the UI can display progress.
enum SyncStage { preparing, uploading, finalizing }

typedef SyncProgressCallback = void Function(SyncStage stage, double? progress);

/// Result of a sync operation with success status and detailed error info
class SyncResult {
  final bool success;
  final String? errorMessage;
  final String? errorCode;
  final dynamic originalError;

  SyncResult({
    required this.success,
    this.errorMessage,
    this.errorCode,
    this.originalError,
  });

  factory SyncResult.success() => SyncResult(success: true);

  factory SyncResult.failure(String message, {String? code, dynamic error}) {
    return SyncResult(
      success: false,
      errorMessage: message,
      errorCode: code,
      originalError: error,
    );
  }

  @override
  String toString() => 'SyncResult(success: $success, error: $errorMessage)';
}

/// Result of an approval/rejection operation with success status and detailed error info
class ApprovalResult {
  final bool success;
  final String? errorMessage;
  final String? errorCode;
  final dynamic originalError;

  ApprovalResult({
    required this.success,
    this.errorMessage,
    this.errorCode,
    this.originalError,
  });

  factory ApprovalResult.success() => ApprovalResult(success: true);

  factory ApprovalResult.failure(
    String message, {
    String? code,
    dynamic error,
  }) {
    return ApprovalResult(
      success: false,
      errorMessage: message,
      errorCode: code,
      originalError: error,
    );
  }

  @override
  String toString() =>
      'ApprovalResult(success: $success, error: $errorMessage)';
}

/// ProfilingStorageService — Disk-only local storage + Firestore cloud sync
/// No in-memory cache — files read/written directly to disk for lower memory footprint
class ProfilingStorageService {
  static final ProfilingStorageService _instance =
      ProfilingStorageService._internal();

  bool _initialized = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();
  final ImageStorageService _imageStorageService = ImageStorageService();

  ProfilingStorageService._internal();

  factory ProfilingStorageService() {
    return _instance;
  }

  String? _normalizeStatus(dynamic rawStatus) {
    final value = rawStatus?.toString().trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    final lower = value.toLowerCase();
    if (lower == 'draft') return 'Draft';
    if (lower == 'unsync' || lower == 'unsynced') return 'Unsync';
    if (lower == 'pending' || lower == 'pending approval') {
      return 'Pending Approval';
    }
    if (lower == 'approved') return 'Approved';

    return value;
  }

  String? _sanitizeText(dynamic raw) {
    if (raw == null) return null;

    String value;
    if (raw is Timestamp) {
      value = raw.toDate().toIso8601String().split('T').first;
    } else if (raw is DateTime) {
      value = raw.toIso8601String().split('T').first;
    } else {
      value = raw.toString().trim();
    }

    if (value.isEmpty) return null;

    final lower = value.toLowerCase();
    if (lower == 'n/a' || lower == 'na' || lower == 'null') {
      return null;
    }

    return value;
  }

  String? _readFirstString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = _sanitizeText(json[key]);
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  String? _readDateString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final raw = json[key];

      if (raw is Timestamp) {
        final dt = raw.toDate();
        return '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}/${dt.year}';
      }

      if (raw is DateTime) {
        return '${raw.month.toString().padLeft(2, '0')}/${raw.day.toString().padLeft(2, '0')}/${raw.year}';
      }

      final text = _sanitizeText(raw);
      if (text == null || text.isEmpty) {
        continue;
      }

      final parsed = DateTime.tryParse(text);
      if (parsed != null) {
        return '${parsed.month.toString().padLeft(2, '0')}/${parsed.day.toString().padLeft(2, '0')}/${parsed.year}';
      }

      // Keep user-entered date formats like MM/DD/YYYY when already plain text.
      return text;
    }

    return null;
  }

  bool _isInProgressDraft(ProfilingData data) {
    final status = data.status?.trim();
    return status == null || status.isEmpty || status == 'Draft';
  }

  /// Initialize (disk-only, no Hive needed)
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
  }

  /// Save profiling data locally to disk (no in-memory cache)
  /// Writes directly to farmer folder as JSON file
  Future<void> saveDraftLocally(
    ProfilingData data, {
    bool setAsCurrent = true,
  }) async {
    try {
      // Only bump `updatedAt` when this draft should be considered the current
      // in-progress draft. When `setAsCurrent` is false (e.g., saving a copy
      // for pending submission), we avoid updating `updatedAt` so it won't be
      // returned by `loadDraftLocally()` as the most-recent draft.
      if (setAsCurrent) {
        data.updatedAt = DateTime.now();
      }

      // If we have a Firestore-assigned id but no local temp id, use Firestore id
      if ((data.tempIdLocal == null || data.tempIdLocal!.isEmpty) &&
          (data.tempIdFirebase != null && data.tempIdFirebase!.isNotEmpty)) {
        data.tempIdLocal = data.tempIdFirebase;
      }

      // Ensure a stable local id for folder naming.
      data.tempIdLocal ??= DateTime.now().millisecondsSinceEpoch.toString();

      // Generate/ensure farmer folder name for disk storage using
      // FIRST NAME + SURNAME only (requested naming convention).
      final firstName = (data.firstName ?? '').trim().isEmpty
          ? 'farmer'
          : data.firstName!.trim();
      final surname = (data.surname ?? '').trim().isEmpty
          ? 'profiling'
          : data.surname!.trim();

      final expectedPrefix =
          '${firstName.replaceAll(' ', '_').toLowerCase()}_${surname.replaceAll(' ', '_').toLowerCase()}_';
      final currentFolder = data.farmerFolderName?.trim() ?? '';
      final shouldRegenerateFolder =
          currentFolder.isEmpty || !currentFolder.startsWith(expectedPrefix);

      if (shouldRegenerateFolder) {
        data.farmerFolderName = _imageStorageService.generateFarmerFolderName(
          firstName,
          surname,
          uniqueId: data.tempIdLocal,
        );
      }

      // Save to disk (only storage)
      await _imageStorageService.saveDraftJson(
        data.farmerFolderName!,
        _profilingDataToJson(data),
        firstName: firstName,
        lastName: surname,
      );

      debugPrint('✅ Draft saved to disk: ${data.farmerFolderName}');
    } catch (e) {
      debugPrint('❌ Error saving draft locally: $e');
      rethrow;
    }
  }

  /// Load draft from local storage
  /// Load current draft from disk (if any)
  /// Returns the most recently modified draft JSON file
  Future<ProfilingData?> loadDraftLocally() async {
    try {
      final drafts = await loadDraftsFromDiskOnly();
      if (drafts.isEmpty) return null;
      // Return most recent in-progress draft only (exclude submitted/unsync).
      for (final draft in drafts) {
        if (_isInProgressDraft(draft)) {
          return draft;
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error loading draft: $e');
      return null;
    }
  }

  /// Load all drafts from disk (disk-only, no cache)
  /// Returns the collection as-is from disk files
  Future<List<ProfilingData>> loadAllDraftsFromHive() async {
    // Renamed function for clarity, but actual implementation is disk-only
    return loadDraftsFromDiskOnly();
  }

  /// Delete local current draft
  /// This removes the draft JSON file from disk
  Future<void> deleteDraftLocally() async {
    try {
      // Delete only folders that contain draft-only records.
      // If a folder also contains Unsync/Pending/Approved JSON, keep it.
      final drafts = await loadDraftsFromDiskOnly();
      final Map<String, List<ProfilingData>> byFolder = {};
      for (final draft in drafts) {
        final folder = draft.farmerFolderName?.trim();
        if (folder == null || folder.isEmpty) continue;
        byFolder.putIfAbsent(folder, () => <ProfilingData>[]).add(draft);
      }

      final foldersToDelete = <String>[];
      byFolder.forEach((folder, records) {
        final hasNonDraft = records.any(
          (record) => !_isInProgressDraft(record),
        );
        if (!hasNonDraft) {
          foldersToDelete.add(folder);
        }
      });

      for (final folder in foldersToDelete) {
        // Write an audit record before deleting so deletes are auditable
        try {
          final appDir = await _imageStorageService.getAppDirectory();
          final auditFile = File('${appDir.path}/deletion_audit.log');
          final record = {
            'timestamp': DateTime.now().toIso8601String(),
            'folder': folder,
            'action': 'deleteDraftLocally',
            'caller': StackTrace.current
                .toString()
                .split('\n')
                .take(3)
                .join(' | '),
          };
          await auditFile.parent.create(recursive: true);
          await auditFile.writeAsString(
            '${record.toString()}\n',
            mode: FileMode.append,
          );
        } catch (e) {
          debugPrint('⚠️ Could not write deletion audit log: $e');
        }

        await _imageStorageService.deleteFarmerFolder(folder);
        debugPrint('✅ Draft-only folder deleted locally: $folder');
      }
    } catch (e) {
      debugPrint('❌ Error deleting draft: $e');
      rethrow;
    }
  }

  /// Clear current draft (no-op for disk-only storage, kept for API compatibility)
  Future<void> clearCurrentDraftPointer() async {
    // Disk-only: no pointer to clear, draft is deleted by deleteDraftLocally()
    debugPrint('✅ Current draft pointer cleared');
  }

  /// Load drafts ONLY from disk files in /SAADProfiling/ (no Hive)
  Future<List<ProfilingData>> loadDraftsFromDiskOnly() async {
    try {
      final List<ProfilingData> allDrafts = [];
      final appDir = await _imageStorageService.getAppDirectory();

      if (await appDir.exists()) {
        debugPrint(
          '🔍 Loading drafts from disk only (this may take a moment): ${appDir.path}',
        );

        // Collect file paths first (fast) then parse them in an isolate to
        // avoid blocking the UI thread when many files exist.
        final List<String> jsonPaths = [];
        await for (final entity in appDir.list(
          recursive: false,
          followLinks: false,
        )) {
          if (entity is Directory) {
            try {
              await for (final fileEntity in entity.list(
                recursive: false,
                followLinks: false,
              )) {
                if (fileEntity is File && fileEntity.path.endsWith('.json')) {
                  jsonPaths.add(fileEntity.path);
                }
              }
            } catch (e) {
              debugPrint('  ⚠️ Error listing files in ${entity.path}: $e');
            }
          }
        }

        // Offload JSON reads + parsing to a background isolate.
        if (jsonPaths.isNotEmpty) {
          final parsed = await compute(_readAndParseDraftFiles, jsonPaths);
          for (final json in parsed) {
            try {
              final data = _jsonToProfilingData(json);
              allDrafts.add(data);
            } catch (_) {
              // ignore malformed per-file JSON in main isolate
            }
          }
        }
      }

      // Sort by updatedAt descending (newest first)
      allDrafts.sort(
        (a, b) => (b.updatedAt ?? DateTime(1970)).compareTo(
          a.updatedAt ?? DateTime(1970),
        ),
      );
      debugPrint('✅ Loaded ${allDrafts.length} draft(s) from disk only');
      return allDrafts;
    } catch (e) {
      debugPrint('❌ Error loading drafts from disk: $e');
      return [];
    }
  }

  /// Background worker: read and parse JSON files given their paths.
  /// Returns a list of decoded JSON maps for successful parses.
  /// Uses synchronous I/O since this runs in a background isolate.
  List<Map<String, dynamic>> _readAndParseDraftFiles(List<String> paths) {
    final List<Map<String, dynamic>> results = [];
    for (final p in paths) {
      try {
        final f = File(p);
        if (!f.existsSync()) {
          continue;
        }
        final contents = f.readAsStringSync();
        if (contents.isEmpty) {
          continue;
        }
        final json = jsonDecode(contents) as Map<String, dynamic>;
        results.add(json);
      } catch (_) {
        // ignore malformed/IO errors in isolate
        continue;
      }
    }
    return results;
  }

  /// Check if device is online
  Future<bool> isOnline() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      debugPrint('❌ Error checking connectivity: $e');
      return false;
    }
  }

  /// Sync local draft to Firestore (when online)
  /// NOTE: Only profiling data syncs. Images remain LOCAL ONLY.
  /// toFirestore() excludes all image paths (idFrontImagePath, idBackImagePath, etc.)
  /// Images are stored in device's local storage under the farmer's folder.
  Future<SyncResult> syncToFirestore(ProfilingData data, String userId) async {
    try {
      final online = await isOnline();
      if (!online) {
        debugPrint('⚠️ Device offline — cannot sync');
        return SyncResult.failure(
          'Device is offline. Please check your internet connection.',
        );
      }

      data.userId = userId;

      // Mark the record as pending approval; do NOT mark as fully synced/approved
      data.status = 'Pending Approval';
      data.createdAt ??= DateTime.now();
      data.updatedAt = DateTime.now();

      // Use the centralized pending save so we don't accidentally write to the
      // approved/profiling_forms collection. Give the write a reasonable timeout
      // so the UI doesn't hang indefinitely on slow networks.
      try {
        final result = await saveToPendingCollection(
          data,
          userId,
        ).timeout(const Duration(seconds: 15));
        if (result.success) {
          debugPrint('✅ Saved to pending collection');
          return result;
        }
        debugPrint(
          '⚠️ Failed to save to pending collection: ${result.errorMessage}',
        );
        return result;
      } on SocketException catch (e) {
        debugPrint('❌ Connection error during sync: $e');
        return SyncResult.failure(
          'Network connection lost. Check your internet and try again.',
          error: e,
        );
      } on FirebaseException catch (e) {
        debugPrint('❌ Firebase error during sync: ${e.code} - ${e.message}');
        return SyncResult.failure(
          'Firebase error: ${e.message}',
          code: e.code,
          error: e,
        );
      } catch (e) {
        // Catch timeout and other exceptions
        debugPrint('❌ Sync to pending collection failed: $e');
        if (e.toString().contains('timed out') ||
            e.toString().contains('TimeoutException')) {
          return SyncResult.failure(
            'Sync operation timed out. Please try again with a stronger connection.',
            error: e,
          );
        }
        return SyncResult.failure('Failed to sync: ${e.toString()}', error: e);
      }
    } catch (e) {
      debugPrint('❌ Error syncing to Firestore: $e');
      return SyncResult.failure(
        'Unexpected error during sync: ${e.toString()}',
        error: e,
      );
    }
  }

  /// Sync only recurrence additions for Existing Farmer flow.
  /// This updates an already-approved profile identified by SAAD I.D No.
  /// and keeps all previous non-recurrence data unchanged.
  Future<SyncResult> syncExistingRecurrenceToApproved(
    ProfilingData data,
    String userId,
  ) async {
    try {
      final online = await isOnline();
      if (!online) {
        return SyncResult.failure(
          'Device is offline. Please check your internet connection.',
        );
      }

      final selectedExistingSaadId = data.selectedExistingSaadId?.trim() ?? '';
      final explicitSaadId = data.saadIdNo?.trim() ?? '';
      final saadId = selectedExistingSaadId.isNotEmpty
          ? selectedExistingSaadId
          : explicitSaadId;
      if (saadId.isEmpty) {
        return SyncResult.failure(
          'SAAD I.D No. is required for Existing Farmer recurrence sync.',
          code: 'MISSING_SAAD_ID',
        );
      }

      // Keep fields aligned with the target existing profile selected in Step 1.
      data.saadIdNo = saadId;
      data.selectedExistingSaadId = saadId;

      final selectedYear = data.yearCovered?.toString().trim();
      final incomingByYear = Map<String, dynamic>.from(
        data.recurrenceByYear ?? {},
      );
      if (selectedYear == null || selectedYear.isEmpty) {
        return SyncResult.failure(
          'Year Covered is required before syncing recurrence.',
          code: 'MISSING_YEAR',
        );
      }
      final selectedIncomingRaw = incomingByYear[selectedYear];
      final selectedIncoming = selectedIncomingRaw is Map
          ? Map<String, dynamic>.from(selectedIncomingRaw)
          : <String, dynamic>{};

      final snapshot = await _firestore
          .collection('profiling_forms')
          .where('status', isEqualTo: 'Approved')
          .where('saadIdNo', isEqualTo: saadId)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 20));

      if (snapshot.docs.isEmpty) {
        return SyncResult.failure(
          'No approved profile found for SAAD I.D No. $saadId',
          code: 'PROFILE_NOT_FOUND',
        );
      }

      final targetDoc = snapshot.docs.first;
      final existingPayload = Map<String, dynamic>.from(targetDoc.data());

      final mergedByYear = <String, dynamic>{};
      final existingByYearRaw = existingPayload['recurrenceByYear'];
      if (existingByYearRaw is Map) {
        mergedByYear.addAll(Map<String, dynamic>.from(existingByYearRaw));
      }

      final existingSelectedRaw = mergedByYear[selectedYear];
      final existingSelected = existingSelectedRaw is Map
          ? Map<String, dynamic>.from(existingSelectedRaw)
          : <String, dynamic>{};

      final fallbackSelected = <String, dynamic>{
        'maleFamilyMembers': data.maleFamilyMembers,
        'femaleFamilyMembers': data.femaleFamilyMembers,
        'yearsInFarming': data.yearsInFarming,
        'landTenureship': data.landTenureship,
        'landTenureshipOthers': data.landTenureshipOthers,
      };

      mergedByYear[selectedYear] = {
        ...existingSelected,
        ...(selectedIncoming.isNotEmpty ? selectedIncoming : fallbackSelected),
      };

      final selectedYearDataRaw = mergedByYear[selectedYear];
      final selectedYearData = selectedYearDataRaw is Map
          ? Map<String, dynamic>.from(selectedYearDataRaw)
          : <String, dynamic>{};

      final updatePayload = <String, dynamic>{
        'status': 'Approved',
        'userId': userId,
        'yearCovered': int.tryParse(selectedYear) ?? data.yearCovered,
        'recurrenceByYear': mergedByYear,
        'maleFamilyMembers':
            selectedYearData['maleFamilyMembers'] ?? data.maleFamilyMembers,
        'femaleFamilyMembers':
            selectedYearData['femaleFamilyMembers'] ?? data.femaleFamilyMembers,
        'yearsInFarming':
            selectedYearData['yearsInFarming'] ?? data.yearsInFarming,
        'landTenureship':
            selectedYearData['landTenureship'] ?? data.landTenureship,
        'landTenureshipOthers':
            selectedYearData['landTenureshipOthers'] ??
            data.landTenureshipOthers,
        'agriRelatedIncome':
            selectedYearData['agriRelatedIncome'] ?? data.agriRelatedIncome,
        'saadNetIncome':
            selectedYearData['saadNetIncome'] ?? data.saadNetIncome,
        'nonSAADNetIncome':
            selectedYearData['nonSAADNetIncome'] ?? data.nonSAADNetIncome,
        'nonAgriRelatedIncome':
            selectedYearData['nonAgriRelatedIncome'] ??
            data.nonAgriRelatedIncome,
        'mainSourcesOfIncome':
            selectedYearData['mainSourcesOfIncome'] ?? data.mainSourcesOfIncome,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await _firestore
          .collection('profiling_forms')
          .doc(targetDoc.id)
          .set(updatePayload, SetOptions(merge: true))
          .timeout(const Duration(seconds: 20));

      return SyncResult.success();
    } on SocketException catch (e) {
      return SyncResult.failure(
        'Network error: Check your connection',
        error: e,
      );
    } on FirebaseException catch (e) {
      return SyncResult.failure(
        'Firebase error: ${e.message ?? e.code}',
        code: e.code,
        error: e,
      );
    } catch (e) {
      return SyncResult.failure('Failed to sync existing recurrence: $e');
    }
  }

  /// Load synced data from Firestore
  Future<List<ProfilingData>> loadSyncedFromFirestore(String userId) async {
    try {
      final docSnapshot = await _firestore
          .collection('profiling_forms')
          .doc(userId)
          .get();

      if (!docSnapshot.exists) {
        debugPrint('📭 No synced data in Firestore for user: $userId');
        return [];
      }

      final data = _jsonToProfilingData(docSnapshot.data() ?? {});
      // Status of this document in Firestore indicates it's synced/approved
      try {
        final payload = docSnapshot.data();
        if (payload != null && payload.containsKey('enumeratorEmail')) {
          data.enumeratorEmail = payload['enumeratorEmail'];
        }
      } catch (_) {}
      debugPrint(
        '✅ Loaded synced data from Firestore: ${data.firstName} ${data.surname}',
      );
      return [data];
    } catch (e) {
      debugPrint('❌ Error loading from Firestore: $e');
      return [];
    }
  }

  /// Convert ProfilingData to JSON-serializable map
  Map<String, dynamic> _profilingDataToJson(ProfilingData data) {
    return {
      'firstName': data.firstName,
      'middleName': data.middleName,
      'surname': data.surname,
      'extensionName': data.extensionName,
      'region': data.region,
      'province': data.province,
      'municipality': data.municipality,
      'barangay': data.barangay,
      'sitioPurok': data.sitioPurok,
      'dateOfBirth': data.dateOfBirth,
      'sex': data.sex,
      'rsbsaFishrIdNo': data.rsbsaFishrIdNo,
      'saadIdNo': data.saadIdNo,
      'isExistingFarmer': data.isExistingFarmer,
      'selectedExistingSaadId': data.selectedExistingSaadId,
      'isIndigenous': data.isIndigenous,
      'indigenousGroup': data.indigenousGroup,
      'isPWD': data.isPWD,
      'spouseName': data.spouseName,
      'primaryCommodity': data.primaryCommodity,
      'saadCommodityType': data.saadCommodityType,
      'saadCommodities': data.saadCommodities,
      'nonSAADCommodityType': data.nonSAADCommodityType,
      'nonSAADCommodities': data.nonSAADCommodities,
      'primaryCommodityOthers': data.primaryCommodityOthers,
      'secondaryCommodity': data.secondaryCommodity,
      'secondaryCommodityOthers': data.secondaryCommodityOthers,
      'maleFamilyMembers': data.maleFamilyMembers,
      'femaleFamilyMembers': data.femaleFamilyMembers,
      'yearsInFarming': data.yearsInFarming,
      'landTenureship': data.landTenureship,
      'landTenureshipOthers': data.landTenureshipOthers,
      'secondaryCommodityRecurrence': data.secondaryCommodityRecurrence,
      'secondaryCommodityRecurrenceOthers':
          data.secondaryCommodityRecurrenceOthers,
      'primaryCommodityRecurrence': data.primaryCommodityRecurrence,
      'primaryCommodityRecurrenceOthers': data.primaryCommodityRecurrenceOthers,
      'yearCovered': data.yearCovered,
      'recurrenceByYear': data.recurrenceByYear,
      'receivedCommodity':
          data.receivedCommodity ?? data.receivedPrimaryCommodity,
      'receivedCommodityOthers': data.receivedCommodityOthers,
      'receivedPrimaryCommodity': data.receivedPrimaryCommodity,
      'receivedSecondaryCommodity': data.receivedSecondaryCommodity,
      'agriRelatedIncome': data.agriRelatedIncome,
      'saadNetIncome': data.saadNetIncome,
      'nonAgriRelatedIncome': data.nonAgriRelatedIncome,
      'mainSourcesOfIncome': data.mainSourcesOfIncome,
      // Specific commodity income fields
      'riceIncomeField': data.riceIncomeField,
      'riceRemarks': data.riceRemarks,
      'hvcIncomeField': data.hvcIncomeField,
      'hvcRemarks': data.hvcRemarks,
      'livestockIncomeField': data.livestockIncomeField,
      'livestockRemarks': data.livestockRemarks,
      'fishingIncomeField': data.fishingIncomeField,
      'fishingRemarks': data.fishingRemarks,
      'nonFarmFisheriesIncomeField': data.nonFarmFisheriesIncomeField,
      'nonFarmFisheriesRemarks': data.nonFarmFisheriesRemarks,
      'beneficiaryNonFarmIncome': data.beneficiaryNonFarmIncome,
      'beneficiaryRemarks': data.beneficiaryRemarks,
      'spouseNonFarmIncome': data.spouseNonFarmIncome,
      'spouseRemarks': data.spouseRemarks,
      'otherMembersNonFarmIncome': data.otherMembersNonFarmIncome,
      'otherMembersRemarks': data.otherMembersRemarks,
      'cooperativeName': data.cooperativeName,
      'cooperativePosition': data.cooperativePosition,
      'dateOfMembership': data.dateOfMembership,
      'cooperativePositionOthers': data.cooperativePositionOthers,
      'idType': data.idType,
      'idFrontImagePath': data.idFrontImagePath,
      'idBackImagePath': data.idBackImagePath,
      'farmerPhotoPath': data.farmerPhotoPath,
      'signatureImagePath': data.signatureImagePath,
      'farmerFolderName': data.farmerFolderName,
      'userId': data.userId,
      'tempIdLocal': data.tempIdLocal,
      'tempIdFirebase': data.tempIdFirebase,
      'createdAt': data.createdAt?.toIso8601String(),
      'updatedAt': data.updatedAt?.toIso8601String(),
      'status': data.status,
    };
  }

  /// Convert JSON to ProfilingData
  ProfilingData _jsonToProfilingData(Map<String, dynamic> json) {
    return ProfilingData(
      firstName: _readFirstString(json, const ['firstName', 'givenName']),
      middleName: _readFirstString(json, const ['middleName']),
      surname: _readFirstString(json, const [
        'surname',
        'lastName',
        'lastname',
        'surName',
      ]),
      extensionName: _readFirstString(json, const ['extensionName']),
      region: json['region'],
      province: json['province'],
      municipality: json['municipality'],
      barangay: json['barangay'],
      sitioPurok: json['sitioPurok'],
      dateOfBirth: _readDateString(json, const [
        'dateOfBirth',
        'birthDate',
        'birthdate',
        'dob',
      ]),
      sex: json['sex'],
      rsbsaFishrIdNo: json['rsbsaFishrIdNo'],
      saadIdNo: json['saadIdNo'],
      isExistingFarmer: json['isExistingFarmer'] == true,
      selectedExistingSaadId: json['selectedExistingSaadId'],
      isIndigenous: json['isIndigenous'],
      indigenousGroup: json['indigenousGroup'],
      isPWD: json['isPWD'],
      spouseName: json['spouseName'],
      tribeEthnicity: json['tribeEthnicity'],
      saadCommodityType: json['saadCommodityType'],
      saadCommodities: (json['saadCommodities'] as List?)
          ?.whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList(),
      nonSAADCommodityType: json['nonSAADCommodityType'],
      nonSAADCommodities: (json['nonSAADCommodities'] as List?)
          ?.whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList(),
      primaryCommodity: json['primaryCommodity'],
      primaryCommodityOthers: json['primaryCommodityOthers'],
      secondaryCommodity: json['secondaryCommodity'],
      secondaryCommodityOthers: json['secondaryCommodityOthers'],
      maleFamilyMembers: json['maleFamilyMembers'],
      femaleFamilyMembers: json['femaleFamilyMembers'],
      yearsInFarming: json['yearsInFarming'],
      landTenureship: json['landTenureship'],
      landTenureshipOthers: json['landTenureshipOthers'],
      secondaryCommodityRecurrence: json['secondaryCommodityRecurrence'],
      secondaryCommodityRecurrenceOthers:
          json['secondaryCommodityRecurrenceOthers'],
      primaryCommodityRecurrence: json['primaryCommodityRecurrence'],
      primaryCommodityRecurrenceOthers:
          json['primaryCommodityRecurrenceOthers'],
      yearCovered: json['yearCovered'],
      recurrenceByYear: (json['recurrenceByYear'] is Map)
          ? Map<String, dynamic>.from(json['recurrenceByYear'])
          : null,
      receivedCommodity: json['receivedCommodity'],
      receivedCommodityOthers: json['receivedCommodityOthers'],
      receivedPrimaryCommodity:
          json['receivedPrimaryCommodity'] ?? json['receivedCommodity'],
      receivedSecondaryCommodity: json['receivedSecondaryCommodity'],
      agriRelatedIncome: json['agriRelatedIncome']?.toDouble(),
      saadNetIncome: json['saadNetIncome']?.toDouble(),
      nonAgriRelatedIncome: json['nonAgriRelatedIncome']?.toDouble(),
      mainSourcesOfIncome: json['mainSourcesOfIncome'],
      riceIncomeField: json['riceIncomeField'],
      riceRemarks: json['riceRemarks'],
      hvcIncomeField: json['hvcIncomeField'],
      hvcRemarks: json['hvcRemarks'],
      livestockIncomeField: json['livestockIncomeField'],
      livestockRemarks: json['livestockRemarks'],
      fishingIncomeField: json['fishingIncomeField'],
      fishingRemarks: json['fishingRemarks'],
      nonFarmFisheriesIncomeField: json['nonFarmFisheriesIncomeField'],
      nonFarmFisheriesRemarks: json['nonFarmFisheriesRemarks'],
      beneficiaryNonFarmIncome: json['beneficiaryNonFarmIncome']?.toString(),
      beneficiaryRemarks: json['beneficiaryRemarks'],
      spouseNonFarmIncome: json['spouseNonFarmIncome']?.toString(),
      spouseRemarks: json['spouseRemarks'],
      otherMembersNonFarmIncome: json['otherMembersNonFarmIncome']?.toString(),
      otherMembersRemarks: json['otherMembersRemarks'],
      idType: json['idType'],
      idFrontImagePath: json['idFrontImagePath'],
      idBackImagePath: json['idBackImagePath'],
      farmerPhotoPath: json['farmerPhotoPath'],
      signatureImagePath: json['signatureImagePath'],
      farmerFolderName: json['farmerFolderName'],
      userId: json['userId'],
      tempIdLocal: json['tempIdLocal'],
      tempIdFirebase: json['tempIdFirebase'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      status: _normalizeStatus(json['status']),
      enumeratorEmail: json['enumeratorEmail'],
      approverEmail: json['approvedBy'] ?? json['approverEmail'],
      approvedAt: json['approvedAt'] != null
          ? DateTime.tryParse(json['approvedAt'])
          : null,
      cooperativeName: json['cooperativeName'],
      cooperativePosition: json['cooperativePosition'],
      dateOfMembership: json['dateOfMembership'],
      cooperativePositionOthers: json['cooperativePositionOthers'],
    );
  }

  /// Save profiling data to pending collection for approval
  ///
  /// Optional [onProgress] receives stage updates so UI can present a
  /// multi-stage progress indicator: preparing -> uploading -> finalizing
  /// Returns a SyncResult with success status and detailed error information
  Future<SyncResult> saveToPendingCollection(
    ProfilingData data,
    String userId, {
    SyncProgressCallback? onProgress,
  }) async {
    try {
      data.userId = userId;
      data.status = 'Pending Approval';
      data.createdAt ??= DateTime.now();
      data.updatedAt = DateTime.now();

      // Notify UI that we are preparing the payload
      try {
        onProgress?.call(SyncStage.preparing, 0.0);
      } catch (_) {}

      // Prefer updating existing pending doc if we know its Firestore id
      String? docId = data.tempIdFirebase;

      // If we don't have a firestore id, try to find by tempIdLocal (fallback)
      if (docId == null || docId.isEmpty) {
        if (data.tempIdLocal != null && data.tempIdLocal!.isNotEmpty) {
          try {
            final query = await _firestore
                .collection('profiling_pending')
                .where('tempIdLocal', isEqualTo: data.tempIdLocal)
                .limit(1)
                .get()
                .timeout(const Duration(seconds: 10));
            if (query.docs.isNotEmpty) {
              docId = query.docs.first.id;
              debugPrint('✅ Found existing pending doc by tempIdLocal: $docId');
            }
          } on FirebaseException catch (e) {
            debugPrint(
              '⚠️ Warning: Could not query existing doc: ${e.code} - ${e.message}',
            );
            // Continue with creating new doc
          }
        }
      }

      // If still no docId, create a new one
      if (docId == null || docId.isEmpty) {
        final newDocRef = _firestore.collection('profiling_pending').doc();
        docId = newDocRef.id;
        debugPrint('📝 Creating new pending doc with ID: $docId');
      }

      data.tempIdFirebase = docId;

      // When a doc is created/updated in Firestore for pending, create/set a local id so
      // subsequent local saves update the same record instead of creating duplicates.
      // We'll use the same id for local purposes.
      data.tempIdLocal ??= docId;

      // Ensure tempIdLocal is persisted in Firestore so we can match later
      final firestoreData = Map<String, dynamic>.from(data.toFirestore());
      if (data.tempIdLocal != null) {
        firestoreData['tempIdLocal'] = data.tempIdLocal;
      }

      // EXPLICITLY ensure status is set in Firestore
      firestoreData['status'] = 'Pending Approval';

      // Include enumerator email for auditing (prefer FirebaseAuth email, fallback to userId)
      try {
        final authEmail = FirebaseAuth.instance.currentUser?.email;
        firestoreData['enumeratorEmail'] = authEmail ?? userId;
      } catch (_) {
        firestoreData['enumeratorEmail'] = userId;
      }

      debugPrint(
        '📤 Saving to pending with data: status=${firestoreData['status']}, firstName=${firestoreData['firstName']}, enumerator=${firestoreData['enumeratorEmail']}',
      );

      // Notify UI that upload is starting
      try {
        onProgress?.call(SyncStage.uploading, 0.5);
      } catch (_) {}

      try {
        await _firestore
            .collection('profiling_pending')
            .doc(docId)
            .set(firestoreData, SetOptions(merge: true))
            .timeout(const Duration(seconds: 20));
        debugPrint(
          '✅ Successfully written to profiling_pending collection: $docId',
        );
      } on SocketException catch (e) {
        debugPrint('❌ Network error writing to Firestore: $e');
        return SyncResult.failure('Network error: ${e.message}', error: e);
      } on FirebaseException catch (e) {
        debugPrint(
          '❌ Firebase error writing to pending collection: ${e.code} - ${e.message}',
        );
        return SyncResult.failure(
          'Failed to save to Firebase: ${e.message ?? e.code}',
          code: e.code,
          error: e,
        );
      } catch (e) {
        // Catch timeout and other exceptions
        debugPrint('❌ Error writing to Firestore: $e');
        if (e.toString().contains('timed out') ||
            e.toString().contains('TimeoutException')) {
          return SyncResult.failure(
            'Firestore write timed out. Connection may be too slow.',
            code: 'TIMEOUT',
            error: e,
          );
        }
        return SyncResult.failure('Failed to save: ${e.toString()}', error: e);
      }

      // Persist the assigned Firestore doc id back into the data object
      data.tempIdFirebase = docId;

      // Notify UI that finalization is in progress
      try {
        onProgress?.call(SyncStage.finalizing, 0.9);
      } catch (_) {}

      // Save a local copy of the profile for offline reference (do NOT remove user's draft)
      // This preserves a local record while the authoritative copy is in Firestore.
      try {
        await saveDraftLocally(data, setAsCurrent: false);
      } catch (e) {
        debugPrint('⚠️ Warning: Could not persist pending doc id locally: $e');
      }

      // Final progress update
      try {
        onProgress?.call(SyncStage.finalizing, 1.0);
      } catch (_) {}

      debugPrint(
        '✅ Saved/updated pending collection doc: $docId (local copy retained)',
      );
      return SyncResult.success();
    } on FirebaseException catch (e) {
      debugPrint(
        '❌ Firebase error saving to pending collection: ${e.code} - ${e.message}',
      );
      return SyncResult.failure(
        'Firebase error: ${e.message ?? e.code}',
        code: e.code,
        error: e,
      );
    } on SocketException catch (e) {
      debugPrint('❌ Network error in saveToPendingCollection: $e');
      return SyncResult.failure(
        'Network error: Check your connection',
        error: e,
      );
    } catch (e) {
      debugPrint('❌ Error saving to pending collection: $e');
      return SyncResult.failure('Unexpected error: ${e.toString()}', error: e);
    }
  }

  /// Load profiles awaiting approval from pending collection (for admin)
  Future<List<ProfilingData>> loadPendingProfiles() async {
    try {
      debugPrint(
        '🔍 Querying profiling_pending collection for status="Pending Approval"...',
      );
      final snapshot = await _firestore
          .collection('profiling_pending')
          .where('status', isEqualTo: 'Pending Approval')
          .get();

      debugPrint('✅ Query returned ${snapshot.docs.length} document(s)');

      // Debug: Show all docs in collection if no pending found
      if (snapshot.docs.isEmpty) {
        debugPrint(
          '⚠️ No pending profiles found. Checking all documents in profiling_pending collection...',
        );
        final allDocs = await _firestore
            .collection('profiling_pending')
            .limit(5)
            .get();
        debugPrint(
          '   Total docs in profiling_pending: ${allDocs.docs.length}',
        );
        for (final doc in allDocs.docs.take(3)) {
          final docData = doc.data();
          debugPrint(
            '   - Doc ${doc.id}: status=${docData['status']}, firstName=${docData['firstName']}',
          );
        }
      }

      final profiles = <ProfilingData>[];
      for (final doc in snapshot.docs) {
        try {
          final data = _jsonToProfilingData(doc.data());
          data.tempIdFirebase = doc.id;
          profiles.add(data);
          debugPrint(
            '  ✓ Loaded: ${data.firstName} ${data.surname} (ID: ${doc.id})',
          );
        } catch (parseError) {
          debugPrint('  ⚠️ Failed to parse document ${doc.id}: $parseError');
        }
      }

      // Sort locally instead of in query to avoid needing composite index
      profiles.sort(
        (a, b) => (b.createdAt ?? DateTime(1970)).compareTo(
          a.createdAt ?? DateTime(1970),
        ),
      );

      // Attempt to populate enumeratorEmail if present in raw docs
      for (final doc in snapshot.docs) {
        final idx = profiles.indexWhere((p) => p.tempIdFirebase == doc.id);
        if (idx != -1) {
          try {
            final payload = doc.data();
            if (payload.containsKey('enumeratorEmail')) {
              profiles[idx].enumeratorEmail = payload['enumeratorEmail'];
            }
          } catch (_) {}
        }
      }

      debugPrint(
        '✅ Loaded ${profiles.length} pending profile(s) from Firestore',
      );
      return profiles;
    } catch (e) {
      debugPrint('❌ Error loading pending profiles: $e');
      debugPrint(
        '   This could mean: 1) No internet, 2) Permissions issue, 3) No documents match query',
      );
      return [];
    }
  }

  /// Approve a pending profile (move to approved collection)
  /// Returns ApprovalResult with detailed error information
  Future<ApprovalResult> approvePendingProfile(
    String pendingDocId,
    ProfilingData data,
  ) async {
    try {
      final saadNo = data.saadIdNo?.trim() ?? '';
      if (saadNo.isEmpty) {
        return ApprovalResult.failure(
          'SAAD I.D No. is required before approval.',
          code: 'MISSING_SAAD_ID',
        );
      }

      data.status = 'Approved';
      data.updatedAt = DateTime.now();

      // Record approver metadata
      final approverEmail =
          FirebaseAuth.instance.currentUser?.email ??
          FirebaseAuth.instance.currentUser?.uid ??
          'unknown';
      data.approverEmail = approverEmail;
      data.approvedAt = DateTime.now();

      // Prepare firestore payload including approver metadata
      final approvedPayload = Map<String, dynamic>.from(data.toFirestore());
      approvedPayload['approvedBy'] = approverEmail;
      approvedPayload['approvedAt'] = data.approvedAt?.toIso8601String();

      try {
        // Save to profiling_forms collection (main approved collection)
        await _firestore
            .collection('profiling_forms')
            .doc(pendingDocId)
            .set(approvedPayload, SetOptions(merge: true))
            .timeout(const Duration(seconds: 20));
      } on SocketException catch (e) {
        debugPrint('❌ Network error saving to approved collection: $e');
        return ApprovalResult.failure(
          'Network error: Check your connection',
          error: e,
        );
      } on FirebaseException catch (e) {
        debugPrint(
          '❌ Firebase error saving to approved collection: ${e.code} - ${e.message}',
        );
        return ApprovalResult.failure(
          'Failed to save to Firebase: ${e.message ?? e.code}',
          code: e.code,
          error: e,
        );
      } catch (e) {
        // Catch timeout and other exceptions
        debugPrint('❌ Error saving to approved collection: $e');
        if (e.toString().contains('timed out') ||
            e.toString().contains('TimeoutException')) {
          return ApprovalResult.failure(
            'Approval save timed out. Please try again.',
            code: 'TIMEOUT',
            error: e,
          );
        }
        return ApprovalResult.failure(
          'Failed to save: ${e.toString()}',
          error: e,
        );
      }

      // Delete from pending collection
      try {
        await _firestore
            .collection('profiling_pending')
            .doc(pendingDocId)
            .delete()
            .timeout(const Duration(seconds: 20));
      } on FirebaseException catch (e) {
        debugPrint(
          '⚠️ Firebase error removing from pending collection: ${e.code} - ${e.message}',
        );
        // Continue even if delete fails - record was already approved
      } on SocketException catch (e) {
        debugPrint('⚠️ Network error removing from pending collection: $e');
        // Continue even if delete fails - record was already approved
      }

      debugPrint(
        '✅ Profile approved and moved to profiling_forms: $pendingDocId by $approverEmail',
      );
      return ApprovalResult.success();
    } on FirebaseException catch (e) {
      debugPrint(
        '❌ Firebase error approving profile: ${e.code} - ${e.message}',
      );
      return ApprovalResult.failure(
        'Firebase error: ${e.message ?? e.code}',
        code: e.code,
        error: e,
      );
    } on SocketException catch (e) {
      debugPrint('❌ Network error approving profile: $e');
      return ApprovalResult.failure(
        'Network error: Check your connection',
        error: e,
      );
    } catch (e) {
      debugPrint('❌ Error approving profile: $e');
      return ApprovalResult.failure(
        'Unexpected error: ${e.toString()}',
        error: e,
      );
    }
  }

  /// Load approved farmer records for Existing Farmer prefill in Step 1.
  /// Only returns records with non-empty SAAD I.D No.
  Future<List<ProfilingData>> loadExistingFarmersForPrefill() async {
    try {
      final snapshot = await _firestore
          .collection('profiling_forms')
          .where('status', isEqualTo: 'Approved')
          .get()
          .timeout(const Duration(seconds: 20));

      final farmers = <ProfilingData>[];
      for (final doc in snapshot.docs) {
        try {
          final data = _jsonToProfilingData(doc.data());
          data.tempIdFirebase ??= doc.id;
          final saadNo = data.saadIdNo?.trim() ?? '';
          if (saadNo.isNotEmpty) {
            farmers.add(data);
          }
        } catch (_) {
          continue;
        }
      }

      farmers.sort(
        (a, b) => (b.updatedAt ?? DateTime(1970)).compareTo(
          a.updatedAt ?? DateTime(1970),
        ),
      );
      return farmers;
    } catch (e) {
      debugPrint('❌ Error loading existing farmers for prefill: $e');
      return [];
    }
  }

  /// Reject a pending profile
  /// Returns ApprovalResult with detailed error information
  Future<ApprovalResult> rejectPendingProfile(
    String pendingDocId,
    String rejectionReason,
  ) async {
    try {
      try {
        await _firestore
            .collection('profiling_pending')
            .doc(pendingDocId)
            .update({
              'status': 'Rejected',
              'rejectionReason': rejectionReason,
              'updatedAt': DateTime.now().toIso8601String(),
            })
            .timeout(const Duration(seconds: 20));
      } on SocketException catch (e) {
        debugPrint('❌ Network error rejecting profile: $e');
        return ApprovalResult.failure(
          'Network error: Check your connection',
          error: e,
        );
      } on FirebaseException catch (e) {
        debugPrint(
          '❌ Firebase error rejecting profile: ${e.code} - ${e.message}',
        );
        return ApprovalResult.failure(
          'Failed to reject profile: ${e.message ?? e.code}',
          code: e.code,
          error: e,
        );
      } catch (e) {
        // Catch timeout and other exceptions
        debugPrint('❌ Error rejecting profile: $e');
        if (e.toString().contains('timed out') ||
            e.toString().contains('TimeoutException')) {
          return ApprovalResult.failure(
            'Rejection operation timed out. Please try again.',
            code: 'TIMEOUT',
            error: e,
          );
        }
        return ApprovalResult.failure(
          'Failed to process rejection: ${e.toString()}',
          error: e,
        );
      }

      debugPrint('✅ Profile rejected: $pendingDocId');
      return ApprovalResult.success();
    } on FirebaseException catch (e) {
      debugPrint(
        '❌ Firebase error in rejectPendingProfile: ${e.code} - ${e.message}',
      );
      return ApprovalResult.failure(
        'Firebase error: ${e.message ?? e.code}',
        code: e.code,
        error: e,
      );
    } on SocketException catch (e) {
      debugPrint('❌ Network error in rejectPendingProfile: $e');
      return ApprovalResult.failure(
        'Network error: Check your connection',
        error: e,
      );
    } catch (e) {
      debugPrint('❌ Error rejecting profile: $e');
      return ApprovalResult.failure(
        'Unexpected error: ${e.toString()}',
        error: e,
      );
    }
  }

  /// Load approved profiles only
  /// Load approved profiles from Firebase ONLY (profiling_forms collection)
  /// These are profiles that have been synced and approved by admin
  /// Do NOT mix with local data
  Future<List<ProfilingData>> loadApprovedProfiles(String userId) async {
    try {
      debugPrint('🔍 Loading approved profiles for userId=$userId');
      // Approved profiles are public — return all docs with status='Approved'
      final snapshot = await _firestore
          .collection('profiling_forms')
          .where('status', isEqualTo: 'Approved')
          .get();

      debugPrint(
        '   Query returned ${snapshot.docs.length} approved doc(s) for userId=$userId',
      );
      if (snapshot.docs.isEmpty) {
        debugPrint(
          '   ⚠️ No approved docs for this userId. Trying enumeratorEmail fallback...',
        );
        // Try fallback: search by enumeratorEmail == current user's email
        try {
          final currentEmail = FirebaseAuth.instance.currentUser?.email;
          if (currentEmail != null && currentEmail.isNotEmpty) {
            final byEmail = await _firestore
                .collection('profiling_forms')
                .where('enumeratorEmail', isEqualTo: currentEmail)
                .where('status', isEqualTo: 'Approved')
                .get();
            debugPrint(
              '   Fallback by enumeratorEmail returned ${byEmail.docs.length} doc(s)',
            );
            if (byEmail.docs.isNotEmpty) {
              // Use the email-matched docs as our snapshot for processing below
              // Reassign snapshot variable via a new local list of docs
              final profiles = <ProfilingData>[];
              for (final doc in byEmail.docs) {
                try {
                  final data = _jsonToProfilingData(doc.data());
                  data.tempIdFirebase = doc.id;
                  profiles.add(data);
                  debugPrint(
                    '  ✓ Loaded (email match): ${data.firstName} ${data.surname} (ID: ${doc.id})',
                  );
                } catch (parseError) {
                  debugPrint(
                    '  ⚠️ Failed to parse document ${doc.id}: $parseError',
                  );
                }
              }
              profiles.sort(
                (a, b) => (b.updatedAt ?? DateTime(1970)).compareTo(
                  a.updatedAt ?? DateTime(1970),
                ),
              );
              debugPrint(
                '✅ Returning ${profiles.length} approved profile(s) via enumeratorEmail fallback',
              );
              return profiles;
            }
          }
        } catch (e) {
          debugPrint('   ⚠️ EnumeratorEmail fallback failed: $e');
        }

        debugPrint(
          '   ⚠️ enumeratorEmail fallback found nothing — showing a small sample of approved docs for debugging:',
        );
        final sample = await _firestore
            .collection('profiling_forms')
            .where('status', isEqualTo: 'Approved')
            .limit(5)
            .get();
        debugPrint('   Sample approved count: ${sample.docs.length}');
        final sampleProfiles = <ProfilingData>[];
        for (final doc in sample.docs) {
          try {
            final pdata = _jsonToProfilingData(doc.data());
            pdata.tempIdFirebase = doc.id;
            sampleProfiles.add(pdata);
            debugPrint(
              '     - Doc ${doc.id}: userId=${doc.data()['userId']}, enumerator=${doc.data()['enumeratorEmail']}, status=${doc.data()['status']}',
            );
          } catch (_) {}
        }
        if (sampleProfiles.isNotEmpty) {
          sampleProfiles.sort(
            (a, b) => (b.updatedAt ?? DateTime(1970)).compareTo(
              a.updatedAt ?? DateTime(1970),
            ),
          );
          debugPrint(
            '✅ Returning ${sampleProfiles.length} sample approved profile(s) as fallback',
          );
          return sampleProfiles;
        }
      }

      final profiles = <ProfilingData>[];
      for (final doc in snapshot.docs) {
        final data = _jsonToProfilingData(doc.data());
        data.tempIdFirebase = doc.id;
        // Marked as approved by status in Firestore
        profiles.add(data);
      }

      // Sort: newest first
      profiles.sort(
        (a, b) => (b.updatedAt ?? DateTime(1970)).compareTo(
          a.updatedAt ?? DateTime(1970),
        ),
      );

      debugPrint(
        '✅ Loaded ${profiles.length} approved profile(s) from Firebase for user $userId',
      );
      return profiles;
    } catch (e) {
      debugPrint('❌ Error loading approved profiles: $e');
      return [];
    }
  }

  /// Load all profiles combining local drafts + pending (Firestore) + approved (Firestore)
  /// - Local drafts are loaded from disk first for instant UI display
  /// - Pending and approved profiles are fetched from Firestore in the background
  /// - Local drafts that match a pending doc (by `tempIdLocal` / `tempIdFirebase`) are
  ///   marked as Pending Approval so the UI can render them as yellow
  Future<List<ProfilingData>> loadAllProfilesMerged(String userId) async {
    try {
      // 1) Local drafts (fast, disk-only)
      final localDrafts = await loadDraftsFromDiskOnly();

      // 2) Firestore pending + approved
      final pending = await loadPendingProfiles();
      final approved = await loadApprovedProfiles(userId);

      // Filter pending to this user's uploads (pending loader does not filter by user)
      final pendingForUser = pending.where((p) => p.userId == userId).toList();

      // Build maps by best-known id to avoid duplicates
      final Map<String, ProfilingData> merged = {};

      String keyFor(ProfilingData p) {
        if (p.tempIdFirebase != null && p.tempIdFirebase!.isNotEmpty) {
          return 'f:${p.tempIdFirebase}';
        }
        if (p.tempIdLocal != null && p.tempIdLocal!.isNotEmpty) {
          return 'l:${p.tempIdLocal}';
        }
        if (p.farmerFolderName != null) return 'name:${p.farmerFolderName}';
        return 'u:${p.updatedAt?.toIso8601String() ?? ''}';
      }

      // Add approved first (highest trust)
      for (final a in approved) {
        merged[keyFor(a)] = a;
      }

      // Add pending (override local/approved if same id key)
      for (final p in pendingForUser) {
        merged[keyFor(p)] = p;
      }

      // Add local drafts; if they match a pending doc, mark as Pending Approval
      for (final l in localDrafts) {
        // Try to match by tempIdLocal -> pending
        final match = pendingForUser.firstWhere(
          (p) =>
              (p.tempIdLocal != null && p.tempIdLocal == l.tempIdLocal) ||
              (p.tempIdFirebase != null &&
                  p.tempIdFirebase == l.tempIdFirebase),
          orElse: () => ProfilingData(),
        );

        if (match.tempIdLocal != null || match.tempIdFirebase != null) {
          // Mark local copy as pending so UI shows yellow; preserve local paths
          l.status = 'Pending Approval';
          // copy timestamps from pending if available
          l.createdAt = l.createdAt ?? match.createdAt;
          l.updatedAt = match.updatedAt ?? l.updatedAt;
        }

        final key = keyFor(l);
        // Don't overwrite an approved record with a plain local draft
        if (!merged.containsKey(key)) merged[key] = l;
      }

      // Convert merged map to list and sort by updatedAt desc
      final result = merged.values.toList();
      result.sort(
        (a, b) => (b.updatedAt ?? DateTime(1970)).compareTo(
          a.updatedAt ?? DateTime(1970),
        ),
      );
      debugPrint(
        '✅ Merged ${result.length} profiles (local+pending+approved) for user $userId',
      );
      return result;
    } catch (e) {
      debugPrint('❌ Error merging profiles: $e');
      return [];
    }
  }

  /// Clear ALL local disk data (remove all farmer folders)
  /// Nuclear option for debugging/reset
  Future<void> clearAllLocalData() async {
    try {
      final appDir = await _imageStorageService.getAppDirectory();
      if (await appDir.exists()) {
        final entities = await appDir.list().toList();
        for (final entity in entities) {
          if (entity is Directory) {
            await entity.delete(recursive: true);
          }
        }
      }
      debugPrint('✅ Cleared all local disk data');
    } catch (e) {
      debugPrint('❌ Error clearing local data: $e');
    }
  }
}
