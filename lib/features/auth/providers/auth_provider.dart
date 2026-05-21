import 'package:flutter/foundation.dart';
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
      // Response: { "status": "success", "data": { "user": {...} } }
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

      // Response: { "status":"success", "data": { "user":{...}, "token":"..." } }
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

  // ── Register ──────────────────────────────────────────
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
      // Map role ke format yang diterima backend
      String backendRole = role;
      if (role == 'provider_residence' || role == 'provider_event') {
        backendRole = role; // kirim apa adanya, backend akan handle
      }

      final res = await _api.post(
        ApiConstants.register,
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
          'password_confirmation': passwordConfirmation,
          'phone': phone.trim(),
          'address': address.trim(),
          'role': backendRole,
        },
      );

      // Response: { "status":"success", "data": { "user":{...}, "token":"..." } }
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
