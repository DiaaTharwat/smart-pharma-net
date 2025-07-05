// lib/repositories/exchange_repository.dart
import 'package:smart_pharma_net/models/exchange_medicine_model.dart';
import 'package:smart_pharma_net/services/api_service.dart';

class ExchangeRepository {
  final ApiService _apiService;

  ExchangeRepository(this._apiService);

  // Fetches medicines available for exchange from other pharmacies
  Future<List<ExchangeMedicineModel>> getExchangeList() async {
    try {
      print('Fetching exchange list from backend...');
      final response = await _apiService.authenticatedGet('exchange/exchange_list/');

      if (response is List) {
        return response.map((json) => ExchangeMedicineModel.fromJson(json)).toList();
      }
      throw Exception('Invalid response format for exchange list');
    } catch (e) {
      print('Error fetching exchange list: $e');
      rethrow;
    }
  }

  // Sends a buy order for a medicine to another pharmacy
  // -- تعديل --
  // تم إضافة `pharmacyBuyerId` المطلوب لإرساله في الرابط الجديد
  Future<Map<String, dynamic>> createBuyOrder({
    required String medicineName,
    required String price, // This should be medicine_price_to_sell
    required int quantity,
    required String pharmacySeller,
    required String pharmacyBuyer, // This is the name of the pharmacy making the order
    required String pharmacyBuyerId, // This is the ID of the pharmacy making the order
  }) async {
    try {
      print('Creating buy order for pharmacy ID: $pharmacyBuyerId...');
      final payload = {
        'medicine_name': medicineName,
        'price': price,
        'quantity': quantity,
        'pharmacy_seller': pharmacySeller,
        'pharmacy_buyer': pharmacyBuyer, // مازال مطلوبًا في جسم الطلب
        'status': 'Pending', // Initial status
      };
      print('Payload: $payload');

      // -- تعديل --
      // تم استبدال `_apiService.post` بالدالة الجديدة `postForPharmacy`
      // لكي يتم بناء المسار الصحيح الذي يتضمن `pharmacy_id`
      final response = await _apiService.postForPharmacy(
        'exchange/buy/order/',
        payload,
        pharmacyId: pharmacyBuyerId,
      );

      return response; // Assuming API returns confirmation or order details
    } catch (e) {
      print('Error creating buy order: $e');
      rethrow;
    }
  }
}