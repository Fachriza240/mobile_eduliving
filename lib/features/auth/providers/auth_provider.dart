import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/storage_helper.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;
  Map<String, dynamic>? _fieldErrors;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get fieldErrors => _fieldErrors;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  // ── Cek Session ──────────────────────────────────────
  Future<void> checkAuthStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final loggedIn = await StorageHelper.isLoggedIn();
      if (!loggedIn) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      final res = await _api.get(ApiConstants.me);
      final data = res['data'] as Map<String, dynamic>?;
      final userData = data?['user'] as Map<String, dynamic>?;
      if (userData != null) {
        _user = UserModel.fromJson(userData);
      }
      _status = AuthStatus.authenticated;
    } catch (_) {
      await StorageHelper.clearAll();
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  // ── Login ─────────────────────────────────────────────
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    _fieldErrors = null;
    notifyListeners();

    try {
      final res = await _api.post(
        ApiConstants.login,
        data: {
          'email': email.trim(),
          'password': password,
        },
      );

      final data = res['data'] as Map<String, dynamic>?;
      final token = data?['token'] as String?;
      final userData = data?['user'] as Map<String, dynamic>?;

      if (token == null || userData == null) {
        throw ApiException(message: 'Respons login tidak valid dari server.');
      }

      _user = UserModel.fromJson(userData);

      await StorageHelper.saveToken(token);
      await StorageHelper.saveUserInfo(
        id: _user!.id,
        name: _user!.name,
        email: _user!.email,
        role: _user!.primaryRole,
      );

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _fieldErrors = e.errors;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Terjadi kesalahan. Coba lagi.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // ── Register Mahasiswa (user biasa) ───────────────────
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String phone,
    required String address,
    String role = 'user',
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    _fieldErrors = null;
    notifyListeners();

    try {
      final res = await _api.post(
        ApiConstants.register,
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
          'password_confirmation': passwordConfirmation,
          'phone': phone.trim(),
          'address': address.trim(),
          'role': role,
        },
      );

      final data = res['data'] as Map<String, dynamic>?;
      final token = data?['token'] as String?;
      final userData = data?['user'] as Map<String, dynamic>?;

      if (token == null || userData == null) {
        throw ApiException(message: 'Respons registrasi tidak valid.');
      }

      _user = UserModel.fromJson(userData);

      await StorageHelper.saveToken(token);
      await StorageHelper.saveUserInfo(
        id: _user!.id,
        name: _user!.name,
        email: _user!.email,
        role: _user!.primaryRole,
      );

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _fieldErrors = e.errors;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Terjadi kesalahan. Coba lagi.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // ── Register Provider (provider_residence / provider_event) ──
  // Wajib kirim: NIK (16 digit), foto KTP (File), selfie (base64 String)
  // Dikirim sebagai multipart/form-data karena ada file upload
  Future<bool> registerProvider({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String role, // 'provider_residence' atau 'provider_event'
    required String providerNik, // 16 digit
    required File providerKtp, // file foto KTP dari galeri
    required String providerSelfieBase64, // base64 string hasil kamera
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    _fieldErrors = null;
    notifyListeners();

    try {
      // Kirim sebagai multipart/form-data (karena ada file KTP)
      final formData = FormData.fromMap({
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'password_confirmation': passwordConfirmation,
        'role': role,
        'provider_nik': providerNik.trim(),
        // File KTP — upload langsung sebagai file
        'provider_ktp': await MultipartFile.fromFile(
          providerKtp.path,
          filename: 'ktp_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
        // Selfie dikirim sebagai string base64
        'provider_selfie': providerSelfieBase64,
      });

      final res = await _api.post(
        ApiConstants.register,
        formData: formData,
      );

      final data = res['data'] as Map<String, dynamic>?;
      final token = data?['token'] as String?;
      final userData = data?['user'] as Map<String, dynamic>?;

      if (token == null || userData == null) {
        throw ApiException(message: 'Respons registrasi tidak valid.');
      }

      _user = UserModel.fromJson(userData);

      await StorageHelper.saveToken(token);
      await StorageHelper.saveUserInfo(
        id: _user!.id,
        name: _user!.name,
        email: _user!.email,
        role: _user!.primaryRole,
      );

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _fieldErrors = e.errors;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan. Coba lagi.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // ── Set Authenticated (untuk keperluan internal) ───────
  void setAuthenticated(UserModel user) {
    _user = user;
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  // ── Logout ────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await _api.post(ApiConstants.logout);
    } catch (_) {}
    await StorageHelper.clearAll();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // ── Refresh User ─────────────────────────────────────
  Future<void> refreshUser() async {
    try {
      final res = await _api.get(ApiConstants.me);
      final data = res['data'] as Map<String, dynamic>?;
      final userData = data?['user'] as Map<String, dynamic>?;
      if (userData != null) {
        _user = UserModel.fromJson(userData);
        notifyListeners();
      }
    } catch (_) {}
  }

  void updateUserLocal(UserModel updated) {
    _user = updated;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _fieldErrors = null;
    notifyListeners();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await _api.put(ApiConstants.userProfile, data: {
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': confirmPassword,
      });
    } catch (e) {
      throw Exception(e.toString().replaceAll('ApiException: ', ''));
    }
  }
}
