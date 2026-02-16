import 'dart:typed_data';

/// ProfilingData — Complete model for all 8 profiling steps
/// Stores all form data locally before uploading to Firestore
class ProfilingData {
  // Step 1: Personal Information
  String? firstName;
  String? middleName;
  String? surname;
  String? extensionName;

  // Step 2: Address Information
  String? region;
  String? province;
  String? municipality;
  String? barangay;
  String? sitioPurok;
  String? dateOfBirth;
  String? sex;

  // Step 3: Other Personal Information
  bool? isIndigenous;
  String? indigenousGroup;
  bool? isPWD;
  String? spouseName;
  String? tribeEthnicity;
  
  
  // Step 4: Main Commodity
  String? primaryCommodity;
  String? primaryCommodityOthers;
  String? secondaryCommodity;
  String? secondaryCommodityOthers;

  // Step 5: Recurrence
  int? maleFamilyMembers;
  int? femaleFamilyMembers;
  int? yearsInFarming;
  String? landTenureship;
  String? landTenureshipOthers;
  String? secondaryCommodityRecurrence;
  String? secondaryCommodityOthersRecurrence;
  String? secondaryCommodityRecurrenceOthers;
  // Recurrence for primary commodity
  bool? primaryCommodityRecurrence;
  String? primaryCommodityRecurrenceOthers;
  int? yearCovered;
  String? receivedCommodity;
  String? receivedCommodityOthers;

  // Step 6: Monthly Family Income
  double? agriRelatedIncome;
  double? saadNetIncome;
  double? nonAgriRelatedIncome;
  String? mainSourcesOfIncome;

  // Step 7: Farm/Fisheries Income
  String? primaryAmount;
  String? primaryRemarks;
  String? secondaryAmount;
  String? secondaryRemarks;
  String? primaryCommodityIncome;
  String? primaryCommodityRemarks;
  String? secondaryCommodityIncome;
  String? secondaryCommodityRemarks;
  
  // Specific commodities income and remarks
  String? riceIncomeField;
  String? riceRemarks;
  String? hvcIncomeField;
  String? hvcRemarks;
  String? livestockIncomeField;
  String? livestockRemarks;
  String? fishingIncomeField;
  String? fishingRemarks;
  String? nonFarmFisheriesIncomeField;
  String? nonFarmFisheriesRemarks;

  // Farmers/Fishers Cooperative
  String? cooperativeName;
  String? cooperativePosition;
  String? dateOfMembership;
  String? cooperativePositionOthers;

  // Step 8: Signature
  String? idType;
  String? idFrontImagePath;
  String? idBackImagePath;
  String? farmerPhotoPath;
  String? signatureImagePath;
  Uint8List? signatureImage;

  // Meta
  String? userId;
  String? status;
  String? enumeratorEmail;
  String? approverEmail;
  DateTime? approvedAt;
    String? farmerFolderName; // Unique folder identifier for organizing images
  String? tempIdLocal;
  String? tempIdFirebase;
  DateTime? createdAt;
  DateTime? updatedAt;

  ProfilingData({
    this.firstName,
    this.middleName,
    this.surname,
    this.extensionName,
    this.region,
    this.province,
    this.municipality,
    this.barangay,
    this.sitioPurok,
    this.dateOfBirth,
    this.sex,
    this.isIndigenous,
    this.indigenousGroup,
    this.isPWD,
    this.spouseName,
    this.tribeEthnicity,
        this.primaryCommodity,
    this.primaryCommodityOthers,
    this.secondaryCommodity,
    this.secondaryCommodityOthers,
    this.maleFamilyMembers,
    this.femaleFamilyMembers,
    this.yearsInFarming,
    this.landTenureship,
    this.landTenureshipOthers,
    this.secondaryCommodityRecurrence,
    this.secondaryCommodityOthersRecurrence,
    this.secondaryCommodityRecurrenceOthers,
    this.primaryCommodityRecurrence,
    this.primaryCommodityRecurrenceOthers,
    this.yearCovered,
    this.receivedCommodity,
    this.receivedCommodityOthers,
    this.agriRelatedIncome,
    this.saadNetIncome,
    this.nonAgriRelatedIncome,
    this.mainSourcesOfIncome,
    this.primaryAmount,
    this.primaryRemarks,
    this.secondaryAmount,
    this.secondaryRemarks,
    this.primaryCommodityIncome,
    this.primaryCommodityRemarks,
    this.secondaryCommodityIncome,
    this.secondaryCommodityRemarks,
    this.riceIncomeField,
    this.riceRemarks,
    this.hvcIncomeField,
    this.hvcRemarks,
    this.livestockIncomeField,
    this.livestockRemarks,
    this.fishingIncomeField,
    this.fishingRemarks,
    this.nonFarmFisheriesIncomeField,
    this.nonFarmFisheriesRemarks,
    this.cooperativeName,
    this.cooperativePosition,
    this.dateOfMembership,
    this.cooperativePositionOthers,
    this.idType,
    this.idFrontImagePath,
    this.idBackImagePath,
    this.farmerPhotoPath,
    this.signatureImagePath,
    this.signatureImage,
    this.userId,
    this.status,
    this.enumeratorEmail,
    this.approverEmail,
    this.approvedAt,
        this.farmerFolderName,
    this.tempIdLocal,
    this.tempIdFirebase,
    this.createdAt,
    this.updatedAt,
  });

  // Backwards-compatible getters used by older UI code
  int? get numberOfMalesInFamily => maleFamilyMembers;
  int? get numberOfFemalesInFamily => femaleFamilyMembers;
  String? get primaryCommodityIncomeRemarks => primaryCommodityRemarks;
  String? get secondaryCommodityIncomeRemarks => secondaryCommodityRemarks;

  /// Convert to Firestore-ready map (excluding image paths for now)
  /// Convert ProfilingData to Firestore-safe format
  /// NOTE: Image paths are EXCLUDED - images stay local only
  /// - idFrontImagePath, idBackImagePath, farmerPhotoPath, signatureImagePath not included
  /// - Only profiling form data (personal info, commodities, income, etc) syncs
  Map<String, dynamic> toFirestore() {
    return {
      'firstName': firstName,
      'middleName': middleName,
      'surname': surname,
      'extensionName': extensionName,
      'region': region,
      'province': province,
      'municipality': municipality,
      'barangay': barangay,
      'sitioPurok': sitioPurok,
      'dateOfBirth': dateOfBirth,
      'sex': sex,
      'isIndigenous': isIndigenous,
      'indigenousGroup': indigenousGroup,
      'isPWD': isPWD,
      'spouseName': spouseName,
      'tribeEthnicity': tribeEthnicity,
      'primaryCommodity': primaryCommodity,
      'primaryCommodityOthers': primaryCommodityOthers,
      'secondaryCommodity': secondaryCommodity,
      'secondaryCommodityOthers': secondaryCommodityOthers,
      'maleFamilyMembers': maleFamilyMembers,
      'femaleFamilyMembers': femaleFamilyMembers,
      'yearsInFarming': yearsInFarming,
      'landTenureship': landTenureship,
      'landTenureshipOthers': landTenureshipOthers,
      'secondaryCommodityRecurrence': secondaryCommodityRecurrence,
      'secondaryCommodityOthersRecurrence': secondaryCommodityOthersRecurrence,
      'secondaryCommodityRecurrenceOthers': secondaryCommodityRecurrenceOthers,
      'primaryCommodityRecurrence': primaryCommodityRecurrence,
      'primaryCommodityRecurrenceOthers': primaryCommodityRecurrenceOthers,
      'yearCovered': yearCovered,
      'receivedCommodity': receivedCommodity,
      'receivedCommodityOthers': receivedCommodityOthers,
      'agriRelatedIncome': agriRelatedIncome,
      'saadNetIncome': saadNetIncome,
      'nonAgriRelatedIncome': nonAgriRelatedIncome,
        'enumeratorEmail': enumeratorEmail,
        'farmerFolderName': farmerFolderName,
      'primaryAmount': primaryAmount,
      'primaryRemarks': primaryRemarks,
      'secondaryAmount': secondaryAmount,
      'secondaryRemarks': secondaryRemarks,
      // legacy primary/secondary fields removed in favor of specific commodity fields
      'riceIncomeField': riceIncomeField,
      'riceRemarks': riceRemarks,
      'hvcIncomeField': hvcIncomeField,
      'hvcRemarks': hvcRemarks,
      'livestockIncomeField': livestockIncomeField,
      'livestockRemarks': livestockRemarks,
      'fishingIncomeField': fishingIncomeField,
      'fishingRemarks': fishingRemarks,
      'nonFarmFisheriesIncomeField': nonFarmFisheriesIncomeField,
      'nonFarmFisheriesRemarks': nonFarmFisheriesRemarks,
      'cooperativeName': cooperativeName,
      'cooperativePosition': cooperativePosition,
      'dateOfMembership': dateOfMembership,
      'cooperativePositionOthers': cooperativePositionOthers,
      'idType': idType,
      'userId': userId,
      'status': status,
      'approverEmail': approverEmail,
      'approvedAt': approvedAt?.toIso8601String(),
      'tempIdLocal': tempIdLocal,
      'tempIdFirebase': tempIdFirebase,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
