import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../providers/provider_marketplace_provider.dart';
import '../../models/provider_models.dart';

class ProviderMarketplaceOrderScreen extends StatefulWidget {
  const ProviderMarketplaceOrderScreen({super.key});

  @override
  State<ProviderMarketplaceOrderScreen> createState() =>
      _ProviderMarketplaceOrderScreenState();
}

class _ProviderMarketplaceOrderScreenState
    extends State<ProviderMarketplaceOrderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _scrollCtrl = ScrollController();

  static const _tabs = [
    {'label': 'Semua',       'status': null},
    {'label': 'Menunggu',    'status': 'pending'},
    {'label': 'Bukti Bayar', 'status': 'payment_uploaded'},
    {'label': 'Dikonfirmasi','status': 'confirmed'},
    {'label': 'Dikirim',     'status': 'shipped'},
    {'label': 'Selesai',     'status': 'completed'},
    {'label': 'Dibatalkan',  'status': 'cancelled'},
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        final status = _tabs[_tabCtrl.index]['status'];
        context.read<ProviderMarketplaceOrderProvider>().setFilter(status as String?);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderMarketplaceOrderProvider>().loadOrders(refresh: true);
    });
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent - 200) {
        context.read<ProviderMarketplaceOrderProvider>().loadOrders();
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.marketLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.receipt_long_rounded,
                  color: AppColors.market, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Pesanan Masuk',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          labelColor: AppColors.market,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.market,
          labelStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(
              fontFamily: 'Poppins', fontSize: 12),
          tabs: _tabs
              .map((t) => Tab(text: t['label'] as String))
              .toList(),
        ),
      ),
      body: Consumer<ProviderMarketplaceOrderProvider>(
        builder: (_, prov, __) {
          if (prov.isLoading) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              itemBuilder: (_, __) => const _OrderSkelCard(),
            );
          }
          if (prov.error != null && prov.orders.isEmpty) {
            return ErrorState(
              message: prov.error!,
              onRetry: () => prov.loadOrders(refresh: true),
            );
          }
          if (prov.orders.isEmpty) {
            return EmptyState(
              message: 'Tidak ada pesanan\ndi kategori ini.',
              icon: Icons.receipt_long_outlined,
              iconColor: AppColors.market,
            );
          }

          return RefreshIndicator(
            onRefresh: () => prov.loadOrders(refresh: true),
            color: AppColors.market,
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount:
                  prov.orders.length + (prov.isLoadingMore ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == prov.orders.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.market),
                    ),
                  );
                }
                final order = prov.orders[i];
                return _OrderCard(
                  order: order,
                  onTap: () => _showOrderDetail(ctx, order, prov),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showOrderDetail(
    BuildContext ctx,
    ProviderMarketplaceOrderModel order,
    ProviderMarketplaceOrderProvider prov,
  ) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _OrderDetailSheet(order: order, prov: prov),
    );
  }
}

// ── Order Card ────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final ProviderMarketplaceOrderModel order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.8),
          boxShadow: [
            BoxShadow(
                color: AppColors.shadow,
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: ID order + status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pesanan #${order.id}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                _StatusBadge(
                  status: (order.status == 'pending' && (order.paymentStatus == 'paid' || order.paymentProofUrl != null)) 
                      ? 'payment_uploaded' 
                      : order.status,
                  label: order.statusLabel,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Nama produk
            if (order.product != null)
              Row(
                children: [
                  const Icon(Icons.storefront_outlined,
                      size: 13, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.product!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 4),
            // Pembeli
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 13, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  order.buyerName,
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.textSecondary),
                ),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Total + metode pengambilan
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatRupiah(order.totalAmount),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.market,
                      ),
                    ),
                    Text(
                      '${order.quantity} item  ·  ${order.pickupMethodLabel}',
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppColors.textHint),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.touch_app_outlined,
                        size: 13, color: AppColors.textHint),
                    const SizedBox(width: 3),
                    const Text(
                      'Lihat Detail',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Order Detail Bottom Sheet ─────────────────────────────
class _OrderDetailSheet extends StatelessWidget {
  final ProviderMarketplaceOrderModel order;
  final ProviderMarketplaceOrderProvider prov;

  const _OrderDetailSheet({required this.order, required this.prov});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detail Pesanan #${order.id}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  _StatusBadge(
                      status: (order.status == 'pending' && (order.paymentStatus == 'paid' || order.paymentProofUrl != null)) 
                          ? 'payment_uploaded' 
                          : order.status,
                      label: order.statusLabel,
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  // Produk
                  if (order.product != null) ...[
                    _detailSection('Produk', [
                      _row('Nama', order.product!.name),
                      _row('Harga satuan', formatRupiah(order.unitPrice)),
                      _row('Jumlah', '${order.quantity} item'),
                      _row('Total', formatRupiah(order.totalAmount),
                          bold: true),
                    ]),
                    const SizedBox(height: 16),
                  ],

                  // Pembeli
                  _detailSection('Pembeli', [
                    _row('Nama', order.buyerName),
                    _row('Telepon', order.buyerPhone),
                    _row('Alamat', order.buyerAddress),
                  ]),
                  const SizedBox(height: 16),

                  // Pengambilan
                  _detailSection('Pengambilan', [
                    _row('Metode', order.pickupMethodLabel),
                    if (order.pickupAddress != null)
                      _row('Alamat pengiriman', order.pickupAddress!),
                    if (order.pickupNotes != null)
                      _row('Catatan', order.pickupNotes!),
                  ]),
                  const SizedBox(height: 16),

                  // Pembayaran
                  _detailSection('Pembayaran', [
                    _row('Metode', order.paymentMethodLabel),
                    _row(
                      'Status', 
                      (order.status == 'completed' || order.status == 'shipped')
                          ? 'Sudah Dibayar' 
                          : (order.pickupMethod == 'pickup' || order.pickupMethod == 'meetup' || order.pickupMethod == 'cod'
                              ? 'Bayar di Tempat'
                              : (order.paymentStatus == 'paid' ? 'Sudah Dibayar' : 'Menunggu Pembayaran')),
                      valueColor: (order.status == 'completed' || order.status == 'shipped' || order.paymentStatus == 'paid')
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    if (order.paymentProofUrl != null)
                      _row('Bukti bayar', 'Sudah diunggah ✓',
                          valueColor: AppColors.success),
                  ]),
                  const SizedBox(height: 24),

                  // Tombol aksi
                  _buildActionButtons(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final buttons = <Widget>[];

    void doAction(Future<bool> Function() action, String successMsg) async {
      Navigator.pop(context);
      final ok = await action();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? successMsg : prov.error ?? 'Gagal.'),
          backgroundColor: ok ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }

    String effectiveStatus = order.status;
    if (effectiveStatus == 'pending' && (order.paymentStatus == 'paid' || order.paymentProofUrl != null)) {
      effectiveStatus = 'payment_uploaded';
    }

    switch (effectiveStatus) {
      case 'pending':
        if (order.pickupMethod == 'cod' || order.pickupMethod == 'meetup' || order.pickupMethod == 'pickup') {
          buttons.add(_actionBtn(
            'Konfirmasi Pesanan',
            Icons.check_circle_outline,
            AppColors.success,
            () => doAction(() => prov.confirmOrder(order.id), 'Pesanan dikonfirmasi.'),
          ));
          buttons.add(const SizedBox(height: 10));
          buttons.add(_actionBtn(
            'Tolak Pesanan',
            Icons.cancel_outlined,
            AppColors.error,
            () => doAction(() => prov.rejectOrder(order.id, reason: 'Dibatalkan oleh penjual.'), 'Pesanan ditolak.'),
            outlined: true,
          ));
        }
        break;
      case 'payment_uploaded':
        buttons.add(_actionBtn(
          'Konfirmasi Pembayaran',
          Icons.check_circle_outline,
          AppColors.success,
          () => doAction(
              () => prov.confirmOrder(order.id), 'Pesanan dikonfirmasi.'),
        ));
        buttons.add(const SizedBox(height: 10));
        buttons.add(_actionBtn(
          'Tolak Pesanan',
          Icons.cancel_outlined,
          AppColors.error,
          () => doAction(
              () => prov.rejectOrder(order.id, reason: 'Dibatalkan oleh penjual.'), 'Pesanan ditolak.'),
          outlined: true,
        ));
        break;
      case 'confirmed':
        if (order.pickupMethod == 'pickup' || order.pickupMethod == 'cod' || order.pickupMethod == 'meetup') {
          buttons.add(_actionBtn(
            'Selesaikan Pesanan (Sudah Diambil/Dibayar)',
            Icons.done_all_rounded,
            AppColors.success,
            () => doAction(() => prov.completeOrder(order.id), 'Pesanan selesai.'),
          ));
        } else {
          buttons.add(_actionBtn(
            'Tandai Diproses / Dikirim',
            Icons.local_shipping_outlined,
            AppColors.market,
            () => doAction(() => prov.shipOrder(order.id), 'Pesanan dikirim.'),
          ));
        }
        break;
      case 'shipped':
      case 'in_progress':
        buttons.add(_actionBtn(
          'Selesaikan Pesanan',
          Icons.done_all_rounded,
          AppColors.success,
          () => doAction(
              () => prov.completeOrder(order.id), 'Pesanan selesai.'),
        ));
        break;
    }

    if (buttons.isEmpty) return const SizedBox.shrink();
    return Column(children: buttons);
  }

  Widget _actionBtn(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool outlined = false,
  }) {
    if (outlined) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 18, color: color),
          label: Text(label,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: Colors.white),
        label: Text(label,
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _detailSection(String title, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  Widget _row(String label, String value,
      {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppColors.textSecondary),
            ),
          ),
          const Text(':  ',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppColors.textSecondary)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight:
                    bold ? FontWeight.w700 : FontWeight.normal,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status Badge ──────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  final String label;

  const _StatusBadge({required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    Color bg;
    switch (status) {
      case 'pending':
        bg = AppColors.warningLight;
        break;
      case 'payment_uploaded':
        bg = AppColors.infoLight;
        break;
      case 'confirmed':
        bg = AppColors.successLight;
        break;
      case 'shipped':
        bg = const Color(0xFFEDE9FE);
        break;
      case 'completed':
        bg = AppColors.successLight;
        break;
      case 'cancelled':
        bg = AppColors.errorLight;
        break;
      default:
        bg = Colors.grey.shade100;
    }

    Color fg;
    switch (status) {
      case 'pending':
        fg = AppColors.warning;
        break;
      case 'payment_uploaded':
        fg = AppColors.info;
        break;
      case 'confirmed':
        fg = AppColors.success;
        break;
      case 'shipped':
        fg = const Color(0xFF7C3AED);
        break;
      case 'completed':
        fg = AppColors.success;
        break;
      case 'cancelled':
        fg = AppColors.error;
        break;
      default:
        fg = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────
class _OrderSkelCard extends StatelessWidget {
  const _OrderSkelCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBox(width: 120, height: 14),
              SkeletonBox(width: 80, height: 24, borderRadius: 20),
            ],
          ),
          const SizedBox(height: 10),
          SkeletonBox(width: 200, height: 12),
          const SizedBox(height: 6),
          SkeletonBox(width: 140, height: 12),
          const SizedBox(height: 12),
          SkeletonBox(width: 100, height: 16),
        ],
      ),
    );
  }
}
