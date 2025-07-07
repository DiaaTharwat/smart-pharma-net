// lib/viewmodels/exchange_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:smart_pharma_net/models/exchange_medicine_model.dart';
import 'package:smart_pharma_net/repositories/exchange_repository.dart';
import 'package:smart_pharma_net/viewmodels/auth_viewmodel.dart';
import 'package:smart_pharma_net/viewmodels/base_viewmodel.dart';
import 'package:smart_pharma_net/viewmodels/medicine_viewmodel.dart';

class ExchangeViewModel extends BaseViewModel {
  final ExchangeRepository _exchangeRepository;
  final AuthViewModel _authViewModel;
  final MedicineViewModel _medicineViewModel;

  List<ExchangeMedicineModel> _exchangeMedicines = [];
  List<ExchangeMedicineModel> _originalExchangeMedicines = [];
  String _searchQuery = '';

  bool _exchangeOrderPlacedSuccessfully = false;
  bool get exchangeOrderPlacedSuccessfully => _exchangeOrderPlacedSuccessfully;

  ExchangeViewModel(this._exchangeRepository, this._authViewModel, this._medicineViewModel);

  List<ExchangeMedicineModel> get exchangeMedicines => _exchangeMedicines;

  List<String> get allExchangeMedicineNames => _originalExchangeMedicines.map((med) => med.medicineName).toList();

  Future<void> loadExchangeMedicines() async {
    setLoading(true);
    setError(null);
    try {
      _originalExchangeMedicines = await _exchangeRepository.getExchangeList();
      applySearchFilter(_searchQuery);
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase().trim();
    applySearchFilter(_searchQuery);
  }

  void applySearchFilter(String query) {
    List<ExchangeMedicineModel> filteredList;

    if (query.isEmpty) {
      filteredList = List.from(_originalExchangeMedicines);
    } else {
      filteredList = _originalExchangeMedicines.where((med) {
        return med.medicineName.toLowerCase().contains(query) ||
            med.pharmacyName.toLowerCase().contains(query);
      }).toList();
    }

    _exchangeMedicines = filteredList.where((med) {
      final int? quantity = int.tryParse(med.medicineQuantityToSell);
      return quantity != null && quantity > 0;
    }).toList();

    notifyListeners();
  }

  Future<void> createBuyOrder({
    required String medicineId,
    required String medicineName,
    required String price,
    required int quantity,
    required String pharmacySeller,
  }) async {
    setError(null);

    try {
      final pharmacyBuyerId = await _authViewModel.getPharmacyId();
      final pharmacyBuyerName = await _authViewModel.getPharmacyName();

      if (pharmacyBuyerId == null || pharmacyBuyerName == null) {
        throw Exception('Cannot create order. User is not logged in as a pharmacy.');
      }

      int index = _originalExchangeMedicines.indexWhere((m) => m.id == medicineId);

      if (index != -1) {
        final currentMedicine = _originalExchangeMedicines[index];
        int currentQuantity = int.parse(currentMedicine.medicineQuantityToSell);
        int newQuantity = currentQuantity - quantity;

        if (newQuantity <= 0) {
          _originalExchangeMedicines.removeAt(index);

          // -- MODIFIED --: Using the new, more reliable removal method.
          _medicineViewModel.removeMedicineByNameAndPharmacy(
            name: currentMedicine.medicineName,
            pharmacyId: currentMedicine.pharmacyId,
          );
        } else {
          _originalExchangeMedicines[index] = currentMedicine.copyWith(
            medicineQuantityToSell: newQuantity.toString(),
          );
        }
        applySearchFilter(_searchQuery);
      }

      await _exchangeRepository.createBuyOrder(
        medicineName: medicineName,
        price: price,
        quantity: quantity,
        pharmacySeller: pharmacySeller,
        pharmacyBuyer: pharmacyBuyerName,
        pharmacyBuyerId: pharmacyBuyerId,
      );

      _exchangeOrderPlacedSuccessfully = true;
      notifyListeners();

    } catch (e) {
      setError(e.toString());
      await loadExchangeMedicines();
      rethrow;
    }
  }

  void resetExchangeOrderPlacedSuccess() {
    _exchangeOrderPlacedSuccessfully = false;
    notifyListeners();
  }
}