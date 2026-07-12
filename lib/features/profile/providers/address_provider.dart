import 'package:flutter/foundation.dart';
import 'package:eduliving_mobile/core/constants/api_constants.dart';
import 'package:eduliving_mobile/core/services/api_service.dart';
import 'package:eduliving_mobile/features/profile/models/address_model.dart';

class AddressProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<AddressModel> _addresses = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  List<AddressModel> get addresses => _addresses;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  AddressModel? get defaultAddress {
    try {
      return _addresses.firstWhere((a) => a.isDefault);
    } catch (_) {
      return _addresses.isNotEmpty ? _addresses.first : null;
    }
  }

  Future<void> fetchAddresses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.get(ApiConstants.userAddresses);
      final data = res['data'] as List? ?? [];
      _addresses = data.map((e) => AddressModel.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addAddress(Map<String, dynamic> data) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.post(ApiConstants.userAddresses, data: data);
      final newAddress = AddressModel.fromJson(res['data']);
      
      if (newAddress.isDefault) {
        _addresses = _addresses.map((a) => 
          AddressModel(
            id: a.id, userId: a.userId, label: a.label, recipientName: a.recipientName,
            phone: a.phone, address: a.address, isDefault: false
          )
        ).toList();
      }
      
      _addresses.add(newAddress);
      
      // Re-sort so default is top
      _addresses.sort((a, b) => b.isDefault ? 1 : (a.isDefault ? -1 : 0));

      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAddress(int id, Map<String, dynamic> data) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.put(ApiConstants.userAddressDetail(id), data: data);
      final updated = AddressModel.fromJson(res['data']);
      
      if (updated.isDefault) {
        _addresses = _addresses.map((a) => 
          AddressModel(
            id: a.id, userId: a.userId, label: a.label, recipientName: a.recipientName,
            phone: a.phone, address: a.address, isDefault: false
          )
        ).toList();
      }
      
      final index = _addresses.indexWhere((a) => a.id == id);
      if (index != -1) {
        _addresses[index] = updated;
      }

      _addresses.sort((a, b) => b.isDefault ? 1 : (a.isDefault ? -1 : 0));

      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAddress(int id) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _api.delete(ApiConstants.userAddressDetail(id));
      _addresses.removeWhere((a) => a.id == id);
      
      if (_addresses.isNotEmpty && !_addresses.any((a) => a.isDefault)) {
         // Fallback default setting locally (backend handles it)
         await fetchAddresses();
      } else {
        notifyListeners();
      }
      
      _isSaving = false;
      return true;
    } catch (e) {
      _error = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> setDefault(int id) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _api.patch(ApiConstants.userAddressSetDefault(id));
      
      _addresses = _addresses.map((a) => 
          AddressModel(
            id: a.id, userId: a.userId, label: a.label, recipientName: a.recipientName,
            phone: a.phone, address: a.address, isDefault: a.id == id
          )
        ).toList();
      
      _addresses.sort((a, b) => b.isDefault ? 1 : (a.isDefault ? -1 : 0));

      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
