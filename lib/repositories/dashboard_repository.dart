import 'package:flutter/foundation.dart';
import 'package:smart_pharma_net/services/api_service.dart';

class DashboardRepository {
  final ApiService _apiService;

  DashboardRepository(this._apiService);

  /// Fetches dashboard data from the backend.
  ///
  /// The backend API at 'account/dashboard/' is responsible for returning
  /// the correct data based on the user's authentication token.
  /// It will return aggregated data for an Admin/Owner, or specific data
  /// for a logged-in Pharmacy.
  Future<Map<String, dynamic>> fetchDashboardData() async {
    try {
      // This single method call is sufficient as the backend handles the logic.
      final data = await _apiService.getDashboardData();
      if (kDebugMode) {
        print("[DashboardRepository] Fetched data: $data");
      }
      return data ?? {};
    } catch (e) {
      if (kDebugMode) {
        print("[DashboardRepository] Error fetching dashboard data: $e");
      }
      // Propagate the error to the ViewModel for user-friendly handling.
      rethrow;
    }
  }

// NOTE: The function `getPharmacyDashboardById` has been removed.
// The endpoint 'account/dashboard/{id}/' which it tried to call does not
// exist in the provided Swagger API documentation.
// The logic for handling an admin impersonating a pharmacy is now correctly
// managed within the DashboardViewModel by using the full data list
// fetched for the admin.
}
