// lib/viewmodels/dashboard_viewmodel.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:smart_pharma_net/models/dashboard_model.dart';
import 'package:smart_pharma_net/repositories/dashboard_repository.dart';
import 'package:smart_pharma_net/viewmodels/auth_viewmodel.dart';
import 'package:smart_pharma_net/viewmodels/pharmacy_viewmodel.dart';
import 'package:smart_pharma_net/viewmodels/medicine_viewmodel.dart';
import 'package:smart_pharma_net/models/pharmacy_model.dart';

class DashboardViewModel extends ChangeNotifier {
  AuthViewModel _authViewModel;
  PharmacyViewModel _pharmacyViewModel;
  MedicineViewModel _medicineViewModel;
  final DashboardRepository _repository;

  DashboardStats? _stats;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _pollingTimer;
  bool _isDisposed = false;

  DashboardStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  DashboardViewModel(
      this._authViewModel,
      this._pharmacyViewModel,
      this._medicineViewModel,
      this._repository,
      ) {
    _authViewModel.addListener(refreshData);
    refreshData();
  }

  void update(AuthViewModel auth, PharmacyViewModel pharmacy, MedicineViewModel medicine) {
    _authViewModel = auth;
    _pharmacyViewModel = pharmacy;
    _medicineViewModel = medicine;
  }

  Future<void> refreshData() async {
    if (_isDisposed) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String? activePharmacyId = _authViewModel.activePharmacyId;

      if (activePharmacyId != null && activePharmacyId.isNotEmpty) {
        await _calculateStatsForSinglePharmacy(activePharmacyId);
      } else {
        final data = await _repository.fetchDashboardData();
        if (_isDisposed) return;
        _stats = DashboardStats.fromJson(data);
      }
    } catch (e) {
      if (_isDisposed) return;
      _stats = null;
      _errorMessage = "Failed to load dashboard data: ${e.toString()}";
    } finally {
      if (_isDisposed) return;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _calculateStatsForSinglePharmacy(String pharmacyId) async {
    final List<PharmacyModel> allPharmacies = _pharmacyViewModel.pharmacies;
    PharmacyModel? targetPharmacy;
    try {
      targetPharmacy = allPharmacies.firstWhere((p) => p.id.toString() == pharmacyId);
    } catch (e) {
      _errorMessage = "Pharmacy details not found.";
      _stats = null;
      return;
    }

    try {
      // 1. جلب الطلبات
      final List<dynamic> orders = await _repository.fetchOrdersForPharmacy(pharmacyId);

      // 2. حساب إحصائيات الطلبات
      int pendingCount = 0;
      int completedCount = 0;
      int cancelledCount = 0;

      for (var order in orders) {
        final status = order['status'] as String?;
        if (status == 'Pending') {
          pendingCount++;
        } else if (status == 'Completed') {
          completedCount++;
        } else if (status == 'Cancelled') {
          cancelledCount++;
        }
      }

      // 3. حساب باقي الإحصائيات
      if (_medicineViewModel.pharmacyIdForLoadedMedicines != pharmacyId) {
        await _medicineViewModel.loadMedicines(pharmacyId: pharmacyId);
        if (_isDisposed) return;
      }
      final totalMedicines = _medicineViewModel.medicines.length;

      // 4. بناء كائن الإحصائيات النهائي
      _stats = DashboardStats(
        totalPharmacies: 0,
        totalSells: targetPharmacy.numberSells,
        totalBuys: targetPharmacy.numberBuys,
        totalMedicines: totalMedicines,
        pendingOrders: pendingCount,
        completedOrders: completedCount,
        cancelledOrders: cancelledCount,
        hasMedicineStats: true,
        hasOrderStats: true,
      );

    } catch (e) {
      _errorMessage = "Failed to load order statistics.";
      print("Error calculating stats for single pharmacy: $e");
      // في حال فشل جلب الطلبات، نعرض باقي البيانات مع أصفار للطلبات
      _stats = DashboardStats(
        totalPharmacies: 0,
        totalSells: targetPharmacy.numberSells,
        totalBuys: targetPharmacy.numberBuys,
        totalMedicines: _medicineViewModel.medicines.length,
        pendingOrders: 0,
        completedOrders: 0,
        cancelledOrders: 0,
        hasMedicineStats: true,
        hasOrderStats: false, // نعلم الواجهة أن بيانات الطلبات غير متاحة
      );
    }
  }

  void startPolling() {
    stopPolling();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      refreshData();
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pollingTimer?.cancel();
    _authViewModel.removeListener(refreshData);
    super.dispose();
  }
}