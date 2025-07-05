// lib/repositories/purchase_repository.dart

import 'package:smart_pharma_net/models/user_purchase_model.dart';
import 'package:smart_pharma_net/services/api_service.dart';

class PurchaseRepository {
  final ApiService _apiService;

  PurchaseRepository(this._apiService);

  Future<void> createUserPurchase(UserPurchaseModel purchaseData) async {
    try {
      // --- تم التعديل هنا ---
      // تم استبدال `post` بدالة `publicPost` لأن هذه العملية
      // يجب أن تكون متاحة للمستخدمين غير المسجلين.
      await _apiService.publicPost('exchange/user_purchase/', purchaseData.toJson());
    } catch (e) {
      print('Error creating user purchase in repository: $e');
      rethrow;
    }
  }
}