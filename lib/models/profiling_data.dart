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
  String? rsbsaFishrIdNo;
  String? saadIdNo;
  bool? isExistingFarmer;
  String? selectedExistingSaadId;

  // Step 3: Other Personal Information
  bool? isIndigenous;
  String? indigenousGroup;
  bool? isPWD;
  String? maritalStatus; // 'married', 'single', 'widowed'
  String? spouseName;
  String? tribeEthnicity;

  // Step 4: SAAD Commodity Type
  String? saadCommodityType;
  List<Map<String, dynamic>>? saadCommodities;

  // Step 5: Non-SAAD Commodity Type
  String? nonSAADCommodityType;
  List<Map<String, dynamic>>? nonSAADCommodities;

  // Step 6: Main Commodity
  String? primaryCommodity;
  String? primaryCommodityOthers;
  String? secondaryCommodity;
  String? secondaryCommodityOthers;

  // Step 7: Recurrence
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
  Map<String, dynamic>? recurrenceByYear;
  String? receivedCommodity;
  String? receivedCommodityOthers;
  // Received commodity expanded: primary + secondary types
  String? receivedPrimaryCommodity;
  String? receivedSecondaryCommodity;
  // Received commodity financials
  double? receivedTotalPrice;
  double? receivedExpenses;
  String? receivedRemarks;

  // Step 8: Monthly Family Income
  double? agriRelatedIncome;
  double? saadNetIncome;
  double? nonSAADNetIncome;
  double? nonAgriRelatedIncome;
  String? mainSourcesOfIncome;

  // Step 9: Farm/Fisheries Income
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

  // Non-Farm/Fisheries Income (3 beneficiary types)
  String? beneficiaryNonFarmIncome;
  String? beneficiaryRemarks; // added for multiline notes
  String? spouseNonFarmIncome;
  String? spouseRemarks;
  String? otherMembersNonFarmIncome;
  String? otherMembersRemarks; // added for multiline notes

  // Step 10: Signature & Images
  String? idType;
  String? idFrontImagePath;
  String? idBackImagePath;
  String? farmerPhotoPath;
  String? signatureImagePath;
  Uint8List? signatureImage;

  // System fields
  String? farmerFolderName; // Unique folder identifier for organizing images
  String? tempIdLocal;
  String? tempIdFirebase;
  DateTime? createdAt;
  DateTime? updatedAt;

  // Cooperative fields
  String? cooperativeName;
  String? cooperativePosition;
  String? dateOfMembership;
  String? cooperativePositionOthers;

  // User & Status fields
  String? userId;
  String? status;
  String? enumeratorEmail;
  String? approverEmail;
  DateTime? approvedAt;

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
    this.rsbsaFishrIdNo,
    this.saadIdNo,
    this.isExistingFarmer,
    this.selectedExistingSaadId,
    this.isIndigenous,
    this.indigenousGroup,
    this.isPWD,
    this.maritalStatus,
    this.spouseName,
    this.tribeEthnicity,
    this.saadCommodityType,
    this.saadCommodities,
    this.nonSAADCommodityType,
    this.nonSAADCommodities,
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
    this.recurrenceByYear,
    this.receivedCommodity,
    this.receivedCommodityOthers,
    this.receivedPrimaryCommodity,
    this.receivedSecondaryCommodity,
    this.receivedTotalPrice,
    this.receivedExpenses,
    this.receivedRemarks,
    this.agriRelatedIncome,
    this.saadNetIncome,
    this.nonSAADNetIncome,
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
    this.beneficiaryNonFarmIncome,
    this.beneficiaryRemarks,
    this.spouseNonFarmIncome,
    this.spouseRemarks,
    this.otherMembersNonFarmIncome,
    this.otherMembersRemarks,
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
      'rsbsaFishrIdNo': rsbsaFishrIdNo,
      'saadIdNo': saadIdNo,
      'isExistingFarmer': isExistingFarmer,
      'selectedExistingSaadId': selectedExistingSaadId,
      'isIndigenous': isIndigenous,
      'indigenousGroup': indigenousGroup,
      'isPWD': isPWD,
      'maritalStatus': maritalStatus,
      'spouseName': spouseName,
      'tribeEthnicity': tribeEthnicity,
      'saadCommodityType': saadCommodityType,
      'saadCommodities': saadCommodities,
      'nonSAADCommodityType': nonSAADCommodityType,
      'nonSAADCommodities': nonSAADCommodities,
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
      'recurrenceByYear': recurrenceByYear,
      'receivedCommodity': receivedCommodity ?? receivedPrimaryCommodity,
      'receivedCommodityOthers': receivedCommodityOthers,
      'receivedPrimaryCommodity': receivedPrimaryCommodity,
      'receivedSecondaryCommodity': receivedSecondaryCommodity,
      'receivedTotalPrice': receivedTotalPrice,
      'receivedExpenses': receivedExpenses,
      'receivedRemarks': receivedRemarks,
      'agriRelatedIncome': agriRelatedIncome,
      'saadNetIncome': saadNetIncome,
      'nonSAADNetIncome': nonSAADNetIncome,
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
      'spouseRemarks': spouseRemarks,
      'nonFarmFisheriesIncomeField': nonFarmFisheriesIncomeField,
      'nonFarmFisheriesRemarks': nonFarmFisheriesRemarks,
      'beneficiaryNonFarmIncome': beneficiaryNonFarmIncome,
      'beneficiaryRemarks': beneficiaryRemarks,
      'spouseNonFarmIncome': spouseNonFarmIncome,
      'otherMembersNonFarmIncome': otherMembersNonFarmIncome,
      'otherMembersRemarks': otherMembersRemarks,
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
