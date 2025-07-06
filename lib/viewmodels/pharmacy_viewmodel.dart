import 'package:flutter/foundation.dart';
import 'package:smart_pharma_net/models/pharmacy_model.dart';
import 'package:smart_pharma_net/repositories/pharmacy_repository.dart';
import 'package:smart_pharma_net/models/medicine_model.dart';
import 'package:smart_pharma_net/repositories/medicine_repository.dart';
import 'package:smart_pharma_net/viewmodels/auth_viewmodel.dart'; // <<< تم إضافة هذا السطر

class PharmacyViewModel extends ChangeNotifier {
  final PharmacyRepository _pharmacyRepository;
  final MedicineRepository _medicineRepository;
  List<PharmacyModel> _pharmacies = [];
  List<MedicineModel> _pharmacyMedicines = [];
  bool _isLoading = false;
  String _error = '';

  PharmacyViewModel(this._pharmacyRepository, this._medicineRepository);

  List<PharmacyModel> get pharmacies => _pharmacies;
  List<MedicineModel> get pharmacyMedicines => _pharmacyMedicines;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> addPharmacy({
    required String name,
    required String city,
    required String licenseNumber,
    required double latitude,
    required double longitude,
    required String password,
    required String confirmPassword,
    required AuthViewModel authViewModel, // <<< تم إضافة هذا السطر
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final pharmacyData = {
        'name': name.trim(),
        'city': city.trim(),
        'license_number': licenseNumber.trim(),
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'password': password,
        'confirm_password': confirmPassword,
      };

      await _pharmacyRepository.addPharmacy(pharmacyData);
      // بعد الإضافة، قم بتحديث القائمة
      await loadPharmacies(searchQuery: '', authViewModel: authViewModel);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      throw Exception('Failed to add pharmacy: $e');
    }
  }

  Future<void> updatePharmacy({
    required String id,
    required String name,
    required String city,
    required String licenseNumber,
    required double latitude,
    required double longitude,
    required AuthViewModel authViewModel, // <<< تم إضافة هذا السطر
    String? password,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final pharmacyData = {
        'name': name.trim(),
        'city': city.trim(),
        'license_number': licenseNumber.trim(),
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        if (password != null && password.isNotEmpty) 'password': password,
      };

      await _pharmacyRepository.updatePharmacy(id, pharmacyData);
      await loadPharmacies(searchQuery: '', authViewModel: authViewModel);

    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =========================  بداية التعديل النهائي =========================
  Future<void> loadPharmacies({
    required String searchQuery,
    required AuthViewModel authViewModel,
  }) async {
    _isLoading = true;
    _error = '';
    // notifyListeners(); // لا داعي لها هنا لتجنب وميض الواجهة

    try {
      // تحقق من دور المستخدم من الـ AuthViewModel
      if (authViewModel.isPharmacy) {
        // إذا كان المستخدم صيدلية، قم بتحميل بياناته فقط
        final pharmacyId = authViewModel.activePharmacyId;
        if (pharmacyId != null) {
          final singlePharmacy = await _pharmacyRepository.getPharmacyDetails(pharmacyId);
          _pharmacies = [singlePharmacy]; // ضع الصيدلية الوحيدة في القائمة
        } else {
          _pharmacies = []; // إذا لم يوجد ID، أفرغ القائمة
          _error = "Could not find pharmacy ID for the logged in user.";
        }
      } else {
        // إذا كان المستخدم Owner، قم بتحميل كل الصيدليات
        _pharmacies = await _pharmacyRepository.getAllPharmacies();
        if (searchQuery.isNotEmpty) {
          _pharmacies = _pharmacies
              .where((pharmacy) =>
              pharmacy.name.toLowerCase().contains(searchQuery.toLowerCase()))
              .toList();
        }
      }
    } catch (e) {
      _error = e.toString();
      _pharmacies = []; // أفرغ القائمة في حالة حدوث خطأ
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  // =========================  نهاية التعديل النهائي =========================

  Future<PharmacyModel> getPharmacyDetails(String id) async {
    try {
      return await _pharmacyRepository.getPharmacyDetails(id);
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> deletePharmacy(String pharmacyId) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      await _pharmacyRepository.deletePharmacy(pharmacyId);
      _pharmacies.removeWhere((pharmacy) => pharmacy.id == pharmacyId);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMedicinesForPharmacy(String pharmacyId) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    try {
      _pharmacyMedicines = await _medicineRepository.getMedicinesForPharmacy(pharmacyId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}