import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../providers/provider_residence_provider.dart';
import '../../models/provider_models.dart';
import 'provider_residence_form_screen.dart';

class ProviderResidenceListScreen extends StatefulWidget {
  const ProviderResidenceListScreen({super.key});

  @override
  State<ProviderResidenceListScreen> createState() => _ProviderResidenceListScreenState();
}

class _ProviderResidenceListScreenState extends State<ProviderResidenceListScreen> {
  String? _filterType;
    final _typeFilters = const [
      {'value': null,         'label': 'Semua'},
      {'value': 'kos',        'label': 'Kos'},
      {'value': 'kontrakan',  'label': 'Kontrakan'},
      {'value': 'rumah_sewa', 'label': 'Rumah Sewa'},
      {'value': 'apartemen',  'label': 'Apartemen'},
    ];
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderResidenceProvider>().loadResidences(refresh: true);
    });
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent - 200) {
        context.read<ProviderResidenceProvider>().loadResidences();
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.residenceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.home_work_rounded, color: AppColors.residence, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Kelola Hunian',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.residence),
            tooltip: 'Tambah Hunian',
            onPressed: () => _goToForm(context),
          ),
        ],
      ),
        body: Column(
    children: [
      Container(
        color: AppColors.white,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _typeFilters.map((f) {
              final isSelected = _filterType == f['value'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(f['label'] as String,
                    style: TextStyle(
                      fontFamily: 'Poppins', fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _filterType = f['value'] as String?);
                    context.read<ProviderResidenceProvider>()
                        .loadResidences(refresh: true, filterType: f['value'] as String?);
                  },
                  selectedColor: AppColors.residence,
                  backgroundColor: AppColors.background,
                  side: BorderSide(
                    color: isSelected ? AppColors.residence : AppColors.border,
                    width: 0.8,
                  ),
                  showCheckmark: false,
                ),
              );
            }).toList(),
          ),
        ),
      ),
      Expanded(
        child: Consumer<ProviderResidenceProvider>(
          builder: (_, prov, __) {
            if (prov.isLoading) {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 4,
                itemBuilder: (_, __) => _ResidenceSkelCard(),
              );
            }
            if (prov.error != null && prov.residences.isEmpty) {
              return ErrorState(
                message: prov.error!,
                onRetry: () => prov.loadResidences(refresh: true),
              );
            }
            if (prov.residences.isEmpty) {
              return EmptyState(
                message: 'Belum ada hunian.\nTambahkan listing pertamamu!',
                icon: Icons.home_work_outlined,
                iconColor: AppColors.residence,
                action: ElevatedButton.icon(
                  onPressed: () => _goToForm(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Tambah Hunian'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.residence,
                    minimumSize: const Size(160, 44),
                  ),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () => prov.loadResidences(refresh: true),
              color: AppColors.residence,
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: prov.residences.length + (prov.isLoadingMore ? 1 : 0),
                itemBuilder: (ctx, i) {
                  if (i == prov.residences.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.residence),
                      ),
                    );
                  }
                  final r = prov.residences[i];
                  return _ProviderResidenceCard(
                    residence: r,
                    onEdit: () => _goToForm(context, residence: r),
                    onDelete: () => _confirmDelete(context, r, prov),
                    onToggle: () => prov.toggleStatus(r.id),
                  );
                },
              ),
            );
          },
        ),
      ),
    ],
  ),
);
}

  void _goToForm(BuildContext ctx, {ProviderResidenceModel? residence}) {
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => ProviderResidenceFormScreen(residence: residence),
      ),
    );
  }

  void _confirmDelete(
    BuildContext ctx,
    ProviderResidenceModel r,
    ProviderResidenceProvider prov,
  ) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Hunian?',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Text(
          '${r.name} akan dihapus. Pastikan tidak ada booking aktif.',
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await prov.deleteResidence(r.id);
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text(ok ? 'Hunian dihapus.' : prov.error ?? 'Gagal menghapus.'),
                  backgroundColor: ok ? AppColors.success : AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ));
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

// ── Card Hunian (versi provider) ──────────────────────────
class _ProviderResidenceCard extends StatelessWidget {
  final ProviderResidenceModel residence;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _ProviderResidenceCard({
    required this.residence,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar
          Stack(
            children: [
              EduImage(
                path: residence.mainImage,
                height: 160,
                borderRadius: 14,
                placeholderIcon: Icons.home_work_outlined,
                placeholderColor: AppColors.residenceLight,
                iconColor: AppColors.residence,
              ),
              // Badge tipe
              Positioned(
                top: 10,
                left: 10,
                child: _badge(residence.residenceType, Colors.black54, Colors.white),
              ),
              // Badge status
              Positioned(
                top: 10,
                right: 10,
                child: _badge(
                  residence.isActive ? 'Aktif' : 'Nonaktif',
                  residence.isActive ? AppColors.success : AppColors.textSecondary,
                  Colors.white,
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  residence.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textHint),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      residence.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatRupiah(residence.price, suffix: '/bln'),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.residence,
                            ),
                          ),
                          Text(
                            '${residence.availableSlots}/${residence.capacity} slot tersedia  ·  ${residence.bookingsCount} booking',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Tombol Aksi
                Row(
                  children: [
                    // Toggle aktif
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onToggle,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: residence.isActive
                              ? AppColors.textSecondary
                              : AppColors.success,
                          side: BorderSide(
                            color: residence.isActive
                                ? AppColors.border
                                : AppColors.success,
                          ),
                          minimumSize: const Size(0, 38),
                        ),
                        icon: Icon(
                          residence.isActive
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 15,
                        ),
                        label: Text(
                          residence.isActive ? 'Nonaktifkan' : 'Aktifkan',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Edit
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                      tooltip: 'Edit',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Hapus
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                      tooltip: 'Hapus',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.errorLight,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(
      label,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: fg,
      ),
    ),
  );
}

// ── Skeleton ──────────────────────────────────────────────
class _ResidenceSkelCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: double.infinity, height: 160, borderRadius: 14),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 220, height: 16),
                const SizedBox(height: 8),
                SkeletonBox(width: 170, height: 13),
                const SizedBox(height: 12),
                SkeletonBox(width: 120, height: 18),
                const SizedBox(height: 6),
                SkeletonBox(width: 200, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
