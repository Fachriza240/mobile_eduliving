import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../providers/provider_dashboard_provider.dart';
import '../../models/provider_models.dart';
import '../../../auth/providers/auth_provider.dart';

class ProviderDashboardScreen extends StatefulWidget {
  final bool isResidence;
  final void Function(int)? onSwitchTab;

  const ProviderDashboardScreen({
    super.key,
    required this.isResidence,
    this.onSwitchTab,
  });

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderDashboardProvider>().loadDashboard(widget.isResidence);
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isResidence ? AppColors.residence : AppColors.activity;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<ProviderDashboardProvider>(
        builder: (_, prov, __) => RefreshIndicator(
          onRefresh: () => prov.loadDashboard(widget.isResidence),
          color: color,
          child: CustomScrollView(
            slivers: [
              // ── AppBar ───────────────────────────────
              SliverAppBar(
                pinned: true,
                automaticallyImplyLeading: false,
                backgroundColor: widget.isResidence
                    ? AppColors.primaryDark
                    : AppColors.activityDark,
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        widget.isResidence ? Icons.home_work_rounded : Icons.event_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.isResidence ? 'Dashboard Hunian' : 'Dashboard Acara',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                actions: [
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/notifications'),
                    child: Container(
                      margin: const EdgeInsets.only(right: 16),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              radius: 4,
                              backgroundColor: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              if (prov.isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (prov.error != null)
                SliverFillRemaining(
                  child: ErrorState(
                    message: prov.error!,
                    onRetry: () => prov.loadDashboard(widget.isResidence),
                  ),
                )
              else if (prov.dashboard != null)
                SliverToBoxAdapter(
                  child: _buildBody(prov.dashboard!, color),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ProviderDashboardModel d, Color color) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status banner ──────────────────────────
          if (!d.isApproved) ...[
            _buildStatusBanner(d.providerStatus),
            const SizedBox(height: 16),
          ],

          // ── Selamat datang ─────────────────────────
          _buildWelcomeCard(d, color),
          const SizedBox(height: 16),

          // ── 3 Kartu Performa ───────────────────────
          _buildPerfCards(d, color),
          const SizedBox(height: 16),

          // ── Aksi Cepat ─────────────────────────────
          _buildQuickActions(color),
          const SizedBox(height: 16),

          // ── Statistik Booking ──────────────────────
          _buildBookingStats(d, color),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Welcome card ────────────────────────────────────────
  Widget _buildWelcomeCard(ProviderDashboardModel d, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Builder(
        builder: (context) {
          final userName = context.read<AuthProvider>().user?.name ?? '';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName.isNotEmpty ? 'Selamat datang, $userName!' : 'Selamat datang!',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── 3 Kartu Performa (mirip web) ────────────────────────
  Widget _buildPerfCards(ProviderDashboardModel d, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _perfCard(
                value: d.monthlyBookings.toString(),
                label: 'Booking Bulan Ini',
                bgFrom: const Color(0xFFEFF6FF),
                bgTo: const Color(0xFFDBEAFE),
                textColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _perfCard(
                value: formatRupiah(d.bookingRevenue),
                label: 'Pendapatan Bulan Ini',
                bgFrom: const Color(0xFFF0FDF4),
                bgTo: const Color(0xFFDCFCE7),
                textColor: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _perfCard(
          value: '${d.approvalRate.toStringAsFixed(1)}%',
          label: 'Tingkat Persetujuan',
          bgFrom: const Color(0xFFFAF5FF),
          bgTo: const Color(0xFFEDE9FE),
          textColor: const Color(0xFF7C3AED),
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _perfCard({
    required String value,
    required String label,
    required Color bgFrom,
    required Color bgTo,
    required Color textColor,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bgFrom, bgTo],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: fullWidth ? 28 : 22,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Aksi Cepat (mirip web) ──────────────────────────────
  Widget _buildQuickActions(Color color) {
    final isRes = widget.isResidence;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aksi Cepat',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _actionBtn(
            icon: Icons.add_rounded,
            title: isRes ? 'Tambah Hunian' : 'Tambah Acara',
            subtitle: isRes ? 'Buat hunian baru' : 'Buat acara baru',
            from: AppColors.primary,
            to: AppColors.primaryMid,
            onTap: () => _switchTab(1),
          ),
          const SizedBox(height: 10),
          _actionBtn(
            icon: Icons.receipt_long_rounded,
            title: 'Kelola Booking',
            subtitle: 'Approve/reject booking',
            from: const Color(0xFFD97706),
            to: const Color(0xFFF59E0B),
            onTap: () => _switchTab(2),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color from,
    required Color to,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [from, to]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.7), size: 20),
          ],
        ),
      ),
    );
  }

  // ── Statistik Booking ───────────────────────────────────
  Widget _buildBookingStats(ProviderDashboardModel d, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistik Booking',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _statTile(
                label: widget.isResidence ? 'Total Hunian' : 'Total Acara',
                value: d.totalItems.toString(),
                icon: widget.isResidence ? Icons.home_work_rounded : Icons.event_rounded,
                color: color,
                bg: widget.isResidence ? AppColors.residenceLight : AppColors.activityLight,
              )),
              const SizedBox(width: 12),
              Expanded(child: _statTile(
                label: 'Total Booking',
                value: d.totalBookings.toString(),
                icon: Icons.receipt_long_rounded,
                color: color,
                bg: widget.isResidence ? AppColors.residenceLight : AppColors.activityLight,
              )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statTile(
                label: 'Menunggu',
                value: d.pendingBookings.toString(),
                icon: Icons.hourglass_top_rounded,
                color: AppColors.warning,
                bg: AppColors.warningLight,
              )),
              const SizedBox(width: 12),
              Expanded(child: _statTile(
                label: 'Disetujui',
                value: d.approvedBookings.toString(),
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.success,
                bg: AppColors.successLight,
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.textSecondary,
            )),
        const Spacer(),
        Text(value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            )),
      ],
    );
  }

  // ── Status Banner ───────────────────────────────────────
  Widget _buildStatusBanner(String status) {
    final isPending = status == 'pending';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPending ? AppColors.warningLight : AppColors.errorLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPending ? AppColors.warning : AppColors.error,
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPending ? Icons.hourglass_top_rounded : Icons.cancel_rounded,
            color: isPending ? AppColors.warning : AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPending ? 'Menunggu Verifikasi' : 'Akun Ditolak',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isPending ? AppColors.warning : AppColors.error,
                  ),
                ),
                Text(
                  isPending
                      ? 'Akun kamu sedang ditinjau oleh admin.'
                      : 'Pengajuan ditolak. Hubungi admin.',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _switchTab(int idx) {
    widget.onSwitchTab?.call(idx);
  }
}