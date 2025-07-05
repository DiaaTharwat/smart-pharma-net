// lib/services/api_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/pharmacy_model.dart';
typedef Pharmacy = PharmacyModel;

class ApiService {
  static const String baseUrl = 'https://smart-pharma-net.vercel.app/';
  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userRoleKey = 'user_role';
  static const String pharmacyIdKey = 'pharmacy_id';
  static const String pharmacyNameKey = 'pharmacy_name';
  static const int timeoutSeconds = 30;
  static const Duration tokenRefreshThreshold = Duration(minutes: 15);

  // NEW: Added key for subscription type
  static const String subscriptionTypeKey = 'subscription_type';

  static const String adminTokenKey = 'admin_access_token_saved';
  static const String adminRefreshTokenKey = 'admin_refresh_token_saved';

  late final SharedPreferences _prefs;
  late final Dio _dio;

  Future<SharedPreferences> init() async {
    _prefs = await SharedPreferences.getInstance();

    _dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: timeoutSeconds),
        receiveTimeout: const Duration(seconds: timeoutSeconds),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
          'Origin': baseUrl,
          'Referer': baseUrl,
        }
    ));
    _setupInterceptors();
    return _prefs;
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // await init();
          final accessToken = _prefs.getString(tokenKey);
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401 && _prefs.getString(refreshTokenKey) != null) {
            bool refreshed = await refreshToken();
            if (refreshed) {
              final newAccessToken = _prefs.getString(tokenKey);
              e.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              return handler.resolve(await _dio.fetch(e.requestOptions));
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<dynamic> publicPost(String endpoint, dynamic data) async {
    final url = baseUrl + endpoint;
    print('Making public POST request with Dio (Browser Simulation) to: $url');
    print('Request Body: ${json.encode(data)}');

    try {
      final response = await _dio.post(endpoint, data: data);

      print('Dio Response Status: ${response.statusCode}');
      print('Dio Response Body: ${response.data}');

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        return response.data;
      } else {
        throw Exception('Request failed with status ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('Dio error during public POST request: $e');
      if (e.response != null) {
        print('Error Response Data: ${e.response?.data}');
        String errorMessage = 'Unknown server error';
        try {
          final errorData = e.response?.data;
          if (errorData is Map && errorData.containsKey('detail')) {
            errorMessage = errorData['detail'].toString();
          } else if (errorData is String && errorData.isNotEmpty) {
            errorMessage = errorData;
          }
        } catch (_) {
        }
        throw Exception(errorMessage);
      } else {
        print('Error sending request: ${e.message}');
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      print('An unexpected error occurred: $e');
      rethrow;
    }
  }

  // ============== NEW METHODS TO FIX THE BUILD ERROR ==============
  Future<void> saveSubscriptionType(String type) async {
    try {
      await _prefs.setString(subscriptionTypeKey, type);
      print('Saved subscription type: $type');
    } catch (e) {
      print('Error saving subscription type: $e');
      rethrow;
    }
  }

  Future<String?> getSubscriptionType() async {
    return _prefs.getString(subscriptionTypeKey);
  }
  // ================================================================

  Future<void> saveAdditionalData(String key, String value) async {
    try {
      await _prefs.setString(key, value);
      print('Saved additional data: $key = $value');
    } catch (e) {
      print('Error saving additional data: $e');
      rethrow;
    }
  }

  Future<String?> getPharmacyId() async {
    return _prefs.getString(pharmacyIdKey);
  }

  Future<void> savePharmacyId(String id) async {
    await _prefs.setString(pharmacyIdKey, id);
    print('Pharmacy ID saved: $id');
  }

  Future<String?> getPharmacyName() async {
    return _prefs.getString(pharmacyNameKey);
  }

  Future<void> savePharmacyName(String name) async {
    await _prefs.setString(pharmacyNameKey, name);
    print('Pharmacy Name saved: $name');
  }

  Future<String?> getAccessToken() async {
    return _prefs.getString(tokenKey);
  }

  Future<String?> get currentRefreshToken async {
    return _prefs.getString(refreshTokenKey);
  }

  Future<String?> get userRole async {
    return _prefs.getString(userRoleKey);
  }

  Future<void> saveTokens(String accessToken, String refreshToken,
      {required String role, String? pharmacyId, String? pharmacyName}) async {
    print(
        'Saving tokens - Access Token: ${accessToken.substring(0, min<int>(20, accessToken.length))}');
    await _prefs.setString(tokenKey, accessToken);
    await _prefs.setString(refreshTokenKey, refreshToken);
    await _prefs.setString(userRoleKey, role);

    if (pharmacyId != null) {
      await _prefs.setString(pharmacyIdKey, pharmacyId);
    }
    if (pharmacyName != null) {
      await _prefs.setString(pharmacyNameKey, pharmacyName);
    }

    print('Tokens and role/pharmacy data saved successfully');
  }

  Future<void> clearTokens() async {
    print('Clearing all tokens');
    await _prefs.remove(tokenKey);
    await _prefs.remove(refreshTokenKey);
    await _prefs.remove(userRoleKey);
    await _prefs.remove(pharmacyIdKey);
    await _prefs.remove(pharmacyNameKey);
    await _prefs.remove(adminTokenKey);
    await _prefs.remove(adminRefreshTokenKey);
    await _prefs.remove(subscriptionTypeKey); // Also clear subscription type on logout
    print('Tokens cleared successfully');
  }

  Map<String, String> get headers {
    final token = _prefs.getString(tokenKey);
    return {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, String> get pharmacyHeaders {
    final token = _prefs.getString(tokenKey);
    final headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    print('Generated pharmacy headers: $headers');
    return headers;
  }

  Future<bool> get isTokenExpired async {
    final token = await getAccessToken();
    return token == null || JwtDecoder.isExpired(token);
  }

  Future<bool> get shouldRefreshToken async {
    final token = await getAccessToken();
    if (token == null) return false;

    final expiryDate = JwtDecoder.getExpirationDate(token);
    final timeUntilExpiry = expiryDate.difference(DateTime.now());

    return timeUntilExpiry < tokenRefreshThreshold;
  }

  Future<bool> refreshToken() async {
    print('Attempting to refresh token...');
    try {
      final currentRefreshToken = await this.currentRefreshToken;

      if (currentRefreshToken == null) {
        print('No refresh token available');
        return false;
      }

      print('Sending refresh token request with token: ${currentRefreshToken.substring(0, min<int>(10, currentRefreshToken.length))}...');

      final refreshHeaders = {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      };

      http.Response response;
      String refreshUrl = Uri.parse(baseUrl).resolve('account/token/refresh/').toString();

      final client = http.Client();
      try {
        var request = http.Request('POST', Uri.parse(refreshUrl));
        request.headers.addAll(refreshHeaders);
        request.body = json.encode({'refresh': currentRefreshToken});

        var streamedResponse = await client.send(request).timeout(const Duration(seconds: timeoutSeconds));
        response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 308) {
          String? redirectLocation = response.headers['location'];
          if (redirectLocation != null && redirectLocation.isNotEmpty) {
            Uri redirectUri = Uri.parse(baseUrl).resolve(redirectLocation);

            print('Received 308 redirect, re-attempting refresh to: $redirectUri');
            request = http.Request('POST', redirectUri);
            request.headers.addAll(refreshHeaders);
            request.body = json.encode({'refresh': currentRefreshToken});
            streamedResponse = await client.send(request).timeout(const Duration(seconds: timeoutSeconds));
            response = await http.Response.fromStream(streamedResponse);
          } else {
            print('308 redirect received but no location header found.');
            await clearTokens();
            return false;
          }
        }
      } finally {
        client.close();
      }

      print('Refresh token response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = _parseResponse(response);
        final newAccessToken = data['access'];

        final newRefreshToken = data['refresh'] ?? currentRefreshToken;

        final currentRole = await userRole ?? 'admin';

        await saveTokens(newAccessToken, newRefreshToken, role: currentRole);
        print('Token refreshed successfully');
        return true;
      } else if (response.statusCode >= 400 && response.statusCode < 500) {
        print('Refresh token is invalid or expired or bad request: ${response.statusCode}');
        await clearTokens();
        return false;
      } else {
        print('Token refresh failed with unexpected status ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error refreshing token: $e');
      await clearTokens();
      return false;
    }
  }

  Future<dynamic> addPharmacy({
    required String name,
    required String city,
    required String latitude,
    required String longitude,
    required String licenseNumber,
    required String password,
    required String confirmPassword,
  }) async {
    return await _authenticatedRequest(() async {
      final token = await getAccessToken();
      if (token == null) {
        throw Exception('Authentication required. Please login again.');
      }

      final requestData = {
        'name': name,
        'city': city,
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'license_number': licenseNumber,
        'password': password,
        'confirm_password': confirmPassword,
      };

      print('Adding pharmacy with data: $requestData');

      final response = await _sendHttpRequest(
        'POST',
        Uri.parse('$baseUrl/account/pharmacy/'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestData),
      );

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 401) {
        final refreshed = await refreshToken();
        if (refreshed) {
          final newToken = await getAccessToken();
          if (newToken != null) {
            final retryResponse = await _sendHttpRequest(
              'POST',
              Uri.parse('$baseUrl/account/pharmacy/'),
              headers: {
                'Content-Type': 'application/json; charset=utf-8',
                'Authorization': 'Bearer $newToken',
              },
              body: json.encode(requestData),
            );
            return _parseResponse(retryResponse);
          }
        }
        throw Exception('Session expired. Please login again.');
      }

      return _parseResponse(response);
    });
  }

  dynamic _parseResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.bodyBytes.isEmpty) {
        return null;
      }
      try {
        return json.decode(utf8.decode(response.bodyBytes));
      } catch (e) {
        print('Error decoding successful response body: $e');
        throw Exception('Invalid response format from server.');
      }
    } else {
      String errorMessage;
      try {
        final errorBody = json.decode(utf8.decode(response.bodyBytes));
        errorMessage = errorBody['error']?.toString() ?? errorBody['detail']?.toString() ?? errorBody['message']?.toString() ?? 'An unknown error occurred.';
      } catch (e) {
        errorMessage = 'Request failed with status ${response.statusCode}.';
        if (response.body.isNotEmpty) {
          print('Non-JSON error response: ${response.body}');
        }
      }
      throw Exception(errorMessage);
    }
  }

  Future<http.Response> _sendHttpRequest(
      String method,
      Uri uri, {
        Map<String, String>? headers,
        dynamic body,
      }) async {
    http.Client client = http.Client();
    http.Response response = http.Response('Error: Unhandled HTTP response', 500);
    Uri currentUri = uri;

    try {
      for (int i = 0; i < 5; i++) {
        http.Request request = http.Request(method, currentUri);
        if (headers != null) {
          request.headers.addAll(headers);
        }
        if (body != null) {
          if (body is String) {
            request.body = body;
          } else {
            request.body = json.encode(body);
          }
        }

        var streamedResponse = await client.send(request).timeout(const Duration(seconds: timeoutSeconds));
        response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 308 || response.statusCode == 307) {
          String? redirectLocation = response.headers['location'];
          if (redirectLocation != null && redirectLocation.isNotEmpty) {
            currentUri = uri.resolve(redirectLocation);
            print('Received ${response.statusCode} redirect. Retrying $method to: $currentUri');
            continue;
          } else {
            print('Redirect status ${response.statusCode} received but no location header found.');
            return response;
          }
        } else {
          return response;
        }
      }
      return response;
    } finally {
      client.close();
    }
  }

  Future<T> _authenticatedRequest<T>(Future<T> Function() request) async {
    try {
      if (await isTokenExpired) {
        print('Access token is expired, attempting to refresh');
        final refreshed = await refreshToken();
        if (!refreshed) {
          print('Token refresh failed, authentication required');
          await clearTokens();
          throw Exception('Authentication required. Please login again.');
        }
      } else if (await shouldRefreshToken) {
        print('Token close to expiry, refreshing preemptively');
        await refreshToken();
      }

      try {
        return await request();
      } catch (requestError) {
        if (requestError.toString().contains('401') ||
            requestError.toString().toLowerCase().contains('unauthorized')) {
          print('Received 401 from request, attempting token refresh');

          final refreshed = await refreshToken();
          if (refreshed) {
            print('Token refreshed successfully, retrying request');
            return await request();
          } else {
            print('Token refresh failed after 401, authentication required');
            await clearTokens();
            throw Exception('Session expired. Please login again.');
          }
        }
        rethrow;
      }
    } catch (e) {
      if (e.toString().contains('401') ||
          e.toString().contains('authentication') ||
          e.toString().contains('unauthorized') ||
          e.toString().contains('token') ||
          e.toString().contains('timed out')) {
        print('Authentication error detected: $e. Clearing tokens.');
        await clearTokens();
        throw Exception('Session expired. Please login again.');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('Attempting login for email: $email');

      final response = await _sendHttpRequest(
        'POST',
        Uri.parse('${baseUrl}account/owner/login/'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      print('Login response status: ${response.statusCode}');

      final responseBody = _parseResponse(response);
      print('Login successful, response: $responseBody');

      if (responseBody != null && responseBody['access'] != null) {
        print('Saving access token...');

        await saveTokens(
          responseBody['access'],
          responseBody['refresh'] ?? '',
          role: responseBody['role'] ?? 'admin',
        );

        final savedToken = await getAccessToken();
        print('Verified saved token: $savedToken');
        return responseBody;
      }

      throw Exception(responseBody['detail'] ?? 'Login failed');
    } catch (e) {
      print('Login error: $e');
      throw Exception('Login failed: ${e.toString()}');
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
      final token = await getAccessToken();
      final refreshTokenValue = await currentRefreshToken;

      print('Tokennnnnnn: $token');
      print('Refresh Token: $refreshTokenValue');

      if (token == null) {
        throw Exception('You need to log in before registering a pharmacy.');
      }

      print('Preparing to add pharmacy with data: ${{
        'name': name,
        'city': city,
        'latitude': latitude,
        'longitude': longitude,
        'license_number': licenseNumber,
        'password': password,
        'confirm_password': confirmPassword,
      }}');

      print('Access Token: ${token.substring(0, min(20, token.length))}...');

      final requestData = {
        'id': 0,
        'name': name,
        'city': city,
        'latitude': latitude,
        'longitude': longitude,
        'license_number': licenseNumber,
        'password': password,
        'confirm_password': confirmPassword,
      };

      final headers = {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

      print('Tokennnnnnn: $token');
      print('Refresh Token: $refreshTokenValue');

      print('Request Headers: $headers');
      print('Request Body: ${json.encode(requestData)}');

      final response = await _sendHttpRequest(
        'POST',
        Uri.parse('${baseUrl}account/pharmacy/'),
        headers: headers,
        body: json.encode(requestData),
      );

      if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }

      return _parseResponse(response);

    } catch (e) {
      print('Error adding pharmacy: $e');
      rethrow;
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
      final response = await _sendHttpRequest(
        'POST',
        Uri.parse('${baseUrl}account/register/'),
        headers: headers,
        body: json.encode({
          'user': {
            'first_name': firstName,
            'last_name': lastName,
            'username': username,
            'email': email,
            'password': password,
          },
          'gender': gender,
          'phone': phone,
          'nationalID': nationalID,
        }),
      );

      return _parseResponse(response);
    } catch (e) {
      throw Exception(
          'Registration failed: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      final response = await _sendHttpRequest(
        'POST',
        Uri.parse('${baseUrl}auth/users/reset_password/'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: json.encode({
          'email': email,
        }),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        print('Password reset email sent successfully to $email');
        return;
      } else {
        final errorBody = _parseResponse(response);
        String errorMessage = 'Failed to send password reset email.';
        if (errorBody is Map && errorBody.containsKey('email')) {
          errorMessage = errorBody['email'][0];
        } else if (errorBody is Map && errorBody.containsKey('detail')) {
          errorMessage = errorBody['detail'];
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error sending password reset email: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      final refreshTokenValue = await currentRefreshToken;
      if (refreshTokenValue != null) {
        _sendHttpRequest(
          'POST',
          Uri.parse('${baseUrl}account/logout/'),
          headers: {'Content-Type': 'application/json; charset=utf-8'},
          body: json.encode({'refresh': refreshTokenValue}),
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            return http.Response('', 200);
          },
        ).catchError((e) {
          print('Logout server notification failed: $e');
        });
      }
    } catch (e) {
      print('Error preparing logout request: $e');
    } finally {
      await clearTokens();
    }
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? headers}) async {
    try {
      print('Making GET request to: $baseUrl$endpoint');
      print('Using headers: ${headers ?? this.headers}');

      final response = await _sendHttpRequest(
        'GET',
        Uri.parse(baseUrl + endpoint),
        headers: headers ?? this.headers,
      );

      return _parseResponse(response);
    } catch (e) {
      print('Error in GET request: $e');
      rethrow;
    }
  }

  Future<dynamic> authenticatedGet(String endpoint) async {
    try {
      print('Starting authenticated request...');

      final response = await _authenticatedRequest(() async {
        return await _sendHttpRequest(
          'GET',
          Uri.parse(baseUrl + endpoint),
          headers: pharmacyHeaders,
        );
      });
      return _parseResponse(response);

    } catch (e) {
      print('Error in authenticated request: $e');
      rethrow;
    }
  }

  Future<dynamic> post(String endpoint, dynamic data, {Map<String, String>? headers}) async {
    try {
      final response = await _authenticatedRequest(() async {
        return await _sendHttpRequest(
          'POST',
          Uri.parse(baseUrl + endpoint),
          headers: headers ?? this.headers,
          body: json.encode(data),
        );
      });
      return _parseResponse(response);
    } catch (e) {
      print('POST request error: $e');
      rethrow;
    }
  }

  Future<dynamic> update(String endpoint, dynamic data, {Map<String, String>? headers}) async {
    try {
      final response = await _authenticatedRequest(() async {
        return await _sendHttpRequest(
          'PUT',
          Uri.parse(baseUrl + endpoint),
          headers: headers ?? this.headers,
          body: json.encode(data),
        );
      });
      return _parseResponse(response);
    } catch (e) {
      print('UPDATE request error: $e');
      rethrow;
    }
  }

  Future<dynamic> put(String endpoint, dynamic data, {Map<String, String>? headers}) async {
    try {
      final response = await _authenticatedRequest(() async {
        return await _sendHttpRequest(
          'PUT',
          Uri.parse(baseUrl + endpoint),
          headers: headers ?? this.headers,
          body: json.encode(data),
        );
      });
      return _parseResponse(response);
    } catch (e) {
      print('PUT request error: $e');
      rethrow;
    }
  }

  Future<dynamic> patch(String endpoint, dynamic data, {Map<String, String>? headers}) async {
    try {
      final response = await _authenticatedRequest(() async {
        return await _sendHttpRequest(
          'PATCH',
          Uri.parse(baseUrl + endpoint),
          headers: headers ?? this.headers,
          body: json.encode(data),
        );
      });
      return _parseResponse(response);
    } catch (e) {
      print('PATCH request error: $e');
      rethrow;
    }
  }

  Future<dynamic> delete(String endpoint, String id, {Map<String, String>? headers}) async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        throw Exception('Authentication required. Please login again.');
      }

      final fullUrl = baseUrl + endpoint + id;
      print('DELETE request to: $fullUrl');

      final requestHeaders = headers ?? pharmacyHeaders;
      print('Using headers: $requestHeaders');

      final response = await _authenticatedRequest(() async {
        return await _sendHttpRequest(
          'DELETE',
          Uri.parse(fullUrl),
          headers: requestHeaders,
        );
      });

      return _parseResponse(response);
    } catch (e) {
      print('DELETE request error: $e');
      rethrow;
    }
  }

  // =========================================================================
  // ================= الدوال الجديدة للتعامل مع الروابط المخصصة =================
  // =========================================================================

  /// دالة لجلب البيانات من الروابط التي تتطلب `pharmacy_id`
  ///  مثل: `exchange/get/pharmcy_seller/orders/pharmacy/{pharmacy_id}/`
  Future<dynamic> getForPharmacy(String endpoint, {required String pharmacyId}) async {
    final fullEndpoint = '$endpoint' + 'pharmacy/$pharmacyId/';
    print('Calling new GET for pharmacy endpoint: $fullEndpoint');
    return authenticatedGet(fullEndpoint);
  }

  /// دالة لإرسال البيانات للروابط التي تتطلب `pharmacy_id`
  /// مثل: `exchange/buy/order/pharmacy/{pharmacy_id}/`
  Future<dynamic> postForPharmacy(String endpoint, dynamic data, {required String pharmacyId}) async {
    final fullEndpoint = '$endpoint' + 'pharmacy/$pharmacyId/';
    print('Calling new POST for pharmacy endpoint: $fullEndpoint');
    return post(fullEndpoint, data);
  }

  /// دالة لتحديث حالة الطلب باستخدام `order_id`
  /// مثل: `exchange/update_status/{id}/`
  Future<dynamic> patchWithId(String endpoint, dynamic data, {required String resourceId}) async {
    final fullEndpoint = '$endpoint$resourceId/';
    print('Calling new PATCH with ID endpoint: $fullEndpoint');
    return patch(fullEndpoint, data);
  }

  // =========================================================================
  // =========================== نهاية الدوال الجديدة ===========================
  // =========================================================================


  Future<bool> get isLoggedIn async {
    final token = await getAccessToken();
    if (token == null) return false;
    return !JwtDecoder.isExpired(token);
  }

  Future<Map<String, dynamic>> pharmacyLogin(String name, String password) async {
    try {
      const endpoint = 'account/pharmacy/login/';
      final url = '$baseUrl$endpoint';

      print('Attempting pharmacy login with name: $name');
      print('Request URL: $url');
      print('Request payload: ${json.encode({
        'name': name.trim(),
        'password': password.trim(),
      })}');

      final response = await _sendHttpRequest(
        'POST',
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: json.encode({
          'name': name.trim(),
          'password': password.trim(),
        }),
      );

      print('Login response status: ${response.statusCode}');

      final responseBody = _parseResponse(response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Login successful, response body: $responseBody');

        if (!responseBody.containsKey('access') || !responseBody.containsKey('refresh')) {
          print('Invalid response format - missing tokens');
          throw Exception('Invalid response format: missing tokens');
        }

        String pharmacyId = '';
        if (responseBody.containsKey('pharmacy') && responseBody['pharmacy'] is Map) {
          final pharmacy = responseBody['pharmacy'];
          pharmacyId = pharmacy['id']?.toString() ?? '';
          print('Extracted pharmacy ID from response: $pharmacyId');
        }

        await saveTokens(responseBody['access'], responseBody['refresh'],
            role: 'pharmacy', pharmacyId: pharmacyId, pharmacyName: name.trim());

        return {
          'id': pharmacyId,
          'name': name.trim(),
          'access': responseBody['access'],
          'refresh': responseBody['refresh'],
        };
      }

      throw Exception(responseBody['detail'] ?? 'Login failed with status ${response.statusCode}');

    } catch (e) {
      print('Error in pharmacy login: $e');
      rethrow;
    }
  }
}