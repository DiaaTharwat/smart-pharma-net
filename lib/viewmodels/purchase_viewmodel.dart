import 'package:flutter/material.dart';
// --- تم التعديل هنا ---
// تم استيراد الموديل بالاسم الجديد والصحيح
import 'package:smart_pharma_net/models/user_purchase_model.dart';
import 'package:smart_pharma_net/repositories/purchase_repository.dart';
import 'package:smart_pharma_net/viewmodels/base_viewmodel.dart';

class PurchaseViewModel extends BaseViewModel {
  final PurchaseRepository _purchaseRepository;

  PurchaseViewModel(this._purchaseRepository);

  // --- تم التعديل هنا ---
  // تم تحديث نوع البيانات المستقبلة إلى الاسم الجديد
  Future<bool> submitPurchase(UserPurchase purchaseData) async {
    setLoading(true);
    setError(null);
    try {
      await _purchaseRepository.createUserPurchase(purchaseData);
      setLoading(false);
      return true;
    } catch (e) {
      setError(e.toString());
      setLoading(false);
      return false;
    }
  }
}