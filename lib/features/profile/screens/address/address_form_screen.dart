import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eduliving_mobile/core/constants/app_colors.dart';
import 'package:eduliving_mobile/features/profile/models/address_model.dart';
import 'package:eduliving_mobile/features/profile/providers/address_provider.dart';

class AddressFormScreen extends StatefulWidget {
  final AddressModel? address;

  const AddressFormScreen({super.key, this.address});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _labelCtrl;
  
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    final addr = widget.address;
    _nameCtrl = TextEditingController(text: addr?.recipientName ?? '');
    _phoneCtrl = TextEditingController(text: addr?.phone ?? '');
    _addressCtrl = TextEditingController(text: addr?.address ?? '');
    _labelCtrl = TextEditingController(text: addr?.label ?? 'Rumah');
    _isDefault = addr?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final prov = context.read<AddressProvider>();
    final data = {
      'recipient_name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'label': _labelCtrl.text.trim(),
      'is_default': _isDefault,
    };

    bool success;
    if (widget.address == null) {
      success = await prov.addAddress(data);
    } else {
      success = await prov.updateAddress(widget.address!.id, data);
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alamat berhasil disimpan')),
      );
      Navigator.pop(context, true);
    }
  }

  void _delete() async {
    final prov = context.read<AddressProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus Alamat?'),
        content: const Text('Alamat ini akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await prov.deleteAddress(widget.address!.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alamat berhasil dihapus')),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AddressProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.address == null ? 'Tambah Alamat Baru' : 'Ubah Alamat',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        actions: [
          if (widget.address != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: prov.isSaving ? null : _delete,
            ),
        ],
      ),
      body: prov.isSaving
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (prov.error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      color: AppColors.error.withValues(alpha: 0.1),
                      child: Text(
                        prov.error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  
                  const Text('Kontak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    validator: (v) => v!.isEmpty ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Nomor Telepon',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      prefixText: '(+62) ',
                    ),
                    validator: (v) => v!.isEmpty ? 'Nomor telepon wajib diisi' : null,
                  ),
                  
                  const SizedBox(height: 24),
                  const Text('Alamat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Nama Jalan, Gedung, No. Rumah',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    validator: (v) => v!.isEmpty ? 'Alamat lengkap wajib diisi' : null,
                  ),

                  const SizedBox(height: 24),
                  const Text('Pengaturan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _labelCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tandai Sebagai (Kantor, Rumah, dll)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SwitchListTile(
                    title: const Text('Atur sebagai Alamat Utama'),
                    subtitle: const Text('Alamat ini akan otomatis terpilih saat checkout'),
                    value: _isDefault,
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setState(() => _isDefault = val);
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: prov.isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: prov.isSaving 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text(
                            'Simpan',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
