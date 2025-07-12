// lib/repositories/dashboard_repository.dart
import 'package:flutter/foundation.dart';
import 'package:smart_pharma_net/services/api_service.dart';

class DashboardRepository {
  final ApiService _apiService;

  DashboardRepository(this._apiService);

  Future<Map<String, dynamic>> fetchDashboardData({String? pharmacyId}) async {
    String endpoint = 'account/dashboard/';
    if (pharmacyId != null && pharmacyId.isNotEmpty) {
      endpoint = 'account/dashboard/?pharmacy_id=$pharmacyId';
    }
    try {
      final data = await _apiService.authenticatedGet(endpoint);
      return data ?? {};
    } catch (e) {
      if (kDebugMode) {
        print("[DashboardRepository] Error fetching dashboard data: $e");
      }
      rethrow;
    }
  }

  // ✨✨ دالة جديدة لجلب الطلبات ✨✨
  Future<List<dynamic>> fetchOrdersForPharmacy(String pharmacyId) async {
    try {
      // استدعاء نقطة النهاية التي تعيد كل الطلبات لصيدلية معينة
      final orders = await _apiService.get('exchange/get/pharmcy_seller/orders/$pharmacyId/');
      // تأكد من أن الـ API يعيد قائمة
      return orders is List ? orders : [];
    } catch (e) {
      print("[DashboardRepository] Error fetching orders for pharmacy $pharmacyId: $e");
      rethrow;
    }
  }
}