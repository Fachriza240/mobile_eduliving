import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/providers/auth_provider.dart';

class RatingScreen extends StatefulWidget {
  final bool isResidence;
  final int rateableId;
  final String rateableName;

  const RatingScreen({
    super.key,
    required this.isResidence,
    required this.rateableId,
    required this.rateableName,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  final ApiService _api = ApiService();
  final _commentCtrl = TextEditingController();
  int _rating = 0;
  bool _isLoading = false;
  bool _isEditing = false;
  bool _isDeleting = false;
  
  File? _selectedPhoto;
  String? _existingPhotoUrl;

  @override
  void initState() {
    super.initState();
    _fetchExistingRating();
  }

  Future<void> _fetchExistingRating() async {
    try {
      final type = widget.isResidence ? 'residences' : 'activities';
      final id = widget.rateableId;

      final res = await _api.get('/$type/$id');
      if (res['data'] != null && res['data']['ratings'] != null) {
        final ratings = res['data']['ratings'] as List<dynamic>;
        
        // Dapatkan userId dari provider
        final userId = Provider.of<AuthProvider>(context, listen: false).user?.id;
        if (userId == null) return;

        final existing = ratings.cast<Map<String, dynamic>>().firstWhere(
            (r) => r['user_id'] == userId,
            orElse: () => <String, dynamic>{});

        if (existing.isNotEmpty) {
          if (mounted) {
            setState(() {
              _rating = int.tryParse(existing['rating']?.toString() ?? '0') ?? 0;
              _commentCtrl.text = existing['review']?.toString() ?? '';
              _existingPhotoUrl = existing['photo_path']?.toString();
              _isEditing = true;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching existing rating: $e');
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() => _selectedPhoto = File(picked.path));
    }
  }

  Future<void> _delete() async {
    setState(() => _isDeleting = true);
    try {
      final type = widget.isResidence ? 'residence' : 'activity';
      final id = widget.rateableId;

      // API delete requires type and id in body or query, but dio delete accepts data
      await _api.delete('/user/ratings/0', data: {
        'type': type,
        'id': id,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ulasan berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('ApiException: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih bintang terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final type = widget.isResidence ? 'residence' : 'activity';
      final id = widget.rateableId;

      final formData = FormData.fromMap({
        'type': type,
        'id': id,
        'rating': _rating,
        'review': _commentCtrl.text.trim(),
      });

      if (_selectedPhoto != null) {
        formData.files.add(MapEntry(
          'photo',
          await MultipartFile.fromFile(_selectedPhoto!.path),
        ));
      }

      await _api.post(
        '/user/ratings', 
        formData: formData,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ulasan berhasil dikirim, terima kasih!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('ApiException: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isResidence = widget.isResidence;
    final color = isResidence ? AppColors.residence : AppColors.activity;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const EduAppBar(title: 'Beri Ulasan'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info item yang dirating
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isResidence
                          ? Icons.home_work_outlined
                          : Icons.event_outlined,
                      color: color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.rateableName,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Pilih bintang
            const Text('Penilaian',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final star = i + 1;
                return GestureDetector(
                  onTap: () => setState(() => _rating = star),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      star <= _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 44,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                _rating == 0
                    ? 'Ketuk bintang untuk memberi nilai'
                    : [
                        '',
                        'Sangat Buruk',
                        'Buruk',
                        'Cukup',
                        'Bagus',
                        'Sangat Bagus'
                      ][_rating],
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: _rating == 0
                        ? AppColors.textHint
                        : Colors.amber.shade700,
                    fontWeight: FontWeight.w600),
              ),
            ),

            const SizedBox(height: 24),

            // Komentar
            const Text('Komentar (opsional)',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _commentCtrl,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Ceritakan pengalamanmu...',
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Foto Bukti (opsional)',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickPhoto,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                ),
                child: _selectedPhoto != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_selectedPhoto!, fit: BoxFit.cover),
                      )
                    : _existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: EduImage(
                              path: _existingPhotoUrl!,
                              width: 100,
                              height: 100,
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, color: AppColors.textHint, size: 28),
                              SizedBox(height: 8),
                              Text('Upload', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                            ],
                          ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading || _isDeleting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Simpan Ulasan',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
              ),
            ),

            if (_isEditing) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: _isLoading || _isDeleting ? null : _delete,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.red, strokeWidth: 2),
                        )
                      : const Text('Hapus Ulasan',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
