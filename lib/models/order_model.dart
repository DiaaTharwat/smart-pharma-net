// lib/models/order_model.dart
class OrderModel {
  final String id;
  final String medicineName;
  final String price;
  final int quantity;
  final String pharmacyBuyer;
  final String status;
  final String? createdAt; // Made nullable
  final String? updatedAt; // Made nullable

  OrderModel({
    required this.id,
    required this.medicineName,
    required this.price,
    required this.quantity,
    required this.pharmacyBuyer,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Ensuring 'id' is always a non-null string, providing a fallback empty string
    final String parsedId = json['id']?.toString() ?? '';
    if (parsedId.isEmpty && json.containsKey('id') && json['id'] != null) {
      // If 'id' is explicitly null or empty string from JSON, but key exists,
      // it indicates a potential issue in backend or unexpected response.
      // For robustness, we might throw an error or log a warning.
      print('Warning: Order JSON contains null or empty ID for: $json');
    }

    return OrderModel(
      id: parsedId,
      // تأكد من إضافة .toString() قبل ?? '' للحقول التي يجب أن تكون String
      medicineName: json['med_name']?.toString() ?? 'N/A Medicine', // <--- تعديل هنا
      price: json['price']?.toString() ?? '0.0',
      quantity: int.tryParse(json['quantity']?.toString() ?? '') ?? 0,
      pharmacyBuyer: json['pharma_buyer']?.toString() ?? 'Unknown Pharmacy', // <--- تعديل هنا
      status: json['status']?.toString() ?? 'Unknown Status', // <--- تعديل هنا
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'med_name': medicineName,
      'price': price,
      'quantity': quantity,
      'pharma_buyer': pharmacyBuyer,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // New: Add copyWith method
  OrderModel copyWith({
    String? id,
    String? medicineName,
    String? price,
    int? quantity,
    String? pharmacyBuyer,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      medicineName: medicineName ?? this.medicineName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      pharmacyBuyer: pharmacyBuyer ?? this.pharmacyBuyer,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}