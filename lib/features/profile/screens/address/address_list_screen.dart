import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eduliving_mobile/core/constants/app_colors.dart';
import 'package:eduliving_mobile/features/profile/models/address_model.dart';
import 'package:eduliving_mobile/features/profile/providers/address_provider.dart';
import 'package:eduliving_mobile/features/profile/screens/address/address_form_screen.dart';

class AddressListScreen extends StatefulWidget {
  final bool isSelecting;
  final AddressModel? selectedAddress;

  const AddressListScreen({
    super.key,
    this.isSelecting = false,
    this.selectedAddress,
  });

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AddressProvider>().fetchAddresses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isSelecting ? 'Pilih Alamat' : 'Alamat Saya',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: Consumer<AddressProvider>(
        builder: (context, prov, child) {
          if (prov.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (prov.addresses.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada alamat tersimpan.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: prov.fetchAddresses,
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 80), // for fab space
              itemCount: prov.addresses.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final address = prov.addresses[index];
                final isSelected = widget.isSelecting &&
                    widget.selectedAddress?.id == address.id;

                return InkWell(
                  onTap: () {
                    if (widget.isSelecting) {
                      Navigator.pop(context, address);
                    } else {
                      _goToForm(context, address: address);
                    }
                  },
                  child: Container(
                    color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.isSelecting) ...[
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: isSelected ? AppColors.primary : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      address.recipientName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '(+62) ${address.phone}',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                address.address,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [
                                  if (address.label.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        address.label,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  if (address.isDefault)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: AppColors.primary),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Utama',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (widget.isSelecting)
                          TextButton(
                            onPressed: () => _goToForm(context, address: address),
                            child: const Text('Ubah'),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () => _goToForm(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Tambah Alamat Baru',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  void _goToForm(BuildContext context, {AddressModel? address}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddressFormScreen(address: address),
      ),
    );
    if (result == true) {
      if (mounted) {
        context.read<AddressProvider>().fetchAddresses();
      }
    }
  }
}
