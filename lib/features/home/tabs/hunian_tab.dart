import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../residence/providers/residence_provider.dart';
import '../../residence/screens/residence_list_screen.dart';

class HunianTab extends StatefulWidget {
  const HunianTab({super.key});

  @override
  State<HunianTab> createState() => _HunianTabState();
}

class _HunianTabState extends State<HunianTab> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  final _categories = const [
    {'id': '', 'label': 'Semua'},
    {'id': 'kos', 'label': 'Kos'},
    {'id': 'kontrakan', 'label': 'Kontrakan'},
    {'id': 'apartemen', 'label': 'Apartemen'},
    {'id': 'rumah_sewa', 'label': 'Rumah Sewa'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ResidenceProvider>().loadResidences(refresh: true);
    });

    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent - 200) {
        context.read<ResidenceProvider>().loadResidences();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
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
              child: const Icon(Icons.home_work_rounded,
                  color: AppColors.residence, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Hunian',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: EduSearchBar(
              controller: _searchCtrl,
              hint: 'Cari hunian, lokasi...',
              onChanged: (q) => context.read<ResidenceProvider>().setSearch(q),
              onClear: () => context.read<ResidenceProvider>().setSearch(''),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  // ── Filter Chip BIRU ──────────────────────────────
  Widget _buildCategoryFilter() {
    return Consumer<ResidenceProvider>(
      builder: (_, prov, __) => Container(
        height: 48,
        color: AppColors.white,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: _categories.length,
          itemBuilder: (_, i) => FilterChipWidget(
            label: _categories[i]['label']!,
            isSelected: prov.selectedCategory == _categories[i]['id'],
            onTap: () => prov.setCategory(_categories[i]['id']!),
            selectedColor: AppColors.residence,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Consumer<ResidenceProvider>(
      builder: (_, prov, __) {
        if (prov.isLoading) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            itemBuilder: (_, __) => const _ResidenceSkelCard(),
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
            message: 'Belum ada hunian.\nCoba ubah filter pencarian.',
            icon: Icons.home_work_outlined,
            iconColor: AppColors.residence,
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
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.residence),
                  ),
                );
              }
              final r = prov.residences[i];
              return _ResidenceCard(
                name: r.name,
                address: r.address,
                price: r.discountedPrice,
                originalPrice: r.price,
                hasDiscount: r.hasDiscount,
                period: r.rentalPeriod,
                image: r.mainImage,
                slots: r.availableSlots ?? 0,
                isAvailable: r.isAvailable,
                rating: r.ratingAverage ?? 0,
                ratingCount: r.ratingCount ?? 0,
                category: r.categoryName,
                facilities: r.facilities.take(3).toList(),
                onTap: () => Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => ResidenceListScreen(initialId: r.id),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────
// CARD HUNIAN — BIRU
// ─────────────────────────────────────────────────────
class _ResidenceCard extends StatelessWidget {
  final String name, address, image, category;
  final double price, originalPrice;
  final double rating;
  final int ratingCount, slots;
  final bool isAvailable, hasDiscount;
  final String? period;
  final List<String> facilities;
  final VoidCallback onTap;

  const _ResidenceCard({
    required this.name,
    required this.address,
    required this.price,
    required this.originalPrice,
    required this.hasDiscount,
    required this.image,
    required this.slots,
    required this.isAvailable,
    required this.rating,
    required this.ratingCount,
    required this.category,
    required this.facilities,
    required this.period,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Gambar ────────────────────────
            Stack(children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
                child: EduImage(
                  path: image,
                  height: 175,
                  borderRadius: 0,
                  placeholderIcon: Icons.home_work_outlined,
                  placeholderColor: AppColors.residenceLight,
                  iconColor: AppColors.residence,
                ),
              ),
              if (category != '-')
                Positioned(
                  top: 12,
                  left: 12,
                  child: _badge(category, Colors.black54, Colors.white),
                ),
              if (hasDiscount)
                Positioned(
                  top: 12,
                  right: 12,
                  child: _badge('DISKON', AppColors.error, Colors.white),
                ),
              if (!isAvailable)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text('PENUH',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                ),
            ]),

            // ── Info ──────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 5),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 13, color: AppColors.textHint),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                    ),
                  ]),

                  // Fasilitas chip biru
                  if (facilities.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: facilities
                          .map(
                            (f) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.residenceLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(f,
                                  style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 10,
                                      color: AppColors.residence,
                                      fontWeight: FontWeight.w500)),
                            ),
                          )
                          .toList(),
                    ),
                  ],

                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasDiscount)
                            Text(
                              formatRupiah(originalPrice),
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: AppColors.textHint,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          // Harga BIRU
                          Text(
                            formatRupiah(price, suffix: '/${_short(period)}'),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.residence,
                            ),
                          ),
                        ],
                      ),
                      Row(children: [
                        StarRating(rating: rating, reviewCount: ratingCount),
                        const SizedBox(width: 10),
                        if (isAvailable)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.residenceSurface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('$slots slot',
                                style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.residence)),
                          ),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: fg)),
      );

  String _short(String? p) {
    switch (p) {
      case 'monthly':
        return 'bln';
      case 'yearly':
        return 'thn';
      case 'daily':
        return 'hari';
      default:
        return 'bln';
    }
  }
}

// ─────────────────────────────────────────────────────
// SKELETON
// ─────────────────────────────────────────────────────
class _ResidenceSkelCard extends StatelessWidget {
  const _ResidenceSkelCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
          color: AppColors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: double.infinity, height: 175, borderRadius: 14),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 220, height: 16),
                const SizedBox(height: 8),
                SkeletonBox(width: 160, height: 13),
                const SizedBox(height: 10),
                Row(children: [
                  SkeletonBox(width: 60, height: 22, borderRadius: 6),
                  const SizedBox(width: 6),
                  SkeletonBox(width: 60, height: 22, borderRadius: 6),
                ]),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonBox(width: 110, height: 20),
                    SkeletonBox(width: 60, height: 20),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
