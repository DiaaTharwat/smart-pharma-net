import 'package:flutter/foundation.dart' show immutable;

@immutable
class UserPurchase {
  final String username;
  final String email;
  final String phoneNumber;
  final String address;
  final String medicine;
  // --- تم التعديل هنا ---
  // تم إضافة حقل نوع الشراء ليكون متوافقًا مع الـ Swagger
  final String? typePurchase; // Can be 'visa' or 'cash_on_delivery'

  const UserPurchase({
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.medicine,
    this.typePurchase, // حقل اختياري
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'username': username,
      'email': email,
      'phone_number': phoneNumber,
      'address': address,
      'medicine': medicine,
    };
    // نتأكد إننا مش هنضيف الحقل لو كان فاضي
    if (typePurchase != null) {
      data['type_purchase'] = typePurchase;
    }
    return data;
  }
}