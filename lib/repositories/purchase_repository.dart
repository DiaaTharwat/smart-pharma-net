import 'package:smart_pharma_net/models/user_purchase_model.dart';
import 'package:smart_pharma_net/services/api_service.dart';

class PurchaseRepository {
  final ApiService _apiService;

  PurchaseRepository(this._apiService);

  // --- تم التعديل هنا ---
  // تم تحديث نوع البيانات المستقبلة إلى الموديل الجديد
  Future<void> createUserPurchase(UserPurchase purchaseData) async {
    try {
      // الدالة دي بتستخدم `publicPost` بشكل صحيح لأن المستخدم غير مسجل
      await _apiService.publicPost('exchange/user_purchase/', purchaseData.toJson());
    } catch (e) {
      print('Error creating user purchase in repository: $e');
      rethrow;
    }
  }
}