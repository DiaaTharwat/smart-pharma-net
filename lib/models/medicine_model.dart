// lib/models/medicine_model.dart

class MedicineModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final int quantity;
  final String pharmacyId;
  final String pharmacyName; // Added this field
  final String category;
  final String expiryDate;
  final bool canBeSell;
  final int? quantityToSell;
  final double priceSell;
  final double? distance;
  final String? imageUrl; // NEW: Added imageUrl field

  MedicineModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.pharmacyId,
    required this.pharmacyName, // Added to constructor
    required this.category,
    required this.expiryDate,
    required this.canBeSell,
    this.quantityToSell,
    required this.priceSell,
    this.distance,
    this.imageUrl, // NEW: Added to constructor
  });

  factory MedicineModel.fromJson(Map<String, dynamic> json) {
    // Helper to safely extract pharmacy name from the nested structure
    String getPharmacyName(Map<String, dynamic> jsonData) {
      if (jsonData.containsKey('pharmacy_location') &&
          jsonData['pharmacy_location'] is Map &&
          jsonData['pharmacy_location'].containsKey('pharmacy_name')) {
        return jsonData['pharmacy_location']['pharmacy_name'] as String;
      }
      return 'Unknown Pharmacy'; // Fallback value
    }

    return MedicineModel(
      id: json['id'].toString(),
      name: json['name'] as String,
      description: json['description'] as String,
      price: double.parse(json['price'].toString()),
      quantity: int.parse(json['quantity'].toString()),
      pharmacyId: (json['pharmacy'] ?? json['pharmacy_id'] ?? json['pharmacyId'])?.toString() ?? '',
      pharmacyName: getPharmacyName(json), // Use the helper to parse the name
      category: json['category'] as String,
      expiryDate: json['exp_date'] as String,
      canBeSell: json['can_be_sell'] as bool,
      quantityToSell: json['quantity_to_sell'] != null ? int.parse(json['quantity_to_sell'].toString()) : null,
      priceSell: double.parse(json['price_sell'].toString()),
      distance: json['distance'] != null ? double.tryParse(json['distance'].toString()) : null,
      imageUrl: json['image_url'] as String?, // NEW: Parse imageUrl
    );
  }

  // --- تم التعديل هنا ---
  // تم حذف الحقول الـ readOnly مثل `id` و `pharmacy` من هنا
  // لضمان عدم إرسالها للسيرفر بالخطأ في أي مكان مستقبلاً
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price.toString(),
      'quantity': quantity,
      'category': category,
      'exp_date': expiryDate,
      'can_be_sell': canBeSell,
      'quantity_to_sell': quantityToSell,
      'price_sell': priceSell.toString(),
      'image_url': imageUrl,
    };
  }

  MedicineModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    int? quantity,
    String? pharmacyId,
    String? pharmacyName,
    String? category,
    String? expiryDate,
    bool? canBeSell,
    int? quantityToSell,
    double? priceSell,
    double? distance,
    String? imageUrl, // NEW: Added to copyWith
  }) {
    return MedicineModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      pharmacyName: pharmacyName ?? this.pharmacyName,
      category: category ?? this.category,
      expiryDate: expiryDate ?? this.expiryDate,
      canBeSell: canBeSell ?? this.canBeSell,
      quantityToSell: quantityToSell ?? this.quantityToSell,
      priceSell: priceSell ?? this.priceSell,
      distance: distance ?? this.distance,
      imageUrl: imageUrl ?? this.imageUrl, // NEW: Handle imageUrl in copyWith
    );
  }
}