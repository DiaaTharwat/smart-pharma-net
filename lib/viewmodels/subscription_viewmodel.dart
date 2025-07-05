// lib/viewmodels/subscription_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:smart_pharma_net/repositories/subscription_repository.dart';
import 'package:smart_pharma_net/viewmodels/auth_viewmodel.dart';
import 'package:smart_pharma_net/services/api_service.dart';

class SubscriptionViewModel extends ChangeNotifier {
  final SubscriptionRepository _subscriptionRepository;
  final ApiService _apiService;
  final AuthViewModel _authViewModel;

  bool _isLoading = false;
  String? _error;

  SubscriptionViewModel(this._subscriptionRepository, this._apiService, this._authViewModel);

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Setters
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  set error(String? value) {
    _error = value;
    notifyListeners();
  }

  Future<bool> subscribeToPlan(String type) async {
    isLoading = true;
    error = null;

    try {
      final pharmacyId = await _authViewModel.getPharmacyId();
      if (pharmacyId == null) {
        throw Exception('Pharmacy ID not found. Please select a pharmacy to manage.');
      }

      await _subscriptionRepository.subscribe(
        type: type,
        pharmacyId: pharmacyId,
      );

      await _apiService.saveSubscriptionType(type);

      isLoading = false;
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      isLoading = false;
      return false;
    }
  }

  void clearError() {
    error = null;
  }

  void clearLocalSubscription() {
    _apiService.saveSubscriptionType('Free');
    notifyListeners();
  }
}