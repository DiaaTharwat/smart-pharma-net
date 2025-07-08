import 'package:smart_pharma_net/services/api_service.dart';
import '../models/dashboard_model.dart';

class DashboardRepository {
  final ApiService _apiService;

  DashboardRepository(this._apiService);

  Future<DashboardStats> getDashboardStats({int? pharmacyId}) async {
    try {
      final data = await _apiService.getDashboardData(pharmacyId: pharmacyId);
      return DashboardStats.fromJson(data);
    } catch (e) {
      print("Error in DashboardRepository: $e");
      rethrow;
    }
  }
}