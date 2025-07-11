// lib/viewmodels/medicine_view_model.dart

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

  String _lastSearchQuery = '';

  int _currentPage = 1;
  bool _hasNextPage = true;
  bool _isFetchingMore = false;

  MedicineViewModel(this._medicineRepository, this._pharmacyRepository);

  List<MedicineModel> get medicines => _medicines;
  bool get isLoading => _isLoading;
  String get error => _error;

  // ========== ✅ Fix Start: Added public getter for isFetchingMore ==========
  bool get isFetchingMore => _isFetchingMore;
  // ========== ✅ Fix End ==========

  List<String> get allMedicineNames =>
      _originalMedicinesList.map((med) => med.name).toList();

  Future<void> loadMedicines(
      {String? pharmacyId, bool forceLoadAll = false}) async {
    _isLoading = true;
    _error = '';
    _lastSearchQuery = '';
    notifyListeners();

    try {
      _currentPage = 1;
      _hasNextPage = true;
      _medicines.clear();
      _originalMedicinesList.clear();

      if (pharmacyId != null && !forceLoadAll) {
        final fetchedMedicines =
        await _medicineRepository.getMedicinesForPharmacy(pharmacyId);
        _medicines =
            fetchedMedicines.map((m) => m.copyWith(distance: null)).toList();
        _originalMedicinesList = List.from(_medicines);
        _hasNextPage = false;
      } else {
        final response =
        await _medicineRepository.getAllMedicines(page: _currentPage);
        final fetchedMedicines = response['medicines'] as List<MedicineModel>;
        _medicines =
            fetchedMedicines.map((m) => m.copyWith(distance: null)).toList();
        _originalMedicinesList = List.from(_medicines);
        _hasNextPage = response['next'] != null;
      }
    } catch (e) {
      _error = e.toString();
      print("Error loading medicines: $_error");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreMedicines() async {
    if (_isFetchingMore || !_hasNextPage) return;

    _isFetchingMore = true;
    notifyListeners();

    try {
      _currentPage++;
      final Map<String, dynamic> response;
      if (_lastSearchQuery.isNotEmpty) {
        response = await _medicineRepository.searchMedicines(_lastSearchQuery,
            page: _currentPage);
      } else {
        response = await _medicineRepository.getAllMedicines(page: _currentPage);
      }

      final newMedicines = response['medicines'] as List<MedicineModel>;
      _medicines.addAll(newMedicines.map((m) => m.copyWith(distance: null)));
      _originalMedicinesList.addAll(List.from(newMedicines));

      _hasNextPage = response['next'] != null;
    } catch (e) {
      print("Error loading more medicines: $e");
      _currentPage--;
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  void removeMedicineById(String medicineId) {
    _originalMedicinesList
        .removeWhere((medicine) => medicine.id == medicineId);
    _medicines.removeWhere((medicine) => medicine.id == medicineId);
    notifyListeners();
  }

  void removeMedicineByNameAndPharmacy(
      {required String name, required String pharmacyId}) {
    _originalMedicinesList
        .removeWhere((med) => med.name == name && med.pharmacyId == pharmacyId);
    _medicines
        .removeWhere((med) => med.name == name && med.pharmacyId == pharmacyId);
    notifyListeners();
  }

  Future<void> searchMedicines(String query, {String? pharmacyId}) async {
    _isLoading = true;
    _error = '';
    _lastSearchQuery = query;
    notifyListeners();

    try {
      _currentPage = 1;
      _hasNextPage = true;
      _medicines.clear();

      if (query.isEmpty) {
        await loadMedicines(forceLoadAll: true);
      } else {
        final response =
        await _medicineRepository.searchMedicines(query, page: _currentPage);
        final fetchedMedicines = response['medicines'] as List<MedicineModel>;
        _medicines =
            fetchedMedicines.map((m) => m.copyWith(distance: null)).toList();
        _hasNextPage = response['next'] != null;
      }
    } catch (e) {
      _error = e.toString();
      _medicines = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addMedicine({
    required String name,
    required String description,
    required double price,
    required int quantity,
    required String pharmacyId,
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

      await _medicineRepository.addMedicine(
          medicineData: medicineData, pharmacyId: pharmacyId);

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
          medicineData: medicineData);

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

  Future<void> deleteMedicine(
      {required String pharmacyId, required String medicineId}) async {
    _error = '';
    try {
      await _medicineRepository.deleteMedicine(
          pharmacyId: pharmacyId, medicineId: medicineId);
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

  Future<void> sortMedicinesByDistance(
      LatLng userLocation, List<PharmacyModel> allPharmacies) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      if (allPharmacies.isEmpty) {
        _error = "No pharmacies available to sort by distance.";
        _medicines =
            List.from(_medicines.map((m) => m.copyWith(distance: null)));
        notifyListeners();
        return;
      }

      final Map<String, PharmacyModel> pharmacyMap = {
        for (var p in allPharmacies) p.id: p
      };

      final Distance distanceCalculator = Distance();
      List<MedicineModel> medicinesToSort = List.from(_medicines);
      List<MedicineModel> processedMedicines = [];

      for (var med in medicinesToSort) {
        PharmacyModel? pharmacy = pharmacyMap[med.pharmacyId];
        double? calculatedDistance;
        if (pharmacy != null &&
            pharmacy.latitude != 0.0 &&
            pharmacy.longitude != 0.0) {
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
      _medicines =
          List.from(_medicines.map((m) => m.copyWith(distance: null)));
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearDistanceSort() {
    if (_lastSearchQuery.isNotEmpty) {
      searchMedicines(_lastSearchQuery);
    } else {
      loadMedicines(forceLoadAll: true);
    }
  }
}