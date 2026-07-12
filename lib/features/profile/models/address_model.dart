class AddressModel {
  final int id;
  final int userId;
  final String label;
  final String recipientName;
  final String phone;
  final String address;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.userId,
    required this.label,
    required this.recipientName,
    required this.phone,
    required this.address,
    required this.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'],
      userId: json['user_id'],
      label: json['label'] ?? 'Rumah',
      recipientName: json['recipient_name'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      isDefault: json['is_default'] == 1 || json['is_default'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'recipient_name': recipientName,
      'phone': phone,
      'address': address,
      'is_default': isDefault ? 1 : 0,
    };
  }
}
