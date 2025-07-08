// lib/viewmodels/dashboard_view_model.dart

import 'package:flutter/material.dart';
import 'package:smart_pharma_net/models/dashboard_model.dart';
import 'package:smart_pharma_net/repositories/dashboard_repository.dart';

class DashboardViewModel extends ChangeNotifier {
  final DashboardRepository _repository;
  DashboardStats? _stats;
  bool _isLoading = false;
  String? _errorMessage;
  int? _selectedPharmacyId;

  DashboardStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get selectedPharmacyId => _selectedPharmacyId;

  DashboardViewModel(this._repository);

  void selectPharmacy(int? pharmacyId) {
    if (_selectedPharmacyId != pharmacyId) {
      _selectedPharmacyId = pharmacyId;
      fetchDashboardStats(pharmacyId: _selectedPharmacyId);
    }
  }

  Future<void> fetchDashboardStats({int? pharmacyId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _stats = await _repository.getDashboardStats(pharmacyId: pharmacyId ?? _selectedPharmacyId);
    } catch (e) {
      // =================== الجزء الذي تم تعديله بذكاء ===================
      // نتعامل مع خطأ 404 بشكل خاص
      if (e.toString().contains('404')) {
        _errorMessage = "Dashboard feature is not available on the server yet. Please contact backend support.";
      } else {
        _errorMessage = "An error occurred: ${e.toString()}";
      }
      print(_errorMessage);
      // =================================================================
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}