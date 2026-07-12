import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../providers/provider_activity_provider.dart';
import '../../models/provider_models.dart';

class ProviderActivityFormScreen extends StatefulWidget {
  final ProviderActivityModel? activity;

  const ProviderActivityFormScreen({super.key, this.activity});

  @override
  State<ProviderActivityFormScreen> createState() =>
      _ProviderActivityFormScreenState();
}

class _ProviderActivityFormScreenState
    extends State<ProviderActivityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker  = ImagePicker();

  // ── Controllers ───────────────────────────────────────
  final _nameCtrl         = TextEditingController();
  final _descCtrl         = TextEditingController();
  final _locationCtrl     = TextEditingController();
  final _priceCtrl        = TextEditingController();
  final _capacityCtrl     = TextEditingController();
  final _latCtrl          = TextEditingController();
  final _lngCtrl          = TextEditingController();
  final _discountValCtrl  = TextEditingController();

  // Speaker dialog
  final _speakerNameCtrl  = TextEditingController();
  final _speakerTitleCtrl = TextEditingController();

  // Benefit
  final _benefitCtrl      = TextEditingController();

  // ── State ─────────────────────────────────────────────
  DateTime? _eventDate;
  TimeOfDay? _eventTime;
  DateTime? _registrationDeadline;
  String _discountType = '';
  int? _categoryId;

  final List<String> _benefits = [];
  final List<Map<String, String>> _speakers = [];

  List<XFile>  _newImages      = [];
  List<String> _existingImages = [];

  bool get _isEdit => widget.activity != null;

  final _discountOptions = const [
    {'value': '',           'label': 'Tidak Ada Diskon'},
    {'value': 'percentage', 'label': 'Persentase (%)'},
    {'value': 'fixed',      'label': 'Nominal (Rp)'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderActivityProvider>().loadCategories();
    });
    _prefillIfEdit();
  }

  void _prefillIfEdit() {
    final a = widget.activity;
    if (a == null) return;

    _nameCtrl.text      = a.name;
    _descCtrl.text      = a.description;
    _locationCtrl.text  = a.location;
    _priceCtrl.text     = a.price.toInt().toString();
    _capacityCtrl.text  = a.capacity.toString();
    _latCtrl.text       = (a.latitude ?? '').toString();
    _lngCtrl.text       = (a.longitude ?? '').toString();
    _categoryId         = a.categoryId;
    if (a.eventDate != null) {
    final localEvent = a.eventDate!.toLocal();
    _eventDate = DateTime(localEvent.year, localEvent.month, localEvent.day);
    _eventTime = TimeOfDay(hour: localEvent.hour, minute: localEvent.minute);
    }
    if (a.registrationDeadline != null) {
      final localDeadline = a.registrationDeadline!.toLocal();
      _registrationDeadline = DateTime(localDeadline.year, localDeadline.month, localDeadline.day);
    }
    _existingImages     = List.from(a.images);
    _benefits.addAll(a.benefits);
    _speakers.addAll(a.speakers.map((s) => {
      'name': s['name']?.toString() ?? '',
      'title': s['title']?.toString() ?? '',
    }));
    _discountType       = a.discountType ?? '';
    if (a.discountValue != null && a.discountValue! > 0) {
      _discountValCtrl.text = a.discountValue!.toInt().toString();
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _descCtrl, _locationCtrl, _priceCtrl, _capacityCtrl,
      _latCtrl, _lngCtrl, _discountValCtrl, _speakerNameCtrl, _speakerTitleCtrl,
      _benefitCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _pickImages() async {
    final total = _existingImages.length + _newImages.length;
    if (total >= 10) { _snack('Maksimal 10 foto.', isError: true); return; }
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isEmpty) return;
    setState(() => _newImages.addAll(picked.take(10 - total)));
  }

  Future<void> _pickEventDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.activity),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  Future<void> _pickEventTime() async {
  final picked = await showTimePicker(
    context: context,
    initialTime: _eventTime ?? const TimeOfDay(hour: 9, minute: 0),
    builder: (ctx, child) => Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: const ColorScheme.light(primary: AppColors.activity),
      ),
      child: child!,
    ),
  );
  if (picked != null) setState(() => _eventTime = picked);
}

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _registrationDeadline ?? DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: _eventDate ?? DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.activity),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _registrationDeadline = picked);
  }

  String _combineDateTimeToUtcString(DateTime date, TimeOfDay? time) {
  final localCombined = DateTime(
    date.year, date.month, date.day,
    time?.hour ?? 0, time?.minute ?? 0,
  );
  final utc = localCombined.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${utc.year}-${two(utc.month)}-${two(utc.day)} ${two(utc.hour)}:${two(utc.minute)}:00';
}

Future<FormData> _buildFormData() async {
  final fields = <MapEntry<String, dynamic>>[
    MapEntry('name',        _nameCtrl.text.trim()),
    MapEntry('description', _descCtrl.text.trim()),
    MapEntry('location',    _locationCtrl.text.trim()),
    MapEntry('price',       _priceCtrl.text.trim()),
    MapEntry('capacity',    _capacityCtrl.text.trim()),
    if (_categoryId != null) MapEntry('category_id', _categoryId.toString()),
    if (_eventDate != null)
      MapEntry('event_date', _combineDateTimeToUtcString(_eventDate!, _eventTime)),
    if (_registrationDeadline != null)
      MapEntry('registration_deadline',
          _combineDateTimeToUtcString(_registrationDeadline!, const TimeOfDay(hour: 23, minute: 59)))
    else if (_eventDate != null)
      MapEntry('registration_deadline', _combineDateTimeToUtcString(
          _eventDate!.subtract(const Duration(days: 1)), const TimeOfDay(hour: 23, minute: 59))),
    if (_latCtrl.text.isNotEmpty) MapEntry('latitude', _latCtrl.text.trim()),
    if (_lngCtrl.text.isNotEmpty) MapEntry('longitude', _lngCtrl.text.trim()),
    if (_discountType.isNotEmpty) MapEntry('discount_type', _discountType),
    if (_discountType.isNotEmpty && _discountValCtrl.text.isNotEmpty)
      MapEntry('discount_value', _discountValCtrl.text.trim()),
  ];

  for (int i = 0; i < _benefits.length; i++) {
    fields.add(MapEntry('benefits[$i]', _benefits[i]));
  }
  for (int i = 0; i < _speakers.length; i++) {
    fields.add(MapEntry('speakers[$i][name]',  _speakers[i]['name'] ?? ''));
    fields.add(MapEntry('speakers[$i][title]', _speakers[i]['title'] ?? ''));
  }

  final imageFiles = <MapEntry<String, MultipartFile>>[];
  for (int i = 0; i < _newImages.length; i++) {
    imageFiles.add(MapEntry(
      'images[$i]',
      await MultipartFile.fromFile(_newImages[i].path, filename: 'img_$i.jpg'),
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
      _snack('Tambahkan minimal 1 foto acara.', isError: true);
      return;
    }
    if (_eventDate == null) {
    _snack('Tanggal acara wajib dipilih.', isError: true);
    return;
  }
  if (_eventTime == null) {
    _snack('Jam mulai acara wajib dipilih.', isError: true);
    return;
  }
  if (_registrationDeadline == null) {
    _snack('Batas pendaftaran wajib dipilih.', isError: true);
    return;
  }
  final eventDateTime = DateTime(_eventDate!.year, _eventDate!.month, _eventDate!.day, _eventTime!.hour, _eventTime!.minute);
  final deadlineDateTime = DateTime(_registrationDeadline!.year, _registrationDeadline!.month, _registrationDeadline!.day, 23, 59);
  if (!deadlineDateTime.isBefore(eventDateTime)) {
    _snack('Batas pendaftaran harus sebelum tanggal acara.', isError: true);
    return;
  }
  if (!eventDateTime.isAfter(DateTime.now())) {
    _snack('Tanggal & jam acara harus setelah sekarang.', isError: true);
    return;
  }

    final prov = context.read<ProviderActivityProvider>();
    final formData = await _buildFormData();
    bool ok;

    if (_isEdit) {
      ok = await prov.updateActivity(widget.activity!.id, formData);
    } else {
      ok = await prov.createActivity(formData);
    }

    if (mounted) {
      if (ok) {
        _snack(_isEdit ? 'Acara berhasil diperbarui!' : 'Acara berhasil ditambahkan!');
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

  void _showSpeakerDialog({int? editIndex}) {
    if (editIndex != null) {
      _speakerNameCtrl.text  = _speakers[editIndex]['name'] ?? '';
      _speakerTitleCtrl.text = _speakers[editIndex]['title'] ?? '';
    } else {
      _speakerNameCtrl.clear();
      _speakerTitleCtrl.clear();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          editIndex != null ? 'Edit Pembicara' : 'Tambah Pembicara',
          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _speakerNameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Pembicara'),
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _speakerTitleCtrl,
              decoration: const InputDecoration(labelText: 'Jabatan / Institusi'),
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.activity),
            onPressed: () {
              final name = _speakerNameCtrl.text.trim();
              if (name.isEmpty) return;
              setState(() {
                final entry = {
                  'name': name,
                  'title': _speakerTitleCtrl.text.trim(),
                };
                if (editIndex != null) {
                  _speakers[editIndex] = entry;
                } else {
                  _speakers.add(entry);
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
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
        title: Text(
          _isEdit ? 'Edit Acara' : 'Tambah Acara',
          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        actions: [
          Consumer<ProviderActivityProvider>(
            builder: (_, prov, __) => TextButton(
              onPressed: prov.isSaving ? null : _submit,
              child: prov.isSaving
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.activity))
                  : const Text('Simpan',
                      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: AppColors.activity)),
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
              _sectionTitle('Foto Acara', Icons.photo_library_outlined),
              const SizedBox(height: 10),
              _buildPhotoSection(),
              const SizedBox(height: 20),

              // ── Informasi Umum ────────────────────────
              _sectionTitle('Informasi Acara', Icons.info_outline),
              const SizedBox(height: 10),
              _buildCard(
                child: Column(
                  children: [
                    _field(
                      ctrl: _nameCtrl,
                      label: 'Nama Acara',
                      hint: 'Cth: Seminar AI & Future of Work',
                      validator: (v) => (v?.trim().isEmpty ?? true) ? 'Nama wajib diisi' : null,
                    ),
                    const SizedBox(height: 14),
                    _field(
                      ctrl: _descCtrl,
                      label: 'Deskripsi',
                      hint: 'Jelaskan acara kamu...',
                      maxLines: 4,
                      validator: (v) => (v?.trim().isEmpty ?? true) ? 'Deskripsi wajib diisi' : null,
                    ),
                    const SizedBox(height: 14),
                    _field(
                      ctrl: _locationCtrl,
                      label: 'Lokasi',
                      hint: 'Cth: Aula Gedung Rektorat Lt. 3',
                      validator: (v) => (v?.trim().isEmpty ?? true) ? 'Lokasi wajib diisi' : null,
                    ),
                    const SizedBox(height: 14),
                    Consumer<ProviderActivityProvider>(
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

              // ── Tanggal ───────────────────────────────
              _sectionTitle('Jadwal', Icons.calendar_month_outlined),
              const SizedBox(height: 10),
              _buildCard(
                child: Column(
                  children: [
                    _datePicker(
                      label: 'Tanggal Acara *',
                      value: _eventDate,
                      onTap: _pickEventDate,
                    ),
                    const SizedBox(height: 14),
                    _timePicker(
                      label: 'Jam Mulai Acara *',
                      value: _eventTime,
                      onTap: _pickEventTime,
                    ),
                    const SizedBox(height: 14),
                    _datePicker(
                      label: 'Batas Pendaftaran',
                      value: _registrationDeadline,
                      onTap: _pickDeadline,
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
                            hint: '0 = Gratis',
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
                            hint: '100',
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (v) => (v?.trim().isEmpty ?? true) ? 'Kapasitas wajib diisi' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
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
                        hint: _discountType == 'percentage' ? '10' : '50000',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Pembicara ─────────────────────────────
              _sectionTitle('Pembicara', Icons.record_voice_over_outlined),
              const SizedBox(height: 10),
              _buildSpeakersSection(),
              const SizedBox(height: 20),

              // ── Manfaat / Benefits ────────────────────
              _sectionTitle('Manfaat Peserta', Icons.checklist_rounded),
              const SizedBox(height: 10),
              _buildBenefitsSection(),
              const SizedBox(height: 20),

              // ── Lokasi GPS (Opsional) ─────────────────
              _sectionTitle('Koordinat GPS (Opsional)', Icons.map_outlined),
              const SizedBox(height: 10),
              _buildCard(
                child: Column(
                  children: [
                    _field(ctrl: _latCtrl, label: 'Latitude', hint: '-6.914744'),
                    const SizedBox(height: 14),
                    _field(ctrl: _lngCtrl, label: 'Longitude', hint: '107.609810'),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Submit ────────────────────────────────
              Consumer<ProviderActivityProvider>(
                builder: (_, prov, __) => ElevatedButton(
                  onPressed: prov.isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.activity,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: prov.isSaving
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(
                          _isEdit ? 'Perbarui Acara' : 'Buat Acara',
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

  Widget _buildPhotoSection() {
    final allImages = [
      ..._existingImages.map((url) => _PhotoItem(url: url)),
      ..._newImages.map((x) => _PhotoItem(path: x.path)),
    ];

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (allImages.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: allImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final item = allImages[i];
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: item.url != null
                            ? EduImage(path: item.url, width: 100, height: 100, fit: BoxFit.cover, borderRadius: 10)
                            : Image.file(File(item.path!), width: 100, height: 100, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 4, right: 4,
                        child: GestureDetector(
                          onTap: () => setState(() {
                            if (item.url != null) { _existingImages.remove(item.url); }
                            else { _newImages.removeWhere((x) => x.path == item.path); }
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white, size: 12),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          if (allImages.isNotEmpty) const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _pickImages,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.activity,
              side: const BorderSide(color: AppColors.activity),
              minimumSize: const Size(double.infinity, 44),
            ),
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text('${allImages.isEmpty ? 'Tambah' : 'Tambah Lagi'} Foto (${allImages.length}/10)'),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeakersSection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._speakers.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.activityLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.activitySurface),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.activitySurface,
                    child: Icon(Icons.person_rounded, color: AppColors.activity, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['name'] ?? '', style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700)),
                        if ((s['title'] ?? '').isNotEmpty)
                          Text(s['title']!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.activity), onPressed: () => _showSpeakerDialog(editIndex: i)),
                  IconButton(icon: const Icon(Icons.close, size: 16, color: AppColors.error), onPressed: () => setState(() => _speakers.removeAt(i))),
                ],
              ),
            );
          }),
          OutlinedButton.icon(
            onPressed: () => _showSpeakerDialog(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.activity,
              side: const BorderSide(color: AppColors.activity),
              minimumSize: const Size(double.infinity, 44),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tambah Pembicara'),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _benefitCtrl,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Cth: Sertifikat, Snack, E-book...',
                    hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textHint),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.activity, width: 2)),
                  ),
                  onFieldSubmitted: (_) => _addBenefit(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _addBenefit,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.activity,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          if (_benefits.isNotEmpty) ...[
            const SizedBox(height: 10),
            ..._benefits.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.activity, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(b, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13))),
                  GestureDetector(
                    onTap: () => setState(() => _benefits.remove(b)),
                    child: const Icon(Icons.close, color: AppColors.textHint, size: 16),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  void _addBenefit() {
    final v = _benefitCtrl.text.trim();
    if (v.isEmpty || _benefits.contains(v)) return;
    setState(() { _benefits.add(v); _benefitCtrl.clear(); });
  }

  Widget _datePicker({required String label, required DateTime? value, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 18, color: value != null ? AppColors.activity : AppColors.textHint),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value != null ? formatDate(value) : label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: value != null ? AppColors.textPrimary : AppColors.textHint,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  Widget _timePicker({required String label, required TimeOfDay? value, required VoidCallback onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time_rounded, size: 18, color: value != null ? AppColors.activity : AppColors.textHint),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value != null
                  ? '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')} WIB'
                  : label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: value != null ? AppColors.textPrimary : AppColors.textHint,
              ),
            ),
          ),
          const Icon(Icons.arrow_drop_down, color: AppColors.textHint),
        ],
      ),
    ),
  );
}

  Widget _sectionTitle(String title, IconData icon) => Row(
    children: [
      Icon(icon, color: AppColors.activity, size: 18),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
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
      decoration: InputDecoration(labelText: label, hintText: hint, alignLabelWithHint: maxLines > 1),
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

class _PhotoItem { final String? url; final String? path; _PhotoItem({this.url, this.path}); }
