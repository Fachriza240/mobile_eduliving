import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../auth/providers/auth_provider.dart';
import '../profile/screens/edit_profile_screen.dart';
import '../profile/screens/change_password_screen.dart';

/// Tab Profil versi Provider — sama seperti user tapi dengan badge role penyedia
/// dan tombol menu yang relevan untuk penyedia.
class ProviderProfileTab extends StatelessWidget {
  const ProviderProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isResidence = user?.isProviderResidence ?? false;
    final color = isResidence ? AppColors.residence : AppColors.activity;
    final colorLight = isResidence ? AppColors.residenceLight : AppColors.activityLight;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isResidence
                      ? const [Color(0xFF1E3A8A), Color(0xFF2563EB)]
                      : const [Color(0xFF14532D), Color(0xFF16A34A)],
                ),
              ),
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      user?.initials ?? 'P',
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
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isResidence ? Icons.home_work_rounded : Icons.event_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          user?.roleLabel ?? 'Provider',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Menu List ──────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Info akun
                  _MenuSection(
                    title: 'Akun',
                    children: [
                      _MenuItem(
                        icon: Icons.person_outline_rounded,
                        iconColor: color,
                        iconBg: colorLight,
                        title: 'Edit Profil',
                        onTap: () => _goToEditProfile(context),
                      ),
                      _MenuItem(
                        icon: Icons.lock_outline_rounded,
                        iconColor: color,
                        iconBg: colorLight,
                        title: 'Ubah Kata Sandi',
                        onTap: () => _goToChangePassword(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Kelola bisnis
                  _MenuSection(
                    title: isResidence ? 'Kelola Hunian' : 'Kelola Acara',
                    children: [
                      _MenuItem(
                        icon: isResidence ? Icons.home_work_outlined : Icons.event_outlined,
                        iconColor: color,
                        iconBg: colorLight,
                        title: isResidence ? 'Daftar Hunian Saya' : 'Daftar Acara Saya',
                        onTap: () => _switchTab(context, 1),
                      ),
                      _MenuItem(
                        icon: Icons.receipt_long_outlined,
                        iconColor: color,
                        iconBg: colorLight,
                        title: 'Manajemen Booking',
                        onTap: () => _switchTab(context, 2),
                      ),
                      _MenuItem(
                        icon: Icons.dashboard_outlined,
                        iconColor: color,
                        iconBg: colorLight,
                        title: 'Dashboard Statistik',
                        onTap: () => _switchTab(context, 0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bantuan
                  _MenuSection(
                    title: 'Lainnya',
                    children: [
                      _MenuItem(
                        icon: Icons.help_outline_rounded,
                        iconColor: AppColors.textSecondary,
                        iconBg: AppColors.background,
                        title: 'Bantuan & FAQ',
                        onTap: () => _soon(context),
                      ),
                      _MenuItem(
                        icon: Icons.info_outline_rounded,
                        iconColor: AppColors.textSecondary,
                        iconBg: AppColors.background,
                        title: 'Tentang EduLiving',
                        onTap: () => _soon(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Logout
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 0.8),
                    ),
                    child: _MenuItem(
                      icon: Icons.logout_rounded,
                      iconColor: AppColors.error,
                      iconBg: AppColors.errorLight,
                      title: 'Keluar',
                      titleColor: AppColors.error,
                      showDivider: false,
                      onTap: () => _confirmLogout(context),
                    ),
                  ),

                  const SizedBox(height: 32),
                  Text(
                    'EduLiving v1.0.0 — Provider',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToEditProfile(BuildContext ctx) {
    Navigator.push(
      ctx,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
  }

  void _goToChangePassword(BuildContext ctx) {
    Navigator.push(
      ctx,
      MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
    );
  }

  void _soon(BuildContext ctx) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: const Text('Fitur ini segera hadir.'),
      backgroundColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _switchTab(BuildContext ctx, int idx) {
    // Kirim event ke ProviderHomeScreen melalui Navigator pop atau callback
    // Untuk sekarang gunakan snackbar placeholder
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text('Buka tab ${['Dashboard', 'Listing', 'Booking'][idx]}'),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _confirmLogout(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar?',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: const Text('Kamu akan keluar dari akun penyedia ini.',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await ctx.read<AuthProvider>().logout();
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

// ── Menu Section ──────────────────────────────────────────
class _MenuSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _MenuSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textHint,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 0.8),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

// ── Menu Item ─────────────────────────────────────────────
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final Color? titleColor;
  final VoidCallback onTap;
  final bool showDivider;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.onTap,
    this.titleColor,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: titleColor ?? AppColors.textPrimary,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 56),
      ],
    );
  }
}
