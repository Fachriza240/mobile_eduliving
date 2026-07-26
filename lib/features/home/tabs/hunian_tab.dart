import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../residence/providers/residence_provider.dart';
import '../../residence/screens/residence_detail_screen.dart';

class HunianTab extends StatefulWidget {
  final bool showBackButton;
  const HunianTab({super.key, this.showBackButton = false});

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
        automaticallyImplyLeading: widget.showBackButton,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
                onPressed: () => Navigator.pop(context),
              )
            : null,
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
            child: Row(
              children: [
                Expanded(
                  child: EduSearchBar(
                    controller: _searchCtrl,
                    hint: 'Cari hunian, lokasi...',
                    onChanged: (q) =>
                        context.read<ResidenceProvider>().setSearch(q),
                    onClear: () =>
                        context.read<ResidenceProvider>().setSearch(''),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _showFilterSheet,
                  child: Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: AppColors.residence.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.tune,
                        color: AppColors.residence, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Active filter chips
          Consumer<ResidenceProvider>(
            builder: (context, p, _) {
              final hasFilter =
                  p.selectedCategory.isNotEmpty || 
                  p.selectedKosType != null || 
                  p.selectedRentalPeriod != null;
              if (!hasFilter) return const SizedBox.shrink();
              return Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (p.selectedCategory.isNotEmpty)
                              _ActiveFilterChip(
                                label: p.selectedCategory.toUpperCase(),
                                onRemove: () => p.setFilter(
                                    category: '',
                                    kosType: null,
                                    rentalPeriod: p.selectedRentalPeriod,
                                    minPrice: p.minPrice,
                                    maxPrice: p.maxPrice,
                                    sortBy: p.sortBy),
                              ),
                            if (p.selectedKosType != null)
                              Padding(
                                padding: p.selectedCategory.isNotEmpty
                                    ? const EdgeInsets.only(left: 8)
                                    : EdgeInsets.zero,
                                child: _ActiveFilterChip(
                                  label: 'Kos ${p.selectedKosType}'.toUpperCase(),
                                  onRemove: () => p.setFilter(
                                      category: p.selectedCategory,
                                      kosType: null,
                                      rentalPeriod: p.selectedRentalPeriod,
                                      minPrice: p.minPrice,
                                      maxPrice: p.maxPrice,
                                      sortBy: p.sortBy),
                                ),
                              ),
                            if (p.selectedRentalPeriod != null)
                              Padding(
                                padding: (p.selectedCategory.isNotEmpty || p.selectedKosType != null)
                                    ? const EdgeInsets.only(left: 8)
                                    : EdgeInsets.zero,
                                child: _ActiveFilterChip(
                                  label: (p.selectedRentalPeriod == 'monthly' ? 'Bulanan' : 'Tahunan').toUpperCase(),
                                  onRemove: () => p.setFilter(
                                      category: p.selectedCategory,
                                      kosType: p.selectedKosType,
                                      rentalPeriod: null,
                                      minPrice: p.minPrice,
                                      maxPrice: p.maxPrice,
                                      sortBy: p.sortBy),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => p.clearFilter(),
                      child: const Text(
                        'Reset filter',
                        style: TextStyle(
                          color: AppColors.residence,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _FilterSheet(),
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
                    builder: (_) => ResidenceDetailScreen(id: r.id),
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
                  width: double.infinity,
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

class _FilterSheet extends StatefulWidget {
  const _FilterSheet();

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String _category = '';
  String? _kosType;
  String? _rentalPeriod;
  double? _minPrice;
  double? _maxPrice;
  String? _sortBy;
  RangeValues _priceRange = const RangeValues(0, 5000000);

  @override
  void initState() {
    super.initState();
    final p = context.read<ResidenceProvider>();
    _category = p.selectedCategory;
    _kosType = p.selectedKosType;
    _rentalPeriod = p.selectedRentalPeriod;
    _minPrice = p.minPrice;
    _maxPrice = p.maxPrice;
    _sortBy = p.sortBy;
    
    double min = p.minPrice ?? 0;
    double max = p.maxPrice ?? 5000000;
    _priceRange = RangeValues(min, max);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filter Hunian',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Tipe Hunian',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChipUI(
                  label: 'Semua',
                  value: '',
                  selected: _category,
                  onTap: (v) => setState(() {
                        _category = v!;
                        _kosType = null;
                      })),
              _FilterChipUI(
                  label: 'Kos',
                  value: 'kos',
                  selected: _category,
                  onTap: (v) => setState(() => _category = v!)),
              _FilterChipUI(
                  label: 'Kontrakan',
                  value: 'kontrakan',
                  selected: _category,
                  onTap: (v) => setState(() {
                        _category = v!;
                        _kosType = null;
                      })),
              _FilterChipUI(
                  label: 'Apartemen',
                  value: 'apartemen',
                  selected: _category,
                  onTap: (v) => setState(() {
                        _category = v!;
                        _kosType = null;
                      })),
            ],
          ),
          if (_category == 'kos') ...[
            const SizedBox(height: 16),
            const Text('Tipe Kos',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChipUI(
                    label: 'Semua',
                    value: null,
                    selected: _kosType,
                    onTap: (v) => setState(() => _kosType = v)),
                _FilterChipUI(
                    label: 'Putra',
                    value: 'putra',
                    selected: _kosType,
                    onTap: (v) => setState(() => _kosType = v)),
                _FilterChipUI(
                    label: 'Putri',
                    value: 'putri',
                    selected: _kosType,
                    onTap: (v) => setState(() => _kosType = v)),
                _FilterChipUI(
                    label: 'Campur',
                    value: 'campur',
                    selected: _kosType,
                    onTap: (v) => setState(() => _kosType = v)),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const Text('Periode Sewa',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChipUI(
                  label: 'Semua',
                  value: null,
                  selected: _rentalPeriod,
                  onTap: (v) => setState(() => _rentalPeriod = v)),
              _FilterChipUI(
                  label: 'Bulanan',
                  value: 'monthly',
                  selected: _rentalPeriod,
                  onTap: (v) => setState(() => _rentalPeriod = v)),
              _FilterChipUI(
                  label: 'Tahunan',
                  value: 'yearly',
                  selected: _rentalPeriod,
                  onTap: (v) => setState(() => _rentalPeriod = v)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Rentang Harga (Per Bulan)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formatRupiah(_priceRange.start), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text(formatRupiah(_priceRange.end), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 5000000,
            divisions: 50,
            activeColor: AppColors.residence,
            inactiveColor: AppColors.border,
            labels: RangeLabels(
              formatRupiah(_priceRange.start),
              formatRupiah(_priceRange.end),
            ),
            onChanged: (values) {
              setState(() {
                _priceRange = values;
                _minPrice = values.start;
                _maxPrice = values.end;
              });
            },
          ),
          
          const SizedBox(height: 16),
          const Text('Urutkan Berdasarkan',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChipUI(
                  label: 'Terbaru',
                  value: null,
                  selected: _sortBy,
                  onTap: (v) => setState(() => _sortBy = v)),
              _FilterChipUI(
                  label: 'Termurah',
                  value: 'price_asc',
                  selected: _sortBy,
                  onTap: (v) => setState(() => _sortBy = v)),
              _FilterChipUI(
                  label: 'Termahal',
                  value: 'price_desc',
                  selected: _sortBy,
                  onTap: (v) => setState(() => _sortBy = v)),
              _FilterChipUI(
                  label: 'Rating Tertinggi',
                  value: 'rating_desc',
                  selected: _sortBy,
                  onTap: (v) => setState(() => _sortBy = v)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                context.read<ResidenceProvider>().setFilter(
                      category: _category,
                      kosType: _kosType,
                      rentalPeriod: _rentalPeriod,
                      minPrice: _minPrice,
                      maxPrice: _maxPrice,
                      sortBy: _sortBy,
                    );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.residence,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Terapkan Filter',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipUI extends StatelessWidget {
  final String label;
  final String? value;
  final String? selected;
  final Function(String?) onTap;

  const _FilterChipUI({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.residence : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.residence : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _ActiveFilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.residence.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.residence,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child:
                const Icon(Icons.close, size: 14, color: AppColors.residence),
          ),
        ],
      ),
    );
  }
}
