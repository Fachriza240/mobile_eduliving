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
          if (prov.isLoadingDetail) {
            return _loadingState();
          }
          if (prov.detailError != null) {
            return Scaffold(
              appBar: const EduAppBar(title: 'Detail Acara'),
              body: ErrorState(
                message: prov.detailError!,
                onRetry: () => prov.loadActivityDetail(widget.id),
              ),
            );
          }
          if (prov.selectedActivity == null) {
            return const SizedBox();
          }
          return _buildContent(prov.selectedActivity!);
        },
      ),
    );
  }

  Widget _buildContent(ActivityModel a) {
    final isLoggedIn = context.read<AuthProvider>().isAuthenticated;

    return CustomScrollView(
      slivers: [
        // ── SliverAppBar hijau ─────────────
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

              // Deskripsi
              _section('Deskripsi', _descText(a.description)),
              const SizedBox(height: 8),

              // Pemateri (field speakers Serren)
              if (a.speakers.isNotEmpty) ...[
                _section('Pemateri', _buildSpeakers(a.speakers)),
                const SizedBox(height: 8),
              ],

              // Benefit (field benefits Serren)
              if (a.benefits.isNotEmpty) ...[
                _section('Yang Akan Kamu Dapat', _buildBenefits(a.benefits)),
                const SizedBox(height: 8),
              ],

              // Info Detail
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
          // Status badge
          _statusBadge(a),
          const SizedBox(height: 10),

          Text(a.name,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),

          // Penyelenggara
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

          // Tanggal hijau
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

          // Harga + slot
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Harga HIJAU
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

          // Tombol daftar hijau
          _registerButton(a, isLoggedIn),
        ],
      ),
    );
  }

  Widget _registerButton(ActivityModel a, bool isLoggedIn) {
    if (a.isEventPassed) {
      return const SizedBox.shrink();
    }
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
        _showRegSheet(a);
      },
      icon: const Icon(Icons.how_to_reg_rounded, size: 18),
      label: const Text('Daftar Sekarang'),
    );
  }

  // Pemateri — card hijau muda
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

  // Benefit — centang hijau
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

  // ── Form Pendaftaran BottomSheet ──────────────────
  void _showRegSheet(ActivityModel a) {
    final user = context.read<AuthProvider>().user;
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final phoneCtrl = TextEditingController(text: user?.phone ?? '');
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;
    String? err;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.activityLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.how_to_reg_rounded,
                          color: AppColors.activity, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Formulir Pendaftaran',
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700)),
                          Text(a.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // Nama Lengkap
                  _sheetLabel('Nama Lengkap'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Nama lengkap sesuai identitas',
                      prefixIcon: Icon(Icons.person_outline, size: 20),
                    ),
                    validator: (v) => (v?.trim().isEmpty ?? true)
                        ? 'Nama tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: 14),

                  // Email
                  _sheetLabel('Email'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Email aktif Anda',
                      prefixIcon: Icon(Icons.email_outlined, size: 20),
                    ),
                    validator: (v) {
                      if (v?.trim().isEmpty ?? true) {
                        return 'Email tidak boleh kosong';
                      }
                      if (!v!.contains('@')) {
                        return 'Format email tidak valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Nomor Telepon
                  _sheetLabel('Nomor Telepon'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'Contoh: 08123456789',
                      prefixIcon: Icon(Icons.phone_outlined, size: 20),
                    ),
                    validator: (v) => (v?.trim().isEmpty ?? true)
                        ? 'Nomor telepon tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Harga hijau
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.activityLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.activity.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Biaya Pendaftaran',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: AppColors.textSecondary)),
                        Text(
                          a.isFree ? 'Gratis' : formatRupiah(a.discountedPrice),
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.activity),
                        ),
                      ],
                    ),
                  ),

                  if (err != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(err!,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: AppColors.error)),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Tombol submit hijau
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.activity),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setSheet(() {
                              isSubmitting = true;
                              err = null;
                            });
                            try {
                              await ApiService().post(
                                ApiConstants.userBookings,
                                data: {
                                  'bookable_id': a.id,
                                  'bookable_type': 'App\\Models\\Activity',
                                  'full_name': nameCtrl.text.trim(),
                                  'email': emailCtrl.text.trim(),
                                  'phone': phoneCtrl.text.trim(),
                                  'total_price': a.discountedPrice,
                                },
                              );
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                _successDialog();
                              }
                            } catch (e) {
                              setSheet(() {
                                err = e
                                    .toString()
                                    .replaceAll('ApiException: ', '');
                                isSubmitting = false;
                              });
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Kirim Pendaftaran'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
