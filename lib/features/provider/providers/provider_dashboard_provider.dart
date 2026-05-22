import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/provider_models.dart';

class ProviderDashboardProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  ProviderDashboardModel? _dashboard;
  bool _isLoading = false;
  String? _error;

  ProviderDashboardModel? get dashboard => _dashboard;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDashboard(bool isResidence) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final endpoint = isResidence
          ? ApiConstants.providerResidenceDashboard
          : ApiConstants.providerEventDashboard;

      final res = await _api.get(endpoint);
      final data = res['data'] as Map<String, dynamic>?;
      if (data != null) {
        _dashboard = ProviderDashboardModel.fromJson(data);
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
