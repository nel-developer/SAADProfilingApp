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
  String? maritalStatus;
  String? spouseName;

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

  // Step 8: Signature
  String? idType;
  String? idFrontImagePath;
  String? idBackImagePath;
  String? farmerPhotoPath;
  String? signatureImagePath;
  Uint8List? signatureImage;

  // Meta
  String? userId;
  String? farmerFolderName; // Unique folder identifier for organizing images
  DateTime? createdAt;
  DateTime? updatedAt;
  bool? isSynced; // true if uploaded to Firestore

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
    this.maritalStatus,
    this.spouseName,
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
    this.idType,
    this.idFrontImagePath,
    this.idBackImagePath,
    this.farmerPhotoPath,
    this.signatureImagePath,
    this.signatureImage,
    this.userId,
    this.farmerFolderName,
    this.createdAt,
    this.updatedAt,
    this.isSynced = false,
  });

  /// Convert to Firestore-ready map (excluding image paths for now)
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
      'maritalStatus': maritalStatus,
      'spouseName': spouseName,
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
      'yearCovered': yearCovered,
      'receivedCommodity': receivedCommodity,
      'receivedCommodityOthers': receivedCommodityOthers,
      'agriRelatedIncome': agriRelatedIncome,
      'saadNetIncome': saadNetIncome,
      'nonAgriRelatedIncome': nonAgriRelatedIncome,
      'mainSourcesOfIncome': mainSourcesOfIncome,
      'primaryAmount': primaryAmount,
      'primaryRemarks': primaryRemarks,
      'secondaryAmount': secondaryAmount,
      'secondaryRemarks': secondaryRemarks,
      'idType': idType,
      'idFrontImagePath': idFrontImagePath,
      'idBackImagePath': idBackImagePath,
      'farmerPhotoPath': farmerPhotoPath,
      'signatureImagePath': signatureImagePath,
      'farmerFolderName': farmerFolderName,
      'userId': userId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isSynced': isSynced ?? false,
    };
  }
}
