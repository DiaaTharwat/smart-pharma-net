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
  // -- ✨ تم التصحيح النهائي والكامل ✨ --
  Future<Map<String, dynamic>> createBuyOrder({
    required String medicineName,
    required String price,
    required int quantity,
    required String pharmacySeller, // Name of the selling pharmacy
    required String pharmacyBuyer,  // Name of the buying pharmacy
    required String pharmacyBuyerId, // ✨ رجعنا نستخدم الـ ID تاني
    required String recieveDate,    // The new date field
  }) async {
    try {
      print('Creating buy order for pharmacy ID: $pharmacyBuyerId...');
      final payload = {
        'medicine_name': medicineName,
        'price': price,
        'quantity': quantity,
        'pharmacy_seller': pharmacySeller,
        'pharmacy_buyer': pharmacyBuyer,
        'recieve_date': recieveDate,
        'status': 'Pending',
      };
      print('Payload: $payload');

      // ✨ تم استخدام الدالة الصحيحة 'postForPharmacy' اللي بتبعت الـ ID في الرابط
      final response = await _apiService.postForPharmacy(
        'exchange/buy/order/', // ده الجزء الأول من الرابط
        payload,
        pharmacyId: pharmacyBuyerId, // ودي الدالة بتضيفها للرابط
      );

      return response;
    } catch (e) {
      print('Error creating buy order: $e');
      rethrow;
    }
  }
}