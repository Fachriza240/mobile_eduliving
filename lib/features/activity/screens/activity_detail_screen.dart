import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/activity_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/activity_provider.dart';
import '../../bookmark/providers/bookmark_provider.dart';
import 'activity_booking_screen.dart';

class ActivityDetailScreen extends StatefulWidget {
  final int id;
  const ActivityDetailScreen({super.key, required this.id});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  int _imgIdx = 0;
  final _pageCtrl = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<ActivityProvider>().loadActivityDetail(widget.id));
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
      body: Consumer<ActivityProvider>(
        builder: (_, prov, __) {
          if (prov.isLoadingDetail) return _loadingState();
          if (prov.detailError != null) {
            return Scaffold(
              appBar: const EduAppBar(title: 'Detail Acara'),
              body: ErrorState(
                message: prov.detailError!,
                onRetry: () => prov.loadActivityDetail(widget.id),
              ),
            );
          }
          if (prov.selectedActivity == null) return const SizedBox();
          return _buildContent(prov.selectedActivity!);
        },
      ),
    );
  }

  Widget _buildContent(ActivityModel a) {
    final isLoggedIn = context.read<AuthProvider>().isAuthenticated;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: AppColors.activityDark,
          leading: _backBtn(),
          actions: [
            if (isLoggedIn)
              Consumer<BookmarkProvider>(
                builder: (context, bookmarkProv, _) {
                  final isBookmarked =
                      bookmarkProv.isBookmarked('Activity', widget.id);
                  return GestureDetector(
                    onTap: () => bookmarkProv.toggle('Activity', widget.id),
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
                        color: AppColors.activity,
                      ),
                    ),
                  );
                },
              ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _buildGallery(a.images),
          ),
        ),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMainInfo(a, isLoggedIn),
              const SizedBox(height: 8),
              _section('Deskripsi', _descText(a.description)),
              const SizedBox(height: 8),
              if (a.speakers.isNotEmpty) ...[
                _section('Pemateri', _buildSpeakers(a.speakers)),
                const SizedBox(height: 8),
              ],
              if (a.benefits.isNotEmpty) ...[
                _section('Yang Akan Kamu Dapat', _buildBenefits(a.benefits)),
                const SizedBox(height: 8),
              ],
              _section(
                'Informasi Acara',
                Column(children: [
                  InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Tanggal Acara',
                    value: formatDate(a.eventDate),
                    iconColor: AppColors.activity,
                  ),
                  if (a.registrationDeadline != null)
                    InfoRow(
                      icon: Icons.timer_outlined,
                      label: 'Batas Pendaftaran',
                      value: formatDate(a.registrationDeadline),
                      iconColor: a.isDeadlinePassed
                          ? AppColors.error
                          : AppColors.activity,
                    ),
                  if (a.location != null)
                    InfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Lokasi',
                      value: a.location!,
                      iconColor: AppColors.activity,
                    ),
                  InfoRow(
                    icon: Icons.people_outlined,
                    label: 'Kapasitas',
                    value: '${a.capacity ?? 0} peserta',
                    iconColor: AppColors.activity,
                  ),
                  InfoRow(
                    icon: Icons.business_outlined,
                    label: 'Penyelenggara',
                    value: a.providerName,
                    iconColor: AppColors.activity,
                  ),
                ]),
              ),
              const SizedBox(height: 8),
              _section('Ulasan & Penilaian', _buildRatings(a.ratings)),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainInfo(ActivityModel a, bool isLoggedIn) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statusBadge(a),
          const SizedBox(height: 10),
          Text(a.name,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.business_outlined,
                size: 14, color: AppColors.textHint),
            const SizedBox(width: 4),
            Text(a.providerName,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: AppColors.textSecondary)),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.calendar_today_outlined,
                size: 14, color: AppColors.activity),
            const SizedBox(width: 4),
            Text(formatDate(a.eventDate),
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.activity)),
          ]),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.isFree ? 'Gratis' : formatRupiah(a.discountedPrice),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.activity,
                    ),
                  ),
                  if (a.hasDiscount)
                    Text(formatRupiah(a.price),
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: AppColors.textHint,
                            decoration: TextDecoration.lineThrough)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${a.availableSlots ?? 0}',
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const Text('slot tersisa',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppColors.textHint)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _registerButton(a, isLoggedIn),
        ],
      ),
    );
  }

  Widget _registerButton(ActivityModel a, bool isLoggedIn) {
    if (a.isEventPassed) return const SizedBox.shrink();
    if (a.isDeadlinePassed) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.border),
          child: const Text('Pendaftaran Ditutup',
              style: TextStyle(color: AppColors.textHint)),
        ),
      );
    }
    if (!a.isAvailable) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.border),
          child: const Text('Kuota Penuh',
              style: TextStyle(color: AppColors.textHint)),
        ),
      );
    }

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.activity),
      onPressed: () {
        if (!isLoggedIn) {
          _loginRequired();
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ActivityBookingScreen(activity: a),
          ),
        );
      },
      icon: const Icon(Icons.how_to_reg_rounded, size: 18),
      label: const Text('Daftar Sekarang'),
    );
  }

  Widget _buildSpeakers(List<Map<String, dynamic>> speakers) {
    return Column(
      children: speakers.map((s) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.activityLight,
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: AppColors.activity.withValues(alpha: 0.15)),
          ),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.activitySurface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.person_rounded,
                  color: AppColors.activity, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s['name']?.toString() ?? 'Pemateri',
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                  if (s['position'] != null)
                    Text(s['position'].toString(),
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                ],
              ),
            ),
          ]),
        );
      }).toList(),
    );
  }

  Widget _buildBenefits(List<String> benefits) {
    return Column(
      children: benefits.map((b) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: AppColors.activitySurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    size: 13, color: AppColors.activity),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(b,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRatings(List<dynamic> ratings) {
    if (ratings.isEmpty) {
      return const Text('Belum ada ulasan untuk acara ini.',
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

  Widget _sheetLabel(String t) => Text(t,
      style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary));

  void _successDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.activitySurface,
                borderRadius: BorderRadius.circular(36),
              ),
              child: const Icon(Icons.check_rounded,
                  size: 40, color: AppColors.activity),
            ),
            const SizedBox(height: 16),
            const Text('Berhasil Mendaftar!',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              'Pendaftaran berhasil dikirim. Cek email atau halaman booking untuk info selanjutnya.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.activity),
            onPressed: () => Navigator.pop(context),
            child: const Text('Oke, Terima Kasih!'),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(ActivityModel a) {
    String label;
    Color color;
    if (a.isEventPassed) {
      label = 'Selesai';
      color = AppColors.textHint;
    } else if (!a.isAvailable) {
      label = 'Kuota Penuh';
      color = AppColors.error;
    } else if (a.isDeadlinePassed) {
      label = 'Ditutup';
      color = AppColors.warning;
    } else {
      label = 'Buka Pendaftaran';
      color = AppColors.activity;
    }
    return StatusBadge(label: label, color: color);
  }

  Widget _buildGallery(List<String> images) {
    if (images.isEmpty) {
      return Container(
        color: AppColors.activityLight,
        child: const Center(
          child:
              Icon(Icons.event_outlined, size: 64, color: AppColors.activity),
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
          height: 280,
          placeholderIcon: Icons.event_outlined,
          placeholderColor: AppColors.activityLight,
          iconColor: AppColors.activity,
        ),
      ),
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
                      ? AppColors.activity
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
            const Icon(Icons.lock_outline, size: 48, color: AppColors.activity),
            const SizedBox(height: 12),
            const Text('Masuk Diperlukan',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Silakan masuk untuk mendaftar acara ini.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.activity),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/login');
              },
              child: const Text('Masuk Sekarang'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.activity,
                  side: const BorderSide(color: AppColors.activity)),
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
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.activityDark,
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
                  SkeletonBox(width: 260, height: 26),
                  const SizedBox(height: 10),
                  SkeletonBox(width: 180, height: 16),
                  const SizedBox(height: 16),
                  SkeletonBox(width: double.infinity, height: 80),
                  const SizedBox(height: 12),
                  SkeletonBox(width: double.infinity, height: 120),
                ],
              ),
            ),
          ),
        ]),
      );
}
