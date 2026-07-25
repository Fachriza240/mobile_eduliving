import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/booking_model.dart';
import '../../../core/widgets/common_widgets.dart';
import '../providers/booking_provider.dart';

class BookingRenewScreen extends StatefulWidget {
  final BookingModel booking;
  const BookingRenewScreen({super.key, required this.booking});

  @override
  State<BookingRenewScreen> createState() => _BookingRenewScreenState();
}

class _BookingRenewScreenState extends State<BookingRenewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _durationCtrl = TextEditingController(text: '1');
  
  bool _isLoading = false;
  
  // Ambil detail hunian
  Map<String, dynamic> get residence => widget.booking.bookable ?? {};
  
  // Tipe periode: 'yearly' atau 'monthly'
  String get rentalPeriod => (residence['rental_period'] ?? residence['rent_period'] ?? 'monthly').toString().toLowerCase();
  
  // Harga hunian
  double get price {
    if (residence['price'] != null) {
      return double.tryParse(residence['price'].toString()) ?? 0.0;
    }
    return 0.0;
  }
  
  // Tanggal mulai = tanggal selesai booking lama
  DateTime get startDate => widget.booking.endDate ?? DateTime.now();

  int _getDurationValue() {
    return int.tryParse(_durationCtrl.text) ?? 1;
  }

  // Hitung total harga
  double _calculateTotal() {
    return price * _getDurationValue();
  }
  
  // Hitung tanggal selesai baru
  DateTime _calculateEndDate() {
    final dur = _getDurationValue();
    final monthsToAdd = rentalPeriod == 'yearly' ? dur * 12 : dur;
    
    // Cara simple tambah bulan di Dart
    return DateTime(
      startDate.year,
      startDate.month + monthsToAdd,
      startDate.day,
      startDate.hour,
      startDate.minute,
    );
  }

  @override
  void dispose() {
    _durationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const EduAppBar(title: 'Perpanjang Sewa'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildResidenceInfo(),
            const SizedBox(height: 8),
            _buildForm(),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildResidenceInfo() {
    final images = residence['images'] as List?;
    final imgPath = images != null && images.isNotEmpty ? images.first.toString() : null;
    
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hunian yang Dipilih',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: EduImage(
                  path: imgPath,
                  width: 80,
                  height: 80,
                  placeholderIcon: Icons.home_work_outlined,
                  placeholderColor: AppColors.residenceLight,
                  iconColor: AppColors.residence,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.booking.bookableName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            residence['address']?.toString() ?? '-',
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
                    const SizedBox(height: 8),
                    Text(
                      '${formatRupiah(price)}/${rentalPeriod == 'yearly' ? 'thn' : 'bln'}',
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.residenceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.history_toggle_off, color: AppColors.residence, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sewa Aktif: ${formatDateShort(widget.booking.startDate)} – ${formatDateShort(widget.booking.endDate)}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.residence,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Detail Perpanjangan',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            
            const Text('Durasi Sewa *',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _durationCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '1',
                suffixText: rentalPeriod == 'yearly' ? 'Tahun' : 'Bulan',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
              onChanged: (val) {
                setState(() {}); // trigger rebuild untuk hitung total
              },
              validator: (val) {
                if (val == null || val.isEmpty) return 'Durasi harus diisi';
                final v = int.tryParse(val);
                if (v == null || v < 1) return 'Durasi tidak valid';
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Periode sewa baru
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.successLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.calendar_month, color: AppColors.success, size: 18),
                      SizedBox(width: 8),
                      Text('Periode Sewa Baru',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Mulai', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textSecondary)),
                      Text(formatDateWithTime(startDate), style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Berakhir', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textSecondary)),
                      Text(formatDateWithTime(_calculateEndDate()), style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Estimasi Total',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: AppColors.textSecondary)),
                Text(formatRupiah(_calculateTotal()),
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRenew,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Ajukan Perpanjangan',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _submitRenew() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final prov = context.read<BookingProvider>();
    
    // hitung total bulan yang dikirim ke backend
    final dur = _getDurationValue();
    final monthsToSend = rentalPeriod == 'yearly' ? dur * 12 : dur;
    
    final success = await prov.renewBooking(widget.booking.id, monthsToSend);
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perpanjang sewa berhasil diajukan!'),
          backgroundColor: AppColors.success,
        )
      );
      // Kembali ke screen sebelumnya dengan membawa flag true agar ter-refresh
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(prov.error ?? 'Gagal mengajukan perpanjangan'),
          backgroundColor: AppColors.error,
        )
      );
    }
    
    if (mounted) setState(() => _isLoading = false);
  }
}
