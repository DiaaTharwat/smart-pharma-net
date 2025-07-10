// lib/viewmodels/auth_viewmodel.dart







import 'package:flutter/foundation.dart';



import 'package:shared_preferences/shared_preferences.dart';



import 'package:smart_pharma_net/models/pharmacy_model.dart';



import 'package:smart_pharma_net/repositories/auth_repository.dart';



import 'package:smart_pharma_net/viewmodels/base_viewmodel.dart';



import 'package:smart_pharma_net/services/api_service.dart';



import 'package:smart_pharma_net/models/user_model.dart';







class AuthViewModel extends BaseViewModel {



  final AuthRepository _authRepository;



  final ApiService _apiService;







  bool _isAdmin = false;



  bool _isPharmacy = false;



  String? _loggedInPharmacyId;



  String? _loggedInPharmacyName;



  bool _isImpersonating = false;



  String? _impersonatedPharmacyId;



  String? _impersonatedPharmacyName;



  String? _ownerEmail;



  UserModel? _currentUser;



  String? _subscriptionType;







  AuthViewModel(this._authRepository, this._apiService);







  bool get isAdmin => _isAdmin;



  bool get isPharmacy => _isPharmacy;



  bool get isImpersonating => _isImpersonating;



  bool get canActAsPharmacy => _isPharmacy || _isImpersonating;



  String? get ownerEmail => _ownerEmail;



  UserModel? get currentUser => _currentUser;



  String? get subscriptionType => _subscriptionType;







  String? get activePharmacyId {



    if (_isImpersonating) return _impersonatedPharmacyId;



    if (_isPharmacy) return _loggedInPharmacyId;



    return null;



  }







  String? get activePharmacyName {



    if (_isImpersonating) return _impersonatedPharmacyName;



    if (_isPharmacy) return _loggedInPharmacyName;



    return null;



  }







  void updateSubscriptionStatus(String? newStatus) {



    _subscriptionType = newStatus;



    notifyListeners();



  }







  Future<void> impersonatePharmacy(PharmacyModel pharmacy) async {



    if (!_isAdmin) return;



    _isImpersonating = true;



    _impersonatedPharmacyId = pharmacy.id.toString();



    _impersonatedPharmacyName = pharmacy.name;



    notifyListeners();



  }







  Future<void> stopImpersonation() async {



    _isImpersonating = false;



    _impersonatedPharmacyId = null;



    _impersonatedPharmacyName = null;



    notifyListeners();



  }







  Future<bool> login(String email, String password) async {



    setLoading(true);



    setError(null);



    try {



      final result = await _authRepository.login(email, password);



      if (result != null) {



        final accessToken = result['access']?.toString();



        final refreshToken = result['refresh']?.toString();



        if (accessToken == null || refreshToken == null) {



          throw Exception('Invalid response: missing tokens');



        }



        await _authRepository.saveTokens(accessToken, refreshToken, role: 'admin');



        _isAdmin = true;



        _isPharmacy = false;



        _isImpersonating = false;



        _loggedInPharmacyId = null;



        _loggedInPharmacyName = null;



        _impersonatedPharmacyId = null;



        _impersonatedPharmacyName = null;



        _ownerEmail = email;







        await fetchUserProfile();







        notifyListeners();



        return true;



      }



      throw Exception('Invalid admin credentials');



    } catch (e) {



      setError(e.toString());



      return false;



    } finally {



      setLoading(false);



    }



  }







  Future<String?> pharmacyLogin({



    required String name,



    required String password,



  }) async {



    setLoading(true);



    setError(null);



    try {



      final response = await _apiService.pharmacyLogin(name, password);







      if (response != null) {



        final pharmacyId = response['id']?.toString();



        final pharmacyNameReturned = response['name']?.toString();



        final accessToken = response['access'] as String?;



        final refreshToken = response['refresh'] as String?;







        if (pharmacyId == null || pharmacyId.isEmpty) {



          throw Exception('Pharmacy login failed: No pharmacy ID returned.');



        }



        if (accessToken == null || refreshToken == null) {



          throw Exception('Pharmacy login failed: Missing tokens.');



        }







        await _authRepository.saveTokens(



          accessToken,



          refreshToken,



          role: 'pharmacy',



          pharmacyId: pharmacyId,



          pharmacyName: pharmacyNameReturned,



        );







        _isAdmin = false;



        _isPharmacy = true;



        _isImpersonating = false;



        _loggedInPharmacyId = pharmacyId;



        _loggedInPharmacyName = pharmacyNameReturned;



        _impersonatedPharmacyId = null;



        _impersonatedPharmacyName = null;







        await fetchUserProfile();



        _subscriptionType = await _apiService.getSubscriptionType();







        notifyListeners();



        return null;



      } else {



        throw Exception('Login failed: Invalid response');



      }



    } catch (e) {



      final errorMessage = e.toString().replaceAll('Exception: ', '');



      setError(errorMessage);



      return errorMessage;



    } finally {



      setLoading(false);



    }



  }







  Future<void> logout() async {



    await _authRepository.logout();



    _isAdmin = false;



    _isPharmacy = false;



    _isImpersonating = false;



    _impersonatedPharmacyId = null;



    _impersonatedPharmacyName = null;



    _loggedInPharmacyId = null;



    _loggedInPharmacyName = null;



    _ownerEmail = null;



    _currentUser = null;



    _subscriptionType = null;



    notifyListeners();



  }







  Future<void> restoreAdminSession() async {



    setLoading(true);



    setError(null);



    try {



      final prefs = await SharedPreferences.getInstance();



      final savedAdminAccessToken = prefs.getString(ApiService.adminTokenKey);



      final savedAdminRefreshToken = prefs.getString(ApiService.adminRefreshTokenKey);



      if (savedAdminAccessToken != null && savedAdminRefreshToken != null) {



        await _authRepository.saveTokens(



          savedAdminAccessToken,



          savedAdminRefreshToken,



          role: 'admin',



        );



        await prefs.remove(ApiService.adminTokenKey);



        await prefs.remove(ApiService.adminRefreshTokenKey);



        _isAdmin = true;



        _isPharmacy = false;



        _loggedInPharmacyName = null;



        notifyListeners();



      } else {



        await logout();



      }



    } catch (e) {



      setError(e.toString());



      await logout();



      rethrow;



    } finally {



      setLoading(false);



    }



  }







  Future<bool> register({



    required String firstName,



    required String lastName,



    required String username,



    required String email,



    required String password,



    required String gender,



    required String phone,



    required String nationalID,



  }) async {



    setLoading(true);



    setError(null);



    try {



      await _authRepository.register(



        firstName: firstName,



        lastName: lastName,



        username: username,



        email: email,



        password: password,



        gender: gender,



        phone: phone,



        nationalID: nationalID,



      );



      return true;



    } catch (e) {



      setError(e.toString());



      return false;



    } finally {



      setLoading(false);



    }



  }







  Future<bool> requestPasswordReset(String email) async {



    setLoading(true);



    setError(null);



    try {



      await _authRepository.sendPasswordResetEmail(email);



      return true;



    } catch (e) {



      setError(e.toString());



      return false;



    } finally {



      setLoading(false);



    }



  }







  Future<bool> isLoggedIn() async {



    final isValid = await _authRepository.isLoggedIn();



    if (isValid) {



      final prefs = await SharedPreferences.getInstance();



      final currentRole = prefs.getString(ApiService.userRoleKey);







      if (currentRole == 'pharmacy') {



        _isPharmacy = true;



        _isAdmin = false;



        _isImpersonating = false;



        _loggedInPharmacyId = prefs.getString(ApiService.pharmacyIdKey);



        _loggedInPharmacyName = prefs.getString(ApiService.pharmacyNameKey);



        _subscriptionType = await _apiService.getSubscriptionType();







      } else if (currentRole == 'admin') {



        _isAdmin = true;



        _isPharmacy = false;



      } else {



        _isAdmin = false;



        _isPharmacy = false;



      }



      if(_currentUser == null) {



        await fetchUserProfile();



      }



    } else {



      await logout();



    }



    notifyListeners();



    return isValid;



  }







  Future<String?> getPharmacyId() async {



    return activePharmacyId;



  }







  Future<String?> getPharmacyName() async {



    return activePharmacyName;



  }







  Future<String?> getUserRole() async {



    return _apiService.userRole;



  }







  Future<void> fetchUserProfile() async {



    setLoading(true);



    try {



      final userData = await _authRepository.getUserProfile();



      _currentUser = UserModel.fromJson(userData);



      notifyListeners();



    } catch (e) {



      setError(e.toString());



    } finally {



      setLoading(false);



    }



  }







  Future<bool> updateProfile({required String firstName, required String lastName}) async {



    setLoading(true);



    setError(null);



    try {



      final updatedUser = await _authRepository.updateUserProfile(firstName: firstName, lastName: lastName);



      _currentUser = UserModel.fromJson(updatedUser);



      notifyListeners();



      return true;



    } catch (e) {



      setError(e.toString());



      return false;



    } finally {



      setLoading(false);



    }



  }







  Future<bool> changePassword({required String currentPassword, required String newPassword}) async {



    setLoading(true);



    setError(null);



    try {



      await _authRepository.changePassword(currentPassword: currentPassword, newPassword: newPassword);



      return true;



    } catch (e) {



      setError(e.toString());



      return false;



    } finally {



      setLoading(false);



    }



  }







  Future<bool> changeEmail({required String currentPassword, required String newEmail}) async {



    setLoading(true);



    setError(null);



    try {



      await _authRepository.changeEmail(currentPassword: currentPassword, newEmail: newEmail);



      await fetchUserProfile();



      return true;



    } catch (e) {



      setError(e.toString());



      return false;



    } finally {



      setLoading(false);



    }



  }







  Future<bool> deleteAccount() async {



    setLoading(true);



    setError(null);



    try {



      await _authRepository.deleteAccount();



      await logout();



      return true;



    } catch (e) {



      setError(e.toString());



      return false;



    } finally {



      setLoading(false);



    }



  }



}