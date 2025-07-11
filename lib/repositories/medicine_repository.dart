import '../models/medicine_model.dart';
import '../services/api_service.dart';

class MedicineRepository {
  final ApiService _apiService;
  // Endpoint للصيدلية لإدارة أدويتها
  static const String _pharmacyManagmentEndpoint = 'medicine/medicines/';
  // Endpoint للبحث العام
  static const String _publicSearchEndpoint = 'search_medicine/';
  // Endpoint للمالك لإدارة كل الصيدليات
  static const String _ownerEndpoint = 'medicine/owner/pharmacies/';


  List<MedicineModel> _processMedicineList(dynamic response, String source) {
    print('Response received from $source: $response');

    if (response is List) {
      final medicines = response.map((json) => MedicineModel.fromJson(json)).toList();
      print('Successfully parsed ${medicines.length} medicines from $source');
      return medicines;
    }
    print('Invalid response format from $source: $response');
    return [];
  }

  MedicineRepository(this._apiService);

  // ========== Fix Start: Updated to handle paginated response ==========
  Future<List<MedicineModel>> getAllMedicines() async {
    try {
      print('Getting all medicines from public endpoint...');
      final response = await _apiService.get(_publicSearchEndpoint);

      // The response from the server is now paginated. We need to extract the 'results' list.
      if (response is Map<String, dynamic> && response.containsKey('results')) {
        return _processMedicineList(response['results'], 'all-medicines');
      }

      print('Invalid or unexpected response format from all-medicines: $response');
      // Return empty list if the format is not what we expect.
      return [];
    } catch (e) {
      print('Error getting all medicines: $e');
      rethrow;
    }
  }
  // ========== Fix End ==========

  // ========== Fix Start: Added Role-based Endpoint Logic ==========
  Future<List<MedicineModel>> getMedicinesForPharmacy(String pharmacyId) async {
    try {
      final role = await _apiService.userRole;
      String endpoint;

      if (role == 'admin') {
        print('Getting medicines for pharmacy: $pharmacyId using OWNER endpoint');
        endpoint = '$_ownerEndpoint$pharmacyId/medicines/';
      } else { // role == 'pharmacy'
        print('Getting medicines for own pharmacy using PHARMACY endpoint');
        // الصيدلية تجلب أدويتها من الرابط المباشر، والسيرفر يعرفها من التوكين
        endpoint = _pharmacyManagmentEndpoint;
      }

      final response = await _apiService.authenticatedGet(endpoint);
      return _processMedicineList(response, 'medicines-for-pharmacy-$pharmacyId');
    } catch (e) {
      print('Error getting medicines for pharmacy: $e');
      return [];
    }
  }
  // ========== Fix End ==========

  // ========== Fix Start: Updated to use correct query parameter and handle paginated response ==========
  Future<List<MedicineModel>> searchMedicines(String query) async {
    try {
      // The swagger file now uses 'search' as the query parameter, not 'query'.
      final endpoint = '$_publicSearchEndpoint?search=${Uri.encodeComponent(query)}';
      print('Searching medicines with query: "$query" at endpoint: $endpoint');
      final response = await _apiService.get(endpoint);

      // The response from the server is paginated. We need to extract the 'results' list.
      if (response is Map<String, dynamic> && response.containsKey('results')) {
        return _processMedicineList(response['results'], 'search-medicines');
      }

      print('Invalid or unexpected response format from search-medicines: $response');
      // Return empty list if the format is not what we expect.
      return [];
    } catch (e) {
      print('Error searching medicines: $e');
      rethrow;
    }
  }
  // ========== Fix End ==========


  Future<MedicineModel> getMedicineDetails(String id) async {
    try {
      print('Getting medicine details for ID: $id');
      final response = await _apiService.get('$_pharmacyManagmentEndpoint$id/');
      return MedicineModel.fromJson(response);
    } catch (e) {
      print('Error getting medicine details: $e');
      rethrow;
    }
  }

  // ========== Fix Start: Added Role-based Endpoint Logic ==========
  Future<MedicineModel> addMedicine({required Map<String, dynamic> medicineData, required String pharmacyId}) async {
    try {
      final role = await _apiService.userRole;
      String endpoint;

      if (role == 'admin') {
        endpoint = '$_ownerEndpoint$pharmacyId/medicines/';
        print('Adding new medicine using OWNER endpoint: $endpoint');
      } else { // role == 'pharmacy'
        endpoint = _pharmacyManagmentEndpoint;
        print('Adding new medicine using PHARMACY endpoint: $endpoint');
      }

      print('Medicine data: $medicineData');
      final response = await _apiService.post(endpoint, medicineData, headers: _apiService.pharmacyHeaders);

      if (response == null) {
        throw Exception('Failed to add medicine: No response from server');
      }
      return MedicineModel.fromJson(response);
    } catch (e) {
      print('Error adding medicine: $e');
      throw Exception('Failed to add medicine: ${e.toString()}');
    }
  }
  // ========== Fix End ==========

  // ========== Fix Start: Added Role-based Endpoint Logic ==========
  Future<void> updateMedicine({required String pharmacyId, required String medicineId, required Map<String, dynamic> medicineData}) async {
    try {
      final role = await _apiService.userRole;
      String endpoint;

      if (role == 'admin') {
        endpoint = '$_ownerEndpoint$pharmacyId/medicines/$medicineId/';
        print('Updating medicine using OWNER endpoint: $endpoint');
      } else { // role == 'pharmacy'
        endpoint = '$_pharmacyManagmentEndpoint$medicineId/';
        print('Updating medicine using PHARMACY endpoint: $endpoint');
      }

      await _apiService.patch(endpoint, medicineData, headers: _apiService.pharmacyHeaders);
    } catch (e) {
      print('Error updating medicine in repository: $e');
      rethrow;
    }
  }
  // ========== Fix End ==========

  // ========== Fix Start: Added Role-based Endpoint Logic ==========
  Future<void> deleteMedicine({required String pharmacyId, required String medicineId}) async {
    try {
      final role = await _apiService.userRole;
      String endpoint;

      if (role == 'admin') {
        endpoint = '$_ownerEndpoint$pharmacyId/medicines/$medicineId/';
        print('Deleting medicine using OWNER endpoint: $endpoint');
      } else { // role == 'pharmacy'
        endpoint = '$_pharmacyManagmentEndpoint$medicineId/';
        print('Deleting medicine using PHARMACY endpoint: $endpoint');
      }

      // The delete method in ApiService was changed to not require a second id
      await _apiService.delete(endpoint, '', headers: _apiService.pharmacyHeaders);
    } catch (e) {
      print('Error deleting medicine in repository: $e');
      rethrow;
    }
  }
// ========== Fix End ==========
}