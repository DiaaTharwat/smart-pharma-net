// lib/viewmodels/medicine_viewmodel.dart
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../models/medicine_model.dart';
import '../models/pharmacy_model.dart';
import '../repositories/medicine_repository.dart';
import '../repositories/pharmacy_repository.dart';

class MedicineViewModel extends ChangeNotifier {
  final MedicineRepository _medicineRepository;
  final PharmacyRepository _pharmacyRepository;
  List<MedicineModel> _medicines = [];
  List<MedicineModel> _originalMedicinesList = [];
  bool _isLoading = false;
  String _error = '';

  MedicineViewModel(this._medicineRepository, this._pharmacyRepository);

  List<MedicineModel> get medicines => _medicines;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> loadMedicines({String? pharmacyId, bool forceLoadAll = false}) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      List<MedicineModel> fetchedMedicines;
      if (pharmacyId != null && !forceLoadAll) {
        fetchedMedicines = await _medicineRepository.getMedicinesForPharmacy(pharmacyId);
      } else {
        fetchedMedicines = await _medicineRepository.getAllMedicines();
      }
      _medicines = fetchedMedicines.map((m) => m.copyWith(distance: null)).toList();
      _originalMedicinesList = List.from(_medicines);

    } catch (e) {
      _error = e.toString();
      print("Error loading medicines: $_error");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchMedicines(String query, {String? pharmacyId}) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    try {
      if (query.isEmpty) {
        _medicines = List.from(_originalMedicinesList.map((m) => m.copyWith(distance: null)));
      } else {
        List<MedicineModel> allMedsToSearchFrom;
        if(pharmacyId != null) {
          allMedsToSearchFrom = await _medicineRepository.getMedicinesForPharmacy(pharmacyId);
        } else {
          allMedsToSearchFrom = await _medicineRepository.getAllMedicines();
        }

        final lowerCaseQuery = query.toLowerCase().trim();
        _medicines = allMedsToSearchFrom
            .where((medicine) =>
        medicine.name.toLowerCase().contains(lowerCaseQuery) ||
            medicine.category.toLowerCase().contains(lowerCaseQuery))
            .map((m) => m.copyWith(distance: null))
            .toList();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- تم التعديل هنا ---
  Future<bool> addMedicine({
    required String name,
    required String description,
    required double price,
    required int quantity,
    required String pharmacyId, // هذا المتغير ضروري لتحديد الصيدلية
    required String category,
    required String expiryDate,
    required bool canBeSell,
    required int quantityToSell,
    required double priceSell,
    String? imageUrl,
  }) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    try {
      final medicineData = {
        'name': name.trim(),
        'category': category.trim(),
        'description': description.trim(),
        'price': price.toString(),
        'quantity': quantity,
        'exp_date': expiryDate,
        'can_be_sell': canBeSell,
        'quantity_to_sell': quantityToSell,
        'price_sell': priceSell.toString(),
        'image_url': (imageUrl != null && imageUrl.isNotEmpty) ? imageUrl : null,
      };

      // تم تعديل استدعاء الدالة لتمرير `pharmacyId`
      // هذا يفترض أن لديك دالة في الـ Repository تقبل `pharmacyId`
      // إذا كانت الدالة الحالية `addMedicine` لا تقبل `pharmacyId`، يجب تعديلها هناك أيضاً
      await _medicineRepository.addMedicine(
          medicineData: medicineData,
          pharmacyId: pharmacyId // تمرير `pharmacyId` هنا هو مفتاح الحل
      );

      await loadMedicines(pharmacyId: pharmacyId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateMedicine({
    required String name,
    required String description,
    required double price,
    required int quantity,
    required String category,
    required String expiryDate,
    required String medicineId,
    required String pharmacyId,
    required bool canBeSell,
    required int quantityToSell,
    required double priceSell,
    String? imageUrl,
  }) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    try {
      final medicineData = {
        'name': name.trim(),
        'category': category.trim(),
        'description': description.trim(),
        'price': price.toString(),
        'quantity': quantity,
        'exp_date': expiryDate,
        'can_be_sell': canBeSell,
        'quantity_to_sell': quantityToSell,
        'price_sell': priceSell.toString(),
        'image_url': (imageUrl != null && imageUrl.isNotEmpty) ? imageUrl : null,
      };

      await _medicineRepository.updateMedicine(
          pharmacyId: pharmacyId,
          medicineId: medicineId,
          medicineData: medicineData
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteMedicine({required String pharmacyId, required String medicineId}) async {
    _error = '';
    try {
      await _medicineRepository.deleteMedicine(pharmacyId: pharmacyId, medicineId: medicineId);
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<MedicineModel> getMedicineDetails(String id) async {
    try {
      return await _medicineRepository.getMedicineDetails(id);
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> sortMedicinesByDistance(LatLng userLocation, List<PharmacyModel> allPharmacies) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      if (allPharmacies.isEmpty) {
        _error = "No pharmacies available to sort by distance.";
        _medicines = List.from(_originalMedicinesList.map((m) => m.copyWith(distance: null)));
        notifyListeners();
        return;
      }

      final Map<String, PharmacyModel> pharmacyMap = {
        for (var p in allPharmacies) p.id: p
      };

      final Distance distanceCalculator = Distance();
      List<MedicineModel> medicinesToSort = List.from(_originalMedicinesList);
      List<MedicineModel> processedMedicines = [];

      for (var med in medicinesToSort) {
        PharmacyModel? pharmacy = pharmacyMap[med.pharmacyId];
        double? calculatedDistance;
        if (pharmacy != null && pharmacy.latitude != 0.0 && pharmacy.longitude != 0.0) {
          calculatedDistance = distanceCalculator.as(
            LengthUnit.Meter,
            userLocation,
            LatLng(pharmacy.latitude, pharmacy.longitude),
          );
        } else {
          calculatedDistance = double.infinity;
        }
        processedMedicines.add(med.copyWith(distance: calculatedDistance));
      }

      processedMedicines.sort((a, b) {
        if (a.distance == null && b.distance == null) return 0;
        if (a.distance == null) return 1;
        if (b.distance == null) return -1;
        return a.distance!.compareTo(b.distance!);
      });
      _medicines = processedMedicines;

    } catch (e) {
      _error = "Error sorting medicines by distance: ${e.toString()}";
      _medicines = List.from(_originalMedicinesList.map((m) => m.copyWith(distance: null)));
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearDistanceSort({String? pharmacyIdForReset}) {
    if (_originalMedicinesList.isNotEmpty) {
      _medicines = List.from(_originalMedicinesList.map((m) => m.copyWith(distance: null)));
    } else {
      loadMedicines(pharmacyId: pharmacyIdForReset);
    }
    notifyListeners();
  }
}