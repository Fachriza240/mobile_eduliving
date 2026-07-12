import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/residence_model.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/residence_provider.dart';
import 'residence_booking_screen.dart';
import '../../profile/screens/rating_screen.dart';
import '../../bookmark/providers/bookmark_provider.dart';
import '../../profile/providers/booking_provider.dart';

class ResidenceDetailScreen extends StatefulWidget {
  final int id;
  const ResidenceDetailScreen({super.key, required this.id});

  @override
  State<ResidenceDetailScreen> createState() => _ResidenceDetailScreenState();
}

class _ResidenceDetailScreenState extends State<ResidenceDetailScreen> {
  int _imgIdx = 0;
  final _pageCtrl = PageController();
  int? _ratingFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ResidenceProvider>().loadResidenceDetail(widget.id);
      if (context.read<AuthProvider>().isAuthenticated) {
        context.read<BookingProvider>().loadBookings();
      }
    });
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
              if (r.residenceType != null) ...[
                _buildSpecificDetails(r),
                const SizedBox(height: 8),
              ],
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
                ]),
              ),
              const SizedBox(height: 8),
              _section('Penyedia', _buildProviderInfo(r.provider)),
              const SizedBox(height: 8),
              _section('Ulasan & Penilaian', _buildRatings(r)),
              // Tombol Beri Ulasan — muncul jika user sudah bayar
              if (isLoggedIn && _hasPaidBooking(r.id)) ...[
                const SizedBox(height: 8),
                Container(
                  color: AppColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.residence,
                        side: const BorderSide(color: AppColors.residence),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RatingScreen(
                            isResidence: true,
                            rateableId: r.id,
                            rateableName: r.name,
                          ),
                        ),
                      ).then((_) =>
                          context.read<ResidenceProvider>().loadResidenceDetail(r.id)),
                      icon: const Icon(Icons.star_border_rounded, size: 18),
                      label: const Text('Beri Ulasan',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProviderInfo(Map<String, dynamic>? providerData) {
    if (providerData == null) return const SizedBox();
    
    final name = providerData['name']?.toString() ?? 'Penyedia';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final createdAtStr = providerData['created_at']?.toString();
    final lastSeenStr = providerData['last_seen_at']?.toString();
    
    String memberSince = 'Penyedia';
    if (createdAtStr != null) {
      final dt = DateTime.tryParse(createdAtStr);
      if (dt != null) {
        memberSince = 'Anggota sejak ${dt.year}';
      }
    }

    Widget? lastSeenWidget;
    if (lastSeenStr != null) {
      final dt = DateTime.tryParse(lastSeenStr);
      if (dt != null) {
        if (DateTime.now().difference(dt).inMinutes < 5) {
          lastSeenWidget = const Text('Online', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w500));
        } else {
          lastSeenWidget = Text('Terakhir online ${dt.day}/${dt.month}/${dt.year}', style: TextStyle(fontSize: 12, color: Colors.grey[500]));
        }
      }
    }
    if (lastSeenWidget == null) {
      lastSeenWidget = Text('Belum pernah online', style: TextStyle(fontSize: 12, color: Colors.grey[500]));
    }

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.residence.withOpacity(0.1),
          child: Text(
            initial,
            style: const TextStyle(
                color: AppColors.residence,
                fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                memberSince,
                style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(height: 2),
              lastSeenWidget,
            ],
          ),
        ),
      ],
    );
  }

  /// Cek apakah user punya booking yang sudah dibayar untuk hunian ini
  bool _hasPaidBooking(int residenceId) {
    try {
      final bookingProv = context.read<BookingProvider>();
      return bookingProv.allBookings.any((b) {
        final paymentStatus = b.transaction?['payment_status'] ?? '';
        return b.isResidence &&
            b.bookableId == residenceId &&
            (paymentStatus == 'paid' || b.status == 'completed');
      });
    } catch (_) {
      return false;
    }
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
                    Text('${formatRupiah(r.price)}/${r.rentalPeriodShort}',
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: AppColors.textHint,
                            decoration: TextDecoration.lineThrough)),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: formatRupiah(r.discountedPrice),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.residence,
                          ),
                        ),
                        TextSpan(
                          text: '/${r.rentalPeriodShort}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
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

        final bookingProv = context.read<BookingProvider>();
        final hasActive = bookingProv.allBookings.any((b) =>
            b.isResidence &&
            b.bookableId == r.id &&
            (b.status == 'pending' || b.status == 'approved'));

        if (r.hasActiveBooking || hasActive) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              backgroundColor: const Color(0xFF333333),
              content: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Anda sudah memiliki booking aktif untuk hunian ini. Selesaikan atau batalkan booking sebelumnya terlebih dahulu.',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.white,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          );
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

  Widget _buildSpecificDetails(ResidenceModel r) {
    String title = 'Detail Hunian';
    IconData icon = Icons.home_work_outlined;

    if (r.residenceType == 'apartemen') {
      title = 'Detail Apartemen';
      icon = Icons.apartment_outlined;
    } else if (r.residenceType == 'kontrakan') {
      title = 'Detail Kontrakan';
      icon = Icons.house_outlined;
    } else if (r.residenceType == 'rumah_sewa') {
      title = 'Detail Rumah';
      icon = Icons.house_siding_outlined;
    } else if (r.residenceType == 'kos') {
      title = 'Detail Kos';
      icon = Icons.meeting_room_outlined;
    }

    List<Widget> gridItems = [];

    Widget buildGridItem(String label, String value, IconData itemIcon, {bool isHighlighted = false}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        decoration: BoxDecoration(
          color: isHighlighted ? AppColors.residenceLight : AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(itemIcon, size: 20, color: isHighlighted ? AppColors.residence : Colors.grey[600]),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 10, color: isHighlighted ? AppColors.residence : Colors.grey[600], fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isHighlighted ? AppColors.residence : AppColors.textPrimary), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      );
    }

    if (r.residenceType == 'apartemen') {
      if (r.unitType != null) gridItems.add(buildGridItem('Tipe Unit', r.unitType!, Icons.layers_outlined, isHighlighted: true));
      if (r.floorNumber != null) gridItems.add(buildGridItem('Lantai', 'Lantai ${r.floorNumber}', Icons.elevator_outlined));
      if (r.towerName != null) gridItems.add(buildGridItem('Tower/Gedung', r.towerName!, Icons.business_outlined));
      if (r.availableSlots != null) gridItems.add(buildGridItem('Unit tersedia', '${r.availableSlots} unit', Icons.door_front_door_outlined));
      if (r.roomSize != null) gridItems.add(buildGridItem('Luas Unit', '${r.roomSize} m²', Icons.square_foot_outlined));
      if (r.bathroomCount != null) gridItems.add(buildGridItem('Kamar Mandi', '${r.bathroomCount}', Icons.bathtub_outlined));
      if (r.furnishStatus != null) gridItems.add(buildGridItem('Furnitur', r.furnishStatusLabel, Icons.chair_outlined, isHighlighted: r.furnishStatus != 'unfurnished'));
    } else if (r.residenceType == 'kontrakan' || r.residenceType == 'rumah_sewa') {
      if (r.availableSlots != null) gridItems.add(buildGridItem('Jumlah Unit', '${r.availableSlots} unit', Icons.house_outlined));
      if (r.bedroomCount != null) gridItems.add(buildGridItem('Kamar Tidur', '${r.bedroomCount} kamar', Icons.bed_outlined));
      if (r.bathroomCount != null) gridItems.add(buildGridItem('Kamar Mandi', '${r.bathroomCount} kamar', Icons.bathtub_outlined));
      if (r.buildingSize != null) gridItems.add(buildGridItem('Luas Bangunan', '${r.buildingSize} m²', Icons.straighten_outlined));
      if (r.landSize != null) gridItems.add(buildGridItem('Luas Tanah', '${r.landSize} m²', Icons.grid_4x4_outlined));
      if (r.furnishStatus != null) gridItems.add(buildGridItem('Furnitur', r.furnishStatusLabel, Icons.chair_outlined, isHighlighted: r.furnishStatus != 'unfurnished'));
    } else if (r.residenceType == 'kos') {
      if (r.kosType != null) gridItems.add(buildGridItem('Jenis Kos', r.kosTypeLabel, Icons.transgender_outlined, isHighlighted: true));
      if (r.capacity != null) gridItems.add(buildGridItem('Jumlah Kamar', '${r.capacity} kamar', Icons.meeting_room_outlined));
      if (r.roomSize != null) gridItems.add(buildGridItem('Ukuran Kamar', '${r.roomSize} m²', Icons.square_foot_outlined));
      if (r.furnishStatus != null) gridItems.add(buildGridItem('Furnitur', r.furnishStatusLabel, Icons.chair_outlined, isHighlighted: r.furnishStatus != 'unfurnished'));
    }

    if (gridItems.isEmpty) return const SizedBox();

    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.residenceLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.residence, size: 16),
              ),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.8,
            children: gridItems,
          ),
        ],
      ),
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

  Widget _buildRatings(ResidenceModel residence) {
    var ratings = residence.ratings;
    final currentUserId = Provider.of<AuthProvider>(context, listen: false).user?.id;

    if (residence.ratings.isEmpty) {
      return const Text('Belum ada ulasan untuk hunian ini.',
          style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.textSecondary));
    }

    // Filter logic
    if (_ratingFilter != null) {
      ratings = ratings.where((r) {
        final val = double.tryParse(r['rating']?.toString() ?? '0') ?? 0;
        return val == _ratingFilter!.toDouble();
      }).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter UI
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildStarFilterChip('Semua', null),
              const SizedBox(width: 8),
              _buildStarFilterChip('5 Bintang', 5),
              const SizedBox(width: 8),
              _buildStarFilterChip('4 Bintang', 4),
              const SizedBox(width: 8),
              _buildStarFilterChip('3 Bintang', 3),
              const SizedBox(width: 8),
              _buildStarFilterChip('2 Bintang', 2),
              const SizedBox(width: 8),
              _buildStarFilterChip('1 Bintang', 1),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (ratings.isEmpty)
          const Text('Tidak ada ulasan dengan rating tersebut.',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppColors.textSecondary))
        else
          ...ratings.map((r) {
        final user = r['user'] as Map<String, dynamic>?;
        final userName = user?['name'] ?? 'Pengguna';
        final userId = r['user_id'];
        final ratingVal = double.tryParse(r['rating']?.toString() ?? '0') ?? 0;
        final comment = r['review'] ?? '';
        final photoPath = r['photo_path']?.toString();
        final providerReply = r['provider_reply']?.toString();
        final initial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';
        
        // Coba parsing tanggal
        String dateStr = '';
        if (r['created_at'] != null) {
          final dt = DateTime.tryParse(r['created_at'].toString());
          if (dt != null) {
            final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
            dateStr = '${dt.day} ${months[dt.month - 1]} ${dt.year}';
          }
        }

        final isMyReview = currentUserId != null && userId == currentUserId;

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(initial,
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
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
                                if (dateStr.isNotEmpty)
                                  Text(dateStr,
                                      style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 11,
                                          color: AppColors.textHint)),
                                if (isMyReview) ...[
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => RatingScreen(
                                          isResidence: true,
                                          rateableId: residence.id,
                                          rateableName: residence.name,
                                        ),
                                      ),
                                    ).then((_) {
                                      // Reload detail to show updated rating
                                      context.read<ResidenceProvider>().loadResidenceDetail(residence.id);
                                    }),
                                    child: const Icon(Icons.edit_square, size: 16, color: AppColors.primary),
                                  ),
                                ]
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: List.generate(
                            5,
                            (index) => Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: index < ratingVal
                                  ? Colors.orange
                                  : Colors.grey[300],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (comment.toString().trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(comment.toString(),
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: AppColors.textSecondary)),
              ],
              if (photoPath != null && photoPath.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: EduImage(
                    path: photoPath,
                    width: 100,
                    height: 100,
                  ),
                ),
              ],
              if (providerReply != null && providerReply.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primaryLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.reply_rounded, size: 14, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text('Balasan Pemilik',
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(providerReply,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
      ],
    );
  }

  Widget _buildStarFilterChip(String label, int? value) {
    final isSelected = _ratingFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _ratingFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.residence : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? AppColors.residence : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _backBtn() => IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
            ],
          ),
          child: const Icon(Icons.arrow_back_rounded, color: Colors.black87, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
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
