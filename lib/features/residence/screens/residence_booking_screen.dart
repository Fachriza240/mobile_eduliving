import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/residence_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/providers/auth_provider.dart';

class ResidenceBookingScreen extends StatefulWidget {
  final ResidenceModel residence;
  const ResidenceBookingScreen({super.key, required this.residence});

  @override
  State<ResidenceBookingScreen> createState() => _ResidenceBookingScreenState();
}

class _ResidenceBookingScreenState extends State<ResidenceBookingScreen> {
  final _api = ApiService();

  DateTime? _checkInDate;
  int _durationMonths = 1; // durasi sewa dalam bulan
  bool _isLoading = false;
  String? _error;

  // Dokumen identitas — wajib min 1 (KTP / surat keterangan dll)
  final List<File> _documents = [];
  bool _isPickingDoc = false;
  final _picker = ImagePicker();

  double get _total => widget.residence.discountedPrice * _durationMonths;

  Future<void> _pickCheckInDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      builder: (_, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.residence),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _checkInDate = picked;
        _error = null;
      });
    }
  }

  Future<void> _addDocument() async {
    setState(() => _isPickingDoc = true);
    try {
      // Tampilkan pilihan: ambil foto atau pilih file
      final choice = await showModalBottomSheet<String>(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tambah Dokumen',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: AppColors.residence),
                title: const Text('Foto KTP / Dokumen',
                    style: TextStyle(fontFamily: 'Poppins')),
                onTap: () => Navigator.pop(_, 'camera'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppColors.residence),
                title: const Text('Pilih dari Galeri',
                    style: TextStyle(fontFamily: 'Poppins')),
                onTap: () => Navigator.pop(_, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined,
                    color: AppColors.residence),
                title: const Text('Pilih File PDF / Gambar',
                    style: TextStyle(fontFamily: 'Poppins')),
                onTap: () => Navigator.pop(_, 'file'),
              ),
            ],
          ),
        ),
      );

      if (choice == null) return;

      if (choice == 'camera') {
        final picked = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
        );
        if (picked != null) {
          setState(() => _documents.add(File(picked.path)));
        }
      } else if (choice == 'gallery') {
        final picked = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
        );
        if (picked != null) {
          setState(() => _documents.add(File(picked.path)));
        }
      } else if (choice == 'file') {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        );
        if (result != null && result.files.single.path != null) {
          setState(() => _documents.add(File(result.files.single.path!)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal menambah dokumen: $e',
              style: const TextStyle(fontFamily: 'Poppins')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      setState(() => _isPickingDoc = false);
    }
  }

  Future<void> _submit() async {
    if (_checkInDate == null) {
      setState(() => _error = 'Pilih tanggal masuk terlebih dahulu');
      return;
    }
    if (_documents.isEmpty) {
      setState(() => _error = 'Upload minimal 1 dokumen identitas (KTP/SIM)');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Kirim sebagai multipart karena ada file dokumen
      final formData = FormData.fromMap({
        'bookable_id': widget.residence.id,
        // FIX: backend butuh 'residence' bukan 'App\\Models\\Residence'
        'bookable_type': 'residence',
        // FIX: backend butuh check_in_date (tanggal masuk)
        'check_in_date': _checkInDate!.toIso8601String().split('T').first,
        // FIX: backend butuh duration_months bukan start_date/end_date
        'duration_months': _durationMonths,
      });

      // Tambah dokumen ke form
      for (int i = 0; i < _documents.length; i++) {
        final file = _documents[i];
        final ext = file.path.split('.').last.toLowerCase();
        formData.files.add(MapEntry(
          'documents[]',
          await MultipartFile.fromFile(
            file.path,
            filename: 'doc_${i}_${DateTime.now().millisecondsSinceEpoch}.$ext',
          ),
        ));
      }

      await _api.post(ApiConstants.userBookings, formData: formData);

      if (!mounted) return;
      _showSuccess();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('ApiException: ', '');
        _isLoading = false;
      });
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.residenceSurface,
                borderRadius: BorderRadius.circular(36),
              ),
              child: const Icon(Icons.check_rounded,
                  size: 40, color: AppColors.residence),
            ),
            const SizedBox(height: 16),
            const Text('Pemesanan Dikirim!',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              'Pemesanan sedang menunggu persetujuan provider. Biasanya 1–2 hari kerja.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.residence),
            onPressed: () {
              Navigator.of(context)
                ..pop()
                ..pop()
                ..pop();
            },
            child: const Text('Lihat Booking Saya'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pesan Hunian'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(height: 3, color: AppColors.residence),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Ringkasan Hunian ─────────────
            _buildSummary(),
            const SizedBox(height: 8),

            // ── Form Detail ───────────────────
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Detail Pemesanan',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),

                  // Info pemesan read-only
                  _infoBox('Nama Pemesan', user?.name ?? '-',
                      Icons.person_outline),
                  const SizedBox(height: 10),
                  _infoBox('Email', user?.email ?? '-', Icons.email_outlined),
                  const SizedBox(height: 20),

                  // Tanggal Masuk
                  _fieldLabel('Tanggal Masuk'),
                  const SizedBox(height: 8),
                  _datePicker(
                    label: _checkInDate != null
                        ? formatDate(_checkInDate)
                        : 'Pilih tanggal masuk',
                    onTap: _pickCheckInDate,
                    selected: _checkInDate != null,
                  ),
                  const SizedBox(height: 20),

                  // Durasi Sewa
                  _fieldLabel('Durasi Sewa'),
                  const SizedBox(height: 8),
                  _buildDurationSelector(),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Upload Dokumen ────────────────
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Dokumen Identitas',
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text('Wajib min. 1 dokumen (KTP/SIM/Surat)',
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  color: AppColors.textHint)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _documents.isNotEmpty
                              ? AppColors.residenceSurface
                              : AppColors.errorLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_documents.length} file',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _documents.isNotEmpty
                                  ? AppColors.residence
                                  : AppColors.error),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Daftar dokumen yang sudah di-upload
                  if (_documents.isNotEmpty) ...[
                    ..._documents.asMap().entries.map((entry) {
                      final i = entry.key;
                      final file = entry.value;
                      final name = file.path.split('/').last;
                      final isPdf = name.toLowerCase().endsWith('.pdf');
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.residenceLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.residence.withOpacity(0.2)),
                        ),
                        child: Row(children: [
                          Icon(
                            isPdf
                                ? Icons.picture_as_pdf_outlined
                                : Icons.image_outlined,
                            color: AppColors.residence,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: AppColors.textPrimary),
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _documents.removeAt(i)),
                            child: const Icon(Icons.close,
                                color: AppColors.error, size: 18),
                          ),
                        ]),
                      );
                    }),
                    const SizedBox(height: 8),
                  ],

                  // Tombol tambah dokumen
                  OutlinedButton.icon(
                    onPressed: _isPickingDoc ? null : _addDocument,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      _documents.isEmpty
                          ? 'Tambah Dokumen'
                          : 'Tambah Dokumen Lagi',
                      style: const TextStyle(fontFamily: 'Poppins'),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.residence,
                      side: const BorderSide(color: AppColors.residence),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Ringkasan Harga ───────────────
            _buildPriceSummary(),

            // ── Error ─────────────────────────
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: AppColors.error)),
                    ),
                  ]),
                ),
              ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildDurationSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline,
                color: AppColors.residence),
            onPressed: _durationMonths > 1
                ? () => setState(() => _durationMonths--)
                : null,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '$_durationMonths Bulan',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.residence),
                ),
                Text(
                  formatRupiah(_total),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline,
                color: AppColors.residence),
            onPressed: _durationMonths < 24
                ? () => setState(() => _durationMonths++)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final r = widget.residence;
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: EduImage(
            path: r.mainImage,
            width: 76,
            height: 76,
            placeholderColor: AppColors.residenceLight,
            iconColor: AppColors.residence,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.location_on_outlined,
                    size: 11, color: AppColors.textHint),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(r.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppColors.textSecondary)),
                ),
              ]),
              const SizedBox(height: 4),
              Text(
                formatRupiah(r.discountedPrice,
                    suffix: '/${r.rentalPeriodShort}'),
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.residence),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ringkasan Harga',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _priceRow(
              'Harga sewa', formatRupiah(widget.residence.discountedPrice)),
          _priceRow('Durasi', '$_durationMonths bulan'),
          if (_checkInDate != null) ...[
            _priceRow('Tanggal masuk', formatDate(_checkInDate)),
            _priceRow(
              'Estimasi selesai',
              formatDate(DateTime(
                _checkInDate!.year,
                _checkInDate!.month + _durationMonths,
                _checkInDate!.day,
              )),
            ),
          ],
          const Divider(height: 20),
          _priceRow('Total', formatRupiah(_total),
              bold: true, color: AppColors.residence),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Pembayaran',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.textSecondary)),
                  Text(formatRupiah(_total),
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.residence)),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.residence),
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Kirim Pemesanan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBox(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Icon(icon, size: 18, color: AppColors.textHint),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: AppColors.textHint)),
            Text(value,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
          ],
        ),
      ]),
    );
  }

  Widget _datePicker({
    required String label,
    required VoidCallback? onTap,
    bool selected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.residence : AppColors.border,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_outlined,
              size: 18,
              color: selected ? AppColors.residence : AppColors.textHint),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: selected ? AppColors.textPrimary : AppColors.textHint,
                  fontWeight:
                      selected ? FontWeight.w500 : FontWeight.w400)),
        ]),
      ),
    );
  }

  Widget _fieldLabel(String t) => Text(t,
      style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary));

  Widget _priceRow(String label, String value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: bold ? 14 : 13,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                  color: bold ? AppColors.textPrimary : AppColors.textSecondary)),
          Text(value,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: bold ? 16 : 13,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  color: color ?? AppColors.textPrimary)),
        ],
      ),
    );
  }
}
