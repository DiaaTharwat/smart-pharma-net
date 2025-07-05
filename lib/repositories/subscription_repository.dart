// lib/repositories/subscription_repository.dart
import 'package:smart_pharma_net/services/api_service.dart'; // تأكد من المسار الصحيح

class SubscriptionRepository {
  final ApiService _apiService; // Add ApiService as a dependency

  SubscriptionRepository(this._apiService); // Constructor now takes ApiService

  // الدالة الآن تتطلب `pharmacyId` و `type` للاشتراك
  Future<Map<String, dynamic>> subscribe({required String type, required String pharmacyId}) async {
    try {
      print('Subscribing pharmacy ID: $pharmacyId to plan: $type');

      // جسم الطلب الآن يحتوي على النوع فقط، لأن الصيدلية يتم تحديدها من الرابط
      final payload = {'type': type};

      // يتم استخدام الدالة الجديدة `postForPharmacy` لبناء الرابط الصحيح
      final dynamic responseData = await _apiService.postForPharmacy(
        'exchange/subscripe/', // نقطة النهاية الأساسية من السواجر
        payload,
        pharmacyId: pharmacyId,
      );

      if (responseData != null && responseData is Map<String, dynamic>) {
        return responseData;
      } else {
        throw Exception('Unexpected response format from subscription API.');
      }
    } catch (e) {
      print('Error subscribing: $e');
      rethrow;
    }
  }
}