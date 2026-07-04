import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/marketplace_provider.dart';
import '../models/marketplace_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../bookmark/providers/bookmark_provider.dart';
import '../providers/cart_provider.dart';
import 'checkout_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  MarketplaceProductModel? _product;
  bool _isLoading = true;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p =
        await context.read<MarketplaceProvider>().fetchDetail(widget.productId);
    if (mounted) {
      setState(() {
        _product = p;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: const Center(
            child: CircularProgressIndicator(color: AppColors.market)),
      );
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Produk')),
        body: const Center(child: Text('Produk tidak ditemukan')),
      );
    }

    final product = _product!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // App bar dengan galeri foto
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2))
                  ],
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.black87, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Consumer<BookmarkProvider>(
                builder: (context, bookmarkProv, _) {
                  final isBookmarked = bookmarkProv.isBookmarked(
                      'MarketplaceProduct', product.id);
                  return IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2))
                        ],
                      ),
                      child: Icon(
                        isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color:
                            isBookmarked ? AppColors.market : Colors.grey[400],
                        size: 20,
                      ),
                    ),
                    onPressed: () =>
                        bookmarkProv.toggle('MarketplaceProduct', product.id),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    itemCount:
                        product.images.isNotEmpty ? product.images.length : 1,
                    onPageChanged: (i) =>
                        setState(() => _currentImageIndex = i),
                    itemBuilder: (context, index) {
                      if (product.images.isEmpty) {
                        return Container(
                          color: AppColors.market.withOpacity(0.1),
                          child: Icon(Icons.storefront_outlined,
                              size: 60,
                              color: AppColors.market.withOpacity(0.4)),
                        );
                      }
                      return EduImage(
                        path: product.images[index],
                        height: 300,
                        placeholderIcon: Icons.storefront_outlined,
                        placeholderColor: AppColors.marketLight,
                        iconColor: AppColors.market,
                      );
                    },
                  ),
                  // Dot indicators
                  if (product.images.length > 1)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                            product.images.length,
                            (i) =>
                                _DotIndicator(active: i == _currentImageIndex)),
                      ),
                    ),
                  // Kondisi badge
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: product.condition == 'new'
                            ? Colors.green.shade600
                            : Colors.orange.shade600,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.conditionLabel,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Konten
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Info utama
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Builder(
                            builder: (ctx) {
                              final userId = ctx.read<AuthProvider>().user?.id;
                              if (userId == null ||
                                  product.seller.id != userId) {
                                return const SizedBox.shrink();
                              }
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.market,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.storefront_rounded,
                                        size: 12, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text(
                                      'Produk Anda',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          if (product.averageRating > 0)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star,
                                    color: Colors.amber, size: 16),
                                const SizedBox(width: 2),
                                Text(
                                  product.averageRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppHelpers.formatPrice(product.price),
                        style: TextStyle(
                          color: AppColors.market,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            'Stok: ${product.stockQuantity}',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: product.isAvailable
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.isAvailable ? 'Tersedia' : 'Habis',
                              style: TextStyle(
                                fontSize: 12,
                                color: product.isAvailable
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Penjual
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.market.withOpacity(0.1),
                        child: Text(
                          product.seller.name.isNotEmpty
                              ? product.seller.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                              color: AppColors.market,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.seller.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            Text(
                              'Penjual',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                      if (product.seller.phone != null)
                        GestureDetector(
                          onTap: () => AppHelpers.openWhatsApp(
                              context,
                              product.seller.phone!,
                              'Halo, saya tertarik dengan produk "${product.name}"'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.chat_outlined,
                                    size: 14, color: Colors.green),
                                SizedBox(width: 4),
                                Text('Chat',
                                    style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Deskripsi
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Deskripsi Produk',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        product.description,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey[700], height: 1.6),
                      ),
                      if (product.conditionNotes != null &&
                          product.conditionNotes!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text('Catatan Kondisi',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text(
                          product.conditionNotes!,
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              height: 1.5),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 100), // ruang untuk bottom bar
              ],
            ),
          ),
        ],
      ),

      // Tombol beli dan keranjang
      bottomNavigationBar: product.isAvailable
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    )
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Kalkulasi lebar aman tanpa menggunakan Expanded
                    // Lebar OutlinedButton sekitar 50, spacing 12.
                    final available = constraints.maxWidth;
                    final isInfinite = available == double.infinity;
                    final buttonWidth = isInfinite ? 250.0 : (available - 50 - 12);

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () {
                              context.read<CartProvider>().addItem(product);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        '${product.name} ditambahkan ke keranjang')),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              side: const BorderSide(color: AppColors.market),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Icon(Icons.add_shopping_cart,
                                color: AppColors.market),
                          ),
                        ),
                        SizedBox(
                          width: buttonWidth > 0 ? buttonWidth : 200,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CheckoutScreen(
                                      product: product, quantity: 1),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.market,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text(
                              'Beli Sekarang',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            )
          : null,
    );
  }
}

class _DotIndicator extends StatelessWidget {
  final bool active;

  const _DotIndicator({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: active ? 18 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white54,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
