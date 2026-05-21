import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';

class AppHelpers {
  AppHelpers._();

  static String getImageUrl(String path) => buildImageUrl(path);

  static String formatPrice(double price, {String suffix = ''}) =>
      formatRupiah(price, suffix: suffix);

  static String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    final dt = DateTime.tryParse(dateStr);
    return formatDateShort(dt);
  }

  static void openWhatsApp(BuildContext context, String phone, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Hubungi: $phone')),
    );
  }
}
