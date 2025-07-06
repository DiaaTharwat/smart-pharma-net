// lib/models/exchange_medicine_model.dart

class ExchangeMedicineModel {
  final String id;
  final String medicineName;
  final String medicinePriceToSell;
  final String medicineQuantityToSell;
  final String pharmacyName;
  final String pharmacyLatitude;
  final String pharmacyLongitude;
  final String pharmacyId;
  final String medicineExpiryDate; // تم إضافته
  final String? imageUrl; // تم إضافته

  ExchangeMedicineModel({
    required this.id,
    required this.medicineName,
    required this.medicinePriceToSell,
    required this.medicineQuantityToSell,
    required this.pharmacyName,
    required this.pharmacyLatitude,
    required this.pharmacyLongitude,
    required this.pharmacyId,
    required this.medicineExpiryDate,
    this.imageUrl,
  });

  factory ExchangeMedicineModel.fromJson(Map<String, dynamic> json) {
    return ExchangeMedicineModel(
      id: json['id']?.toString() ?? '',
      medicineName: json['medicine_name'] ?? 'Unknown Medicine',
      medicinePriceToSell: json['medicine_price_to_sell']?.toString() ?? '0.0',
      medicineQuantityToSell: json['medicine_quantity_to_sell']?.toString() ?? '0',
      pharmacyName: json['pharmacy_name'] ?? 'Unknown Pharmacy',
      pharmacyLatitude: json['pharmacy_latitude']?.toString() ?? '0.0',
      pharmacyLongitude: json['pharmacy_longitude']?.toString() ?? '0.0',
      pharmacyId: json['pharmacy_id']?.toString() ?? '',
      // ملاحظة: تأكد من أن الـ API يرسل هذه الحقول بنفس الأسماء
      medicineExpiryDate: json['medicine_expiry_date'] ?? 'N/A',
      imageUrl: json['image_url'],
    );
  }

  ExchangeMedicineModel copyWith({
    String? id,
    String? medicineName,
    String? medicinePriceToSell,
    String? medicineQuantityToSell,
    String? pharmacyName,
    String? pharmacyLatitude,
    String? pharmacyLongitude,
    String? pharmacyId,
    String? medicineExpiryDate,
    String? imageUrl,
  }) {
    return ExchangeMedicineModel(
      id: id ?? this.id,
      medicineName: medicineName ?? this.medicineName,
      medicinePriceToSell: medicinePriceToSell ?? this.medicinePriceToSell,
      medicineQuantityToSell:
      medicineQuantityToSell ?? this.medicineQuantityToSell,
      pharmacyName: pharmacyName ?? this.pharmacyName,
      pharmacyLatitude: pharmacyLatitude ?? this.pharmacyLatitude,
      pharmacyLongitude: pharmacyLongitude ?? this.pharmacyLongitude,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      medicineExpiryDate: medicineExpiryDate ?? this.medicineExpiryDate,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}