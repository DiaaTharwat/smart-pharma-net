// lib/viewmodels/dashboard_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:smart_pharma_net/models/dashboard_model.dart';
import 'package:smart_pharma_net/repositories/dashboard_repository.dart';
import 'package:smart_pharma_net/viewmodels/auth_viewmodel.dart';

class DashboardViewModel extends ChangeNotifier {
  final DashboardRepository _repository;
  final AuthViewModel _authViewModel;

  DashboardStats? _stats;
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic>? _adminDashboardData;

  DashboardStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  DashboardViewModel(this._repository, this._authViewModel);

  Future<void> fetchDashboardStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // الحالة الأولى: أدمن في الوضع العام
      if (_authViewModel.isAdmin && !_authViewModel.isImpersonating) {
        _adminDashboardData = await _repository.getAdminDashboardData();
        _stats = DashboardStats.fromJson(_adminDashboardData ?? {});
      }
      // الحالة الثانية: صيدلية مسجلة دخول
      else if (_authViewModel.isPharmacy) {
        final pharmacyData = await _repository.getLoggedInPharmacyDashboardData();
        _stats = DashboardStats.fromJson(pharmacyData ?? {}, isFromSinglePharmacy: true);
      }
      // الحالة الثالثة: أدمن يتقمص دور صيدلية
      else if (_authViewModel.isImpersonating) {
        if (_adminDashboardData == null) {
          _adminDashboardData = await _repository.getAdminDashboardData();
        }

        final List pharmacies = _adminDashboardData?['pharmacies'] as List? ?? [];
        final pharmacyJson = pharmacies.firstWhere(
              (p) => p['id'].toString() == _authViewModel.activePharmacyId,
          orElse: () => null,
        );

        if (pharmacyJson != null) {
          _stats = DashboardStats.fromSinglePharmacyImpersonation(pharmacyJson);
        } else {
          _stats = DashboardStats();
          _errorMessage = "Could not find stats for the selected pharmacy.";
        }
      }

    } catch (e) {
      _stats = DashboardStats();
      _errorMessage = "Failed to load dashboard. Please try again.";
      print("Error in DashboardViewModel: ${e.toString()}");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}