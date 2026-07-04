import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../auth/providers/auth_provider.dart';
import '../home/home_screen.dart'; // HomeScreen user (existing)
import 'screens/dashboard/provider_dashboard_screen.dart';
import 'screens/residence/provider_residence_list_screen.dart';
import 'screens/activity/provider_activity_list_screen.dart';
import 'screens/booking_mgmt/provider_booking_list_screen.dart';
import 'package:eduliving_mobile/features/provider/provider_profile_tab.dart';
import 'provider_marketplace_home_screen.dart';

/// Root screen yang memilih antara user HomeScreen dan provider HomeScreen
/// berdasarkan role dari AuthProvider.
class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user == null) return const HomeScreen();

    if (user.isProviderResidence) {
      return const ProviderHomeScreen(isResidence: true);
    }
    if (user.isProviderEvent) {
      return const ProviderHomeScreen(isResidence: false);
    }
    if (user.isProviderMarketplace) {
      return const ProviderMarketplaceHomeScreen();
    }

    return const HomeScreen(); // role user/mahasiswa
  }
}

// ============================================================
// PROVIDER HOME SCREEN
// ============================================================
class ProviderHomeScreen extends StatefulWidget {
  final bool isResidence;

  const ProviderHomeScreen({super.key, required this.isResidence});

  @override
  State<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends State<ProviderHomeScreen> {
  int _idx = 0;

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      ProviderDashboardScreen(
        isResidence: widget.isResidence,
        onSwitchTab: (idx) => setState(() => _idx = idx),
      ),
      if (widget.isResidence)
        const ProviderResidenceListScreen()
      else
        const ProviderActivityListScreen(),
      ProviderBookingListScreen(isResidence: widget.isResidence),
      const ProviderProfileTab(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isResidence ? AppColors.residence : AppColors.activity;

    return Scaffold(
      body: IndexedStack(index: _idx, children: _tabs),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.navBackground,
          border: const Border(
            top: BorderSide(color: AppColors.divider, width: 0.8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _idx,
          onTap: (i) => setState(() => _idx = i),
          selectedItemColor: color,
          unselectedItemColor: AppColors.navUnselected,
          backgroundColor: AppColors.navBackground,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
          ),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(widget.isResidence
                  ? Icons.home_work_outlined
                  : Icons.event_outlined),
              activeIcon: Icon(widget.isResidence
                  ? Icons.home_work_rounded
                  : Icons.event_rounded),
              label: widget.isResidence ? 'Hunian' : 'Acara',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long_rounded),
              label: 'Booking',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
