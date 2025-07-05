// lib/repositories/pharmacy_repository.dart
import '../models/pharmacy_model.dart';
import '../services/api_service.dart';

class PharmacyRepository {
  final ApiService _apiService;

  PharmacyRepository(this._apiService);

  Future<List<PharmacyModel>> getAllPharmacies() async {
    try {
      final response = await _apiService.get('account/pharmacy/');
      if (response is List) {
        return response.map((json) => PharmacyModel.fromJson(json)).toList();
      }
      throw Exception('Invalid response format');
    } catch (e) {
      print('Error getting pharmacies: $e');
      rethrow;
    }
  }

  Future<PharmacyModel> getPharmacyDetails(String id) async {
    final response = await _apiService.get('account/pharmacy/$id');
    return PharmacyModel.fromJson(response);
  }

  Future<PharmacyModel> addPharmacy(Map<String, dynamic> pharmacyData) async {
    try {
      print('Adding pharmacy with data: $pharmacyData');
      final response = await _apiService.post('account/pharmacy/', pharmacyData);
      return PharmacyModel.fromJson(response);
    } catch (e) {
      print('Error adding pharmacy: $e');
      rethrow;
    }
  }

  // ==================== NEW METHOD ====================
  Future<PharmacyModel> updatePharmacy(String id, Map<String, dynamic> pharmacyData) async {
    try {
      print('Updating pharmacy $id with data: $pharmacyData');
      // The endpoint for update is account/pharmacy/{id}/
      final response = await _apiService.update('account/pharmacy/$id/', pharmacyData);
      return PharmacyModel.fromJson(response);
    } catch (e) {
      print('Error updating pharmacy: $e');
      rethrow;
    }
  }
  // ===================================================

  Future<List<PharmacyModel>> searchPharmacies(String query) async {
    final response = await _apiService.get('account/pharmacy/search?query=$query');
    if (response is List) {
      return response.map((json) => PharmacyModel.fromJson(json)).toList();
    }
    return [];
  }

  Future<void> deletePharmacy(String pharmacyId) async {
    try {
      print('Attempting to delete pharmacy with ID: $pharmacyId');
      await _apiService.delete('account/pharmacy/', '$pharmacyId/');
      print('Pharmacy deletion successful');
    } catch (e) {
      print('Error deleting pharmacy: $e');
      rethrow;
    }
  }
}