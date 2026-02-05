import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:da_project_1/models/profiling_data.dart';
import 'dart:convert';
import 'package:da_project_1/services/image_storage_service.dart';

/// ProfilingStorageService — Manages local (Hive) and cloud (Firestore) storage
/// Users explicitly call save() to persist locally; sync() to upload when online
class ProfilingStorageService {
  static const String _boxName = 'profiling_drafts';
  static const String _currentDraftKey = 'current_draft';

  late Box<String> _box;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();

  /// Initialize Hive
  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<String>(_boxName);
  }

  /// Save profiling data locally (explicit save)
  /// User must call this; it's not automatic
  Future<void> saveDraftLocally(ProfilingData data) async {
    try {
      data.updatedAt = DateTime.now();
      final jsonString = jsonEncode(_profilingDataToJson(data));
      await _box.put(_currentDraftKey, jsonString);
      print('✅ Draft saved locally');
      // Also write a visible JSON draft into the farmer folder if available
      try {
        final imageService = ImageStorageService();
        String folderName = data.farmerFolderName ?? '';
        if (folderName.isEmpty) {
          // generate from full name
          final fullName = '${data.firstName ?? ''} ${data.middleName ?? ''} ${data.surname ?? ''}'.trim();
          folderName = imageService.generateFarmerFolderNameFromFullName(fullName);
          // persist generated folder name back to data
          data.farmerFolderName = folderName;
        }
        await imageService.saveDraftJson(data.farmerFolderName!, _profilingDataToJson(data));
      } catch (e) {
        print('⚠️ Failed to write visible draft JSON: $e');
      }
    } catch (e) {
      print('❌ Error saving draft locally: $e');
      rethrow;
    }
  }

  /// Load draft from local storage
  Future<ProfilingData?> loadDraftLocally() async {
    try {
      final jsonString = _box.get(_currentDraftKey);
      if (jsonString == null) return null;
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return _jsonToProfilingData(json);
    } catch (e) {
      print('❌ Error loading draft: $e');
      return null;
    }
  }

  /// Delete local draft
  Future<void> deleteDraftLocally() async {
    try {
      await _box.delete(_currentDraftKey);
      print('✅ Draft deleted locally');
    } catch (e) {
      print('❌ Error deleting draft: $e');
      rethrow;
    }
  }

  /// Check if device is online
  Future<bool> isOnline() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      print('❌ Error checking connectivity: $e');
      return false;
    }
  }

  /// Sync local draft to Firestore (when online)
  Future<bool> syncToFirestore(ProfilingData data, String userId) async {
    try {
      final online = await isOnline();
      if (!online) {
        print('⚠️ Device offline — cannot sync');
        return false;
      }

      data.userId = userId;
      data.isSynced = true;

      // Upload to Firestore
      await _firestore
          .collection('profiling_forms')
          .doc(userId)
          .set(data.toFirestore(), SetOptions(merge: true));

      print('✅ Synced to Firestore');

      // Mark as synced in local storage
      await saveDraftLocally(data);
      return true;
    } catch (e) {
      print('❌ Error syncing to Firestore: $e');
      return false;
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
      'isIndigenous': data.isIndigenous,
      'indigenousGroup': data.indigenousGroup,
      'isPWD': data.isPWD,
      'maritalStatus': data.maritalStatus,
      'spouseName': data.spouseName,
      'primaryCommodity': data.primaryCommodity,
      'primaryCommodityOthers': data.primaryCommodityOthers,
      'secondaryCommodity': data.secondaryCommodity,
      'secondaryCommodityOthers': data.secondaryCommodityOthers,
      'maleFamilyMembers': data.maleFamilyMembers,
      'femaleFamilyMembers': data.femaleFamilyMembers,
      'yearsInFarming': data.yearsInFarming,
      'landTenureship': data.landTenureship,
      'landTenureshipOthers': data.landTenureshipOthers,
      'secondaryCommodityRecurrence': data.secondaryCommodityRecurrence,
      'secondaryCommodityOthersRecurrence': data.secondaryCommodityOthersRecurrence,
      'yearCovered': data.yearCovered,
      'receivedCommodity': data.receivedCommodity,
      'receivedCommodityOthers': data.receivedCommodityOthers,
      'agriRelatedIncome': data.agriRelatedIncome,
      'saadNetIncome': data.saadNetIncome,
      'nonAgriRelatedIncome': data.nonAgriRelatedIncome,
      'mainSourcesOfIncome': data.mainSourcesOfIncome,
      'primaryAmount': data.primaryAmount,
      'primaryRemarks': data.primaryRemarks,
      'secondaryAmount': data.secondaryAmount,
      'secondaryRemarks': data.secondaryRemarks,
      'idType': data.idType,
      'idFrontImagePath': data.idFrontImagePath,
      'idBackImagePath': data.idBackImagePath,
      'farmerPhotoPath': data.farmerPhotoPath,
      'signatureImagePath': data.signatureImagePath,
      'farmerFolderName': data.farmerFolderName,
      'userId': data.userId,
      'createdAt': data.createdAt?.toIso8601String(),
      'updatedAt': data.updatedAt?.toIso8601String(),
      'isSynced': data.isSynced ?? false,
    };
  }

  /// Convert JSON to ProfilingData
  ProfilingData _jsonToProfilingData(Map<String, dynamic> json) {
    return ProfilingData(
      firstName: json['firstName'],
      middleName: json['middleName'],
      surname: json['surname'],
      extensionName: json['extensionName'],
      region: json['region'],
      province: json['province'],
      municipality: json['municipality'],
      barangay: json['barangay'],
      sitioPurok: json['sitioPurok'],
      dateOfBirth: json['dateOfBirth'],
      sex: json['sex'],
      isIndigenous: json['isIndigenous'],
      indigenousGroup: json['indigenousGroup'],
      isPWD: json['isPWD'],
      maritalStatus: json['maritalStatus'],
      spouseName: json['spouseName'],
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
      secondaryCommodityOthersRecurrence: json['secondaryCommodityOthersRecurrence'],
      yearCovered: json['yearCovered'],
      receivedCommodity: json['receivedCommodity'],
      receivedCommodityOthers: json['receivedCommodityOthers'],
      agriRelatedIncome: json['agriRelatedIncome']?.toDouble(),
      saadNetIncome: json['saadNetIncome']?.toDouble(),
      nonAgriRelatedIncome: json['nonAgriRelatedIncome']?.toDouble(),
      mainSourcesOfIncome: json['mainSourcesOfIncome'],
      primaryAmount: json['primaryAmount'],
      primaryRemarks: json['primaryRemarks'],
      secondaryAmount: json['secondaryAmount'],
      secondaryRemarks: json['secondaryRemarks'],
      idType: json['idType'],
      idFrontImagePath: json['idFrontImagePath'],
      idBackImagePath: json['idBackImagePath'],
      farmerPhotoPath: json['farmerPhotoPath'],
      signatureImagePath: json['signatureImagePath'],
      farmerFolderName: json['farmerFolderName'],
      userId: json['userId'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      isSynced: json['isSynced'] ?? false,
    );
  }
}
