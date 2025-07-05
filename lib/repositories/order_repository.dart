// lib/repositories/order_repository.dart
import 'package:smart_pharma_net/models/order_model.dart';
import 'package:smart_pharma_net/models/important_notification_model.dart';
import 'package:smart_pharma_net/services/api_service.dart';

class OrderRepository {
  final ApiService _apiService;

  OrderRepository(this._apiService);

  // Get orders where the current pharmacy is the seller
  Future<List<OrderModel>> getIncomingOrdersForSeller({required String pharmacyId}) async {
    try {
      print('Fetching incoming orders for seller pharmacy ID: $pharmacyId...');

      // -- تعديل نهائي --
      // تم بناء الرابط الصحيح يدويًا هنا ليتوافق مع السيرفر
      // بدلاً من استخدام `getForPharmacy` التي كانت تضيف مسارًا خاطئًا
      final String fullEndpoint = 'exchange/get/pharmcy_seller/orders/$pharmacyId/';
      print('Calling corrected endpoint: $fullEndpoint');
      final response = await _apiService.authenticatedGet(fullEndpoint);

      if (response is List) {
        return response.map((json) => OrderModel.fromJson(json)).toList();
      }
      // Added a check for a specific error message from the backend
      if (response is Map && response['detail'] == 'No orders found for this pharmacy.') {
        return []; // Return an empty list if no orders are found
      }
      throw Exception('Invalid response format for incoming orders');
    } catch (e) {
      // If the error indicates no orders, return an empty list gracefully.
      if (e.toString().contains('No orders found')) {
        return [];
      }
      print('Error fetching incoming orders: $e');
      rethrow;
    }
  }

  // This function now fetches important notifications
  Future<List<ImportantNotificationModel>> getImportantNotifications({required String pharmacyId}) async {
    try {
      print('Fetching important notifications for pharmacy ID: $pharmacyId...');

      // -- تعديل نهائي --
      // تم بناء الرابط الصحيح يدويًا هنا أيضًا
      final String fullEndpoint = 'exchange/get_notification/pharmacy/$pharmacyId/';
      print('Calling corrected endpoint: $fullEndpoint');
      final response = await _apiService.authenticatedGet(fullEndpoint);

      if (response is List) {
        return response.map((json) => ImportantNotificationModel.fromJson(json)).toList();
      }
      // Added a check for a specific error message from the backend
      if (response is Map && response['detail'] == 'No notifications found for this pharmacy.') {
        return []; // Return an empty list if no notifications are found
      }
      throw Exception('Invalid response format for important notifications');
    } catch (e) {
      // If the error indicates no notifications, return an empty list gracefully.
      if (e.toString().contains('No notifications found')) {
        return [];
      }
      print('Error fetching important notifications: $e');
      rethrow;
    }
  }

  // Update order status
  Future<OrderModel> updateOrderStatus(String orderId, String newStatus) async {
    try {
      print('Updating order $orderId status to $newStatus...');
      final payload = {'status': newStatus};
      final response = await _apiService.patchWithId(
        'exchange/update_status/',
        payload,
        resourceId: orderId,
      );

      return OrderModel.fromJson(response);
    } catch (e) {
      print('Error updating order status: $e');
      rethrow;
    }
  }
}