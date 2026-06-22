import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../providers/provider_residence_provider.dart';
import '../../models/provider_models.dart';

class ProviderResidenceFormScreen extends StatefulWidget {
  final ProviderResidenceModel? residence;

  const ProviderResidenceFormScreen({super.key, this.residence});

  @override
  State<ProviderResidenceFormScreen> createState() =>
      _ProviderResidenceFormScreenState();
}

class _ProviderResidenceFormScreenState
    extends State<ProviderResidenceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker  = ImagePicker();

  // ── Controllers ───────────────────────────────────────
  final _nameCtrl        = TextEditingController();
  final _descCtrl        = TextEditingController();
  final _addressCtrl     = TextEditingController();
  final _priceCtrl       = TextEditingController();
  final _capacityCtrl    = TextEditingController();
  final _availableCtrl   = TextEditingController(); // FIX #7: available_slots
  final _latCtrl         = TextEditingController();
  final _lngCtrl         = TextEditingController();
  final _discountValCtrl = TextEditingController();
  final _customFacilCtrl = TextEditingController(); // FIX #10: custom_facilities

  // Kos specific
  final _roomSizeCtrl  = TextEditingController();

  // Kontrakan/Rumah specific
  final _bedroomCtrl   = TextEditingController();
  final _bathroomCtrl  = TextEditingController();
  final _buildingCtrl  = TextEditingController();
  final _landCtrl      = TextEditingController();

  // Apartemen specific
  final _floorCtrl     = TextEditingController();
  final _towerCtrl     = TextEditingController();

  // ── State ─────────────────────────────────────────────
  String _residenceType = 'kos';
  String _furnishStatus = 'unfurnished';
  String _rentalPeriod  = 'monthly';
  String _kosType       = 'putra';
  String _unitType      = 'studio';
  String _discountType  = '';
  bool   _isActive      = true; // FIX #8: is_active
  int?   _categoryId;

  final List<String> _facilities    = [];
  final _facilityCtrl = TextEditingController();

  List<XFile>  _newImages      = [];
  List<String> _existingImages = [];
  // FIX #9: track gambar yang dihapus saat edit
  final List<int> _removedImageIndexes = [];

  bool get _isEdit => widget.residence != null;

  // ── Dropdown options ──────────────────────────────────
  final _typeOptions = const [
    {'value': 'kos',        'label': 'Kos'},
    {'value': 'kontrakan',  'label': 'Kontrakan'},
    {'value': 'rumah_sewa', 'label': 'Rumah Sewa'},
    {'value': 'apartemen',  'label': 'Apartemen'},
  ];

  final _furnishOptions = const [
    {'value': 'unfurnished',    'label': 'Unfurnished'},
    {'value': 'semi_furnished', 'label': 'Semi Furnished'},
    {'value': 'full_furnished', 'label': 'Full Furnished'},
  ];

  // FIX #2: hapus 'daily', backend hanya terima monthly/yearly
  final _rentalOptions = const [
    {'value': 'monthly', 'label': 'Bulanan'},
    {'value': 'yearly',  'label': 'Tahunan'},
  ];

  final _kosTypeOptions = const [
    {'value': 'putra',  'label': 'Putra'},
    {'value': 'putri',  'label': 'Putri'},
    {'value': 'campur', 'label': 'Campur'},
  ];

  final _unitTypeOptions = const [
    {'value': 'studio', 'label': 'Studio'},
    {'value': '1BR',    'label': '1 Bedroom'},
    {'value': '2BR',    'label': '2 Bedroom'},
    {'value': '3BR',    'label': '3 Bedroom'},
    {'value': '4BR',    'label': '4 Bedroom'},
  ];

  // FIX #1: 'fixed' → 'flat' sesuai validasi backend
  final _discountOptions = const [
    {'value': '',           'label': 'Tidak Ada Diskon'},
    {'value': 'percentage', 'label': 'Persentase (%)'},
    {'value': 'flat',       'label': 'Nominal (Rp)'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderResidenceProvider>().loadCategories();
    });
    _prefillIfEdit();
  }

  void _prefillIfEdit() {
    final r = widget.residence;
    if (r == null) return;

    _nameCtrl.text     = r.name;
    _descCtrl.text     = r.description;
    _addressCtrl.text  = r.address;
    _priceCtrl.text    = r.price.toInt().toString();
    _capacityCtrl.text = r.capacity.toString();
    // FIX #7: prefill available_slots
    _availableCtrl.text = r.availableSlots.toString();
    _latCtrl.text      = (r.latitude ?? '').toString();
    _lngCtrl.text      = (r.longitude ?? '').toString();
    _residenceType     = r.residenceType;
    _furnishStatus     = r.furnishStatus ?? 'unfurnished';
    _rentalPeriod      = r.rentalPeriod;
    _categoryId        = r.categoryId;
    _existingImages    = List.from(r.images);
    _facilities.addAll(r.facilities);
    _discountType      = r.discountType ?? '';
    // FIX #8: prefill is_active
    _isActive          = r.isActive;
    if (r.discountValue != null && r.discountValue! > 0) {
      _discountValCtrl.text = r.discountValue!.toInt().toString();
    }

    _kosType  = r.kosType ?? 'putra';
    _unitType = r.unitType ?? 'studio';
    if (r.roomSize     != null) _roomSizeCtrl.text  = r.roomSize!.toInt().toString();
    if (r.bedroomCount != null) _bedroomCtrl.text   = r.bedroomCount.toString();
    if (r.bathroomCount!= null) _bathroomCtrl.text  = r.bathroomCount.toString();
    if (r.buildingSize != null) _buildingCtrl.text  = r.buildingSize!.toInt().toString();
    if (r.landSize     != null) _landCtrl.text      = r.landSize!.toInt().toString();
    if (r.floorNumber  != null) _floorCtrl.text     = r.floorNumber.toString();
    if (r.towerName    != null) _towerCtrl.text     = r.towerName!;
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _descCtrl, _addressCtrl, _priceCtrl, _capacityCtrl,
      _availableCtrl, _latCtrl, _lngCtrl, _discountValCtrl, _customFacilCtrl,
      _roomSizeCtrl, _bedroomCtrl, _bathroomCtrl, _buildingCtrl, _landCtrl,
      _floorCtrl, _towerCtrl, _facilityCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  // ── Pick Images ───────────────────────────────────────
  Future<void> _pickImages() async {
    final total = _existingImages.length + _newImages.length;
    if (total >= 10) { _snack('Maksimal 10 foto.', isError: true); return; }
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isEmpty) return;
    setState(() => _newImages.addAll(picked.take(10 - total)));
  }

  // FIX #9: hapus gambar existing — track index yang dihapus
  void _removeExistingImage(int originalIndex) {
    setState(() {
      _removedImageIndexes.add(originalIndex);
      _existingImages.removeAt(
        _existingImages.length - (originalIndex + 1 - _removedImageIndexes
            .where((i) => i < originalIndex).length),
      );
    });
  }

  // ── Build FormData ────────────────────────────────────
  Future<FormData> _buildFormData() async {
    final fields = <MapEntry<String, dynamic>>[
      MapEntry('name',            _nameCtrl.text.trim()),
      MapEntry('description',     _descCtrl.text.trim()),
      MapEntry('address',         _addressCtrl.text.trim()),
      MapEntry('price_per_month', _priceCtrl.text.trim()),
      MapEntry('capacity',        _capacityCtrl.text.trim()),
      MapEntry('residence_type',  _residenceType),
      MapEntry('furnish_status',  _furnishStatus),
      MapEntry('rental_period',   _rentalPeriod),
      // FIX #8: kirim is_active
      MapEntry('is_active',       _isActive ? '1' : '0'),
      if (_categoryId != null) MapEntry('category_id', _categoryId.toString()),
      if (_latCtrl.text.isNotEmpty) MapEntry('latitude',  _latCtrl.text.trim()),
      if (_lngCtrl.text.isNotEmpty) MapEntry('longitude', _lngCtrl.text.trim()),
      if (_discountType.isNotEmpty) MapEntry('discount_type', _discountType),
      if (_discountType.isNotEmpty && _discountValCtrl.text.isNotEmpty)
        MapEntry('discount_value', _discountValCtrl.text.trim()),
    ];

    // FIX #7: kirim available_slots saat edit
    if (_isEdit && _availableCtrl.text.isNotEmpty) {
      fields.add(MapEntry('available_slots', _availableCtrl.text.trim()));
    }

    // FIX #9: kirim index gambar yang dihapus
    if (_isEdit && _removedImageIndexes.isNotEmpty) {
      for (int i = 0; i < _removedImageIndexes.length; i++) {
        fields.add(MapEntry('removed_images[$i]', _removedImageIndexes[i].toString()));
      }
    }

    // Facilities
    for (int i = 0; i < _facilities.length; i++) {
      fields.add(MapEntry('facilities[$i]', _facilities[i]));
    }

    // FIX #10: kirim custom_facilities jika ada
    if (_customFacilCtrl.text.trim().isNotEmpty) {
      fields.add(MapEntry('custom_facilities', _customFacilCtrl.text.trim()));
    }

    // Type-specific
    if (_residenceType == 'kos') {
      fields.add(MapEntry('kos_type', _kosType));
      if (_roomSizeCtrl.text.isNotEmpty)
        fields.add(MapEntry('room_size', _roomSizeCtrl.text.trim()));
    } else if (_residenceType == 'kontrakan' || _residenceType == 'rumah_sewa') {
      // FIX #5: wajib ada, tapi validator sudah di form — tetap kirim
      fields.add(MapEntry('bedroom_count',  _bedroomCtrl.text.trim()));
      fields.add(MapEntry('bathroom_count', _bathroomCtrl.text.trim()));
      if (_buildingCtrl.text.isNotEmpty) fields.add(MapEntry('building_size', _buildingCtrl.text.trim()));
      if (_landCtrl.text.isNotEmpty)     fields.add(MapEntry('land_size',     _landCtrl.text.trim()));
    } else if (_residenceType == 'apartemen') {
      fields.add(MapEntry('unit_type', _unitType));
      // FIX #6: wajib ada
      fields.add(MapEntry('floor_number', _floorCtrl.text.trim()));
      if (_towerCtrl.text.isNotEmpty)    fields.add(MapEntry('tower_name',    _towerCtrl.text.trim()));
      // FIX #3: tambah bedroom, bathroom, room_size untuk apartemen
      if (_bedroomCtrl.text.isNotEmpty)  fields.add(MapEntry('bedroom_count',  _bedroomCtrl.text.trim()));
      if (_bathroomCtrl.text.isNotEmpty) fields.add(MapEntry('bathroom_count', _bathroomCtrl.text.trim()));
      if (_roomSizeCtrl.text.isNotEmpty) fields.add(MapEntry('room_size',      _roomSizeCtrl.text.trim()));
    }

    // New images
    final imageFiles = <MapEntry<String, MultipartFile>>[];
    for (int i = 0; i < _newImages.length; i++) {
      imageFiles.add(MapEntry(
        'images[$i]',
        await MultipartFile.fromFile(_newImages[i].path, filename: 'image_$i.jpg'),
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
      _snack('Tambahkan minimal 1 foto hunian.', isError: true);
      return;
    }

    final prov     = context.read<ProviderResidenceProvider>();
    final formData = await _buildFormData();
    bool ok;

    if (_isEdit) {
      ok = await prov.updateResidence(widget.residence!.id, formData);
    } else {
      ok = await prov.createResidence(formData);
    }

    if (mounted) {
      if (ok) {
        _snack(_isEdit ? 'Hunian berhasil diperbarui!' : 'Hunian berhasil ditambahkan!');
        Navigator.pop(context);
      } else {
        _snack(prov.error ?? 'Terjadi kesalahan.', isError: true);
      }
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Edit Hunian' : 'Tambah Hunian',
          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        actions: [
          Consumer<ProviderResidenceProvider>(
            builder: (_, prov, __) => TextButton(
              onPressed: prov.isSaving ? null : _submit,
              child: prov.isSaving
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                  : const Text('Simpan',
                      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Foto ─────────────────────────────────
              _sectionTitle('Foto Hunian', Icons.photo_library_outlined),
              const SizedBox(height: 10),
              _buildPhotoSection(),
              const SizedBox(height: 20),

              // ── Tipe Hunian ───────────────────────────
              _sectionTitle('Tipe Hunian', Icons.category_outlined),
              const SizedBox(height: 10),
              _buildTypeSelector(),
              const SizedBox(height: 20),

              // ── Informasi Umum ────────────────────────
              _sectionTitle('Informasi Umum', Icons.info_outline),
              const SizedBox(height: 10),
              _buildCard(
                child: Column(
                  children: [
                    _field(
                      ctrl: _nameCtrl,
                      label: 'Nama Hunian',
                      hint: 'Cth: Kos Putri Bu Sari',
                      validator: (v) => (v?.trim().isEmpty ?? true) ? 'Nama wajib diisi' : null,
                    ),
                    const SizedBox(height: 14),
                    _field(
                      ctrl: _descCtrl,
                      label: 'Deskripsi',
                      hint: 'Jelaskan hunian kamu...',
                      maxLines: 4,
                      validator: (v) => (v?.trim().isEmpty ?? true) ? 'Deskripsi wajib diisi' : null,
                    ),
                    const SizedBox(height: 14),
                    _field(
                      ctrl: _addressCtrl,
                      label: 'Alamat Lengkap',
                      hint: 'Jl. Contoh No. 1, Kota',
                      maxLines: 2,
                      validator: (v) => (v?.trim().isEmpty ?? true) ? 'Alamat wajib diisi' : null,
                    ),
                    const SizedBox(height: 14),
                    Consumer<ProviderResidenceProvider>(
                      builder: (_, prov, __) => DropdownButtonFormField<int>(
                        value: _categoryId,
                        decoration: const InputDecoration(labelText: 'Kategori *'),
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textPrimary),
                        validator: (v) => v == null ? 'Kategori wajib dipilih' : null,
                        hint: prov.categories.isEmpty
                            ? const Text('Memuat kategori...')
                            : const Text('Pilih kategori'),
                        items: prov.categories.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                        )).toList(),
                        onChanged: (v) => setState(() => _categoryId = v),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Harga & Kapasitas ─────────────────────
              _sectionTitle('Harga & Kapasitas', Icons.monetization_on_outlined),
              const SizedBox(height: 10),
              _buildCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            ctrl: _priceCtrl,
                            label: 'Harga (Rp)',
                            hint: '1500000',
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (v) => (v?.trim().isEmpty ?? true) ? 'Harga wajib diisi' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field(
                            ctrl: _capacityCtrl,
                            label: 'Kapasitas',
                            hint: '10',
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (v) => (v?.trim().isEmpty ?? true) ? 'Kapasitas wajib diisi' : null,
                          ),
                        ),
                      ],
                    ),
                    // FIX #7: field available_slots hanya tampil saat edit
                    if (_isEdit) ...[
                      const SizedBox(height: 14),
                      _field(
                        ctrl: _availableCtrl,
                        label: 'Slot Tersedia',
                        hint: '5',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Slot tersedia wajib diisi';
                          final cap = int.tryParse(_capacityCtrl.text.trim()) ?? 0;
                          final avail = int.tryParse(v.trim()) ?? 0;
                          if (avail > cap) return 'Tidak boleh melebihi kapasitas ($cap)';
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 14),
                    _buildDropdown(
                      label: 'Periode Sewa',
                      value: _rentalPeriod,
                      options: _rentalOptions,
                      onChanged: (v) => setState(() => _rentalPeriod = v!),
                    ),
                    const SizedBox(height: 14),
                    _buildDropdown(
                      label: 'Status Furnitur',
                      value: _furnishStatus,
                      options: _furnishOptions,
                      onChanged: (v) => setState(() => _furnishStatus = v!),
                    ),
                    // FIX #8: toggle is_active
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                      title: const Text(
                        'Aktifkan Listing',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        _isActive ? 'Hunian terlihat oleh pengguna' : 'Hunian disembunyikan sementara',
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 11),
                      ),
                      activeColor: AppColors.residence,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Field Spesifik per Tipe ───────────────
              _buildTypeSpecificSection(),
              const SizedBox(height: 20),

              // ── Diskon ───────────────────────────────
              _sectionTitle('Diskon', Icons.local_offer_outlined),
              const SizedBox(height: 10),
              _buildCard(
                child: Column(
                  children: [
                    _buildDropdown(
                      label: 'Tipe Diskon',
                      value: _discountType,
                      options: _discountOptions,
                      onChanged: (v) => setState(() => _discountType = v!),
                    ),
                    if (_discountType.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _field(
                        ctrl: _discountValCtrl,
                        label: _discountType == 'percentage' ? 'Besaran Diskon (%)' : 'Besaran Diskon (Rp)',
                        hint: _discountType == 'percentage' ? '10' : '100000',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Fasilitas ─────────────────────────────
              _sectionTitle('Fasilitas', Icons.checklist_rounded),
              const SizedBox(height: 10),
              _buildFacilitiesSection(),
              const SizedBox(height: 20),

              // ── Lokasi (Opsional) ─────────────────────
              _sectionTitle('Lokasi (Opsional)', Icons.map_outlined),
              const SizedBox(height: 10),
              _buildCard(
                child: Column(
                  children: [
                    _field(ctrl: _latCtrl, label: 'Latitude',  hint: '-6.914744'),
                    const SizedBox(height: 14),
                    _field(ctrl: _lngCtrl, label: 'Longitude', hint: '107.609810'),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Submit Button ─────────────────────────
              Consumer<ProviderResidenceProvider>(
                builder: (_, prov, __) => ElevatedButton(
                  onPressed: prov.isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.residence,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: prov.isSaving
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(
                          _isEdit ? 'Perbarui Hunian' : 'Tambah Hunian',
                          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Photo Section ─────────────────────────────────────
  Widget _buildPhotoSection() {
    // FIX #9: pisahkan existing dan new, tampilkan dengan tombol hapus yang track index asli
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_existingImages.isNotEmpty || _newImages.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Gambar lama (existing)
                  ..._existingImages.asMap().entries.map((entry) {
                    final displayIndex = entry.key;
                    // Hitung index asli di array server (sebelum ada yang dihapus)
                    int serverIndex = displayIndex;
                    for (final removed in _removedImageIndexes) {
                      if (removed <= serverIndex) serverIndex++;
                    }
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: EduImage(
                              path: entry.value,
                              width: 100, height: 100, fit: BoxFit.cover, borderRadius: 10,
                            ),
                          ),
                          Positioned(
                            top: 4, right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _removedImageIndexes.add(serverIndex);
                                  _existingImages.removeAt(displayIndex);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                                child: const Icon(Icons.close, color: Colors.white, size: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  // Gambar baru
                  ..._newImages.asMap().entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(File(entry.value.path), width: 100, height: 100, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 4, right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() => _newImages.removeAt(entry.key)),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                              child: const Icon(Icons.close, color: Colors.white, size: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          if (_existingImages.isNotEmpty || _newImages.isNotEmpty) const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _pickImages,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.residence,
              side: const BorderSide(color: AppColors.residence),
              minimumSize: const Size(double.infinity, 44),
            ),
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(
              '${(_existingImages.isEmpty && _newImages.isEmpty) ? 'Tambah' : 'Tambah Lagi'} Foto (${_existingImages.length + _newImages.length}/10)',
            ),
          ),
        ],
      ),
    );
  }

  // ── Type Selector ─────────────────────────────────────
  Widget _buildTypeSelector() {
    return _buildCard(
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: _typeOptions.map((opt) {
          final isSelected = _residenceType == opt['value'];
          return GestureDetector(
            onTap: () => setState(() => _residenceType = opt['value']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.residence : AppColors.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.residence : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Text(
                opt['label']!,
                style: TextStyle(
                  fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Type Specific Fields ──────────────────────────────
  Widget _buildTypeSpecificSection() {
    if (_residenceType == 'kos') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Detail Kos', Icons.bedroom_parent_outlined),
          const SizedBox(height: 10),
          _buildCard(
            child: Column(
              children: [
                _buildDropdown(
                  label: 'Jenis Kos',
                  value: _kosType,
                  options: _kosTypeOptions,
                  onChanged: (v) => setState(() => _kosType = v!),
                ),
                const SizedBox(height: 14),
                _field(
                  ctrl: _roomSizeCtrl,
                  label: 'Ukuran Kamar (m²)',
                  hint: '12',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_residenceType == 'kontrakan' || _residenceType == 'rumah_sewa') {
      final label = _residenceType == 'kontrakan' ? 'Detail Kontrakan' : 'Detail Rumah Sewa';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(label, Icons.home_outlined),
          const SizedBox(height: 10),
          _buildCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        ctrl: _bedroomCtrl,
                        label: 'Kamar Tidur',
                        hint: '3',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        // FIX #5: tambah validator wajib
                        validator: (v) => (v?.trim().isEmpty ?? true) ? 'Kamar tidur wajib diisi' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        ctrl: _bathroomCtrl,
                        label: 'Kamar Mandi',
                        hint: '2',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        // FIX #5: tambah validator wajib
                        validator: (v) => (v?.trim().isEmpty ?? true) ? 'Kamar mandi wajib diisi' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _field(ctrl: _buildingCtrl, label: 'Luas Bangunan (m²)', hint: '80',
                      keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
                    const SizedBox(width: 12),
                    Expanded(child: _field(ctrl: _landCtrl, label: 'Luas Tanah (m²)', hint: '120',
                      keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_residenceType == 'apartemen') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Detail Apartemen', Icons.apartment_outlined),
          const SizedBox(height: 10),
          _buildCard(
            child: Column(
              children: [
                _buildDropdown(
                  label: 'Tipe Unit',
                  value: _unitType,
                  options: _unitTypeOptions,
                  onChanged: (v) => setState(() => _unitType = v!),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        ctrl: _floorCtrl,
                        label: 'Lantai',
                        hint: '5',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        // FIX #6: tambah validator wajib
                        validator: (v) => (v?.trim().isEmpty ?? true) ? 'Lantai wajib diisi' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _field(ctrl: _towerCtrl, label: 'Nama Tower', hint: 'Tower A')),
                  ],
                ),
                // FIX #3 & #4: tambah bedroom, bathroom, room_size untuk apartemen
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _field(ctrl: _bedroomCtrl, label: 'Kamar Tidur', hint: '2',
                      keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
                    const SizedBox(width: 12),
                    Expanded(child: _field(ctrl: _bathroomCtrl, label: 'Kamar Mandi', hint: '1',
                      keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
                  ],
                ),
                const SizedBox(height: 14),
                _field(
                  ctrl: _roomSizeCtrl,
                  label: 'Luas Unit (m²)',
                  hint: '36',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ],
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  // ── Facilities Section ────────────────────────────────
  Widget _buildFacilitiesSection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input fasilitas chip
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _facilityCtrl,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Cth: WiFi, AC, Parkir...',
                    hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textHint),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.residence, width: 2)),
                  ),
                  onFieldSubmitted: (_) => _addFacility(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _addFacility,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.residence,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          if (_facilities.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: _facilities.map((f) => Chip(
                label: Text(f, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12)),
                deleteIcon: const Icon(Icons.close, size: 14),
                onDeleted: () => setState(() => _facilities.remove(f)),
                backgroundColor: AppColors.residenceLight,
                side: const BorderSide(color: AppColors.residenceSurface),
                labelStyle: const TextStyle(color: AppColors.residenceDark),
                deleteIconColor: AppColors.residenceDark,
              )).toList(),
            ),
          ],
          // FIX #10: custom_facilities — fasilitas bebas ketik dipisah koma
          const SizedBox(height: 14),
          _field(
            ctrl: _customFacilCtrl,
            label: 'Fasilitas Tambahan (pisah koma)',
            hint: 'Cth: Dapur bersama, Jemuran, Ruang tamu',
          ),
        ],
      ),
    );
  }

  void _addFacility() {
    final v = _facilityCtrl.text.trim();
    if (v.isEmpty || _facilities.contains(v)) return;
    setState(() { _facilities.add(v); _facilityCtrl.clear(); });
  }

  // ── Helpers ───────────────────────────────────────────
  Widget _sectionTitle(String title, IconData icon) => Row(
    children: [
      Icon(icon, color: AppColors.residence, size: 18),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(
        fontFamily: 'Poppins', fontSize: 14,
        fontWeight: FontWeight.w700, color: AppColors.textPrimary,
      )),
    ],
  );

  Widget _buildCard({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border, width: 0.8),
    ),
    child: child,
  );

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label, hintText: hint, alignLabelWithHint: maxLines > 1,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<Map<String, String>> options,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textPrimary),
      items: options.map((o) => DropdownMenuItem(
        value: o['value'],
        child: Text(o['label']!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
      )).toList(),
      onChanged: onChanged,
    );
  }
}
