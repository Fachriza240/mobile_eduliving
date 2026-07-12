import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../models/marketplace_model.dart';
import '../providers/marketplace_provider.dart';
import '../../profile/models/address_model.dart';
import '../../profile/providers/address_provider.dart';
import '../../profile/screens/address/address_list_screen.dart';
import 'transaction_detail_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final MarketplaceProductModel product;
  final int quantity;

  const CheckoutScreen({
    super.key,
    required this.product,
    required this.quantity,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();

  late int _quantity;
  String _pickupMethod = 'pickup';
  bool _isLoading = false;
  AddressModel? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _quantity = widget.quantity;
    
    final validMethods = widget.product.pickupMethods.where((m) => m != 'cod').toList();
    if (validMethods.isNotEmpty) {
      _pickupMethod = validMethods.first;
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prov = context.read<AddressProvider>();
      if (prov.addresses.isEmpty) {
        await prov.fetchAddresses();
      }
      if (mounted) {
        setState(() {
          _selectedAddress = prov.defaultAddress;
        });
      }
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih alamat pengiriman!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final res = await context.read<MarketplaceTransactionProvider>().buyProduct(
        widget.product.id,
        {
          'quantity': _quantity,
          'buyer_name': _selectedAddress!.recipientName,
          'buyer_phone': _selectedAddress!.phone,
          'buyer_address': _selectedAddress!.address, 
          'pickup_method': _pickupMethod,
          'pickup_notes': _notesCtrl.text,
          'payment_method': 'pending', // Will be chosen in TransactionDetailScreen
        }
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesanan berhasil dibuat!'), backgroundColor: Colors.green),
      );
      
      final transactionId = res['data']['id']; // assuming 'data' contains the transaction info
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TransactionDetailScreen(transactionId: transactionId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('ApiException: ', '')), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _incrementQuantity() {
    if (_quantity < widget.product.stockQuantity) {
      setState(() {
        _quantity++;
      });
    }
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final total = widget.product.price * _quantity;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const EduAppBar(title: 'Beli Produk'),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ADDRESS SECTION (Ala Shopee)
                if (_pickupMethod == 'delivery') ...[
                  InkWell(
                  onTap: () async {
                    final selected = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddressListScreen(
                          isSelecting: true,
                          selectedAddress: _selectedAddress,
                        ),
                      ),
                    );
                    if (selected != null && selected is AddressModel) {
                      setState(() => _selectedAddress = selected);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: AppColors.market, size: 20),
                            const SizedBox(width: 8),
                            const Text('Alamat Pengiriman', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14)),
                            const Spacer(),
                            const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_selectedAddress == null)
                          const Text('Belum ada alamat terpilih. Ketuk untuk memilih.', style: TextStyle(fontFamily: 'Poppins', color: AppColors.error, fontSize: 13))
                        else ...[
                          Row(
                            children: [
                              Text(_selectedAddress!.recipientName, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(width: 8),
                              Text('(+62) ${_selectedAddress!.phone}', style: const TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(_selectedAddress!.address, style: const TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
                        ]
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ],

                // Product Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: widget.product.firstImage.isNotEmpty
                            ? EduImage(path: widget.product.firstImage, width: 80, height: 80, borderRadius: 0)
                            : Container(width: 80, height: 80, color: Colors.grey[200]),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.product.name, 
                                style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15)),
                            const SizedBox(height: 4),
                            Text(widget.product.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Harga:', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textHint)),
                                    Text(formatter.format(widget.product.price), style: const TextStyle(fontFamily: 'Poppins', color: AppColors.market, fontWeight: FontWeight.w700, fontSize: 14)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Stok:', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textHint)),
                                    Text('${widget.product.stockQuantity} tersedia', style: const TextStyle(fontFamily: 'Poppins', color: AppColors.market, fontWeight: FontWeight.w600, fontSize: 13)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Divider(height: 1),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('Penjual: ', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textHint)),
                                Text(widget.product.seller.name, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Jumlah Selector
                const Text('Jumlah *', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: _decrementQuantity,
                            icon: const Icon(Icons.remove_circle_outline, color: AppColors.market),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 16),
                          Text('$_quantity', style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 16),
                          IconButton(
                            onPressed: _incrementQuantity,
                            icon: const Icon(Icons.add_circle_outline, color: AppColors.market),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      Text('Maks: ${widget.product.stockQuantity}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textHint)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Informasi Pembeli
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline, color: Colors.blue, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: const Text(
                                'Metode pembayaran dipilih di langkah berikutnya. Tersedia transfer bank, E-Wallet, dan lainnya.',
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.blue, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Metode Pengambilan
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_shipping_outlined, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          const Text('Metode Pengambilan *', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15, color: Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('Penjual hanya menyediakan metode berikut:', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      
                      Column(
                        children: () {
                          var methods = widget.product.pickupMethods.where((m) => m != 'cod').toList();
                          if (methods.isEmpty) methods = ['pickup'];
                          return methods;
                        }().map((method) {
                          String title = '';
                          String desc = '';
                          IconData icon = Icons.local_shipping;
                          Color themeColor = Colors.grey;
                          
                          if (method == 'cod') {
                            title = 'COD (Bayar di Tempat)';
                            desc = 'Pembeli bertemu dengan penjual, bayar langsung saat menerima barang.';
                            icon = Icons.money_outlined;
                            themeColor = Colors.green;
                          } else if (method == 'delivery') {
                            title = 'Diantar Seller';
                            desc = 'Penjual mengantar barang ke alamat pembeli. Pembeli transfer terlebih dahulu.';
                            icon = Icons.motorcycle_outlined;
                            themeColor = Colors.blue;
                          } else {
                            title = 'Ambil Sendiri';
                            desc = 'Pembeli datang langsung ke lokasi penjual untuk mengambil barang.';
                            icon = Icons.directions_walk;
                            themeColor = Colors.orange;
                          }

                          final isSelected = _pickupMethod == method;
                          
                          return GestureDetector(
                            onTap: () => setState(() => _pickupMethod = method),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12.0),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected ? themeColor.withValues(alpha: 0.05) : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? themeColor : AppColors.border,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Radio<String>(
                                    value: method,
                                    groupValue: _pickupMethod,
                                    onChanged: (val) {
                                      if (val != null) setState(() => _pickupMethod = val);
                                    },
                                    activeColor: themeColor,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(icon, color: isSelected ? themeColor : AppColors.textPrimary, size: 16),
                                            const SizedBox(width: 6),
                                            Text(title, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13, color: isSelected ? themeColor : AppColors.textPrimary)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(desc, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Text('Catatan (Opsional)', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      _inputField('Catatan tambahan untuk penjual...', _notesCtrl, maxLines: 3, labelFloating: false),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),

                // Ringkasan
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.receipt_long_outlined, color: AppColors.textPrimary, size: 20),
                          const SizedBox(width: 8),
                          const Text('Ringkasan', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Harga Satuan', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary)),
                          Text(formatter.format(widget.product.price), style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Jumlah', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary)),
                          Text('$_quantity', style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: AppColors.divider),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total', style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          Text(formatter.format(total), style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.green)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.market,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      disabledBackgroundColor: AppColors.market.withOpacity(0.5),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Buat Pesanan', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Kembali', style: TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField(String label, TextEditingController ctrl, {int maxLines = 1, TextInputType keyboard = TextInputType.text, bool required = false, bool labelFloating = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelFloating) ...[
          Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboard,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
          validator: required ? (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null : null,
          decoration: InputDecoration(
            hintText: labelFloating ? null : label,
            hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textHint),
            isDense: true,
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
          ),
        ),
      ],
    );
  }
}
