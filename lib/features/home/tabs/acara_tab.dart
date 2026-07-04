import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../activity/providers/activity_provider.dart';
import '../../activity/screens/activity_detail_screen.dart';

class AcaraTab extends StatefulWidget {
  final bool showBackButton;
  const AcaraTab({super.key, this.showBackButton = false});

  @override
  State<AcaraTab> createState() => _AcaraTabState();
}

const _kCategories = [
  {'id': '', 'label': 'Semua'},
  {'id': 'seminar', 'label': 'Seminar'},
  {'id': 'workshop', 'label': 'Workshop'},
  {'id': 'kompetisi', 'label': 'Kompetisi'},
  {'id': 'webinar', 'label': 'Webinar'},
  {'id': 'pelatihan', 'label': 'Pelatihan'},
];

class _AcaraTabState extends State<AcaraTab>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late TabController _tabCtrl;

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _FilterSheet(),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityProvider>().loadActivities(refresh: true);
    });

    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent - 200) {
        context.read<ActivityProvider>().loadActivities();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _tabCtrl.dispose();
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
                color: AppColors.activityLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.event_rounded,
                  color: AppColors.activity, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Acara',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            children: [
              // Search bar & Filter
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: EduSearchBar(
                        controller: _searchCtrl,
                        hint: 'Cari acara, seminar...',
                        onChanged: (q) =>
                            context.read<ActivityProvider>().setSearch(q),
                        onClear: () => context.read<ActivityProvider>().setSearch(''),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _showFilterSheet,
                      child: Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          color: AppColors.activity.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.tune,
                            color: AppColors.activity, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              // Tab bar HIJAU
              TabBar(
                controller: _tabCtrl,
                labelColor: AppColors.activity,
                unselectedLabelColor: AppColors.textHint,
                indicatorColor: AppColors.activity,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Mendatang'),
                  Tab(text: 'Sudah Selesai'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Active filter chip
          Consumer<ActivityProvider>(
            builder: (context, p, _) {
              if (p.selectedCategory.isEmpty) return const SizedBox.shrink();
              return Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: Row(
                  children: [
                    _ActiveFilterChip(
                      label: p.selectedCategory.toUpperCase(),
                      onRemove: () => p.setCategory(''),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => p.setCategory(''),
                      child: const Text(
                        'Reset filter',
                        style: TextStyle(
                          color: AppColors.activity,
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
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildList(upcoming: true),
                _buildList(upcoming: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList({required bool upcoming}) {
    return Consumer<ActivityProvider>(
      builder: (_, prov, __) {
        if (prov.isLoading) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            itemBuilder: (_, __) => const _AcaraSkelCard(),
          );
        }

        final filtered = prov.activities
            .where((a) => upcoming ? !a.isEventPassed : a.isEventPassed)
            .toList();

        if (prov.error != null && prov.activities.isEmpty) {
          return ErrorState(
            message: prov.error!,
            onRetry: () => prov.loadActivities(refresh: true),
          );
        }

        if (filtered.isEmpty) {
          return EmptyState(
            message: upcoming
                ? 'Belum ada acara mendatang.\nCek kembali nanti!'
                : 'Belum ada acara yang selesai.',
            icon: Icons.event_outlined,
            iconColor: AppColors.activity,
          );
        }

        return RefreshIndicator(
          onRefresh: () => prov.loadActivities(refresh: true),
          color: AppColors.activity,
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length + (prov.isLoadingMore ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (i == filtered.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.activity),
                  ),
                );
              }
              final a = filtered[i];
              return _AcaraCard(
                name: a.name,
                providerName: a.providerName,
                category: a.categoryName,
                image: a.mainImage,
                eventDate: a.eventDate,
                price: a.discountedPrice,
                isFree: a.isFree,
                slots: a.availableSlots ?? 0,
                isAvailable: a.isAvailable,
                isPassed: a.isEventPassed,
                isDeadlinePassed: a.isDeadlinePassed,
                location: a.location,
                onTap: () => Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => ActivityDetailScreen(id: a.id),
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
// CARD ACARA — HIJAU
// ─────────────────────────────────────────────────────
class _AcaraCard extends StatelessWidget {
  final String name, providerName, category, image;
  final DateTime? eventDate;
  final double price;
  final int slots;
  final bool isFree, isAvailable, isPassed, isDeadlinePassed;
  final String? location;
  final VoidCallback onTap;

  const _AcaraCard({
    required this.name,
    required this.providerName,
    required this.category,
    required this.image,
    required this.eventDate,
    required this.price,
    required this.isFree,
    required this.slots,
    required this.isAvailable,
    required this.isPassed,
    required this.isDeadlinePassed,
    required this.location,
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
                  height: 160,
                  borderRadius: 0,
                  placeholderIcon: Icons.event_outlined,
                  placeholderColor: AppColors.activityLight,
                  iconColor: AppColors.activity,
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: _badge(category, Colors.black54, Colors.white),
              ),
              if (isFree)
                Positioned(
                  top: 12,
                  right: 12,
                  child: _badge('GRATIS', AppColors.activity, Colors.white),
                ),
              if (isPassed)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text('SELESAI',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                ),
              if (!isPassed && isDeadlinePassed)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: _badge('DITUTUP', AppColors.error, Colors.white),
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
                  const SizedBox(height: 6),

                  // Penyelenggara
                  Row(children: [
                    const Icon(Icons.business_outlined,
                        size: 13, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(providerName,
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                  ]),
                  const SizedBox(height: 4),

                  // Tanggal HIJAU
                  Row(children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 13, color: AppColors.activity),
                    const SizedBox(width: 4),
                    Text(
                      formatDateShort(eventDate),
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.activity),
                    ),
                    if (location != null) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: AppColors.textHint),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(location!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      ),
                    ],
                  ]),

                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Harga HIJAU
                      Text(
                        isFree ? 'Gratis' : formatRupiah(price),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.activity,
                        ),
                      ),

                      // Slot
                      if (!isPassed)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isAvailable && !isDeadlinePassed
                                ? AppColors.activitySurface
                                : AppColors.errorLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isDeadlinePassed
                                ? 'Ditutup'
                                : isAvailable
                                    ? '$slots slot'
                                    : 'Penuh',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isAvailable && !isDeadlinePassed
                                  ? AppColors.activity
                                  : AppColors.error,
                            ),
                          ),
                        ),
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
}

// ─────────────────────────────────────────────────────
// SKELETON
// ─────────────────────────────────────────────────────
class _AcaraSkelCard extends StatelessWidget {
  const _AcaraSkelCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
          color: AppColors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          SkeletonBox(width: double.infinity, height: 160, borderRadius: 14),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 230, height: 16),
                const SizedBox(height: 8),
                SkeletonBox(width: 160, height: 13),
                const SizedBox(height: 6),
                SkeletonBox(width: 130, height: 13),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonBox(width: 100, height: 20),
                    SkeletonBox(width: 70, height: 30, borderRadius: 8),
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

// ─────────────────────────────────────────────────────
// FILTER SHEET & CHIP
// ─────────────────────────────────────────────────────
class _FilterSheet extends StatefulWidget {
  const _FilterSheet();

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String _category = '';
  String? _sortBy;
  double? _minPrice;
  double? _maxPrice;
  RangeValues _priceRange = const RangeValues(0, 1000000);

  @override
  void initState() {
    super.initState();
    final p = context.read<ActivityProvider>();
    _category = p.selectedCategory;
    _sortBy = p.sortBy;
    _minPrice = p.minPrice;
    _maxPrice = p.maxPrice;

    double min = p.minPrice ?? 0;
    double max = p.maxPrice ?? 1000000;
    _priceRange = RangeValues(min, max);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Acara',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Kategori',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: _kCategories.map((c) {
              final isSelected = _category == c['id'];
              return GestureDetector(
                onTap: () {
                  setState(() => _category = c['id']!);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.activity
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.activity
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    c['label']!,
                    style: TextStyle(
                      color:
                          isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            'Rentang Harga',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
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
            max: 1000000,
            divisions: 50,
            activeColor: AppColors.activity,
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
          const SizedBox(height: 24),
          const Text(
            'Urutkan Berdasarkan',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: [
              _buildSortChip('Terbaru', null),
              _buildSortChip('Termurah', 'price_asc'),
              _buildSortChip('Termahal', 'price_desc'),
              _buildSortChip('Rating Tertinggi', 'rating_desc'),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                context.read<ActivityProvider>().setFilter(
                      category: _category,
                      sortBy: _sortBy,
                      minPrice: _minPrice,
                      maxPrice: _maxPrice,
                    );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.activity,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Terapkan Filter',
                  style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String? value) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () => setState(() => _sortBy = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.activity : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.activity : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.activity.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.activity,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: AppColors.activity),
          ),
        ],
      ),
    );
  }
}
