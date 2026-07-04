import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/marketplace_provider.dart';
import '../models/marketplace_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_helpers.dart';
import 'transaction_detail_screen.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    {'label': 'Semua', 'status': null},
    {'label': 'Menunggu', 'status': 'pending'},
    {'label': 'Dikonfirmasi', 'status': 'confirmed'},
    {'label': 'Selesai', 'status': 'completed'},
    {'label': 'Dibatalkan', 'status': 'cancelled'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketplaceTransactionProvider>().fetchTransactions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Transaksi Saya',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.market,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.market,
          labelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          onTap: (i) {
            final status = _tabs[i]['status'] as String?;
            context
                .read<MarketplaceTransactionProvider>()
                .fetchTransactions(status: status);
          },
          tabs: _tabs.map((t) => Tab(text: t['label'] as String)).toList(),
        ),
      ),
      body: Consumer<MarketplaceTransactionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.market),
            );
          }
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.error!,
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: provider.fetchTransactions,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.market),
                    child: const Text('Coba Lagi',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }
          if (provider.transactions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Belum ada transaksi',
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.market,
            onRefresh: provider.fetchTransactions,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: provider.transactions.length,
              itemBuilder: (context, i) =>
                  _TransactionCard(tx: provider.transactions[i]),
            ),
          );
        },
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final MarketplaceTransactionModel tx;

  const _TransactionCard({required this.tx});

  Color _statusColor(MarketplaceTransactionModel tx) {
    if (tx.status == 'pending' && tx.paymentStatus == 'paid') {
      return Colors.blue; // payment_uploaded
    }
    switch (tx.status) {
      case 'pending':
        return Colors.orange;
      case 'payment_uploaded':
        return Colors.blue;
      case 'confirmed':
        return Colors.teal;
      case 'shipped':
        return Colors.indigo;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TransactionDetailScreen(transactionId: tx.id)),
        ).then((_) {
          context.read<MarketplaceTransactionProvider>().fetchTransactions();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#TRX-${tx.id.toString().padLeft(4, '0')}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor(tx).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tx.statusLabel,
                    style: TextStyle(
                        color: _statusColor(tx),
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),

            const Divider(height: 14),

            // Produk
            if (tx.product != null) ...[
              Text(
                tx.product!.name,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${tx.quantity}x ${AppHelpers.formatPrice(tx.unitPrice)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppHelpers.formatDate(tx.createdAt.toString()),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                Text(
                  AppHelpers.formatPrice(tx.totalAmount),
                  style: TextStyle(
                    color: AppColors.market,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            // Aksi (upload bukti bayar jika pending)
            if (tx.status == 'pending' && tx.paymentStatus != 'paid') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 38,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => TransactionDetailScreen(transactionId: tx.id)),
                    ).then((_) {
                      context.read<MarketplaceTransactionProvider>().fetchTransactions();
                    });
                  },
                  icon: const Icon(Icons.upload_outlined, size: 16),
                  label: const Text('Upload Bukti Bayar',
                      style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.market,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ));
  }


}
