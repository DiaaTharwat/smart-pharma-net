// lib/repositories/auth_repository.dart
// ignore_for_file: unnecessary_null_comparison

import 'package:smart_pharma_net/services/api_service.dart'; //

class AuthRepository {
  final ApiService _apiService;

  AuthRepository(this._apiService);

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('Attempting login in repository with email: $email');
      final response = await _apiService.login(email, password);

      print('Login response in repository: $response');

      if (response == null) {
        throw Exception('Invalid credentials');
      }

      if (!response.containsKey('access') || !response.containsKey('refresh')) {
        throw Exception('Invalid response format');
      }

      return response;
    } catch (e) {
      print('Login error in repository: $e');
      rethrow;
    }
  }

  // -- تعديل نهائي --
  // تم تغيير `Map<String, String>? additionalData` إلى متغيرات صريحة
  // `String? pharmacyId` و `String? pharmacyName` لإصلاح خطأ التحويل
  Future<void> saveTokens(
      String accessToken,
      String refreshToken, {
        required String role,
        String? pharmacyId,
        String? pharmacyName,
      }) async {
    try {
      print('Saving tokens in repository - Role: $role');

      // -- تعديل --
      // الاستدعاء الآن يستخدم المتغيرات الجديدة مباشرة
      await _apiService.saveTokens(
        accessToken,
        refreshToken,
        role: role,
        pharmacyId: pharmacyId,
        pharmacyName: pharmacyName,
      );

      print('Tokens saved successfully');
    } catch (e) {
      print('Error saving tokens in repository: $e');
      rethrow;
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      final isValid = await _apiService.isLoggedIn;
      print('Token validation in repository - IsLoggedIn: $isValid');
      return isValid;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  Future<String?> getUserRole() async {
    try {
      final role = await _apiService.userRole;
      print('Getting user role in repository: $role');
      return role;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  Future<void> logout() async {
    try {
      print('Logging out user from repository');
      await _apiService.logout();
    } catch (e) {
      print('Error during logout from repository: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> registerPharmacy({
    required String name,
    required String city,
    required String latitude,
    required String longitude,
    required String licenseNumber,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      return await _apiService.registerPharmacy(
        name: name.trim(),
        city: city.trim(),
        latitude: latitude.trim(),
        longitude: longitude.trim(),
        licenseNumber: licenseNumber.trim(),
        password: password.trim(),
        confirmPassword: confirmPassword.trim(),
      );
    } catch (e) {
      if (e.toString().contains('400')) {
        throw Exception('Registration data invalid. Please check your inputs.');
      } else if (e.toString().contains('license_number')) {
        throw Exception('License number already registered');
      } else if (e.toString().contains('name')) {
        throw Exception('Pharmacy name already taken');
      } else {
        throw Exception('Registration failed: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
    required String gender,
    required String phone,
    required String nationalID,
  }) async {
    try {
      return await _apiService.register(
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        username: username.trim(),
        email: email.trim(),
        password: password.trim(),
        gender: gender,
        phone: phone.trim(),
        nationalID: nationalID.trim(),
      );
    } catch (e) {
      if (e.toString().contains('400')) {
        throw Exception('Registration data invalid. Please check your inputs.');
      } else if (e.toString().contains('email')) {
        throw Exception('Email already in use');
      }  else {
        throw Exception('Registration failed: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _apiService.sendPasswordResetEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refreshToken() async {
    try {
      await _apiService.refreshToken();
    } catch (e) {
      throw Exception('Session expired. Please login again.');
    }
  }
}