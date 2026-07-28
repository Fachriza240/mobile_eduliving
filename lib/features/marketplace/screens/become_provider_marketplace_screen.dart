import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/file_helper.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:flutter/foundation.dart';

class BecomeProviderMarketplaceScreen extends StatefulWidget {
  const BecomeProviderMarketplaceScreen({super.key});

  @override
  State<BecomeProviderMarketplaceScreen> createState() =>
      _BecomeProviderMarketplaceScreenState();
}

class _BecomeProviderMarketplaceScreenState
    extends State<BecomeProviderMarketplaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api     = ApiService();
  final _nikCtrl = TextEditingController();

  XFile? _ktpFile;
  XFile? _selfieFile;
  bool  _isLoading = false;
  bool  _agreed    = false;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _nikCtrl.dispose();
    super.dispose();
  }

  // ── Pick KTP (galeri/kamera) ───────────────────────
  Future<void> _pickKtp(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (picked != null) setState(() => _ktpFile = picked);
  }

  // ── Pick Selfie (kamera) ───────────────────────────
  Future<void> _pickSelfie() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 800,
      preferredCameraDevice: CameraDevice.front,
    );
    if (picked != null) setState(() => _selfieFile = picked);
  }

  // ── Submit ─────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ktpFile == null) {
      _snack('Upload foto KTP terlebih dahulu.', isError: true);
      return;
    }
    if (_selfieFile == null) {
      _snack('Ambil foto selfie terlebih dahulu.', isError: true);
      return;
    }
    if (!_agreed) {
      _snack('Centang persetujuan syarat & ketentuan terlebih dahulu.',
          isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Selfie → base64
      final selfieBytes  = await _selfieFile!.readAsBytes();
      final selfieBase64 = 'data:image/jpg;base64,${base64Encode(selfieBytes)}';

      // KTP → multipart file
      final formData = FormData.fromMap({
        'seller_nik'   : _nikCtrl.text.trim(),
        'seller_ktp'   : await FileHelper.createMultipart(
          _ktpFile!, 
          filename: 'ktp.jpg',
        ),
        'seller_selfie': selfieBase64,
      });

      await _api.post(
        ApiConstants.becomeProviderMarketplace,
        formData: formData,
      );

      if (mounted) await context.read<AuthProvider>().refreshUser();
      if (!mounted) return;

      _showSuccessDialog();
    } catch (e) {
      if (mounted) _snack(e.toString(), isError: true);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // ── Dialogs & snack ───────────────────────────────
  void _showKtpSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ambil Foto KTP',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Kamera', style: TextStyle(fontFamily: 'Poppins')),
              onTap: () {
                Navigator.pop(context);
                _pickKtp(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeri', style: TextStyle(fontFamily: 'Poppins')),
              onTap: () {
                Navigator.pop(context);
                _pickKtp(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF43A047), size: 44),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pengajuan Terkirim!',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Pengajuan seller-mu sedang ditinjau admin. Kamu akan mendapat notifikasi setelah disetujui.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.market,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // tutup dialog
                final auth = context.read<AuthProvider>();
                final user = auth.user;
                if (user != null) {
                  auth.updateUserLocal(
                    user.copyWith(
                      isSeller: true,
                      isSellerModeActive: true,
                    ),
                  );
                }
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/home',
                  (_) => false,
                );
              },
              child: const Text(
                'Oke, Mengerti',
                style: TextStyle(
                    fontFamily: 'Poppins', fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Build ──────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text(
          'Daftar Jadi Penjual',
          style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _heroBanner(),
                  const SizedBox(height: 24),

                  // ── NIK ───────────────────────────────
                  _sectionLabel('Nomor Induk Kependudukan (NIK) *'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nikCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 16,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                    decoration: _inputDeco(
                      hint: '16 digit NIK sesuai KTP',
                      icon: Icons.credit_card_outlined,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'NIK wajib diisi';
                      if (v.length != 16) return 'NIK harus 16 digit';
                      return null;
                    },
                  ),

                  const SizedBox(height: 8),

                  // ── Foto KTP ──────────────────────────
                  _sectionLabel('Foto KTP *'),
                  const SizedBox(height: 8),
                  _photoPickerCard(
                    label: 'Foto KTP',
                    hint: 'Pastikan foto jelas & tidak terpotong',
                    file: _ktpFile,
                    icon: Icons.credit_card_outlined,
                    onTap: _showKtpSourceSheet,
                  ),

                  const SizedBox(height: 16),

                  // ── Foto Selfie ───────────────────────
                  _sectionLabel('Foto Selfie *'),
                  const SizedBox(height: 4),
                  Text(
                    'Foto selfie sambil memegang KTP menghadap kamera.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _photoPickerCard(
                    label: 'Ambil Selfie',
                    hint: 'Gunakan kamera depan, pencahayaan cukup',
                    file: _selfieFile,
                    icon: Icons.face_outlined,
                    onTap: _pickSelfie,
                  ),

                  const SizedBox(height: 20),
                  _infoCard(),
                  const SizedBox(height: 20),
                  _agreementTile(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.market),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        color: AppColors.white,
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.market,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.border,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'Kirim Pengajuan',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ),
    );
  }

  // ── Widgets ────────────────────────────────────────
  Widget _heroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.market, AppColors.market.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daftar Jadi\nPenjual EduLiving',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Lengkapi data identitas untuk\nverifikasi akun penjualmu.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.85),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(35),
            ),
            child: const Icon(Icons.storefront_rounded,
                color: Colors.white, size: 38),
          ),
        ],
      ),
    );
  }

  Widget _photoPickerCard({
    required String label,
    required String hint,
    required XFile? file,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: file != null ? AppColors.market : AppColors.border,
            width: file != null ? 1.5 : 1.0,
          ),
        ),
        child: file != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: kIsWeb ? Image.network(file.path, fit: BoxFit.cover) : Image.file(File(file.path), fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.market,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Ganti',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.marketLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: AppColors.market, size: 26),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFFF9A825), size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Data identitasmu digunakan untuk verifikasi dan keamanan transaksi. Pengajuan akan ditinjau admin dalam 1×24 jam.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Color(0xFF795548),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _agreementTile() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _agreed ? AppColors.market : AppColors.border,
          width: _agreed ? 1.5 : 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _agreed,
            onChanged: (v) => setState(() => _agreed = v ?? false),
            activeColor: AppColors.market,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4)),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _agreed = !_agreed),
              child: const Text(
                'Saya menyatakan data yang diberikan adalah benar dan menyetujui Syarat & Ketentuan menjadi penjual di EduLiving.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      );

  InputDecoration _inputDeco({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
          fontFamily: 'Poppins', fontSize: 13, color: AppColors.textHint),
      prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.white,
      counterText: '',
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        borderSide: const BorderSide(color: AppColors.market, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }
}
