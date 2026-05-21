import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/booking_provider.dart';
import '../../profile/screens/booking_list_screen.dart';
import '../../profile/screens/edit_profile_screen.dart';

class ProfilTab extends StatelessWidget {
  const ProfilTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) return _guestView(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Profil Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 21),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => auth.refreshUser(),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _profileHeader(context, auth),
              const SizedBox(height: 8),
              _statsRow(context),
              const SizedBox(height: 8),
              _menuList(context, auth),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header Avatar Biru ────────────────────────────
  Widget _profileHeader(BuildContext context, AuthProvider auth) {
    final user = auth.user!;
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Avatar gradient biru brand
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(38),
            ),
            child: Center(
              child: Text(
                user.initials,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(user.email,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(user.roleLabel,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ),
              ],
            ),
          ),

          // Tombol edit
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit_outlined,
                  size: 18, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  // ── Statistik Booking ─────────────────────────────
  Widget _statsRow(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (_, prov, __) => Container(
        color: AppColors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Row(
          children: [
            _statItem(
                'Menunggu', prov.countByStatus('pending'), AppColors.warning),
            _divider(),
            _statItem(
                'Aktif', prov.countByStatus('approved'), AppColors.success),
            _divider(),
            _statItem(
                'Selesai', prov.countByStatus('completed'), AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, int count, Color color) {
    return Expanded(
      child: Column(children: [
        Text(count.toString(),
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color)),
        Text(label,
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: AppColors.textSecondary)),
      ]),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 36, color: AppColors.divider);

  // ── Menu List ─────────────────────────────────────
  Widget _menuList(BuildContext context, AuthProvider auth) {
    return Container(
      color: AppColors.white,
      child: Column(
        children: [
          _sectionLabel('Aktivitas'),
          _item(context,
              icon: Icons.receipt_long_outlined,
              label: 'Riwayat Pemesanan',
              desc: 'Hunian dan acara yang pernah dipesan',
              iconBg: AppColors.primaryLight,
              iconColor: AppColors.primary, onTap: () {
            context.read<BookingProvider>().loadBookings();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BookingListScreen()),
            );
          }),
          _dividerFull(),
          _item(context,
              icon: Icons.bookmark_border_rounded,
              label: 'Bookmark Saya',
              desc: 'Hunian dan acara yang disimpan',
              iconBg: AppColors.marketLight,
              iconColor: AppColors.market,
              onTap: () => Navigator.pushNamed(context, '/bookmarks')),
          _dividerFull(),
          _sectionLabel('Akun'),
          _item(context,
              icon: Icons.person_outline_rounded,
              label: 'Edit Profil',
              desc: 'Ubah nama dan informasi pribadi',
              iconBg: AppColors.primaryLight,
              iconColor: AppColors.primary,
              onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EditProfileScreen()),
                  )),
          _dividerFull(),
          _item(context,
              icon: Icons.lock_outline_rounded,
              label: 'Ubah Kata Sandi',
              desc: 'Perbarui password akun Anda',
              iconBg: const Color(0xFFEDE7F6),
              iconColor: const Color(0xFF7B1FA2),
              onTap: () => Navigator.pushNamed(context, '/change-password')),
          _dividerFull(),
          _sectionLabel('Lainnya'),
          _item(context,
              icon: Icons.help_outline_rounded,
              label: 'Bantuan & FAQ',
              desc: 'Pertanyaan yang sering ditanyakan',
              iconBg: AppColors.activityLight,
              iconColor: AppColors.activity,
              onTap: () => _soon(context, 'Bantuan')),
          _dividerFull(),
          _item(context,
              icon: Icons.info_outline_rounded,
              label: 'Tentang EduLiving',
              desc: 'Versi 1.0.0 • Platform Layanan Mahasiswa',
              iconBg: AppColors.primaryLight,
              iconColor: AppColors.primary,
              onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'EduLiving',
                    applicationVersion: '1.0.0',
                    applicationLegalese: '© 2026 Tim EduLiving',
                  )),
          _dividerFull(),
          _item(context,
              icon: Icons.logout_rounded,
              label: 'Keluar',
              desc: 'Logout dari akun EduLiving',
              iconBg: AppColors.errorLight,
              iconColor: AppColors.error,
              labelColor: AppColors.error,
              onTap: () => _confirmLogout(context, auth)),
        ],
      ),
    );
  }

  Widget _sectionLabel(String title) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        color: AppColors.background,
        child: Text(title.toUpperCase(),
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textHint,
                letterSpacing: 1.2)),
      );

  Widget _item(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String desc,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
    Color? labelColor,
  }) =>
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: labelColor ?? AppColors.textPrimary)),
                  Text(desc,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppColors.textHint)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: AppColors.textHint),
          ]),
        ),
      );

  Widget _dividerFull() =>
      const Divider(height: 1, indent: 74, color: AppColors.divider);

  // ── Tampilan Tamu ─────────────────────────────────
  Widget _guestView(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar:
          AppBar(automaticallyImplyLeading: false, title: const Text('Profil')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(Icons.person_rounded,
                    size: 56, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text('Belum Masuk',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Text(
                'Masuk ke akun EduLiving untuk mengakses profil dan riwayat pemesanan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.6),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: const Text('Masuk Sekarang'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: const Text('Daftar Akun Baru'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar dari EduLiving?',
            style:
                TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: const Text('Anda akan logout dari akun ini.',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              await auth.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (_) => false);
              }
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  void _soon(BuildContext context, String f) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$f segera hadir!',
            style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
