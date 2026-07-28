import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/residence_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/utils/file_helper.dart';

class ResidenceBookingScreen extends StatefulWidget {
  final ResidenceModel residence;
  const ResidenceBookingScreen({super.key, required this.residence});

  @override
  State<ResidenceBookingScreen> createState() => _ResidenceBookingScreenState();
}

class _ResidenceBookingScreenState extends State<ResidenceBookingScreen> {
  final _api = ApiService();
  final _notesCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '1');
  final _picker = ImagePicker();

  DateTime? _startDate;
  bool _termsAccepted = false;
  bool _isLoading = false;
  String? _error;

  // Dokumen
  XFile? _ktpFile;
  String? _ktpFileName;
  XFile? _kkFile;
  String? _kkFileName;

  // Pilihan durasi: bergantung pada rental_period
  bool get _isYearly => widget.residence.rentalPeriod == 'yearly';
  
  int get _durationValue {
    int val = int.tryParse(_durationCtrl.text) ?? 1;
    return val < 1 ? 1 : val; // Ensure at least 1
  }

  // Konversi ke bulan untuk dikirim ke backend
  int get _durationMonths => _isYearly ? _durationValue * 12 : _durationValue;

  @override
  void initState() {
    super.initState();
    _durationCtrl.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  DateTime? get _endDate {
    if (_startDate == null) return null;
    return DateTime(
      _startDate!.year,
      _startDate!.month + _durationMonths,
      _startDate!.day,
    );
  }

  // Harga: untuk tahunan total = harga/tahun × durasi_tahun
  //        untuk bulanan total = harga/bulan × durasi_bulan
  double get _total {
    final price = widget.residence.discountedPrice;
    return _isYearly ? price * _durationValue : price * _durationValue;
  }

  Future<void> _pickDate() async {
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
        _startDate = picked;
        _error = null;
      });
    }
  }

  Future<void> _pickDocument(bool isKtp) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        if (isKtp) {
          _ktpFile = picked;
          _ktpFileName = picked.name;
        } else {
          _kkFile = picked;
          _kkFileName = picked.name;
        }
      });
    }
  }

  Future<void> _submit() async {
    // Validasi
    if (_startDate == null) {
      setState(() => _error = 'Pilih tanggal masuk terlebih dahulu');
      return;
    }
    if (_ktpFile == null) {
      setState(() => _error = 'Upload KTP terlebih dahulu (wajib)');
      return;
    }
    if (!_termsAccepted) {
      setState(() => _error = 'Anda harus menyetujui syarat & ketentuan');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Gunakan FormData karena ada file upload
      final formData = FormData.fromMap({
        'bookable_type': 'residence',
        'bookable_id': widget.residence.id,
        'check_in_date': _startDate!.toIso8601String().split('T').first,
        'check_out_date': _endDate!.toIso8601String().split('T').first,
        'duration_months': _durationMonths,
        if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
      });

      // Tambah dokumen — backend expect documents[] array
      formData.files.add(MapEntry(
        'documents[]',
        await FileHelper.createMultipart(
          _ktpFile!,
          filename: 'ktp_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      ));
      if (_kkFile != null) {
        formData.files.add(MapEntry(
          'documents[]',
          await FileHelper.createMultipart(
            _kkFile!,
            filename: 'kk_${DateTime.now().millisecondsSinceEpoch}.jpg',
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
            const Text('Booking Terkirim!',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              'Booking sedang menunggu persetujuan provider. Biasanya 1–2 hari kerja.',
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.residence),
              onPressed: () => Navigator.of(context)
                ..pop()
                ..pop()
                ..pop(),
              child: const Text('Lihat Booking Saya'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.residence;

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
            // ── Hunian yang Dipilih ──────────────
            _buildHunianHeader(r),
            const SizedBox(height: 8),

            // ── Detail Booking ───────────────────
            _buildSection(
              title: 'Detail Booking',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tanggal masuk
                  _fieldLabel('Tanggal Masuk *'),
                  const SizedBox(height: 8),
                  _datePicker(
                    label: _startDate != null
                        ? formatDate(_startDate)
                        : 'Pilih tanggal masuk',
                    onTap: _pickDate,
                    selected: _startDate != null,
                  ),
                  const SizedBox(height: 14),

                  // Durasi sewa
                  _fieldLabel('Durasi Sewa *'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _durationCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: AppColors.white,
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
                        borderSide: const BorderSide(
                            color: AppColors.residence, width: 1.5),
                      ),
                      suffixText: _isYearly ? 'Tahun' : 'Bulan',
                      suffixStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: AppColors.textSecondary),
                    ),
                  ),

                  // Tanggal keluar (auto)
                  if (_startDate != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.residenceLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        const Icon(Icons.calendar_month_outlined,
                            size: 16, color: AppColors.residence),
                        const SizedBox(width: 8),
                        Text(
                          'Tanggal Keluar: ${formatDate(_endDate)}',
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: AppColors.residence,
                              fontWeight: FontWeight.w500),
                        ),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 14),
                  _fieldLabel('Catatan (opsional)'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Permintaan khusus, pertanyaan, dll...',
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              const BorderSide(color: AppColors.residence)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Upload Dokumen ───────────────────
            _buildSection(
              title: 'Upload Dokumen',
              subtitle: 'Upload dokumen yang diperlukan untuk proses booking',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _docUpload(
                    label: 'KTP *',
                    fileName: _ktpFileName,
                    onTap: () => _pickDocument(true),
                    onRemove: () => setState(() {
                      _ktpFile = null;
                      _ktpFileName = null;
                    }),
                  ),
                  const SizedBox(height: 12),
                  _docUpload(
                    label: 'Kartu Keluarga (opsional)',
                    fileName: _kkFileName,
                    onTap: () => _pickDocument(false),
                    onRemove: () => setState(() {
                      _kkFile = null;
                      _kkFileName = null;
                    }),
                  ),
                  const SizedBox(height: 6),
                  const Text('Format: JPG, PNG, PDF · Maks. 2MB',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppColors.textHint)),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Ringkasan Harga ──────────────────
            _buildPriceSummary(r),
            const SizedBox(height: 8),

            // ── Info ─────────────────────────────
            _buildInfoBox(),
            const SizedBox(height: 8),

            // ── S&K + Error ──────────────────────
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () =>
                        setState(() => _termsAccepted = !_termsAccepted),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _termsAccepted,
                          onChanged: (v) => setState(() => _termsAccepted = v!),
                          activeColor: AppColors.residence,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Saya menyetujui Syarat & Ketentuan dan Kebijakan Privasi EduLiving',
                            style:
                                TextStyle(fontFamily: 'Poppins', fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(10)),
                      child: Row(children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(_error!,
                                style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: AppColors.error))),
                      ]),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHunianHeader(ResidenceModel r) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hunian yang Dipilih',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(children: [
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
                                color: AppColors.textSecondary))),
                  ]),
                  const SizedBox(height: 4),
                  if (r.hasDiscount)
                    Text(formatRupiah(r.price),
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: AppColors.textHint,
                            decoration: TextDecoration.lineThrough)),
                  Text(
                    formatRupiah(r.discountedPrice,
                        suffix: '/${r.rentalPeriodShort}'),
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.residence),
                  ),
                ],
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildPriceSummary(ResidenceModel r) {
    final String periodLabel = _isYearly ? 'Tahun' : 'Bulan';
    final String priceLabel = _isYearly ? 'Harga per Tahun' : 'Harga per Bulan';
    final String discountedLabel =
        _isYearly ? 'Harga per Tahun (setelah diskon)' : 'Harga per Bulan (setelah diskon)';

    return _buildSection(
      title: 'Ringkasan',
      child: Column(
        children: [
          _priceRow(priceLabel, formatRupiah(r.price)),
          if (r.hasDiscount) ...[
            _priceRow(
              'Diskon',
              r.discountType == 'percentage'
                  ? '-${r.discountValue?.toStringAsFixed(0)}%'
                  : '-${formatRupiah(r.discountValue ?? 0)}',
              color: AppColors.activity,
            ),
            _priceRow(discountedLabel,
                formatRupiah(r.discountedPrice)),
          ],
          _priceRow('Durasi', '$_durationValue $periodLabel'),
          const Divider(height: 16),
          _priceRow('Total', formatRupiah(_total),
              bold: true, color: AppColors.residence),
        ],
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.infoLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.info_outline, size: 16, color: AppColors.info),
              const SizedBox(width: 6),
              const Text('Informasi Penting',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.info)),
            ]),
            const SizedBox(height: 8),
            ...[
              '• Booking diproses dalam 1×24 jam',
              '• Pembayaran dilakukan setelah booking disetujui',
              '• Batalkan booking maks. 24 jam sebelum check-in',
            ].map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(s,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.textSecondary)),
                )),
          ],
        ),
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
            if (_startDate != null)
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
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.residence,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor:
                      AppColors.residence.withValues(alpha: 0.5),
                ),
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_outlined, size: 18),
                label: Text(_isLoading ? 'Memproses...' : 'Buat Booking',
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────

  Widget _buildSection(
      {required String title, String? subtitle, required Widget child}) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _datePicker(
      {required String label,
      required VoidCallback? onTap,
      bool selected = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? AppColors.residence : AppColors.border,
              width: selected ? 1.8 : 1),
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
                  fontWeight: selected ? FontWeight.w500 : FontWeight.w400)),
        ]),
      ),
    );
  }

  Widget _docUpload({
    required String label,
    required String? fileName,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    final hasFile = fileName != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: hasFile ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: hasFile ? AppColors.residenceLight : Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: hasFile ? AppColors.residence : AppColors.border,
                  width: hasFile ? 1.5 : 1),
            ),
            child: Row(children: [
              Icon(
                  hasFile
                      ? Icons.description_outlined
                      : Icons.upload_file_outlined,
                  size: 20,
                  color: hasFile ? AppColors.residence : AppColors.textHint),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasFile ? fileName : 'Pilih file...',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color:
                          hasFile ? AppColors.residence : AppColors.textHint),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasFile)
                GestureDetector(
                  onTap: onRemove,
                  child:
                      const Icon(Icons.close, size: 18, color: AppColors.error),
                )
              else
                const Text('Pilih File',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppColors.residence,
                        fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ],
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
                  color:
                      bold ? AppColors.textPrimary : AppColors.textSecondary)),
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
