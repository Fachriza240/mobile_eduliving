import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../providers/provider_dashboard_provider.dart';
import '../../models/provider_models.dart';

class ProviderDashboardScreen extends StatefulWidget {
  final bool isResidence;
  const ProviderDashboardScreen({super.key, required this.isResidence});

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
    final colorLight = widget.isResidence ? AppColors.residenceLight : AppColors.activityLight;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<ProviderDashboardProvider>(
        builder: (_, prov, __) => RefreshIndicator(
          onRefresh: () => prov.loadDashboard(widget.isResidence),
          color: color,
          child: CustomScrollView(
            slivers: [
              // ── Hero AppBar ───────────────────────────
              SliverAppBar(
                expandedHeight: 160,
                pinned: true,
                automaticallyImplyLeading: false,
                backgroundColor: widget.isResidence
                    ? AppColors.primaryDark
                    : AppColors.activityDark,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHero(color),
                ),
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
                  child: _buildBody(prov.dashboard!, color, colorLight),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hero gradient ─────────────────────────────────────
  Widget _buildHero(Color color) {
    final isRes = widget.isResidence;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isRes
              ? const [Color(0xFF1E3A8A), Color(0xFF1E40AF), Color(0xFF2563EB)]
              : const [Color(0xFF14532D), Color(0xFF15803D), Color(0xFF16A34A)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isRes ? Icons.home_work_rounded : Icons.event_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                isRes ? 'Dashboard Penyedia Hunian' : 'Dashboard Penyedia Acara',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ringkasan aktivitas dan pendapatan kamu',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ProviderDashboardModel d, Color color, Color colorLight) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status banner (jika belum approved) ──────
          if (!d.isApproved) _buildStatusBanner(d.providerStatus),
          if (!d.isApproved) const SizedBox(height: 16),

          // ── Kartu Pendapatan ──────────────────────────
          _buildRevenueCard(d, color),
          const SizedBox(height: 16),

          // ── Grid Statistik ────────────────────────────
          _buildStatsGrid(d, color, colorLight),
          const SizedBox(height: 24),

          // ── Quick actions ─────────────────────────────
          _buildQuickInfo(d, color, colorLight),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(String status) {
    final isPending  = status == 'pending';
    final isRejected = status == 'rejected';

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
                      ? 'Akun kamu sedang ditinjau oleh admin. Sabar ya!'
                      : isRejected
                          ? 'Pengajuan kamu ditolak. Hubungi admin untuk info lebih lanjut.'
                          : 'Status akun tidak dikenal.',
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

  Widget _buildRevenueCard(ProviderDashboardModel d, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isResidence
              ? [AppColors.primaryDark, AppColors.primary]
              : [AppColors.activityDark, AppColors.activity],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Pendapatan',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatRupiah(d.totalRevenue),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _revItem('Booking', formatRupiah(d.bookingRevenue)),
              const SizedBox(width: 20),
              _revItem('Marketplace', formatRupiah(d.marketplaceRevenue)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _revItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            color: Colors.white60,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(ProviderDashboardModel d, Color color, Color colorLight) {
    final items = [
      _StatItem(
        label: widget.isResidence ? 'Total Hunian' : 'Total Acara',
        value: d.totalItems.toString(),
        icon: widget.isResidence ? Icons.home_work_rounded : Icons.event_rounded,
        color: color,
        colorLight: colorLight,
      ),
      _StatItem(
        label: 'Total Booking',
        value: d.totalBookings.toString(),
        icon: Icons.receipt_long_rounded,
        color: color,
        colorLight: colorLight,
      ),
      _StatItem(
        label: 'Menunggu',
        value: d.pendingBookings.toString(),
        icon: Icons.hourglass_top_rounded,
        color: AppColors.warning,
        colorLight: AppColors.warningLight,
      ),
      _StatItem(
        label: 'Bulan Ini',
        value: d.monthlyBookings.toString(),
        icon: Icons.calendar_month_rounded,
        color: AppColors.info,
        colorLight: AppColors.infoLight,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _buildStatCard(items[i]),
    );
  }

  Widget _buildStatCard(_StatItem item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: item.colorLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, color: item.color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.value,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: item.color,
                ),
              ),
              Text(
                item.label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfo(ProviderDashboardModel d, Color color, Color colorLight) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performa',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _infoRow('Disetujui', '${d.approvedBookings} booking', Icons.check_circle_outline, AppColors.success),
          const Divider(height: 20),
          _infoRow(
            'Tingkat persetujuan',
            '${d.approvalRate.toStringAsFixed(1)}%',
            Icons.thumb_up_outlined,
            color,
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
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color colorLight;

  _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.colorLight,
  });
}
