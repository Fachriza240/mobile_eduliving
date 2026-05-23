import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  // Field khusus provider
  final _nikCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String _selectedRole = 'user';

  // Provider verification fields
  File? _ktpFile;
  String? _selfieBase64;
  bool _isPickingImage = false;

  final _picker = ImagePicker();

  final List<Map<String, dynamic>> _roles = [
    {
      'value': 'user',
      'label': 'Mahasiswa',
      'desc': 'Cari hunian, ikut acara, beli barang',
      'icon': Icons.person_rounded,
      'color': AppColors.primary,
      'lightColor': AppColors.primaryLight,
    },
    {
      'value': 'provider_residence',
      'label': 'Provider Hunian',
      'desc': 'Tawarkan kost / kontrakan ke mahasiswa',
      'icon': Icons.home_work_rounded,
      'color': AppColors.residence,
      'lightColor': AppColors.residenceLight,
    },
    {
      'value': 'provider_event',
      'label': 'Provider Acara',
      'desc': 'Buat dan kelola event kampus',
      'icon': Icons.event_rounded,
      'color': AppColors.activity,
      'lightColor': AppColors.activityLight,
    },
  ];

  bool get _isProvider =>
      _selectedRole == 'provider_residence' ||
      _selectedRole == 'provider_event';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _nikCtrl.dispose();
    super.dispose();
  }

  // ── Pilih Foto KTP dari Galeri ──────────────────────
  Future<void> _pickKtp() async {
    setState(() => _isPickingImage = true);
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1280,
      );
      if (picked != null) {
        setState(() => _ktpFile = File(picked.path));
      }
    } catch (e) {
      _showError('Gagal memilih foto KTP: $e');
    } finally {
      setState(() => _isPickingImage = false);
    }
  }

  // ── Ambil Foto Selfie dari Kamera ───────────────────
  Future<void> _takeSelfie() async {
    setState(() => _isPickingImage = true);
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1280,
        preferredCameraDevice: CameraDevice.front,
      );
      if (picked != null) {
        final bytes = await File(picked.path).readAsBytes();
        final ext = picked.path.split('.').last.toLowerCase();
        final mime = ext == 'png' ? 'png' : 'jpeg';
        final base64Str = 'data:image/$mime;base64,${base64Encode(bytes)}';
        setState(() => _selfieBase64 = base64Str);
      }
    } catch (e) {
      _showError('Gagal mengambil foto selfie: $e');
    } finally {
      setState(() => _isPickingImage = false);
    }
  }

  // Selfie bisa juga dari galeri
  Future<void> _pickSelfieFromGallery() async {
    setState(() => _isPickingImage = true);
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1280,
      );
      if (picked != null) {
        final bytes = await File(picked.path).readAsBytes();
        final ext = picked.path.split('.').last.toLowerCase();
        final mime = ext == 'png' ? 'png' : 'jpeg';
        final base64Str = 'data:image/$mime;base64,${base64Encode(bytes)}';
        setState(() => _selfieBase64 = base64Str);
      }
    } catch (e) {
      _showError('Gagal memilih foto selfie: $e');
    } finally {
      setState(() => _isPickingImage = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    // Validasi tambahan untuk provider
    if (_isProvider) {
      if (_ktpFile == null) {
        _showError('Foto KTP wajib diunggah untuk provider');
        return;
      }
      if (_selfieBase64 == null) {
        _showError('Foto selfie wajib diambil untuk provider');
        return;
      }
    }

    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();

    bool ok;
    if (_isProvider) {
      // Register provider — kirim multipart dengan NIK, KTP, selfie
      ok = await auth.registerProvider(
        name: _nameCtrl.text,
        email: _emailCtrl.text,
        password: _passCtrl.text,
        passwordConfirmation: _confirmCtrl.text,
        role: _selectedRole,
        providerNik: _nikCtrl.text.trim(),
        providerKtp: _ktpFile!,
        providerSelfieBase64: _selfieBase64!,
      );
    } else {
      // Register user biasa
      ok = await auth.register(
        name: _nameCtrl.text,
        email: _emailCtrl.text,
        password: _passCtrl.text,
        passwordConfirmation: _confirmCtrl.text,
        phone: '',
        address: '',
        role: _selectedRole,
      );
    }

    if (!mounted) return;

    if (ok) {
      if (_isProvider) {
        _showProviderInfo();
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          auth.errorMessage ?? 'Gagal mendaftar.',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  void _showProviderInfo() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
            SizedBox(width: 8),
            Text('Akun Berhasil Dibuat!',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
          ],
        ),
        content: const Text(
          'Akun Anda sudah dibuat. Sebagai provider, '
          'Anda perlu menunggu persetujuan Admin '
          'sebelum dapat mengelola listing.\n\n'
          'Biasanya 1–2 hari kerja.',
          style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.6),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/home');
            },
            child: const Text('Mengerti, Lanjutkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Buat Akun'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Pilih Role ─────────────────────
                const Text('Daftar sebagai apa?',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                const Text('Pilih peran Anda di EduLiving',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 20),
                ..._roles.map((r) => _buildRoleCard(r)),
                const SizedBox(height: 24),

                // ── Divider ────────────────────────
                Row(children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Lengkapi data diri',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: AppColors.textHint)),
                  ),
                  const Expanded(child: Divider()),
                ]),
                const SizedBox(height: 20),

                // ── Nama ───────────────────────────
                _label('Nama Lengkap'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Nama lengkap Anda',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Nama tidak boleh kosong';
                    if (v.trim().length < 3) return 'Minimal 3 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Email ──────────────────────────
                _label('Email'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'contoh@email.com',
                    prefixIcon: Icon(Icons.email_outlined, size: 20),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email tidak boleh kosong';
                    if (!v.contains('@')) return 'Format email tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Password ───────────────────────
                _label('Kata Sandi'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'Minimal 8 karakter',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscurePass
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Kata sandi tidak boleh kosong';
                    if (v.length < 8) return 'Minimal 8 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Konfirmasi ─────────────────────
                _label('Konfirmasi Kata Sandi'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConfirm,
                  textInputAction:
                      _isProvider ? TextInputAction.next : TextInputAction.done,
                  onFieldSubmitted: _isProvider ? null : (_) => _register(),
                  decoration: InputDecoration(
                    hintText: 'Ulangi kata sandi',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Konfirmasi kata sandi tidak boleh kosong';
                    if (v != _passCtrl.text) return 'Kata sandi tidak cocok';
                    return null;
                  },
                ),

                // ── Section Provider (NIK, KTP, Selfie) ──
                if (_isProvider) ...[
                  const SizedBox(height: 24),
                  _buildProviderDivider(),
                  const SizedBox(height: 20),

                  // NIK
                  _label('NIK (Nomor Induk Kependudukan)'),
                  const SizedBox(height: 4),
                  Text('16 digit sesuai KTP',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppColors.textHint)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nikCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 16,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: '16 digit NIK',
                      prefixIcon: Icon(Icons.badge_outlined, size: 20),
                      counterText: '',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'NIK tidak boleh kosong';
                      if (v.trim().length != 16) return 'NIK harus 16 digit';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Foto KTP
                  _label('Foto KTP'),
                  const SizedBox(height: 4),
                  Text('Upload foto KTP Anda yang jelas dan terbaca',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppColors.textHint)),
                  const SizedBox(height: 10),
                  _buildKtpPicker(),
                  const SizedBox(height: 20),

                  // Foto Selfie
                  _label('Foto Selfie + KTP'),
                  const SizedBox(height: 4),
                  Text('Foto Anda sambil memegang KTP',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppColors.textHint)),
                  const SizedBox(height: 10),
                  _buildSelfiePicker(),
                  const SizedBox(height: 16),

                  // Info verifikasi
                  _buildVerifInfo(),
                ],

                const SizedBox(height: 28),

                // ── Tombol Daftar ──────────────────
                Consumer<AuthProvider>(
                  builder: (_, auth, __) => ElevatedButton(
                    onPressed: (auth.isLoading || _isPickingImage) ? null : _register,
                    child: auth.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white))
                        : const Text('Buat Akun'),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Link Login ─────────────────────
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: RichText(
                      text: const TextSpan(
                        text: 'Sudah punya akun? ',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: AppColors.textSecondary),
                        children: [
                          TextSpan(
                            text: 'Masuk',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProviderDivider() {
    final color = _selectedRole == 'provider_residence'
        ? AppColors.residence
        : AppColors.activity;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user_outlined, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Verifikasi Provider',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color)),
                const SizedBox(height: 2),
                const Text(
                  'Isi data di bawah untuk proses verifikasi akun provider',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKtpPicker() {
    return GestureDetector(
      onTap: _isPickingImage ? null : _pickKtp,
      child: Container(
        width: double.infinity,
        height: 130,
        decoration: BoxDecoration(
          color: _ktpFile != null ? AppColors.background : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _ktpFile != null ? AppColors.residence : AppColors.border,
            width: _ktpFile != null ? 1.8 : 1,
          ),
        ),
        child: _ktpFile != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _ktpFile!,
                      width: double.infinity,
                      height: 130,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _ktpFile = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.residence,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Ganti Foto',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      size: 36, color: AppColors.textHint),
                  const SizedBox(height: 8),
                  const Text('Ketuk untuk upload foto KTP',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: AppColors.textHint)),
                  const SizedBox(height: 2),
                  const Text('JPG, JPEG, atau PNG — maks. 2MB',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppColors.textHint)),
                ],
              ),
      ),
    );
  }

  Widget _buildSelfiePicker() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 130,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _selfieBase64 != null ? AppColors.activity : AppColors.border,
              width: _selfieBase64 != null ? 1.8 : 1,
            ),
          ),
          child: _selfieBase64 != null
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        base64Decode(_selfieBase64!.split(',').last),
                        width: double.infinity,
                        height: 130,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _selfieBase64 = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.activity,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Ambil Ulang',
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_outlined,
                        size: 36, color: AppColors.textHint),
                    const SizedBox(height: 8),
                    const Text('Selfie sambil pegang KTP',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: AppColors.textHint)),
                  ],
                ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isPickingImage ? null : _takeSelfie,
                icon: const Icon(Icons.camera_alt_outlined, size: 16),
                label: const Text('Kamera',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.activity,
                  side: const BorderSide(color: AppColors.activity),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isPickingImage ? null : _pickSelfieFromGallery,
                icon: const Icon(Icons.photo_library_outlined, size: 16),
                label: const Text('Galeri',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.activity,
                  side: const BorderSide(color: AppColors.activity),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVerifInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.warning, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Akun provider membutuhkan verifikasi admin. '
              'Setelah daftar, Anda perlu menunggu persetujuan '
              'sebelum dapat mengelola listing (1–2 hari kerja).',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(Map<String, dynamic> role) {
    final isSelected = _selectedRole == role['value'];
    final Color color = role['color'] as Color;
    final Color lightColor = role['lightColor'] as Color;

    return GestureDetector(
      onTap: () => setState(() {
        _selectedRole = role['value'] as String;
        // Reset provider fields saat ganti role
        _ktpFile = null;
        _selfieBase64 = null;
        _nikCtrl.clear();
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? lightColor : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.8 : 0.8,
          ),
        ),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isSelected ? color : AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(role['icon'] as IconData,
                color: isSelected ? Colors.white : AppColors.textHint,
                size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(role['label'] as String,
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? color : AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(role['desc'] as String,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: isSelected
                ? Icon(Icons.check_circle_rounded,
                    key: const ValueKey('check'), color: color, size: 22)
                : const Icon(Icons.radio_button_unchecked,
                    key: ValueKey('uncheck'),
                    color: AppColors.border,
                    size: 22),
          ),
        ]),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary));
}
