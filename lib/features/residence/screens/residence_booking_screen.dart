import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/residence_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/providers/auth_provider.dart';

class ResidenceBookingScreen extends StatefulWidget {
  final ResidenceModel residence;
  const ResidenceBookingScreen(
      {super.key, required this.residence});

  @override
  State<ResidenceBookingScreen> createState() =>
      _ResidenceBookingScreenState();
}

class _ResidenceBookingScreenState
    extends State<ResidenceBookingScreen> {
  final _api        = ApiService();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading   = false;
  String? _error;

  Future<void> _pickDate(
      {required bool isStart}) async {
    final now   = DateTime.now();
    final first = isStart
        ? now
        : (_startDate ?? now)
            .add(const Duration(days: 1));
    final initial = isStart
        ? now
        : (_startDate ?? now)
            .add(const Duration(days: 30));

    final picked = await showDatePicker(
      context    : context,
      initialDate: initial,
      firstDate  : first,
      lastDate   : DateTime(now.year + 2),
      builder    : (_, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
              primary: AppColors.residence),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          _endDate   = null;
        } else {
          _endDate = picked;
        }
        _error = null;
      });
    }
  }

  int get _months {
    if (_startDate == null || _endDate == null) {
      return 0;
    }
    return ((_endDate!
                    .difference(_startDate!)
                    .inDays) /
                30)
            .ceil();
  }

  double get _total =>
      widget.residence.discountedPrice * _months;

  Future<void> _submit() async {
    if (_startDate == null || _endDate == null) {
      setState(() => _error =
          'Pilih tanggal mulai dan selesai terlebih dahulu');
      return;
    }
    setState(() {
      _isLoading = true;
      _error     = null;
    });
    try {
      await _api.post(
        ApiConstants.userBookings,
        data: {
          'bookable_id'  : widget.residence.id,
          'bookable_type': 'App\\Models\\Residence',
          'start_date'   : _startDate!
              .toIso8601String()
              .split('T')
              .first,
          'end_date'     : _endDate!
              .toIso8601String()
              .split('T')
              .first,
          'total_price'  : _total,
        },
      );
      if (!mounted) return;
      _showSuccess();
    } catch (e) {
      setState(() {
        _error     = e.toString().replaceAll(
            'ApiException: ', '');
        _isLoading = false;
      });
    }
  }

  void _showSuccess() {
    showDialog(
      context           : context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children    : [
            Container(
              width : 72,
              height: 72,
              decoration: BoxDecoration(
                color       : AppColors.residenceSurface,
                borderRadius: BorderRadius.circular(36),
              ),
              child: const Icon(Icons.check_rounded,
                  size : 40,
                  color: AppColors.residence),
            ),
            const SizedBox(height: 16),
            const Text('Pemesanan Dikirim!',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize  : 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              'Pemesanan sedang menunggu persetujuan provider. Biasanya 1–2 hari kerja.',
              textAlign: TextAlign.center,
              style    : TextStyle(
                  fontFamily: 'Poppins',
                  fontSize  : 13,
                  color     : AppColors.textSecondary,
                  height    : 1.5),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style    : ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.residence),
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
    final user =
        context.read<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title  : const Text('Pesan Hunian'),
        leading: IconButton(
          icon     : const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 19),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(
              height: 3,
              color : AppColors.residence),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ── Ringkasan Hunian ─────────────
            _buildSummary(),
            const SizedBox(height: 8),

            // ── Form ─────────────────────────
            Container(
              color  : AppColors.white,
              padding: const EdgeInsets.all(20),
              child  : Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text('Detail Pemesanan',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize  : 15,
                          fontWeight:
                              FontWeight.w700)),
                  const SizedBox(height: 16),

                  // Info pemesan read-only
                  _infoBox('Nama Pemesan',
                      user?.name ?? '-',
                      Icons.person_outline),
                  const SizedBox(height: 10),
                  _infoBox('Email',
                      user?.email ?? '-',
                      Icons.email_outlined),
                  const SizedBox(height: 20),

                  // Tanggal Mulai
                  _fieldLabel('Tanggal Mulai'),
                  const SizedBox(height: 8),
                  _datePicker(
                    label   : _startDate != null
                        ? formatDate(_startDate)
                        : 'Pilih tanggal mulai',
                    onTap   : () =>
                        _pickDate(isStart: true),
                    selected: _startDate != null,
                  ),
                  const SizedBox(height: 14),

                  // Tanggal Selesai
                  _fieldLabel('Tanggal Selesai'),
                  const SizedBox(height: 8),
                  _datePicker(
                    label   : _endDate != null
                        ? formatDate(_endDate)
                        : _startDate == null
                            ? 'Pilih tanggal mulai dahulu'
                            : 'Pilih tanggal selesai',
                    onTap   : _startDate != null
                        ? () => _pickDate(
                            isStart: false)
                        : null,
                    selected: _endDate != null,
                    disabled: _startDate == null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Ringkasan Harga ───────────────
            if (_startDate != null &&
                _endDate != null)
              _buildPriceSummary(),

            // ── Error ─────────────────────────
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child  : Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color       : AppColors.errorLight,
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error,
                        size : 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize  : 12,
                              color:
                                  AppColors.error)),
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

  Widget _buildSummary() {
    final r = widget.residence;
    return Container(
      color  : AppColors.white,
      padding: const EdgeInsets.all(16),
      child  : Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: EduImage(
            path            : r.mainImage,
            width           : 76,
            height          : 76,
            placeholderColor: AppColors.residenceLight,
            iconColor       : AppColors.residence,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(r.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style   : const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize  : 14,
                      fontWeight: FontWeight.w700,
                      color:
                          AppColors.textPrimary)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(
                    Icons.location_on_outlined,
                    size : 11,
                    color: AppColors.textHint),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(r.address,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize  : 11,
                          color: AppColors
                              .textSecondary)),
                ),
              ]),
              const SizedBox(height: 4),
              Text(
                formatRupiah(r.discountedPrice,
                    suffix:
                        '/${r.rentalPeriodShort}'),
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize  : 14,
                    fontWeight: FontWeight.w700,
                    color     : AppColors.residence),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      color  : AppColors.white,
      padding: const EdgeInsets.all(20),
      child  : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ringkasan Harga',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize  : 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _priceRow('Harga sewa',
              formatRupiah(
                  widget.residence.discountedPrice)),
          _priceRow('Durasi', '$_months bulan'),
          const Divider(height: 20),
          _priceRow('Total', formatRupiah(_total),
              bold : true,
              color: AppColors.residence),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color : AppColors.white,
          border: Border(
              top: BorderSide(
                  color: AppColors.divider)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children    : [
            if (_startDate != null &&
                _endDate != null)
              Padding(
                padding: const EdgeInsets.only(
                    bottom: 8),
                child  : Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Pembayaran',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize  : 12,
                            color: AppColors
                                .textSecondary)),
                    Text(formatRupiah(_total),
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize  : 18,
                            fontWeight:
                                FontWeight.w700,
                            color:
                                AppColors.residence)),
                  ],
                ),
              ),
            ElevatedButton(
              style    : ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.residence),
              onPressed:
                  _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width : 20,
                      child :
                          CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                                  Colors.white))
                  : const Text('Kirim Pemesanan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBox(
      String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color       : AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border      : Border.all(
            color: AppColors.border),
      ),
      child: Row(children: [
        Icon(icon,
            size : 18,
            color: AppColors.textHint),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize  : 10,
                    color     : AppColors.textHint)),
            Text(value,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize  : 13,
                    fontWeight: FontWeight.w500,
                    color:
                        AppColors.textPrimary)),
          ],
        ),
      ]),
    );
  }

  Widget _datePicker({
    required String label,
    required VoidCallback? onTap,
    bool selected = false,
    bool disabled = false,
  }) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: disabled
              ? AppColors.background
              : AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppColors.residence
                : AppColors.border,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_outlined,
              size : 18,
              color: selected
                  ? AppColors.residence
                  : AppColors.textHint),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize  : 13,
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textHint,
                  fontWeight: selected
                      ? FontWeight.w500
                      : FontWeight.w400)),
        ]),
      ),
    );
  }

  Widget _fieldLabel(String t) => Text(t,
      style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize  : 13,
          fontWeight: FontWeight.w600,
          color     : AppColors.textPrimary));

  Widget _priceRow(String label, String value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: 4),
      child  : Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize  : bold ? 14 : 13,
                  fontWeight: bold
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: bold
                      ? AppColors.textPrimary
                      : AppColors.textSecondary)),
          Text(value,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize  : bold ? 16 : 13,
                  fontWeight: bold
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: color ??
                      AppColors.textPrimary)),
        ],
      ),
    );
  }
}