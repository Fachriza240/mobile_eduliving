import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/marketplace_provider.dart';
import '../models/marketplace_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../bookmark/providers/bookmark_provider.dart';

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

  void _showBuySheet() {
    if (_product == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _BuySheet(product: _product!),
    );
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

      // Tombol beli (sticky bottom)
      bottomNavigationBar: product.isAvailable
          ? Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, -3))
                ],
              ),
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _showBuySheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.market,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Beli Sekarang',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
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

// ────────────────────────────────────────────────────────────────────────────
//  FORM BELI
// ────────────────────────────────────────────────────────────────────────────

class _BuySheet extends StatefulWidget {
  final MarketplaceProductModel product;

  const _BuySheet({required this.product});

  @override
  State<_BuySheet> createState() => _BuySheetState();
}

class _BuySheetState extends State<_BuySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _pickupAddressCtrl = TextEditingController();
  final _paymentCtrl = TextEditingController();

  int _quantity = 1;
  String _pickupMethod = 'meetup';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill dari data profil user jika tersedia
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameCtrl.text = user.name;
      _phoneCtrl.text = user.phone ?? '';
      _addressCtrl.text = user.address ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    _pickupAddressCtrl.dispose();
    _paymentCtrl.dispose();
    super.dispose();
  }

  double get _total => widget.product.price * _quantity;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await context
          .read<MarketplaceTransactionProvider>()
          .buyProduct(widget.product.id, {
        'quantity': _quantity,
        'buyer_name': _nameCtrl.text,
        'buyer_phone': _phoneCtrl.text,
        'buyer_address': _addressCtrl.text,
        'pickup_method': _pickupMethod,
        'pickup_address':
            _pickupAddressCtrl.text.isNotEmpty ? _pickupAddressCtrl.text : null,
        'pickup_notes': _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
        'payment_method': _paymentCtrl.text,
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Pesanan berhasil dibuat! Hubungi penjual untuk konfirmasi.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushNamed(context, '/transactions');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Form Pembelian',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close)),
                ],
              ),

              // Ringkasan produk
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.market.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    if (widget.product.firstImage.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: EduImage(
                          path: widget.product.firstImage,
                          width: 50,
                          height: 50,
                          placeholderIcon: Icons.storefront_outlined,
                          placeholderColor: AppColors.marketLight,
                          iconColor: AppColors.market,
                        ),
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.product.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          Text(AppHelpers.formatPrice(widget.product.price),
                              style: TextStyle(
                                  color: AppColors.market,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                        ],
                      ),
                    ),
                    // Quantity picker
                    Row(
                      children: [
                        _QtyBtn(
                          icon: Icons.remove,
                          onPressed: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text('$_quantity',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                        _QtyBtn(
                          icon: Icons.add,
                          onPressed: _quantity < widget.product.stockQuantity
                              ? () => setState(() => _quantity++)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _inputField('Nama Penerima', _nameCtrl, required: true),
              const SizedBox(height: 12),
              _inputField('No. HP / WhatsApp', _phoneCtrl,
                  keyboard: TextInputType.phone, required: true),
              const SizedBox(height: 12),
              _inputField('Alamat Lengkap', _addressCtrl,
                  maxLines: 2, required: true),
              const SizedBox(height: 12),

              // Metode pengambilan
              const Text('Metode Pengambilan',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _MethodChip(
                      label: 'COD / Ketemu',
                      value: 'meetup',
                      selected: _pickupMethod,
                      onTap: (v) => setState(() => _pickupMethod = v)),
                  const SizedBox(width: 8),
                  _MethodChip(
                      label: 'Diantar',
                      value: 'delivery',
                      selected: _pickupMethod,
                      onTap: (v) => setState(() => _pickupMethod = v)),
                  const SizedBox(width: 8),
                  _MethodChip(
                      label: 'Ambil Sendiri',
                      value: 'pickup',
                      selected: _pickupMethod,
                      onTap: (v) => setState(() => _pickupMethod = v)),
                ],
              ),

              if (_pickupMethod != 'meetup') ...[
                const SizedBox(height: 12),
                _inputField(
                  _pickupMethod == 'delivery'
                      ? 'Alamat Pengiriman'
                      : 'Lokasi Pengambilan',
                  _pickupAddressCtrl,
                  maxLines: 2,
                ),
              ],

              const SizedBox(height: 12),
              _inputField(
                  'Metode Pembayaran (misal: Transfer BCA)', _paymentCtrl,
                  required: true),
              const SizedBox(height: 12),
              _inputField('Catatan (opsional)', _notesCtrl, maxLines: 2),

              const SizedBox(height: 16),

              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Pembayaran',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(
                    AppHelpers.formatPrice(_total),
                    style: TextStyle(
                        color: AppColors.market,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.market,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Beli ${AppHelpers.formatPrice(_total)}',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(
    String label,
    TextEditingController ctrl, {
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboard,
          validator: required
              ? (v) => (v == null || v.isEmpty) ? '$label wajib diisi' : null
              : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.market),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _QtyBtn({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: onPressed != null
              ? AppColors.market.withOpacity(0.12)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon,
            size: 16,
            color: onPressed != null ? AppColors.market : Colors.grey),
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final Function(String) onTap;

  const _MethodChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.market : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
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
