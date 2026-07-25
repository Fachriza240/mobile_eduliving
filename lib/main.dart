import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/services/fcm_service.dart';
//import 'features/provider/providers/provider_report_provider.dart';

import 'core/utils/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/residence/providers/residence_provider.dart';
import 'features/activity/providers/activity_provider.dart';
import 'features/profile/providers/booking_provider.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/profile/providers/address_provider.dart';
import 'features/provider/provider_home_screen.dart'; // RootScreen

// Provider (penyedia) — BARU
import 'features/provider/providers/provider_dashboard_provider.dart';
import 'features/provider/providers/provider_residence_provider.dart';
import 'features/provider/providers/provider_activity_provider.dart';
import 'features/provider/providers/provider_booking_provider.dart';
import 'features/provider/providers/provider_marketplace_provider.dart';

import 'features/bookmark/providers/bookmark_provider.dart';
import 'features/marketplace/providers/marketplace_provider.dart';
import 'features/marketplace/providers/cart_provider.dart';
import 'features/bookmark/screens/bookmark_screen.dart';
import 'features/marketplace/screens/marketplace_screen.dart';
import 'features/marketplace/screens/cart_screen.dart';
import 'features/profile/screens/riwayat_screen.dart';
import 'features/profile/screens/change_password_screen.dart';
import 'features/notification/notification_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  await FcmService().init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const EduLivingApp());
  
  // Inisialisasi service notifikasi FCM
  await FcmService().init();
}

class EduLivingApp extends StatelessWidget {
  const EduLivingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Role: Mahasiswa
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ResidenceProvider()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),

        // Role: Penyedia
        ChangeNotifierProvider(create: (_) => ProviderDashboardProvider()),
        ChangeNotifierProvider(create: (_) => ProviderResidenceProvider()),
        ChangeNotifierProvider(create: (_) => ProviderActivityProvider()),
        ChangeNotifierProvider(create: (_) => ProviderBookingProvider()),
        ChangeNotifierProvider(create: (_) => ProviderMarketplaceProvider()),
        ChangeNotifierProvider(
            create: (_) => ProviderMarketplaceOrderProvider()),
        ChangeNotifierProvider(create: (_) => BookmarkProvider()),
        ChangeNotifierProvider(create: (_) => MarketplaceProvider()),
        ChangeNotifierProvider(create: (_) => MarketplaceTransactionProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'EduLiving',
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (_) => const SplashScreen(),
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/home': (_) => const RootScreen(),
          '/bookmarks': (_) => const BookmarkScreen(),
          '/marketplace': (_) => const MarketplaceScreen(),
          '/cart': (_) => const CartScreen(),
          '/transactions': (_) => const RiwayatScreen(initialKategori: RiwayatKategori.barang),
          '/change-password': (_) => const ChangePasswordScreen(),
          '/notifications': (_) => const NotificationScreen(),
        },
        onUnknownRoute: (_) => MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      ),
    );
  }
}
