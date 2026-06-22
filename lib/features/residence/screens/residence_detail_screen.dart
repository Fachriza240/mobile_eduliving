import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/residence_model.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/residence_provider.dart';
import 'residence_booking_screen.dart';
import '../../bookmark/providers/bookmark_provider.dart';

class ResidenceDetailScreen extends StatefulWidget {
  final int id;
  const ResidenceDetailScreen({super.key, required this.id});

  @override
  State<ResidenceDetailScreen> createState() => _ResidenceDetailScreenState();
}

class _ResidenceDetailScreenState extends State<ResidenceDetailScreen> {
  int _imgIdx = 0;
  final _pageCtrl = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<ResidenceProvider>().loadResidenceDetail(widget.id));
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<ResidenceProvider>(
        builder: (_, prov, __) {
          if (prov.isLoadingDetail) {
            return _loadingState();
          }
          if (prov.detailError != null) {
            return Scaffold(
              appBar: const EduAppBar(title: 'Detail Hunian'),
              body: ErrorState(
                message: prov.detailError!,
                onRetry: () => prov.loadResidenceDetail(widget.id),
              ),
            );
          }
          if (prov.selectedResidence == null) {
            return const SizedBox();
          }
          return _buildContent(prov.selectedResidence!);
        },
      ),
    );
  }

  Widget _buildContent(ResidenceModel r) {
    final isLoggedIn = context.read<AuthProvider>().isAuthenticated;

    return CustomScrollView(
      slivers: [
        // ── SliverAppBar biru ──────────────
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: AppColors.residenceDark,
          leading: _backBtn(),
          actions: [
            if (isLoggedIn)
              Consumer<BookmarkProvider>(
                builder: (context, bookmarkProv, _) {
                  final isBookmarked =
                      bookmarkProv.isBookmarked('Residence', r.id);
                  return GestureDetector(
                    onTap: () => bookmarkProv.toggle('Residence', r.id),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 20,
                        color: AppColors.residence,
                      ),
                    ),
                  );
                },
              ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _buildGallery(r.images),
          ),
        ),

        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMainInfo(r, isLoggedIn),
              const SizedBox(height: 8),
              if (r.facilities.isNotEmpty) ...[
                _section('Fasilitas', _buildFacilities(r.facilities)),
                const SizedBox(height: 8),
              ],
              _section('Deskripsi', _descText(r.description)),
              const SizedBox(height: 8),
              _section(
                'Informasi',
                Column(children: [
                  InfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Alamat',
                    value: r.address,
                    iconColor: AppColors.residence,
                  ),
                  InfoRow(
                    icon: Icons.calendar_month_outlined,
                    label: 'Periode Sewa',
                    value: r.rentalPeriodLabel.isNotEmpty
                        ? r.rentalPeriodLabel
                        : '-',
                    iconColor: AppColors.residence,
                  ),
                  InfoRow(
                    icon: Icons.people_outlined,
                    label: 'Kapasitas',
                    value: '${r.capacity ?? 0} penghuni',
                    iconColor: AppColors.residence,
                  ),
                  InfoRow(
                    icon: Icons.door_sliding_outlined,
                    label: 'Slot Tersedia',
                    value: '${r.availableSlots ?? 0} slot',
                    iconColor: AppColors.residence,
                  ),
                  InfoRow(
                    icon: Icons.person_outlined,
                    label: 'Penyedia',
                    value: r.providerName,
                    iconColor: AppColors.residence,
                  ),
                ]),
              ),
              const SizedBox(height: 8),
              _section('Ulasan & Penilaian', _buildRatings(r.ratings)),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainInfo(ResidenceModel r, bool isLoggedIn) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nama + Rating
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(r.name,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ),
              const SizedBox(width: 8),
              StarRating(
                  rating: r.ratingAverage ?? 0,
                  reviewCount: r.ratingCount ?? 0,
                  size: 15),
            ],
          ),
          const SizedBox(height: 8),

          // Lokasi
          Row(children: [
            const Icon(Icons.location_on_outlined,
                size: 14, color: AppColors.textHint),
            const SizedBox(width: 4),
            Expanded(
              child: Text(r.address,
                  maxLines: 2,
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: AppColors.textSecondary)),
            ),
          ]),
          const SizedBox(height: 14),

          // Harga + Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (r.hasDiscount)
                    Text(formatRupiah(r.price),
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: AppColors.textHint,
                            decoration: TextDecoration.lineThrough)),
                  Text(
                    formatRupiah(r.discountedPrice),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.residence,
                    ),
                  ),
                  Text(r.rentalPeriodLabel,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.textSecondary)),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: r.isAvailable
                      ? AppColors.residenceSurface
                      : AppColors.errorLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  r.isAvailable ? '${r.availableSlots} Tersedia' : 'Penuh',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: r.isAvailable
                          ? AppColors.residence
                          : AppColors.error),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tombol Pesan — biru
          _bookingButton(r, isLoggedIn),
        ],
      ),
    );
  }

  Widget _bookingButton(ResidenceModel r, bool isLoggedIn) {
    if (!r.isAvailable) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.border),
          child: const Text('Hunian Penuh',
              style: TextStyle(color: AppColors.textHint)),
        ),
      );
    }

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.residence),
      onPressed: () {
        if (!isLoggedIn) {
          _loginRequired();
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResidenceBookingScreen(residence: r),
          ),
        );
      },
      icon: const Icon(Icons.calendar_today_rounded, size: 18),
      label: const Text('Pesan Sekarang'),
    );
  }

  Widget _buildFacilities(List<String> facilities) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: facilities
          .map((f) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.residenceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.residence.withValues(alpha: 0.2)),
                ),
                child: Text(f,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppColors.residence,
                        fontWeight: FontWeight.w500)),
              ))
          .toList(),
    );
  }

  Widget _buildGallery(List<String> images) {
    if (images.isEmpty) {
      return Container(
        color: AppColors.residenceLight,
        child: const Center(
          child: Icon(Icons.home_work_outlined,
              size: 64, color: AppColors.residence),
        ),
      );
    }
    return Stack(children: [
      PageView.builder(
        controller: _pageCtrl,
        itemCount: images.length,
        onPageChanged: (i) => setState(() => _imgIdx = i),
        itemBuilder: (_, i) => EduImage(
          path: images[i],
          height: 300,
          placeholderIcon: Icons.home_work_outlined,
          placeholderColor: AppColors.residenceLight,
          iconColor: AppColors.residence,
        ),
      ),
      // Dot indicator biru
      if (images.length > 1)
        Positioned(
          bottom: 14,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              images.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _imgIdx == i ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _imgIdx == i
                      ? AppColors.residence
                      : Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
    ]);
  }

  Widget _section(String title, Widget child) => Container(
        width: double.infinity,
        color: AppColors.white,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );

  Widget _descText(String t) => Text(t,
      style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          height: 1.7,
          color: AppColors.textSecondary));

  Widget _buildRatings(List<dynamic> ratings) {
    if (ratings.isEmpty) {
      return const Text('Belum ada ulasan untuk hunian ini.',
          style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.textSecondary));
    }
    return Column(
      children: ratings.map((r) {
        final user = r['user'] as Map<String, dynamic>?;
        final userName = user?['name'] ?? 'Pengguna';
        final ratingVal = double.tryParse(r['rating']?.toString() ?? '0') ?? 0;
        final comment = r['comment'] ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(userName,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(ratingVal.toString(),
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                    ],
                  ),
                ],
              ),
              if (comment.toString().trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(comment.toString(),
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: AppColors.textSecondary)),
              ]
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _backBtn() => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.textPrimary),
        ),
      );

  void _loginRequired() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline,
                size: 48, color: AppColors.residence),
            const SizedBox(height: 12),
            const Text('Masuk Diperlukan',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Silakan masuk untuk memesan hunian.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.residence),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/login');
              },
              child: const Text('Masuk Sekarang'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.residence,
                  side: const BorderSide(color: AppColors.residence)),
              onPressed: () => Navigator.pop(context),
              child: const Text('Nanti Saja'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingState() => Scaffold(
        body: CustomScrollView(slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.residenceDark,
            leading: _backBtn(),
            flexibleSpace: const FlexibleSpaceBar(
              background: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 260, height: 24),
                  const SizedBox(height: 10),
                  SkeletonBox(width: 180, height: 16),
                  const SizedBox(height: 16),
                  SkeletonBox(width: double.infinity, height: 60),
                  const SizedBox(height: 16),
                  SkeletonBox(width: double.infinity, height: 120),
                ],
              ),
            ),
          ),
        ]),
      );
}
