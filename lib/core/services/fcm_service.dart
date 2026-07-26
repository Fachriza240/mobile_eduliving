import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../main.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(); // Pastikan firebase terinisialisasi di background
  print("Handling a background message: ${message.messageId}");
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (kIsWeb) return; // Skip mobile local notifications & FCM init on web unless explicitly configured
    // 1. Request permissions for iOS (Android will handle this on its own >13)
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Initialize local notifications for Foreground
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          final data = jsonDecode(details.payload!);
          handleNotificationTap(data);
        }
      },
    );

    // Create a high importance channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // name
      description: 'This channel is used for important notifications.', // description
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 3. Set up Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        _showLocalNotification(message, channel);
      }
    });

    // 4. Set up Background message tap handler
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      handleNotificationTap(message.data);
    });

    // 5. Set up Terminated message handler
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      // Tunggu frame pertama agar context navigator sudah siap
      WidgetsBinding.instance.addPostFrameCallback((_) {
        handleNotificationTap(initialMessage.data);
      });
    }

    // 6. Set up Background Message Handler (Top-level function)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 7. Token refresh listener
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      uploadFcmToken(newToken);
    });
  }

  void _showLocalNotification(RemoteMessage message, AndroidNotificationChannel channel) {
    _localNotifications.show(
      id: message.notification.hashCode,
      title: message.notification?.title,
      body: message.notification?.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: '@mipmap/ic_launcher',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// Memproses tipe notifikasi (payload type) untuk mengarahkan rute
  void handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    if (type == null) return;

    final context = navigatorKey.currentContext;
    if (context == null) return;

    switch (type) {
      // === Mahasiswa (User) ===
      case 'booking.disetujui':
      case 'booking.ditolak':
      case 'booking.kadaluarsa':
      case 'booking.pembayaran_ditolak':
      case 'sewa.perpanjang':
      case 'sewa.rating_reminder':
      case 'ulasan.dibalas':
        // Arahkan ke riwayat booking user (asumsikan route home lalu buka tab profil/riwayat)
        // Di aplikasi ini tidak ada route '/user/bookings' secara eksplisit di main.dart, 
        // sehingga kita arahkan ke profil / history.
        Navigator.pushNamed(context, '/home'); 
        break;

      case 'pesanan.update':
        Navigator.pushNamed(context, '/transactions');
        break;

      case 'seller.disetujui':
      case 'seller.ditolak':
        Navigator.pushNamed(context, '/marketplace');
        break;

      // === Provider (Penyedia) ===
      case 'booking.baru':
      case 'booking.dibatalkan':
      case 'booking.pembayaran':
      case 'booking.pembayaran_manual':
      case 'ulasan.baru':
      case 'provider.disetujui':
      case 'provider.ditolak':
        Navigator.pushNamed(context, '/home'); // Role Provider akan diredirect ke dashboard otomatis
        break;

      // === Seller ===
      case 'pesanan.baru':
        Navigator.pushNamed(context, '/home');
        break;
        
      default:
        // Default ke notifikasi
        Navigator.pushNamed(context, '/notifications');
        break;
    }
  }

  /// Upload FCM Token ke backend (dipanggil saat login / token refresh)
  static Future<void> uploadFcmToken([String? token]) async {
    final fcmToken = token ?? await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) return;

    try {
      await ApiService().post(
        '/fcm-token', // Pastikan endpoint di api_constants atau gunakan string langsung
        data: {'fcm_token': fcmToken},
      );
      print('Berhasil upload FCM Token: $fcmToken');
    } catch (e) {
      print('Gagal upload FCM Token: $e');
    }
  }

  /// Menghapus FCM Token dari backend (dipanggil sebelum logout)
  static Future<void> deleteFcmToken() async {
    try {
      await ApiService().delete('/fcm-token');
      print('Berhasil menghapus FCM Token');
    } catch (e) {
      print('Gagal menghapus FCM Token: $e');
    }
  }
}
