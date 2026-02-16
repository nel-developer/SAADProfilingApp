/// CommodityData — Represents a single commodity entry from the spreadsheet
/// Used for dynamic dropdown/selection in profiling forms
class CommodityData {
  String? id; // Firestore document ID
  String? type; // Type: Livestock, Poultry, HVC, Corn, Rice, Others
  String? commodity; // Livestock, Poultry, Fishing, Rice, Corn, HVC, etc.
  String? saleMeth; // Sale Method, e.g., "Live Animal", "Meat Retail", "By-product"
  String? productForm; // Product Form, e.g., "Swine", "Chicken", "Fish Capture"
  String? pricingBasis; // Pricing Basis, e.g., "Per Head", "Per Kilogram", "Bottle"
  String? unit; // Unit, e.g., "Head", "Kilograms", "Liters", "Service"
  bool? maleRequired; // Checkbox: is male field required?
  bool? femaleRequired; // Checkbox: is female field required?
  bool? totalWeightRequired; // Checkbox: is total weight required?
  bool? totalPriceRequired; // Checkbox: is total price required?
  bool? expensesRequired; // Checkbox: are expenses required?
  String? remarks; // Additional notes
  DateTime? createdAt;
  DateTime? updatedAt;

  CommodityData({
    this.id,
    this.type,
    this.commodity,
    this.saleMeth,
    this.productForm,
    this.pricingBasis,
    this.unit,
    this.maleRequired,
    this.femaleRequired,
    this.totalWeightRequired,
    this.totalPriceRequired,
    this.expensesRequired,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });

  /// Convert CommodityData to Firestore-safe map
  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'commodity': commodity,
      'saleMeth': saleMeth,
      'productForm': productForm,
      'pricingBasis': pricingBasis,
      'unit': unit,
      'maleRequired': maleRequired ?? false,
      'femaleRequired': femaleRequired ?? false,
      'totalWeightRequired': totalWeightRequired ?? false,
      'totalPriceRequired': totalPriceRequired ?? false,
      'expensesRequired': expensesRequired ?? false,
      'remarks': remarks,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Convert Firestore JSON to CommodityData
  factory CommodityData.fromFirestore(Map<String, dynamic> json, String docId) {
    return CommodityData(
      id: docId,
      type: json['type'],
      commodity: json['commodity'],
      saleMeth: json['saleMeth'],
      productForm: json['productForm'],
      pricingBasis: json['pricingBasis'],
      unit: json['unit'],
      maleRequired: json['maleRequired'] ?? false,
      femaleRequired: json['femaleRequired'] ?? false,
      totalWeightRequired: json['totalWeightRequired'] ?? false,
      totalPriceRequired: json['totalPriceRequired'] ?? false,
      expensesRequired: json['expensesRequired'] ?? false,
      remarks: json['remarks'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  /// Copy constructor for editing
  CommodityData copyWith({
    String? id,
    String? type,
    String? commodity,
    String? saleMeth,
    String? productForm,
    String? pricingBasis,
    String? unit,
    bool? maleRequired,
    bool? femaleRequired,
    bool? totalWeightRequired,
    bool? totalPriceRequired,
    bool? expensesRequired,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CommodityData(
      id: id ?? this.id,
      type: type ?? this.type,
      commodity: commodity ?? this.commodity,
      saleMeth: saleMeth ?? this.saleMeth,
      productForm: productForm ?? this.productForm,
      pricingBasis: pricingBasis ?? this.pricingBasis,
      unit: unit ?? this.unit,
      maleRequired: maleRequired ?? this.maleRequired,
      femaleRequired: femaleRequired ?? this.femaleRequired,
      totalWeightRequired: totalWeightRequired ?? this.totalWeightRequired,
      totalPriceRequired: totalPriceRequired ?? this.totalPriceRequired,
      expensesRequired: expensesRequired ?? this.expensesRequired,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
