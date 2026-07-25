import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/booking_model.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../marketplace/models/marketplace_model.dart';
import '../../marketplace/providers/marketplace_provider.dart';
import '../../marketplace/screens/transaction_detail_screen.dart';
import '../providers/booking_provider.dart';
import 'booking_detail_screen.dart';

// ─────────────────────────────────────────────────────────────
// Konfigurasi Kategori
// ─────────────────────────────────────────────────────────────
enum RiwayatKategori { hunian, acara, barang }

// alias internal
typedef _RiwayatKategori = RiwayatKategori;

extension _RiwayatKategoriExt on RiwayatKategori {
  String get label {
    switch (this) {
      case _RiwayatKategori.hunian:
        return 'Hunian';
      case _RiwayatKategori.acara:
        return 'Acara';
      case _RiwayatKategori.barang:
        return 'Barang';
    }
  }

  IconData get icon {
    switch (this) {
      case _RiwayatKategori.hunian:
        return Icons.home_work_rounded;
      case _RiwayatKategori.acara:
        return Icons.event_rounded;
      case _RiwayatKategori.barang:
        return Icons.storefront_rounded;
    }
  }

  Color get color {
    switch (this) {
      case _RiwayatKategori.hunian:
        return AppColors.residence;
      case _RiwayatKategori.acara:
        return AppColors.activity;
      case _RiwayatKategori.barang:
        return AppColors.market;
    }
  }

  Color get lightColor {
    switch (this) {
      case _RiwayatKategori.hunian:
        return AppColors.residenceLight;
      case _RiwayatKategori.acara:
        return AppColors.activityLight;
      case _RiwayatKategori.barang:
        return AppColors.marketLight;
    }
  }

}

// ─────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────
class RiwayatScreen extends StatefulWidget {
  final RiwayatKategori initialKategori;

  const RiwayatScreen({
    super.key,
    this.initialKategori = RiwayatKategori.hunian,
  });

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen>
    with TickerProviderStateMixin {
  late RiwayatKategori _kategori;
  late TabController _tabCtrl;

  // Tab status untuk Hunian & Acara
  final _bookingTabs = const [
    {'label': 'Semua', 'status': ''},
    {'label': 'Menunggu', 'status': 'pending'},
    {'label': 'Aktif', 'status': 'approved'},
    {'label': 'Selesai', 'status': 'completed'},
    {'label': 'Dibatalkan', 'status': 'cancelled'},
  ];

  // Tab status untuk Barang
  final _transaksiTabs = const [
    {'label': 'Semua', 'status': null},
    {'label': 'Menunggu', 'status': 'pending'},
    {'label': 'Dikonfirmasi', 'status': 'confirmed'},
    {'label': 'Selesai', 'status': 'completed'},
    {'label': 'Dibatalkan', 'status': 'cancelled'},
  ];

  @override
  void initState() {
    super.initState();
    _kategori = widget.initialKategori;
    // Panjang tab sesuai initialKategori
    final tabLen = _kategori == RiwayatKategori.barang
        ? _transaksiTabs.length
        : _bookingTabs.length;
    _tabCtrl = TabController(length: tabLen, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    context.read<BookingProvider>().loadBookings();
    context.read<MarketplaceTransactionProvider>().fetchTransactions();
  }

  void _switchKategori(RiwayatKategori k) {
    if (_kategori == k) return;
    // Buat controller baru SEBELUM dispose yang lama
    final newCtrl = TabController(
      length: k == RiwayatKategori.barang
          ? _transaksiTabs.length
          : _bookingTabs.length,
      vsync: this,
    );
    final oldCtrl = _tabCtrl;
    setState(() {
      _kategori = k;
      _tabCtrl = newCtrl;
    });
    // Dispose setelah frame selesai dirender — aman
    WidgetsBinding.instance.addPostFrameCallback((_) {
      oldCtrl.dispose();
    });

    // Refresh data barang ketika pindah ke tab Barang
    if (k == RiwayatKategori.barang) {
      context.read<MarketplaceTransactionProvider>().fetchTransactions();
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _kategori.color;
    final tabs =
        _kategori == _RiwayatKategori.barang ? _transaksiTabs : _bookingTabs;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Riwayat',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              // ── Kategori Chips ─────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: _RiwayatKategori.values
                      .map((k) => _buildCategoryChip(k))
                      .toList(),
                ),
              ),
              // ── Status TabBar ─────────────────────────
              TabBar(
                controller: _tabCtrl,
                isScrollable: true,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w400),
                tabs: tabs.map((t) => Tab(text: t['label'] as String)).toList(),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: tabs.map((t) => _buildTabContent(t)).toList(),
      ),
    );
  }

  Widget _buildCategoryChip(_RiwayatKategori k) {
    final isSelected = _kategori == k;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchKategori(k),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  isSelected ? Colors.white : Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                k.icon,
                size: 20,
                color: isSelected ? k.color : Colors.white,
              ),
              const SizedBox(height: 3),
              Text(
                k.label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? k.color : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(Map<String, dynamic> tabConfig) {
    if (_kategori == _RiwayatKategori.barang) {
      return _buildBarangTab(tabConfig['status'] as String?);
    } else {
      return _buildBookingTab(tabConfig['status'] as String);
    }
  }

  // ── Booking Tab (Hunian / Acara) ─────────────────────────
  Widget _buildBookingTab(String status) {
    return Consumer<BookingProvider>(
      builder: (_, prov, __) {
        if (prov.isLoading) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            itemBuilder: (_, __) => _BookingSkelCard(color: _kategori.color),
          );
        }

        if (prov.error != null) {
          return ErrorState(
            message: prov.error!,
            onRetry: () => prov.loadBookings(),
          );
        }

        // Filter berdasarkan kategori (residence / activity) dan status
        final items = prov.allBookings.where((b) {
          final matchType = _kategori == _RiwayatKategori.hunian
              ? b.isResidence
              : b.isActivity;
          final matchStatus = status.isEmpty || b.status == status;
          return matchType && matchStatus;
        }).toList();

        if (items.isEmpty) {
          return EmptyState(
            message: status.isEmpty
                ? 'Belum ada riwayat ${_kategori.label.toLowerCase()}.\nMulai eksplorasi sekarang!'
                : 'Tidak ada pemesanan dengan status ini.',
            icon: _kategori.icon,
            iconColor: _kategori.color,
          );
        }

        return RefreshIndicator(
          color: _kategori.color,
          onRefresh: () => prov.loadBookings(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (ctx, i) => _BookingCard(
              booking: items[i],
              themeColor: _kategori.color,
              themeLightColor: _kategori.lightColor,
              onTap: () async {
                final result = await Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => BookingDetailScreen(booking: items[i]),
                  ),
                );
                if (result == true) prov.loadBookings();
              },
            ),
          ),
        );
      },
    );
  }

  // ── Transaksi Barang Tab ─────────────────────────────────
  Widget _buildBarangTab(String? status) {
    return Consumer<MarketplaceTransactionProvider>(
      builder: (_, prov, __) {
        if (prov.isLoading) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            itemBuilder: (_, __) =>
                _BookingSkelCard(color: _kategori.color),
          );
        }

        if (prov.error != null) {
          return ErrorState(
            message: prov.error!,
            onRetry: () => prov.fetchTransactions(status: status),
          );
        }

        List<MarketplaceTransactionModel> items = prov.transactions;
        if (status != null) {
          items = items.where((t) => t.status == status).toList();
        }

        if (items.isEmpty) {
          return EmptyState(
            message: status == null
                ? 'Belum ada transaksi barang.\nMulai belanja di Marketplace!'
                : 'Tidak ada transaksi dengan status ini.',
            icon: Icons.storefront_outlined,
            iconColor: AppColors.market,
          );
        }

        return RefreshIndicator(
          color: AppColors.market,
          onRefresh: () => prov.fetchTransactions(status: status),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (ctx, i) => _TransaksiCard(
              tx: items[i],
              onTap: () async {
                await Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) =>
                        TransactionDetailScreen(transactionId: items[i].id),
                  ),
                );
                prov.fetchTransactions(status: status);
              },
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CARD: Booking (Hunian / Acara)
// ─────────────────────────────────────────────────────────────
class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final Color themeColor;
  final Color themeLightColor;
  final VoidCallback onTap;

  const _BookingCard({
    required this.booking,
    required this.themeColor,
    required this.themeLightColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final images = booking.bookable?['images'] as List?;
    final imgPath =
        images != null && images.isNotEmpty ? images.first.toString() : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Header ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                // Gambar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: EduImage(
                    path: imgPath,
                    width: 68,
                    height: 68,
                    placeholderIcon: booking.isResidence
                        ? Icons.home_work_outlined
                        : Icons.event_outlined,
                    placeholderColor: themeLightColor,
                    iconColor: themeColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tipe Badge
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: themeLightColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(children: [
                            Icon(
                              booking.isResidence
                                  ? Icons.home_work_outlined
                                  : Icons.event_outlined,
                              size: 11,
                              color: themeColor,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              booking.isResidence ? 'Hunian' : 'Acara',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: themeColor,
                              ),
                            ),
                          ]),
                        ),
                        if (booking.isRenewal) ...[ 
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.primary),
                            ),
                            child: const Text(
                              'Perpanjangan',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 5),
                      // Nama
                      Text(
                        booking.bookableName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Tanggal dipesan
                      Text(
                        'Dipesan ${formatDateShort(booking.createdAt)}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge.booking(booking.status),
              ]),
            ),

            Divider(height: 1, color: AppColors.divider),

            // ── Footer ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (booking.isResidence && booking.startDate != null)
                          Text(
                            '${formatDateShort(booking.startDate)} – ${formatDateShort(booking.endDate)}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        if (booking.totalPrice != null)
                          Text(
                            formatRupiah(booking.totalPrice!),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: themeColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: themeLightColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Lihat Detail',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: themeColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CARD: Transaksi Barang
// ─────────────────────────────────────────────────────────────
class _TransaksiCard extends StatelessWidget {
  final MarketplaceTransactionModel tx;
  final VoidCallback onTap;

  const _TransaksiCard({required this.tx, required this.onTap});

  Color get _statusColor {
    switch (tx.status) {
      case 'pending':
        return tx.paymentStatus == 'paid' ? Colors.blue : Colors.orange;
      case 'payment_uploaded':
        return Colors.blue;
      case 'confirmed':
        return Colors.teal;
      case 'shipped':
        return Colors.indigo;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Header ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Ikon Barang
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: AppColors.marketLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: tx.product != null && tx.product!.images.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              tx.product!.images.first,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.storefront_outlined,
                                color: AppColors.market,
                                size: 32,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.storefront_outlined,
                            color: AppColors.market,
                            size: 32,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tipe Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.marketLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.storefront_outlined,
                                size: 11, color: AppColors.market),
                            const SizedBox(width: 3),
                            const Text(
                              'Barang',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.market,
                              ),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 5),
                        // Nama Produk
                        Text(
                          tx.product?.name ?? 'Produk #${tx.id}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${tx.quantity}x • ${AppHelpers.formatDate(tx.createdAt.toString())}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tx.statusLabel,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: AppColors.divider),

            // ── Footer ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#TRX-${tx.id.toString().padLeft(4, '0')}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Row(children: [
                    Text(
                      AppHelpers.formatPrice(tx.totalAmount),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.market,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.marketLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Lihat Detail',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.market,
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SKELETON CARD
// ─────────────────────────────────────────────────────────────
class _BookingSkelCard extends StatelessWidget {
  final Color color;
  const _BookingSkelCard({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        SkeletonBox(width: 68, height: 68, borderRadius: 10),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 60, height: 18),
              const SizedBox(height: 8),
              SkeletonBox(width: double.infinity, height: 14),
              const SizedBox(height: 6),
              SkeletonBox(width: 120, height: 12),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SkeletonBox(width: 70, height: 24, borderRadius: 12),
      ]),
    );
  }
}
