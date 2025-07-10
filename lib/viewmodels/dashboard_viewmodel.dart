import 'package:flutter/foundation.dart';
import 'package:smart_pharma_net/models/dashboard_model.dart';
import 'package:smart_pharma_net/repositories/dashboard_repository.dart';
import 'package:smart_pharma_net/viewmodels/auth_viewmodel.dart';

class DashboardViewModel extends ChangeNotifier {
  final DashboardRepository _repository;
  final AuthViewModel _authViewModel;

  DashboardStats? _stats;
  bool _isLoading = false;
  String? _errorMessage;

  // هذا المتغير سيحتفظ ببيانات الأدمن الكاملة لاستخدامها في حالة التقمص
  Map<String, dynamic>? _adminFullData;

  DashboardStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  DashboardViewModel(this._repository, this._authViewModel);

  /// ✨ Fetches dashboard statistics (New Simplified Logic) ✨
  ///
  /// This function now handles all scenarios with a much cleaner approach.
  /// It correctly handles the impersonation case without making invalid API calls.
  Future<void> fetchDashboardStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // --- الحالة الأولى: الأدمن يتقمص دور صيدلية ---
      // هذا هو المنطق الجديد والأكثر كفاءة
      if (_authViewModel.isImpersonating &&
          _authViewModel.activePharmacyId != null) {
        if (_adminFullData != null &&
            _adminFullData!['pharmacies'] is List) {
          final List pharmacies = _adminFullData!['pharmacies'];
          final pharmacyIdToFind = _authViewModel.activePharmacyId;

          // ابحث عن الصيدلية المحددة داخل البيانات التي تم جلبها مسبقًا
          final pharmacyData = pharmacies.firstWhere(
                (p) => p['id'].toString() == pharmacyIdToFind,
            orElse: () => null,
          );

          if (pharmacyData != null) {
            // استخدم الـ factory المخصص لحالة التقمص
            _stats =
                DashboardStats.fromSinglePharmacyImpersonation(pharmacyData);
          } else {
            throw Exception(
                "Could not find impersonated pharmacy data locally.");
          }
        } else {
          // إذا لم تكن بيانات الأدمن موجودة، يجب جلبها أولاً
          // هذا سيناريو احتياطي، في الحالة الطبيعية يجب أن تكون البيانات موجودة
          await _fetchDataFromApi();
          // أعد محاولة منطق التقمص بعد جلب البيانات
          await fetchDashboardStats();
          return; // اخرج من الدالة الحالية لتجنب التحديث المزدوج
        }
      }
      // --- الحالة الثانية: المستخدم العادي (أدمن أو صيدلية) ---
      else {
        await _fetchDataFromApi();
      }
    } catch (e) {
      _stats = null; // Reset stats to avoid showing stale data
      _errorMessage = "فشلت عملية تحميل لوحة التحكم. برجاء المحاولة مرة أخرى.";
      if (kDebugMode) {
        print("Error in DashboardViewModel: ${e.toString()}");
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Helper function to fetch data from the API and process it.
  Future<void> _fetchDataFromApi() async {
    // استخدم الدالة الوحيدة والصحيحة من الـ Repository
    final data = await _repository.fetchDashboardData();

    // استخدم الـ factory الجديد والذكي من الـ Model
    _stats = DashboardStats.fromJson(data);

    // إذا كان المستخدم هو الأدمن، قم بتخزين البيانات الكاملة لاستخدامها لاحقًا في التقمص
    if (_authViewModel.isAdmin && !_authViewModel.isImpersonating) {
      _adminFullData = data;
    }
  }

  /// Clears the current dashboard stats and cached admin data.
  /// Important for logout or when the user context changes.
  void clearStats() {
    _stats = null;
    _errorMessage = null;
    _adminFullData = null; // امسح بيانات الأدمن المخزنة
    notifyListeners();
  }
}
