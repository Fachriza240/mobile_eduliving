import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../providers/provider_marketplace_provider.dart';
import '../../models/provider_models.dart';

class ProviderMarketplaceFormScreen extends StatefulWidget {
  final ProviderMarketplaceProductModel? product;

  const ProviderMarketplaceFormScreen({super.key, this.product});

  @override
  State<ProviderMarketplaceFormScreen> createState() =>
      _ProviderMarketplaceFormScreenState();
}

class _ProviderMarketplaceFormScreenState
    extends State<ProviderMarketplaceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  // Controllers
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _conditionNotesCtrl = TextEditingController();

  // State
  String _condition = 'used';
  int? _categoryId;
  List<XFile> _newImages = [];
  List<String> _existingImages = [];

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderMarketplaceProvider>().loadCategories();
    });
    _prefillIfEdit();
  }

  void _prefillIfEdit() {
    final p = widget.product;
    if (p == null) return;
    _nameCtrl.text = p.name;
    _descCtrl.text = p.description;
    _priceCtrl.text = p.price.toInt().toString();
    _stockCtrl.text = p.stockQuantity.toString();
    _conditionNotesCtrl.text = p.conditionNotes ?? '';
    _condition = p.condition;
    _categoryId = p.categoryId;
    _existingImages = List.from(p.images);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _conditionNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final total = _existingImages.length + _newImages.length;
    if (total >= 10) {
      _snack('Maksimal 10 foto.', isError: true);
      return;
    }
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isEmpty) return;
    setState(() => _newImages.addAll(picked.take(10 - total)));
  }

  Future<FormData> _buildFormData() async {
    final fields = <MapEntry<String, dynamic>>[
      MapEntry('name', _nameCtrl.text.trim()),
      MapEntry('description', _descCtrl.text.trim()),
      MapEntry('price', _priceCtrl.text.trim()),
      MapEntry('stock_quantity', _stockCtrl.text.trim()),
      MapEntry('condition', _condition),
      if (_conditionNotesCtrl.text.trim().isNotEmpty)
        MapEntry('condition_notes', _conditionNotesCtrl.text.trim()),
      if (_categoryId != null)
        MapEntry('category_id', _categoryId),
    ];

    // Gambar baru
    final imageFiles = <MapEntry<String, MultipartFile>>[];
    for (int i = 0; i < _newImages.length; i++) {
      imageFiles.add(MapEntry(
        'images[$i]',
        await MultipartFile.fromFile(_newImages[i].path,
            filename: 'img_$i.jpg'),
      ));
    }

    return FormData.fromMap({
      for (final e in fields) e.key: e.value,
      for (final e in imageFiles) e.key: e.value,
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isEdit && _newImages.isEmpty) {
      _snack('Tambahkan minimal 1 foto produk.', isError: true);
      return;
    }
    if (_categoryId == null) {
    _snack('Pilih kategori produk terlebih dahulu.', isError: true);
    return;
  }

    final prov = context.read<ProviderMarketplaceProvider>();
    prov.clearMessages();

    final formData = await _buildFormData();
    bool ok;

    if (_isEdit) {
      ok = await prov.updateProduct(widget.product!.id, formData);
    } else {
      ok = await prov.createProduct(formData);
    }

    if (!mounted) return;
    if (ok) {
      _snack(prov.successMessage ?? 'Berhasil!');
      Navigator.pop(context);
    } else {
      _snack(prov.error ?? 'Terjadi kesalahan.', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(
          _isEdit ? 'Edit Produk' : 'Tambah Produk',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Consumer<ProviderMarketplaceProvider>(
        builder: (_, prov, __) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── FOTO ──────────────────────────────
                      _sectionLabel('Foto Produk'),
                      const SizedBox(height: 8),
                      _ImagePickerSection(
                        existingImages: _existingImages,
                        newImages: _newImages,
                        onPickImages: _pickImages,
                        onRemoveExisting: (i) =>
                            setState(() => _existingImages.removeAt(i)),
                        onRemoveNew: (i) =>
                            setState(() => _newImages.removeAt(i)),
                      ),

                      const SizedBox(height: 20),
                      // ── NAMA ──────────────────────────────
                      _sectionLabel('Nama Produk *'),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _nameCtrl,
                        hint: 'Contoh: Meja Belajar IKEA',
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Nama wajib diisi' : null,
                      ),

                      const SizedBox(height: 16),
                      // ── DESKRIPSI ─────────────────────────
                      _sectionLabel('Deskripsi *'),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _descCtrl,
                        hint: 'Deskripsikan produkmu secara detail...',
                        maxLines: 4,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Deskripsi wajib diisi' : null,
                      ),

                      const SizedBox(height: 16),
                      // ── HARGA & STOK ──────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionLabel('Harga (Rp) *'),
                                const SizedBox(height: 8),
                                _buildField(
                                  controller: _priceCtrl,
                                  hint: '50000',
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Wajib';
                                    if (int.tryParse(v) == null) return 'Angka';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionLabel('Stok *'),
                                const SizedBox(height: 8),
                                _buildField(
                                  controller: _stockCtrl,
                                  hint: '1',
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Wajib';
                                    if (int.tryParse(v) == null) return 'Angka';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      // ── KONDISI ───────────────────────────
                      _sectionLabel('Kondisi Barang *'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _ConditionChip(
                            label: 'Baru',
                            selected: _condition == 'new',
                            color: Colors.green.shade600,
                            onTap: () =>
                                setState(() => _condition = 'new'),
                          ),
                          const SizedBox(width: 10),
                          _ConditionChip(
                            label: 'Bekas',
                            selected: _condition == 'used',
                            color: Colors.orange.shade600,
                            onTap: () =>
                                setState(() => _condition = 'used'),
                          ),
                        ],
                      ),

                      if (_condition == 'used') ...[
                        const SizedBox(height: 12),
                        _sectionLabel('Catatan Kondisi'),
                        const SizedBox(height: 8),
                        _buildField(
                          controller: _conditionNotesCtrl,
                          hint: 'Contoh: Ada goresan kecil di sudut kanan...',
                          maxLines: 2,
                        ),
                      ],

                      const SizedBox(height: 16),
                      // ── KATEGORI ──────────────────────────
                      _sectionLabel('Kategori*'),
                      const SizedBox(height: 8),
                      _buildCategoryDropdown(prov),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),

              // Loading overlay
              if (prov.isSaving)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.market),
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<ProviderMarketplaceProvider>(
        builder: (_, prov, __) => Container(
          padding:
              const EdgeInsets.fromLTRB(16, 12, 16, 24),
          color: AppColors.white,
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: prov.isSaving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.market,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: prov.isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _isEdit ? 'Simpan Perubahan' : 'Tambah Produk',
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ),
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

  Widget _buildField({
    required TextEditingController controller,
    String? hint,
    int? maxLines,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines ?? 1,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.white,
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
      ),
    );
  }

  Widget _buildCategoryDropdown(ProviderMarketplaceProvider prov) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButton<int?>(
        value: _categoryId,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        hint: const Text('Pilih kategori (opsional)',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppColors.textHint)),
        style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: AppColors.textPrimary),
        items: [
          const DropdownMenuItem<int?>(
            value: null,
            child: Text('Semua Kategori'),
          ),
          ...prov.categories.map((c) => DropdownMenuItem<int?>(
                value: c.id,
                child: Text(c.name),
              )),
        ],
        onChanged: (v) => setState(() => _categoryId = v),
      ),
    );
  }
}

// ── Image Picker Section ─────────────────────────────────
class _ImagePickerSection extends StatelessWidget {
  final List<String> existingImages;
  final List<XFile> newImages;
  final VoidCallback onPickImages;
  final void Function(int) onRemoveExisting;
  final void Function(int) onRemoveNew;

  const _ImagePickerSection({
    required this.existingImages,
    required this.newImages,
    required this.onPickImages,
    required this.onRemoveExisting,
    required this.onRemoveNew,
  });

  @override
  Widget build(BuildContext context) {
    final total = existingImages.length + newImages.length;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Existing images
        ...existingImages.asMap().entries.map((e) => _imgThumb(
              context,
              child: EduImage(
                path: e.value,
                height: 80,
                borderRadius: 8,
                placeholderIcon: Icons.storefront_outlined,
                placeholderColor: AppColors.marketLight,
                iconColor: AppColors.market,
              ),
              onRemove: () => onRemoveExisting(e.key),
            )),

        // New images
        ...newImages.asMap().entries.map((e) => _imgThumb(
              context,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(e.value.path),
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              onRemove: () => onRemoveNew(e.key),
            )),

        // Add button
        if (total < 10)
          GestureDetector(
            onTap: onPickImages,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.marketLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.market.withOpacity(0.4),
                    style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      color: AppColors.market, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    '$total/10',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: AppColors.market),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _imgThumb(BuildContext context,
      {required Widget child, required VoidCallback onRemove}) {
    return Stack(
      children: [
        SizedBox(width: 80, height: 80, child: child),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 13),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Condition Chip ───────────────────────────────────────
class _ConditionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ConditionChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? color : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.normal,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
