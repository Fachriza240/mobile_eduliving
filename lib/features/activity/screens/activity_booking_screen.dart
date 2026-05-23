import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/activity_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/providers/auth_provider.dart';

class ActivityBookingScreen extends StatefulWidget {
  final ActivityModel activity;
  const ActivityBookingScreen({super.key, required this.activity});

  @override
  State<ActivityBookingScreen> createState() => _ActivityBookingScreenState();
}

class _ActivityBookingScreenState extends State<ActivityBookingScreen> {
  final _api = ApiService();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _termsAccepted = false;
  bool _isLoading     = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pre-fill dari data user yang login
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameCtrl.text  = user.name;
      _emailCtrl.text = user.email;
      _phoneCtrl.text = user.phone ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Nama lengkap wajib diisi');
      return;
    }
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Email wajib diisi');
      return;
    }
    if (_phoneCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().length < 8) {
      setState(() => _error = 'Nomor telepon wajib diisi (8–15 digit)');
      return;
    }
    if (!_termsAccepted) {
      setState(() => _error = 'Anda harus menyetujui syarat & ketentuan');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      final a = widget.activity;
      await _api.post(ApiConstants.userBookings, data: {
        'bookable_type':     'activity',
        'bookable_id':       a.id,
        'check_in_date':     a.eventDate!.toIso8601String().split('T').first,
        'participant_name':  _nameCtrl.text.trim(),
        'participant_email': _emailCtrl.text.trim(),
        'participant_phone': _phoneCtrl.text.trim(),
        if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
      });
      if (!mounted) return;
      _showSuccess();
    } catch (e) {
      setState(() {
        _error     = e.toString().replaceAll('ApiException: ', '');
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
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.activitySurface,
                borderRadius: BorderRadius.circular(36),
              ),
              child: const Icon(Icons.check_rounded, size: 40, color: AppColors.activity),
            ),
            const SizedBox(height: 16),
            const Text('Pendaftaran Terkirim!',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              'Pendaftaran sedang menunggu persetujuan provider. Biasanya 1×24 jam.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13,
                  color: AppColors.textSecondary, height: 1.5),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.activity),
              onPressed: () => Navigator.of(context)..pop()..pop()..pop(),
              child: const Text('Lihat Booking Saya'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.activity;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daftar Acara'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(height: 3, color: AppColors.activity),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Acara yang Dipilih ───────────────
            _buildAcaraHeader(a),
            const SizedBox(height: 8),

            // ── Detail Booking ───────────────────
            _buildSection(
              title: 'Detail Booking',
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.activityLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_month_outlined,
                      size: 18, color: AppColors.activity),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tanggal Acara',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                              color: AppColors.activity, fontWeight: FontWeight.w600)),
                      Text(
                        a.eventDate != null
                            ? '${_dayName(a.eventDate!.weekday)}, ${formatDate(a.eventDate)}'
                            : '-',
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 14,
                            fontWeight: FontWeight.w700, color: AppColors.activity),
                      ),
                    ],
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 8),

            // ── Data Diri Peserta ────────────────
            _buildSection(
              title: 'Data Diri Peserta',
              subtitle: 'Pastikan data yang kamu isi sudah benar',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _inputField(
                    label: 'Nama Lengkap *',
                    controller: _nameCtrl,
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 12),
                  _inputField(
                    label: 'Email *',
                    controller: _emailCtrl,
                    icon: Icons.email_outlined,
                    keyboard: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  _inputField(
                    label: 'Nomor Telepon *',
                    controller: _phoneCtrl,
                    icon: Icons.phone_outlined,
                    keyboard: TextInputType.phone,
                    hint: '08xxxxxxxxxx',
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 12),
                  _inputField(
                    label: 'Catatan (opsional)',
                    controller: _notesCtrl,
                    icon: Icons.notes_outlined,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Ringkasan Harga ──────────────────
            _buildPriceSummary(a),
            const SizedBox(height: 8),

            // ── Info ─────────────────────────────
            _buildInfoBox(a),
            const SizedBox(height: 8),

            // ── S&K + Error ──────────────────────
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _termsAccepted = !_termsAccepted),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _termsAccepted,
                          onChanged: (v) => setState(() => _termsAccepted = v!),
                          activeColor: AppColors.activity,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Saya menyetujui Syarat & Ketentuan dan Kebijakan Privasi EduLiving',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 13),
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
                        const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!,
                            style: const TextStyle(fontFamily: 'Poppins',
                                fontSize: 12, color: AppColors.error))),
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
      bottomNavigationBar: _buildBottomBar(a),
    );
  }

  Widget _buildAcaraHeader(ActivityModel a) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Acara yang Dipilih',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: EduImage(
                path: a.images.isNotEmpty ? a.images.first : null,
                width: 76, height: 76,
                placeholderColor: AppColors.activityLight,
                iconColor: AppColors.activity,
                placeholderIcon: Icons.event_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 14,
                          fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  if (a.location != null)
                    Row(children: [
                      const Icon(Icons.location_on_outlined, size: 11, color: AppColors.textHint),
                      const SizedBox(width: 2),
                      Expanded(child: Text(a.location!, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 11,
                              color: AppColors.textSecondary))),
                    ]),
                  const SizedBox(height: 4),
                  if (a.hasDiscount)
                    Text(formatRupiah(a.price),
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 11,
                            color: AppColors.textHint, decoration: TextDecoration.lineThrough)),
                  Text(
                    a.price == 0
                        ? 'Gratis'
                        : '${formatRupiah(a.discountedPrice)} per peserta',
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 15,
                        fontWeight: FontWeight.w700, color: AppColors.activity),
                  ),
                ],
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildPriceSummary(ActivityModel a) {
    return _buildSection(
      title: 'Ringkasan',
      child: Column(
        children: [
          _priceRow('Harga per Peserta', a.price == 0 ? 'Gratis' : formatRupiah(a.price)),
          if (a.hasDiscount) ...[
            _priceRow(
              'Diskon',
              a.discountType == 'percentage'
                  ? '-${a.discountValue!.toStringAsFixed(0)}%'
                  : '-${formatRupiah(a.discountValue!)}',
              color: AppColors.activity,
            ),
            _priceRow('Harga per Peserta (setelah diskon)',
                a.discountedPrice == 0 ? 'Gratis' : formatRupiah(a.discountedPrice)),
          ],
          const Divider(height: 16),
          _priceRow(
            'Total',
            a.discountedPrice == 0 ? 'Gratis' : formatRupiah(a.discountedPrice),
            bold: true, color: AppColors.activity,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(ActivityModel a) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.activityLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.activity.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.info_outline, size: 16, color: AppColors.activity),
              const SizedBox(width: 6),
              const Text('Informasi Penting',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 13,
                      fontWeight: FontWeight.w600, color: AppColors.activity)),
            ]),
            const SizedBox(height: 8),
            ...[
              '• Pendaftaran diproses dalam 1×24 jam',
              '• Pembayaran dilakukan setelah pendaftaran disetujui',
              if (a.registrationDeadline != null)
                '• Batas pendaftaran: ${formatDate(a.registrationDeadline)}',
              if (a.availableSlots != null)
                '• Sisa slot: ${a.availableSlots} tempat',
            ].map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(s, style: const TextStyle(fontFamily: 'Poppins',
                  fontSize: 12, color: AppColors.textSecondary)),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(ActivityModel a) {
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
                  const Text('Total',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                          color: AppColors.textSecondary)),
                  Text(
                    a.discountedPrice == 0 ? 'Gratis' : formatRupiah(a.discountedPrice),
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 18,
                        fontWeight: FontWeight.w700, color: AppColors.activity),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.activity,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: AppColors.activity.withValues(alpha: 0.5),
                ),
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_outlined, size: 18),
                label: Text(_isLoading ? 'Memproses...' : 'Kirim Pendaftaran',
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────

  Widget _buildSection({required String title, String? subtitle, required Widget child}) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 15,
              fontWeight: FontWeight.w700)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12,
                color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _inputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    String? hint,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13,
            fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboard,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18, color: AppColors.textHint),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.activity)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _priceRow(String label, String value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: TextStyle(fontFamily: 'Poppins',
              fontSize: bold ? 14 : 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: bold ? AppColors.textPrimary : AppColors.textSecondary))),
          Text(value, style: TextStyle(fontFamily: 'Poppins',
              fontSize: bold ? 16 : 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: color ?? AppColors.textPrimary)),
        ],
      ),
    );
  }

  String _dayName(int weekday) {
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return days[weekday - 1];
  }
}