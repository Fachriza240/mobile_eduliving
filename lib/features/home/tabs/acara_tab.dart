import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../activity/providers/activity_provider.dart';
import '../../activity/screens/activity_detail_screen.dart';

class AcaraTab extends StatefulWidget {
  const AcaraTab({super.key});

  @override
  State<AcaraTab> createState() => _AcaraTabState();
}

class _AcaraTabState extends State<AcaraTab>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late TabController _tabCtrl;

  final _categories = const [
    {'id': '', 'label': 'Semua'},
    {'id': 'seminar', 'label': 'Seminar'},
    {'id': 'workshop', 'label': 'Workshop'},
    {'id': 'kompetisi', 'label': 'Kompetisi'},
    {'id': 'webinar', 'label': 'Webinar'},
    {'id': 'pelatihan', 'label': 'Pelatihan'},
  ];

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
        automaticallyImplyLeading: false,
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
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: EduSearchBar(
                  controller: _searchCtrl,
                  hint: 'Cari acara, seminar...',
                  onChanged: (q) =>
                      context.read<ActivityProvider>().setSearch(q),
                  onClear: () => context.read<ActivityProvider>().setSearch(''),
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
          _buildCategoryFilter(),
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

  // ── Filter Chip HIJAU ─────────────────────────────
  Widget _buildCategoryFilter() {
    return Consumer<ActivityProvider>(
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
            selectedColor: AppColors.activity,
          ),
        ),
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
