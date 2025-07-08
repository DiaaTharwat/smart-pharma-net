// lib/repositories/dashboard_repository.dart

import 'package:smart_pharma_net/services/api_service.dart';

class DashboardRepository {
  final ApiService _apiService;

  DashboardRepository(this._apiService);

  Future<Map<String, dynamic>> getAdminDashboardData() async {
    try {
      final data = await _apiService.getDashboardData();
      return data ?? {};
    } catch (e) {
      print("Error in getAdminDashboardData: $e");
      rethrow;
    }
  }

  // دالة جديدة لجلب بيانات الصيدلية المسجلة دخول
  Future<Map<String, dynamic>> getLoggedInPharmacyDashboardData() async {
    try {
      // نستدعي الرابط العام، والسيرفر سيتعرف على الصيدلية من التوكن
      final data = await _apiService.getDashboardData();
      return data ?? {};
    } catch (e) {
      print("Error in getLoggedInPharmacyDashboardData: $e");
      rethrow;
    }
  }
}