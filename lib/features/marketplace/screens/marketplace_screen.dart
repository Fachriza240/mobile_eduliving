import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/marketplace_provider.dart';
import '../models/marketplace_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_helpers.dart';
import 'product_detail_screen.dart';
import '../../../features/auth/providers/auth_provider.dart'; 

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketplaceProvider>().fetchProducts(reset: true);
    });
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      final p = context.read<MarketplaceProvider>();
      if (p.hasMore && !p.isLoadingMore) {
        p.fetchProducts();
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _FilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Barang',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/transactions'),
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Transaksi Saya',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search + filter bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onSubmitted: (v) => context
                          .read<MarketplaceProvider>()
                          .setFilter(search: v),
                      decoration: InputDecoration(
                        hintText: 'Cari produk...',
                        hintStyle:
                            TextStyle(color: Colors.grey[400], fontSize: 13),
                        prefixIcon: Icon(Icons.search,
                            size: 18, color: Colors.grey[400]),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  context
                                      .read<MarketplaceProvider>()
                                      .setFilter(search: '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _showFilterSheet,
                  child: Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: AppColors.market.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.tune, color: AppColors.market, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // Active filter chips
          Consumer<MarketplaceProvider>(
            builder: (context, p, _) {
              final hasFilter =
                  p.selectedCategoryId != null || p.selectedCondition != null;
              if (!hasFilter) return const SizedBox.shrink();
              return Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(
                  children: [
                    if (p.selectedCondition != null)
                      _FilterChip(
                        label: p.selectedCondition == 'new'
                            ? 'Barang Baru'
                            : 'Barang Bekas',
                        onRemove: () => p.setFilter(condition: null),
                      ),
                    const Spacer(),
                    GestureDetector(
                      onTap: p.clearFilter,
                      child: Text(
                        'Reset filter',
                        style: TextStyle(
                          color: AppColors.market,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Product grid
          Expanded(
            child: Consumer<MarketplaceProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.market),
                  );
                }
                if (provider.error != null) {
                  return _ErrorView(
                    message: provider.error!,
                    onRetry: () => provider.fetchProducts(reset: true),
                  );
                }
                if (provider.products.isEmpty) {
                  return _EmptyState(
                    message: provider.searchQuery.isNotEmpty
                        ? 'Produk "${provider.searchQuery}" tidak ditemukan'
                        : 'Belum ada produk tersedia',
                  );
                }

                return RefreshIndicator(
                  color: AppColors.market,
                  onRefresh: () => provider.fetchProducts(reset: true),
                  child: GridView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: provider.products.length +
                        (provider.isLoadingMore ? 2 : 0),
                    itemBuilder: (context, index) {
                      if (index >= provider.products.length) {
                        return const _ProductCardSkeleton();
                      }
                      return _ProductCard(
                        product: provider.products[index],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final MarketplaceProductModel product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(productId: product.id),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: product.firstImage.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: AppHelpers.getImageUrl(product.firstImage),
                          height: 130,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                ),
                // Kondisi badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: product.condition == 'new'
                          ? Colors.green.shade600
                          : Colors.orange.shade600,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product.conditionLabel,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              Builder(
                  builder: (ctx) {
                    final userId =
                        ctx.read<AuthProvider>().user?.id;
                    if (userId == null ||
                        product.seller.id != userId) {
                      return const SizedBox.shrink();
                    }
                    return Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.market,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.storefront_rounded,
                                size: 10, color: Colors.white),
                            SizedBox(width: 3),
                            Text(
                              'Produk Anda',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.3),
                    ),
                    const Spacer(),
                    Text(
                      AppHelpers.formatPrice(product.price),
                      style: TextStyle(
                        color: AppColors.market,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (product.averageRating > 0) ...[
                          const Icon(Icons.star, size: 11, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            product.averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          '${product.seller.name}',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[500]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 130,
      width: double.infinity,
      color: AppColors.market.withOpacity(0.1),
      child: Icon(Icons.storefront_outlined,
          color: AppColors.market.withOpacity(0.4), size: 36),
    );
  }
}

class _ProductCardSkeleton extends StatelessWidget {
  const _ProductCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
              height: 130,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              )),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Container(
                    height: 12,
                    color: Colors.grey[200],
                    margin: const EdgeInsets.only(bottom: 6)),
                Container(height: 12, width: 80, color: Colors.grey[200]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.market.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.market.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  color: AppColors.market,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14, color: AppColors.market),
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet();

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _condition;

  @override
  void initState() {
    super.initState();
    _condition = context.read<MarketplaceProvider>().selectedCondition;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filter Produk',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Kondisi Barang',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ConditionChip(
                  label: 'Semua',
                  value: null,
                  selected: _condition,
                  onTap: (v) => setState(() => _condition = v)),
              _ConditionChip(
                  label: 'Baru',
                  value: 'new',
                  selected: _condition,
                  onTap: (v) => setState(() => _condition = v)),
              _ConditionChip(
                  label: 'Seperti Baru',
                  value: 'like_new',
                  selected: _condition,
                  onTap: (v) => setState(() => _condition = v)),
              _ConditionChip(
                  label: 'Baik',
                  value: 'good',
                  selected: _condition,
                  onTap: (v) => setState(() => _condition = v)),
              _ConditionChip(
                  label: 'Cukup',
                  value: 'fair',
                  selected: _condition,
                  onTap: (v) => setState(() => _condition = v)),
              _ConditionChip(
                  label: 'Perlu Perbaikan',
                  value: 'needs_repair',
                  selected: _condition,
                  onTap: (v) => setState(() => _condition = v)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                context
                    .read<MarketplaceProvider>()
                    .setFilter(condition: _condition);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.market,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Terapkan Filter',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConditionChip extends StatelessWidget {
  final String label;
  final String? value;
  final String? selected;
  final Function(String?) onTap;

  const _ConditionChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.market : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.market : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.market.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.storefront_outlined,
                size: 40, color: AppColors.market),
          ),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.market,
                foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}
