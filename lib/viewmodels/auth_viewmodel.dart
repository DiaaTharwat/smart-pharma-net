// lib/viewmodels/auth_viewmodel.dart

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_pharma_net/models/pharmacy_model.dart';
import 'package:smart_pharma_net/repositories/auth_repository.dart';
import 'package:smart_pharma_net/viewmodels/base_viewmodel.dart';
import 'package:smart_pharma_net/services/api_service.dart';

class AuthViewModel extends BaseViewModel {
  final AuthRepository _authRepository;
  final ApiService _apiService;

  bool _isAdmin = false;
  bool _isPharmacy = false;

  bool _isImpersonating = false;
  String? _impersonatedPharmacyId;
  String? _impersonatedPharmacyName;

  String? _passwordBasedImpersonatingName;

  AuthViewModel(this._authRepository, this._apiService);

  bool get isAdmin => _isAdmin;
  bool get isPharmacy => _isPharmacy;
  bool get isImpersonating => _isImpersonating;
  String? get impersonatedPharmacyId => _impersonatedPharmacyId;

  bool get canActAsPharmacy => _isPharmacy || _isImpersonating;

  String? get currentPharmacyName => _isImpersonating ? _impersonatedPharmacyName : _passwordBasedImpersonatingName;

  bool get isNormalUser => !_isAdmin && !_isPharmacy;

  Future<void> impersonatePharmacy(PharmacyModel pharmacy) async {
    if (!_isAdmin) return;

    print('Owner is starting impersonation of: ${pharmacy.name} (ID: ${pharmacy.id})');
    _isImpersonating = true;
    _impersonatedPharmacyId = pharmacy.id;
    _impersonatedPharmacyName = pharmacy.name;
    notifyListeners();
  }

  Future<void> stopImpersonation() async {
    print('Owner is stopping impersonation.');
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
        await _authRepository.saveTokens(
            accessToken,
            refreshToken,
            role: 'admin'
        );
        _isAdmin = true;
        _isPharmacy = false;
        _isImpersonating = false;
        _impersonatedPharmacyId = null;
        _impersonatedPharmacyName = null;
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

  Future<String> pharmacyLogin({
    required String name,
    required String password,
    bool isAdminImpersonating = false,
  }) async {
    setLoading(true);
    setError(null);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (isAdminImpersonating) {
        final currentAdminAccessToken = prefs.getString(ApiService.tokenKey);
        final currentAdminRefreshToken = prefs.getString(ApiService.refreshTokenKey);
        if (currentAdminAccessToken != null && currentAdminRefreshToken != null) {
          await prefs.setString(ApiService.adminTokenKey, currentAdminAccessToken);
          await prefs.setString(ApiService.adminRefreshTokenKey, currentAdminRefreshToken);
        }
      }

      final response = await _apiService.pharmacyLogin(name, password);

      if (response != null) {
        final pharmacyId = response['id']?.toString();
        final pharmacyNameReturned = response['name']?.toString();
        if (pharmacyId == null || pharmacyId.isEmpty) {
          throw Exception('Access denied. This account does not have permission to access this pharmacy.');
        }
        if (pharmacyNameReturned == null || pharmacyNameReturned.toLowerCase() != name.toLowerCase()) {
          throw Exception('Invalid pharmacy credentials - wrong pharmacy name returned');
        }
        final accessToken = response['access'];
        final refreshToken = response['refresh'];

        await _authRepository.saveTokens(
          accessToken,
          refreshToken,
          role: 'pharmacy',
          pharmacyId: pharmacyId,
          pharmacyName: pharmacyNameReturned,
        );

        _isAdmin = isAdminImpersonating;
        _isPharmacy = true;
        _passwordBasedImpersonatingName = pharmacyNameReturned;
        notifyListeners();
        return pharmacyId;
      } else {
        throw Exception('Login failed: Invalid response');
      }
    } catch (e) {
      setError(e.toString());
      rethrow;
    } finally {
      setLoading(false);
    }
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
        _passwordBasedImpersonatingName = null;
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

  Future<void> logout() async {
    await _authRepository.logout();
    _isAdmin = false;
    _isPharmacy = false;
    _isImpersonating = false;
    _impersonatedPharmacyId = null;
    _impersonatedPharmacyName = null;
    _passwordBasedImpersonatingName = null;
    notifyListeners();
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
    final prefs = await SharedPreferences.getInstance();
    final currentRole = prefs.getString(ApiService.userRoleKey);
    final hasPersistedAdminTokens = prefs.containsKey(ApiService.adminTokenKey);

    if (isValid) {
      if (currentRole == 'pharmacy') {
        _isPharmacy = true;
        _passwordBasedImpersonatingName = prefs.getString(ApiService.pharmacyNameKey);
        _isAdmin = hasPersistedAdminTokens;
      } else if (currentRole == 'admin') {
        _isAdmin = true;
        _isPharmacy = false;
      } else {
        _isAdmin = false;
        _isPharmacy = false;
      }
    } else {
      _isAdmin = false;
      _isPharmacy = false;
      _isImpersonating = false;
      await prefs.remove(ApiService.adminTokenKey);
      await prefs.remove(ApiService.adminRefreshTokenKey);
    }
    notifyListeners();
    return isValid;
  }

  Future<String?> getUserRole() async {
    return _apiService.userRole;
  }

  Future<String?> getPharmacyId() async {
    if (_isImpersonating && _impersonatedPharmacyId != null) {
      return _impersonatedPharmacyId;
    }
    if (_isPharmacy) {
      return _apiService.getPharmacyId();
    }
    return null;
  }

  Future<String?> getPharmacyName() async {
    if (_isImpersonating && _impersonatedPharmacyName != null) {
      return _impersonatedPharmacyName;
    }
    if (_isPharmacy) {
      return _apiService.getPharmacyName();
    }
    return null;
  }
}