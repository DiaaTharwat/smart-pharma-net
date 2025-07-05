// lib/models/user_purchase_model.dart

class UserPurchaseModel {
  final String username;
  final String email;
  final String phoneNumber;
  final String address;
  final String medicine;

  UserPurchaseModel({
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.medicine,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'phone_number': phoneNumber,
      'address': address,
      'medicine': medicine,
    };
  }
}