import 'package:flutter/material.dart';
import 'package:smart_pharma_net/models/exchange_medicine_model.dart';
import 'package:smart_pharma_net/repositories/exchange_repository.dart';
import 'package:smart_pharma_net/viewmodels/auth_viewmodel.dart'; // -- إضافة --
import 'package:smart_pharma_net/viewmodels/base_viewmodel.dart';

class ExchangeViewModel extends BaseViewModel {
  final ExchangeRepository _exchangeRepository;
  final AuthViewModel _authViewModel; // -- إضافة -- للوصول لبيانات الصيدلية الحالية

  List<ExchangeMedicineModel> _exchangeMedicines = [];
  List<ExchangeMedicineModel> _originalExchangeMedicines = [];
  String _searchQuery = '';

  bool _exchangeOrderPlacedSuccessfully = false;
  bool get exchangeOrderPlacedSuccessfully => _exchangeOrderPlacedSuccessfully;

  // -- تعديل -- تم تحديث الـ constructor
  ExchangeViewModel(this._exchangeRepository, this._authViewModel);

  List<ExchangeMedicineModel> get exchangeMedicines => _exchangeMedicines;

  // --- ✅ التعديل هنا: تم إضافة السطر الجديد ---
  List<String> get allExchangeMedicineNames => _originalExchangeMedicines.map((med) => med.medicineName).toList();
  // -----------------------------------------

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

  // -- تعديل --
  // الدالة لم تعد تستقبل `pharmacyBuyer`، فهي الآن تحصل عليه من `AuthViewModel`
  Future<void> createBuyOrder({
    required String medicineId,
    required String medicineName,
    required String price,
    required int quantity,
    required String pharmacySeller,
  }) async {
    setError(null);

    try {
      // -- إضافة --
      // جلب بيانات الصيدلية المشترية من AuthViewModel
      final pharmacyBuyerId = await _authViewModel.getPharmacyId();
      final pharmacyBuyerName = await _authViewModel.getPharmacyName();

      if (pharmacyBuyerId == null || pharmacyBuyerName == null) {
        throw Exception('Cannot create order. User is not logged in as a pharmacy.');
      }

      // --- IMMEDIATE UI UPDATE LOGIC (MODIFIED) ---
      int index = _originalExchangeMedicines.indexWhere((m) => m.id == medicineId);

      if (index != -1) {
        final currentMedicine = _originalExchangeMedicines[index];
        int currentQuantity = int.parse(currentMedicine.medicineQuantityToSell);
        int newQuantity = currentQuantity - quantity;

        _originalExchangeMedicines[index] = currentMedicine.copyWith(
          medicineQuantityToSell: newQuantity.toString(),
        );

        applySearchFilter(_searchQuery);
      }
      // --- END IMMEDIATE UI UPDATE LOGIC ---

      // -- تعديل --
      // استدعاء الخادم في الخلفية مع تمرير البيانات الصحيحة
      await _exchangeRepository.createBuyOrder(
        medicineName: medicineName,
        price: price,
        quantity: quantity,
        pharmacySeller: pharmacySeller,
        pharmacyBuyer: pharmacyBuyerName, // الاسم من AuthViewModel
        pharmacyBuyerId: pharmacyBuyerId,   // الـ ID من AuthViewModel
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