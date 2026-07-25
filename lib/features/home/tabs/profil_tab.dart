import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_helpers.dart';
import '../../marketplace/screens/become_provider_marketplace_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/booking_provider.dart';
import '../../profile/screens/riwayat_screen.dart';
import '../../profile/screens/edit_profile_screen.dart';
import '../../profile/screens/address/address_list_screen.dart';

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileCard(context, auth),
              const SizedBox(height: 24),
              _buildRolesSection(context, auth),
              const SizedBox(height: 16),
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

  Widget _buildProfileCard(BuildContext context, AuthProvider auth) {
    final user = auth.user!;
    final joinDate = AppHelpers.formatDate(user.createdAt?.toString() ?? DateTime.now().toString());

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Blue Banner
        Container(
          height: 140,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // White Card
        Container(
          margin: const EdgeInsets.only(top: 80, left: 16, right: 16),
          padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name and Edit Button row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFE0E7FF), borderRadius: BorderRadius.circular(20)),
                              child: Text('User', style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Color(0xFF3730A3), fontWeight: FontWeight.w600)),
                            ),
                            if (user.isApprovedSeller) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(20)),
                                child: Row(
                                  children: [
                                    const Icon(Icons.storefront, size: 12, color: Color(0xFFC2410C)),
                                    const SizedBox(width: 4),
                                    Text('Penjual Marketplace', style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Color(0xFFC2410C), fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ]
                          ],
                        )
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text('Edit Profil', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(color: AppColors.divider),
              ),
              // User Details Grid / List
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Email', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textHint)),
                        const SizedBox(height: 2),
                        Text(user.email, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Nomor Telepon', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textHint)),
                        const SizedBox(height: 2),
                        Text(user.phone ?? '-', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Alamat', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textHint)),
              const SizedBox(height: 2),
              Text(user.address ?? '-', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              const Text('Terdaftar pada', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textHint)),
              const SizedBox(height: 2),
              Text(joinDate, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        // Avatar
        Positioned(
          top: 35,
          left: 32,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              image: user.profilePicture != null
                  ? DecorationImage(image: NetworkImage(user.profilePicture!), fit: BoxFit.cover)
                  : null,
            ),
            child: user.profilePicture == null
                ? Center(
                    child: Text(
                      user.initials,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildRolesSection(BuildContext context, AuthProvider auth) {
    final user = auth.user!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sync_alt_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text('Kelola Peran Akun', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Satu akun dapat memiliki beberapa peran sekaligus. Daftarkan diri Anda untuk membuka akses fitur tambahan.',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          // Marketplace Card
          _buildRoleCard(
            context,
            icon: Icons.storefront_rounded,
            iconBg: const Color(0xFFFFF7ED),
            iconColor: const Color(0xFFEA580C),
            title: 'Penjual Marketplace',
            desc: 'Jual barang bekas mahasiswa',
            status: user.isApprovedSeller ? 'Aktif' : (user.isPendingSeller ? 'Menunggu' : 'Belum terdaftar'),
            statusColor: user.isApprovedSeller ? Colors.green : (user.isPendingSeller ? Colors.orange : AppColors.textHint),
            buttonLabel: user.isApprovedSeller ? 'Dashboard Penjual' : (user.isPendingSeller ? 'Menunggu Persetujuan' : '+ Daftar Sekarang'),
            buttonColor: user.isApprovedSeller ? const Color(0xFFEA580C) : (user.isPendingSeller ? Colors.orange : Colors.white),
            buttonTextColor: user.isApprovedSeller || user.isPendingSeller ? Colors.white : AppColors.primary,
            onTap: () {
              if (user.isApprovedSeller) {
                auth.updateUserLocal(user.copyWith(isSellerModeActive: true));
                Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
              } else if (user.isNotRegisteredSeller) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BecomeProviderMarketplaceScreen())).then((_) {
                  if (context.mounted) context.read<AuthProvider>().refreshUser();
                });
              }
            },
          ),
          const SizedBox(height: 12),
          // Event Card
          _buildRoleCard(
            context,
            icon: Icons.event_available_rounded,
            iconBg: const Color(0xFFFAF5FF),
            iconColor: const Color(0xFF9333EA),
            title: 'Penjual Event',
            desc: 'Selenggarakan & jual tiket event',
            status: 'Segera Hadir',
            statusColor: AppColors.textHint,
            buttonLabel: 'Segera Hadir',
            buttonColor: AppColors.background,
            buttonTextColor: AppColors.textHint,
            onTap: () => _soon(context, 'Pendaftaran Penjual Event'),
          ),
          const SizedBox(height: 12),
          // Kos Card
          _buildRoleCard(
            context,
            icon: Icons.home_work_rounded,
            iconBg: const Color(0xFFECFDF5),
            iconColor: const Color(0xFF059669),
            title: 'Penyedia Kos-Kosan',
            desc: 'Sewakan hunian untuk mahasiswa',
            status: 'Segera Hadir',
            statusColor: AppColors.textHint,
            buttonLabel: 'Segera Hadir',
            buttonColor: AppColors.background,
            buttonTextColor: AppColors.textHint,
            onTap: () => _soon(context, 'Pendaftaran Penyedia Hunian'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String desc,
    required String status,
    required Color statusColor,
    required String buttonLabel,
    required Color buttonColor,
    required Color buttonTextColor,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(desc, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Row(
                children: [
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(status, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: onTap,
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: buttonColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: buttonTextColor == Colors.white
                          ? buttonColor
                          : buttonTextColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      buttonLabel,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: buttonTextColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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

  Widget _menuList(BuildContext context, AuthProvider auth) {
    return Container(
      color: AppColors.white,
      child: Column(
        children: [
          _sectionLabel('Aktivitas'),
          _item(context,
              icon: Icons.receipt_long_outlined,
              label: 'Riwayat',
              desc: 'Hunian, acara, dan barang yang pernah dipesan',
              iconBg: AppColors.primaryLight,
              iconColor: AppColors.primary,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RiwayatScreen()),
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
          _sectionLabel('Akun & Keamanan'),
          _item(context,
              icon: Icons.person_outline_rounded,
              label: 'Edit Profil',
              desc: 'Ubah informasi personal',
              iconBg: AppColors.primaryLight,
              iconColor: AppColors.primary, onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ).then((_) {
              if (context.mounted) auth.refreshUser();
            });
          }),
          _dividerFull(),
          _item(context,
              icon: Icons.location_on_outlined,
              label: 'Alamat Transaksi Barang Saya',
              desc: 'Kelola daftar alamat pengiriman',
              iconBg: AppColors.marketLight,
              iconColor: AppColors.market, onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddressListScreen()),
            );
          }),
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
