import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:async';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../core/widgets/common_widgets.dart';
import '../models/marketplace_model.dart';
import '../providers/marketplace_provider.dart';

class TransactionDetailScreen extends StatefulWidget {
  final int transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  final _cancelReasonCtrl = TextEditingController();
  bool _isLoading = false;
  MarketplaceTransactionModel? _tx;

  // Payment State
  String? _selectedPaymentMethod;
  File? _paymentProofFile;
  String? _paymentProofName;
  bool _isPaymentLoading = false;
  final ImagePicker _picker = ImagePicker();

  // Timer State
  Timer? _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final tx = await context.read<MarketplaceTransactionProvider>().fetchDetail(widget.transactionId);
      if (tx != null) {
        if (mounted) setState(() => _tx = tx);
        _startTimerIfNeeded();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startTimerIfNeeded() {
    _timer?.cancel();
    if (_tx == null) return;
    if (_tx!.status == 'pending' && _tx!.paymentStatus != 'paid') {
      final deadline = _tx!.createdAt.add(const Duration(hours: 24));
      _timeLeft = deadline.difference(DateTime.now());

      if (_timeLeft.isNegative) {
        _timeLeft = Duration.zero;
        return;
      }

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _timeLeft = deadline.difference(DateTime.now());
          if (_timeLeft.isNegative) {
            _timeLeft = Duration.zero;
            timer.cancel();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _cancelReasonCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _cancelTransaction() async {
    if (_cancelReasonCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap masukkan alasan pembatalan')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<MarketplaceTransactionProvider>().cancelTransaction(
        _tx!.id, 
        _cancelReasonCtrl.text.trim()
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi berhasil dibatalkan'), backgroundColor: Colors.green),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _submitPayment() async {
    if (_selectedPaymentMethod == null) return;
    if (_paymentProofFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bukti pembayaran wajib diunggah!')),
      );
      return;
    }

    setState(() => _isPaymentLoading = true);
    try {
      await context.read<MarketplaceTransactionProvider>().uploadPaymentProof(
        _tx!.id,
        _paymentProofFile!.path,
        _selectedPaymentMethod!
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bukti pembayaran berhasil diunggah!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isPaymentLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _tx == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        appBar: EduAppBar(title: 'Detail Transaksi'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_tx == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const EduAppBar(title: 'Detail Transaksi'),
        body: const Center(child: Text('Transaksi tidak ditemukan')),
      );
    }

    final tx = _tx!;
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const EduAppBar(title: 'Detail Transaksi'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timer if pending
            if (tx.status == 'pending' && tx.paymentStatus != 'paid' && _timeLeft > Duration.zero)
              _buildTimerBanner(tx),

            if (tx.status != 'pending' || tx.paymentStatus == 'paid' || _timeLeft == Duration.zero)
              const SizedBox(height: 8),

            // Banner Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusColor(tx),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.remove_red_eye_outlined, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Detail Transaksi',
                        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      tx.statusLabel,
                      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12, color: _getStatusColor(tx)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('ID Transaksi: MP${tx.id.toString().padLeft(6, '0')}AAB', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textHint)),
            const SizedBox(height: 16),

            // Info Produk
            const Text('Informasi Produk', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tx.product != null && tx.product!.firstImage.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: EduImage(path: tx.product!.firstImage, width: 80, height: 80, borderRadius: 0),
                    )
                  else
                    Container(width: 80, height: 80, color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tx.product?.name ?? 'Produk dihapus', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Kategori', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textHint)),
                                Text(tx.product?.category?.name ?? '-', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Harga Satuan', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textHint)),
                                Text(formatter.format(tx.unitPrice), style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Jumlah', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textHint)),
                                Text('${tx.quantity}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textHint)),
                                Text(formatter.format(tx.totalAmount), style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.market)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Selesaikan Pembayaran or Paid Section
            if (tx.status != 'cancelled') ...[
              if (tx.pickupMethod == 'cod' || tx.pickupMethod == 'meetup')
                _buildCodSection(tx)
              else if (tx.paymentStatus != 'paid')
                _buildPaymentSection(tx)
              else
                _buildPaidSection(tx),
              
              const SizedBox(height: 24),
            ],

            // Info Penjual
            const Text('Informasi Penjual', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: tx.seller?.profilePicture != null
                        ? NetworkImage(tx.seller!.profilePicture!)
                        : null,
                    child: tx.seller?.profilePicture == null
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tx.seller?.name ?? '-', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 2),
                      const Text('Penjual Marketplace', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textHint)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Info Pengambilan
            const Text('Informasi Pengambilan', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 12),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Nama Penerima', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textHint)),
                            Text(tx.buyerName, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Nomor Telepon', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textHint)),
                            Text(tx.buyerPhone, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Metode Pengambilan', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textHint)),
                  Text(tx.pickupMethodLabel, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  const Text('Alamat', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textHint)),
                  Text(tx.buyerAddress, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Ringkasan Bawah
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
                  const Text('Ringkasan', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Kode Transaksi:', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textHint)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        color: Colors.grey.shade100,
                        child: Text('MP${tx.id.toString().padLeft(6, '0')}AAB', style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Status:', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textHint)),
                      Text(tx.statusLabel, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  if (tx.status != 'cancelled') ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Status Pembayaran:', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textHint)),
                        Text(
                          tx.pickupMethod == 'cod' || tx.pickupMethod == 'meetup' 
                            ? 'Bayar di Tempat'
                            : (tx.paymentStatus == 'paid' ? 'Dikonfirmasi' : 'Menunggu Pembayaran'), 
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: AppColors.divider),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700)),
                      Text(formatter.format(tx.totalAmount), style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.market)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Batalkan Transaksi
            if (tx.status == 'pending' && tx.paymentStatus != 'paid') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Batalkan Transaksi', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15, color: Colors.red)),
                    const SizedBox(height: 12),
                    const Text('Alasan Pembatalan', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textHint)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _cancelReasonCtrl,
                      maxLines: 3,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.white,
                        hintText: 'Jelaskan alasan pembatalan...',
                        hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textHint),
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.red)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _cancelTransaction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Batalkan Transaksi', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerBanner(MarketplaceTransactionModel tx) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(_timeLeft.inHours);
    final minutes = twoDigits(_timeLeft.inMinutes.remainder(60));
    final seconds = twoDigits(_timeLeft.inSeconds.remainder(60));
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              const Text('Segera Selesaikan Pembayaran!', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: Colors.orange)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Pesanan kamu sudah dibuat. Selesaikan pembayaran sebelum batas waktu habis, atau pesanan akan dibatalkan otomatis.',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Sisa waktu:  ', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.black87)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text('$hours:$minutes:$seconds', style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: Colors.orange)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(MarketplaceTransactionModel tx) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payment_outlined, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              const Text('Selesaikan Pembayaran', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Klik tombol di bawah untuk memilih metode pembayaran. Tersedia transfer bank, e-wallet, dan lainnya.',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          
          const Text('Metode Pembayaran *', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...[
            {'value': 'bank_transfer', 'label': 'Transfer Bank / Manual', 'icon': Icons.account_balance_outlined},
            {'value': 'e_wallet', 'label': 'E-Wallet', 'icon': Icons.account_balance_wallet_outlined},
          ].map((m) => GestureDetector(
            onTap: () => setState(() => _selectedPaymentMethod = m['value'] as String),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _selectedPaymentMethod == m['value'] ? Colors.green.withOpacity(0.05) : Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _selectedPaymentMethod == m['value'] ? Colors.green : AppColors.border,
                  width: _selectedPaymentMethod == m['value'] ? 1.5 : 1,
                ),
              ),
              child: Row(children: [
                Icon(m['icon'] as IconData, size: 20, color: _selectedPaymentMethod == m['value'] ? Colors.green : AppColors.textSecondary),
                const SizedBox(width: 10),
                Text(m['label'] as String, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: _selectedPaymentMethod == m['value'] ? FontWeight.w600 : FontWeight.w400, color: _selectedPaymentMethod == m['value'] ? Colors.green : AppColors.textPrimary)),
                const Spacer(),
                if (_selectedPaymentMethod == m['value']) const Icon(Icons.check_circle, color: Colors.green, size: 18),
              ]),
            ),
          )),

          const SizedBox(height: 12),
          const Text('Bukti Pembayaran *', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _paymentProofFile != null ? null : () async {
              final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
              if (picked != null) {
                setState(() {
                  _paymentProofFile = File(picked.path);
                  _paymentProofName = picked.name;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _paymentProofFile != null ? Colors.green.withOpacity(0.05) : Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _paymentProofFile != null ? Colors.green : AppColors.border),
              ),
              child: Row(children: [
                Icon(_paymentProofFile != null ? Icons.image_outlined : Icons.upload_file_outlined, size: 20, color: _paymentProofFile != null ? Colors.green : AppColors.textHint),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _paymentProofFile != null ? _paymentProofName! : 'Upload bukti bayar (JPG/PNG)',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: _paymentProofFile != null ? Colors.green : AppColors.textHint),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_paymentProofFile != null)
                  GestureDetector(
                    onTap: () => setState(() {
                      _paymentProofFile = null;
                      _paymentProofName = null;
                    }),
                    child: const Icon(Icons.close, size: 18, color: AppColors.error),
                  ),
              ]),
            ),
          ),
          
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor: Colors.green.withOpacity(0.5),
              ),
              onPressed: _isPaymentLoading || _selectedPaymentMethod == null || _paymentProofFile == null ? null : () => _submitPayment(),
              icon: _isPaymentLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.payment, size: 18),
              label: Text(_isPaymentLoading ? 'Memproses...' : 'Bayar Sekarang - ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(tx.totalAmount)}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 12, color: AppColors.textHint),
              SizedBox(width: 4),
              Text('Pembayaran diproses aman oleh sistem', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AppColors.textHint)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCodSection(MarketplaceTransactionModel tx) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.handshake_outlined, color: Colors.green, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bayar di Tempat (COD)', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: Colors.green)),
                SizedBox(height: 4),
                Text('Silakan lakukan pembayaran tunai langsung kepada penjual saat Anda menerima barang.', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary, height: 1.5)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPaidSection(MarketplaceTransactionModel tx) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              const Text('Pembayaran Dikonfirmasi', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 12),
          InfoRow(
            icon: Icons.payments_outlined,
            label: 'Metode Pembayaran',
            value: tx.paymentMethod.isNotEmpty && tx.paymentMethod != 'pending' ? tx.paymentMethod : 'Transfer Manual',
          ),
          if (tx.paymentProofUrl != null)
            const InfoRow(
              icon: Icons.image_outlined,
              label: 'Bukti Pembayaran',
              value: 'Terlampir',
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(MarketplaceTransactionModel tx) {
    if (tx.status == 'pending' && tx.paymentStatus == 'paid') {
      return Colors.blue;
    }
    switch (tx.status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'payment_uploaded': return Colors.blue;
      case 'confirmed': return Colors.teal;
      case 'shipped': return Colors.indigo;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.orange;
    }
  }
}
