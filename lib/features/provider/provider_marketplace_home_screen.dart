import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../auth/providers/auth_provider.dart';
import 'screens/marketplace/provider_marketplace_list_screen.dart';
import 'screens/marketplace/provider_marketplace_order_screen.dart';

/// Home screen khusus untuk role provider_marketplace.
/// Bottom nav: Produk | Pesanan | Profil
class ProviderMarketplaceHomeScreen extends StatefulWidget {
  const ProviderMarketplaceHomeScreen({super.key});

  @override
  State<ProviderMarketplaceHomeScreen> createState() =>
      _ProviderMarketplaceHomeScreenState();
}

class _ProviderMarketplaceHomeScreenState
    extends State<ProviderMarketplaceHomeScreen> {
  int _currentIndex = 0;

  static const _pages = [
    ProviderMarketplaceListScreen(),
    ProviderMarketplaceOrderScreen(),
    _MarketplaceProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: AppColors.market,
        unselectedItemColor: AppColors.textHint,
        selectedLabelStyle: const TextStyle(
            fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            const TextStyle(fontFamily: 'Poppins', fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront_rounded),
            label: 'Produk',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long_rounded),
            label: 'Pesanan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// ── Tab Profil untuk Provider Marketplace ────────────────────────────────────
class _MarketplaceProfileTab extends StatelessWidget {
  const _MarketplaceProfileTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      user?.initials ?? 'M',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? '-',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '-',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.4)),
                    ),
                    child: const Text(
                      'Provider Marketplace',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tombol Keluar Mode Penjual
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 0.8),
                ),
                child: ListTile(
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        title: const Text('Keluar Mode Penjual?',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700)),
                        content: const Text(
                            'Kamu akan kembali ke tampilan pengguna biasa. Akunmu tetap login.',
                            style: TextStyle(
                                fontFamily: 'Poppins', fontSize: 13)),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Batal')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.market),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Keluar Mode Penjual',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      final user = auth.user;
                      if (user != null) {
                        auth.updateUserLocal(
                          user.copyWith(isSellerModeActive: false),
                        );
                      } 
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/home', (_) => false);
                    }
                  },
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.marketLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.swap_horiz_rounded,
                        color: AppColors.market, size: 18),
                  ),
                  title: const Text('Keluar Mode Penjual',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.market)),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textHint),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
