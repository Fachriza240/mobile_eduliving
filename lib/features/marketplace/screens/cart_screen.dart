import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../providers/cart_provider.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
        
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: const Text('Keranjang Belanja', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0.5,
            actions: [
              IconButton(
                onPressed: () {
                  context.read<CartProvider>().clearCart();
                },
                icon: const Icon(Icons.remove_shopping_cart, color: Colors.red),
                tooltip: 'Kosongkan Keranjang',
              ),
            ],
          ),
          bottomNavigationBar: cart.items.isEmpty 
            ? null 
            : BottomAppBar(
                color: Colors.white,
                elevation: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Belanja', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(
                          formatter.format(cart.totalPrice),
                          style: TextStyle(color: AppColors.market, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 140,
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.market),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Lanjut Belanja', style: TextStyle(color: AppColors.market)),
                      ),
                    ),
                  ],
                ),
              ),
          body: cart.items.isEmpty
              ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.market.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.shopping_cart_outlined, size: 64, color: AppColors.market),
                  ),
                  const SizedBox(height: 24),
                  const Text('Yah, keranjangmu kosong!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text('Yuk cari barang menarik di EduLiving Market.', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: 200,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.market,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Mulai Belanja', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
              // Banner Info
              Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: AppColors.market.withOpacity(0.1),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppColors.market),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Setiap produk diproses secara terpisah melalui tombol "Beli".',
                        style: TextStyle(color: AppColors.market, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    final product = item.product;
                    final subtotal = product.price * item.quantity;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: product.firstImage.isNotEmpty
                                    ? EduImage(
                                        path: product.firstImage,
                                        width: 80,
                                        height: 80,
                                        borderRadius: 0,
                                        placeholderIcon: Icons.storefront,
                                      )
                                    : Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.image, color: Colors.grey),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.category?.name ?? 'Kategori',
                                      style: TextStyle(color: AppColors.market, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      product.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      formatter.format(product.price),
                                      style: TextStyle(color: AppColors.market, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Stok: ${product.stockQuantity}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Subtotal text
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Subtotal', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                  Text(
                                    formatter.format(subtotal),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                              // Qty Control
                              Row(
                                children: [
                                  // Update Qty
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        InkWell(
                                          onTap: () => cart.updateQuantity(product.id, item.quantity - 1),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            child: Icon(Icons.remove, size: 16),
                                          ),
                                        ),
                                        Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        InkWell(
                                          onTap: () => cart.updateQuantity(product.id, item.quantity + 1),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            child: Icon(Icons.add, size: 16),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Hapus btn
                                  IconButton(
                                    onPressed: () => cart.removeItem(product.id),
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 36,
                                  child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CheckoutScreen(product: product, quantity: item.quantity),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.market,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                                  child: Text('Beli: ${product.name}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
