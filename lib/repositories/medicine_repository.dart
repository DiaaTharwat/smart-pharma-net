// lib/repositories/medicine_repository.dart
import '../models/medicine_model.dart';
import '../services/api_service.dart';

class MedicineRepository {
  final ApiService _apiService;
  // Endpoint for management (protected)
  static const String _managementEndpoint = 'medicine/medicines/';
  // Endpoint for public search (as used on the website)
  static const String _publicSearchEndpoint = 'search_medicine/';

  // --- إضافة: رابط جديد خاص بالمالك ---
  static const String _ownerEndpoint = 'medicine/owner/pharmacies/';


  // Helper method to process API responses for medicines
  List<MedicineModel> _processMedicineList(dynamic response, String source) {
    print('Response received from $source: $response');

    if (response is List) {
      final medicines = response.map((json) => MedicineModel.fromJson(json)).toList();
      print('Successfully parsed ${medicines.length} medicines from $source');
      return medicines;
    }
    print('Invalid response format from $source: $response');
    return []; // Return empty list instead of throwing exception
  }

  MedicineRepository(this._apiService);

  Future<List<MedicineModel>> getAllMedicines() async {
    try {
      print('Getting all medicines from public endpoint...');
      final response = await _apiService.get(_publicSearchEndpoint);
      return _processMedicineList(response, 'all-medicines');
    } catch (e) {
      print('Error getting all medicines: $e');
      rethrow;
    }
  }

  // --- تم تعديل هذه الدالة بالكامل ---
  Future<List<MedicineModel>> getMedicinesForPharmacy(String pharmacyId) async {
    try {
      print('Getting medicines for pharmacy: $pharmacyId using OWNER endpoint');

      // نقوم ببناء الرابط الصحيح الخاص بالمالك
      final String fullOwnerEndpoint = '$_ownerEndpoint$pharmacyId/medicines/';

      // نستخدم الرابط الجديد لاستدعاء الـ API
      final response = await _apiService.authenticatedGet(fullOwnerEndpoint);

      // لم نعد بحاجة للفلترة هنا، لأن السيرفر يرجع أدوية هذه الصيدلية فقط
      return _processMedicineList(response, 'medicines-for-pharmacy-$pharmacyId');
    } catch (e) {
      print('Error getting medicines for pharmacy: $e');
      return [];
    }
  }

  Future<List<MedicineModel>> searchMedicines(String query) async {
    try {
      print('Searching medicines with query: $query');
      final response = await _apiService.get('$_publicSearchEndpoint?query=${Uri.encodeComponent(query)}');
      print('Search response received: $response');
      if (response is List) {
        final medicines = response.map((json) => MedicineModel.fromJson(json)).toList();
        print('Successfully parsed ${medicines.length} medicines from search');
        return medicines;
      }
      print('Invalid search response format: $response');
      throw Exception('Invalid search response format');
    } catch (e) {
      print('Error searching medicines: $e');
      rethrow;
    }
  }

  Future<MedicineModel> getMedicineDetails(String id) async {
    try {
      print('Getting medicine details for ID: $id');
      final response = await _apiService.get('$_managementEndpoint$id/');
      print('Medicine details response: $response');
      return MedicineModel.fromJson(response);
    } catch (e) {
      print('Error getting medicine details: $e');
      rethrow;
    }
  }

  Future<MedicineModel> addMedicine(Map<String, dynamic> medicineData) async {
    try {
      print('Adding new medicine...');
      print('Medicine data: $medicineData');
      final response = await _apiService.post(_managementEndpoint, medicineData, headers: _apiService.pharmacyHeaders);
      if (response == null) {
        throw Exception('Failed to add medicine: No response from server');
      }
      return MedicineModel.fromJson(response);
    } catch (e) {
      print('Error adding medicine: $e');
      throw Exception('Failed to add medicine: ${e.toString()}');
    }
  }

  Future<void> updateMedicine(String id, Map<String, dynamic> medicineData) async {
    try {
      print('Updating medicine with ID: $id using PATCH');
      print('Update data: $medicineData');

      await _apiService.patch('$_managementEndpoint$id/', medicineData, headers: _apiService.pharmacyHeaders);

    } catch (e) {
      print('Error updating medicine in repository: $e');
      rethrow;
    }
  }

  Future<void> deleteMedicine(String id) async {
    try {
      print('Deleting medicine with ID: $id');
      await _apiService.delete('$_managementEndpoint$id/', '', headers: _apiService.pharmacyHeaders);
      print('Medicine deleted successfully');
    } catch (e) {
      print('Error deleting medicine: $e');
      rethrow;
    }
  }
}