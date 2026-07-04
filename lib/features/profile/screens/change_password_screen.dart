import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _isLoading = false;

  bool _hasMinLength = false;
  bool _isMatching = false;
  bool _hasTypedNew = false;
  bool _hasTypedConfirm = false;

  @override
  void initState() {
    super.initState();
    _newCtrl.addListener(_validateRealTime);
    _confirmCtrl.addListener(_validateRealTime);
  }

  void _validateRealTime() {
    setState(() {
      if (_newCtrl.text.isNotEmpty) _hasTypedNew = true;
      if (_confirmCtrl.text.isNotEmpty) _hasTypedConfirm = true;

      _hasMinLength = _newCtrl.text.length >= 8;
      _isMatching = _newCtrl.text.isNotEmpty && _newCtrl.text == _confirmCtrl.text;
    });
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validasi tambahan
    if (!_hasMinLength || !_isMatching) return;

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    try {
      await context.read<AuthProvider>().changePassword(
            currentPassword: _currentCtrl.text,
            newPassword: _newCtrl.text,
            confirmPassword: _confirmCtrl.text,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kata sandi berhasil diubah!', style: TextStyle(fontFamily: 'Poppins')),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString(), style: const TextStyle(fontFamily: 'Poppins')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Ubah Kata Sandi',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield_outlined, size: 22, color: AppColors.primary),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Amankan akun Anda dengan kata sandi yang kuat. Pastikan mudah diingat tapi sulit ditebak oleh orang lain.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              _buildField(
                label: 'Kata Sandi Saat Ini',
                controller: _currentCtrl,
                obscure: !_showCurrent,
                toggle: () => setState(() => _showCurrent = !_showCurrent),
                isVisible: _showCurrent,
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Kata sandi saat ini wajib diisi'
                    : null,
              ),

              const SizedBox(height: 20),

              _buildField(
                label: 'Kata Sandi Baru',
                controller: _newCtrl,
                obscure: !_showNew,
                toggle: () => setState(() => _showNew = !_showNew),
                isVisible: _showNew,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Kata sandi baru wajib diisi';
                  return null; // The real-time checker handles the length
                },
              ),
              if (_hasTypedNew) _buildRequirement(
                isValid: _hasMinLength,
                text: 'Minimal 8 karakter',
              ),

              const SizedBox(height: 20),

              _buildField(
                label: 'Konfirmasi Kata Sandi Baru',
                controller: _confirmCtrl,
                obscure: !_showConfirm,
                toggle: () => setState(() => _showConfirm = !_showConfirm),
                isVisible: _showConfirm,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Konfirmasi kata sandi wajib diisi';
                  return null; // The real-time checker handles the match
                },
              ),
              if (_hasTypedConfirm) _buildRequirement(
                isValid: _isMatching,
                text: _isMatching ? 'Kata sandi cocok' : 'Kata sandi tidak cocok',
                isError: !_isMatching,
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Simpan Perubahan',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequirement({required bool isValid, required String text, bool isError = false}) {
    final Color color = isValid 
        ? AppColors.success 
        : (isError ? AppColors.error : AppColors.textHint);
    
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle_rounded : (isError ? Icons.cancel_rounded : Icons.radio_button_unchecked_rounded),
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback toggle,
    required bool isVisible,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            errorStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            suffixIcon: IconButton(
              onPressed: toggle,
              icon: Icon(
                isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textHint,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

