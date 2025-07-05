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

  ExchangeMedicineModel({
    required this.id,
    required this.medicineName,
    required this.medicinePriceToSell,
    required this.medicineQuantityToSell,
    required this.pharmacyName,
    required this.pharmacyLatitude,
    required this.pharmacyLongitude,
    required this.pharmacyId,
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
    );
  }

  // --- الدالة المفقودة التي تسببت في الخطأ ---
  // هذه الدالة تسمح بنسخ الكائن مع تعديل بعض خصائصه
  ExchangeMedicineModel copyWith({
    String? id,
    String? medicineName,
    String? medicinePriceToSell,
    String? medicineQuantityToSell,
    String? pharmacyName,
    String? pharmacyLatitude,
    String? pharmacyLongitude,
    String? pharmacyId,
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
    );
  }
}