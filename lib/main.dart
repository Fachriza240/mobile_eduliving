import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/utils/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/residence/providers/residence_provider.dart';
import 'features/activity/providers/activity_provider.dart';
import 'features/profile/providers/booking_provider.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/home/home_screen.dart';
import 'features/provider/provider_home_screen.dart'; // RootScreen

// Provider (penyedia) — BARU
import 'features/provider/providers/provider_dashboard_provider.dart';
import 'features/provider/providers/provider_residence_provider.dart';
import 'features/provider/providers/provider_activity_provider.dart';
import 'features/provider/providers/provider_booking_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        // Role: Penyedia
        ChangeNotifierProvider(create: (_) => ProviderDashboardProvider()),
        ChangeNotifierProvider(create: (_) => ProviderResidenceProvider()),
        ChangeNotifierProvider(create: (_) => ProviderActivityProvider()),
        ChangeNotifierProvider(create: (_) => ProviderBookingProvider()),
      ],
      child: MaterialApp(
        title: 'EduLiving',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (_) => const SplashScreen(),
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/home': (_) => const RootScreen(),
        },
        onUnknownRoute: (_) => MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      ),
    );
  }
}
