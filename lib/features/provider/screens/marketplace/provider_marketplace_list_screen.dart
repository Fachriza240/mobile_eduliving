import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../providers/provider_marketplace_provider.dart';
import '../../models/provider_models.dart';
import 'provider_marketplace_form_screen.dart';

class ProviderMarketplaceListScreen extends StatefulWidget {
  const ProviderMarketplaceListScreen({super.key});

  @override
  State<ProviderMarketplaceListScreen> createState() =>
      _ProviderMarketplaceListScreenState();
}

class _ProviderMarketplaceListScreenState
    extends State<ProviderMarketplaceListScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderMarketplaceProvider>().loadProducts(refresh: true);
    });
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent - 200) {
        context.read<ProviderMarketplaceProvider>().loadProducts();
      }
    });
  }

  @override
  void dispose() {
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.marketLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.storefront_rounded,
                  color: AppColors.market, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Kelola Produk',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.market),
            tooltip: 'Tambah Produk',
            onPressed: () => _goToForm(context),
          ),
        ],
      ),
      body: Consumer<ProviderMarketplaceProvider>(
        builder: (_, prov, __) {
          if (prov.isLoading) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              itemBuilder: (_, __) => const _ProductSkelCard(),
            );
          }
          if (prov.error != null && prov.products.isEmpty) {
            return ErrorState(
              message: prov.error!,
              onRetry: () => prov.loadProducts(refresh: true),
            );
          }
          if (prov.products.isEmpty) {
            return EmptyState(
              message: 'Belum ada produk.\nTambahkan produk pertamamu!',
              icon: Icons.storefront_outlined,
              iconColor: AppColors.market,
              action: ElevatedButton.icon(
                onPressed: () => _goToForm(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Tambah Produk'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.market,
                  minimumSize: const Size(160, 44),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => prov.loadProducts(refresh: true),
            color: AppColors.market,
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: prov.products.length + (prov.isLoadingMore ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == prov.products.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.market),
                    ),
                  );
                }
                final p = prov.products[i];
                return _ProviderProductCard(
                  product: p,
                  onEdit: () => _goToForm(context, product: p),
                  onDelete: () => _confirmDelete(context, p, prov),
                  onToggle: () => prov.toggleAvailability(p.id),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _goToForm(context),
        backgroundColor: AppColors.market,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  void _goToForm(BuildContext ctx,
      {ProviderMarketplaceProductModel? product}) {
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => ProviderMarketplaceFormScreen(product: product),
      ),
    );
  }

  void _confirmDelete(
    BuildContext ctx,
    ProviderMarketplaceProductModel p,
    ProviderMarketplaceProvider prov,
  ) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Produk?',
            style: TextStyle(
                fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Text(
          '${p.name} akan dihapus permanen.',
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await prov.deleteProduct(p.id);
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content:
                      Text(ok ? 'Produk dihapus.' : prov.error ?? 'Gagal.'),
                  backgroundColor: ok ? AppColors.success : AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ));
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

// ── Card Produk ───────────────────────────────────────────
class _ProviderProductCard extends StatelessWidget {
  final ProviderMarketplaceProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _ProviderProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
          // Gambar
          Stack(
            children: [
              EduImage(
                path: product.firstImage,
                height: 150,
                borderRadius: 14,
                placeholderIcon: Icons.storefront_outlined,
                placeholderColor: AppColors.marketLight,
                iconColor: AppColors.market,
              ),
              // Badge kondisi
              Positioned(
                top: 10,
                left: 10,
                child: _badge(
                  product.conditionLabel,
                  product.condition == 'new'
                      ? Colors.green.shade600
                      : Colors.orange.shade600,
                  Colors.white,
                ),
              ),
              // Badge status
              Positioned(
                top: 10,
                right: 10,
                child: _badge(
                  product.isAvailable ? 'Tersedia' : 'Nonaktif',
                  product.isAvailable
                      ? AppColors.success
                      : AppColors.textSecondary,
                  Colors.white,
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (product.categoryName != null) ...[
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.category_outlined,
                        size: 12, color: AppColors.textHint),
                    const SizedBox(width: 3),
                    Text(
                      product.categoryName!,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppColors.textSecondary),
                    ),
                  ]),
                ],
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatRupiah(product.price),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.market,
                            ),
                          ),
                          Text(
                            'Stok: ${product.stockQuantity}  ·  ${product.ordersCount} pesanan',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Tombol aksi
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onToggle,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: product.isAvailable
                              ? AppColors.textSecondary
                              : AppColors.success,
                          side: BorderSide(
                            color: product.isAvailable
                                ? AppColors.border
                                : AppColors.success,
                          ),
                          minimumSize: const Size(0, 38),
                        ),
                        icon: Icon(
                          product.isAvailable
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 15,
                        ),
                        label: Text(
                          product.isAvailable ? 'Nonaktifkan' : 'Aktifkan',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined,
                          color: AppColors.market),
                      tooltip: 'Edit',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.marketLight,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.error),
                      tooltip: 'Hapus',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.errorLight,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(
          label,
          style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg),
        ),
      );
}

// ── Skeleton ──────────────────────────────────────────────
class _ProductSkelCard extends StatelessWidget {
  const _ProductSkelCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: double.infinity, height: 150, borderRadius: 14),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 220, height: 16),
                  const SizedBox(height: 8),
                  SkeletonBox(width: 130, height: 13),
                  const SizedBox(height: 12),
                  SkeletonBox(width: 110, height: 18),
                  const SizedBox(height: 6),
                  SkeletonBox(width: 180, height: 12),
                ]),
          ),
        ],
      ),
    );
  }
}
