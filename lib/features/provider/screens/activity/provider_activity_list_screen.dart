import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../providers/provider_activity_provider.dart';
import '../../models/provider_models.dart';
import 'provider_activity_form_screen.dart';

class ProviderActivityListScreen extends StatefulWidget {
  const ProviderActivityListScreen({super.key});

  @override
  State<ProviderActivityListScreen> createState() =>
      _ProviderActivityListScreenState();
}

class _ProviderActivityListScreenState extends State<ProviderActivityListScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderActivityProvider>().loadActivities(refresh: true);
    });
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent - 200) {
        context.read<ProviderActivityProvider>().loadActivities();
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
                color: AppColors.activityLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.event_rounded, color: AppColors.activity, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Kelola Acara',
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
            icon: const Icon(Icons.add_rounded, color: AppColors.activity),
            tooltip: 'Tambah Acara',
            onPressed: () => _goToForm(context),
          ),
        ],
      ),
      body: Consumer<ProviderActivityProvider>(
        builder: (_, prov, __) {
          if (prov.isLoading) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              itemBuilder: (_, __) => _ActivitySkelCard(),
            );
          }
          if (prov.error != null && prov.activities.isEmpty) {
            return ErrorState(
              message: prov.error!,
              onRetry: () => prov.loadActivities(refresh: true),
            );
          }
          if (prov.activities.isEmpty) {
            return EmptyState(
              message: 'Belum ada acara.\nBuat acara pertamamu!',
              icon: Icons.event_outlined,
              iconColor: AppColors.activity,
              action: ElevatedButton.icon(
                onPressed: () => _goToForm(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Tambah Acara'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.activity,
                  minimumSize: const Size(160, 44),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => prov.loadActivities(refresh: true),
            color: AppColors.activity,
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: prov.activities.length + (prov.isLoadingMore ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == prov.activities.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.activity),
                    ),
                  );
                }
                final a = prov.activities[i];
                return _ProviderActivityCard(
                  activity: a,
                  onEdit: () => _goToForm(context, activity: a),
                  onDelete: () => _confirmDelete(context, a, prov),
                  onToggle: () => prov.toggleStatus(a.id),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _goToForm(context),
        backgroundColor: AppColors.activity,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  void _goToForm(BuildContext ctx, {ProviderActivityModel? activity}) {
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => ProviderActivityFormScreen(activity: activity),
      ),
    );
  }

  void _confirmDelete(
    BuildContext ctx,
    ProviderActivityModel a,
    ProviderActivityProvider prov,
  ) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Acara?',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Text('${a.name} akan dihapus permanen.',
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await prov.deleteActivity(a.id);
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text(ok ? 'Acara dihapus.' : prov.error ?? 'Gagal.'),
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

// ── Card Acara (versi provider) ───────────────────────────
class _ProviderActivityCard extends StatelessWidget {
  final ProviderActivityModel activity;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _ProviderActivityCard({
    required this.activity,
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
          Stack(
            children: [
              EduImage(
                path: activity.mainImage,
                height: 150,
                borderRadius: 14,
                placeholderIcon: Icons.event_outlined,
                placeholderColor: AppColors.activityLight,
                iconColor: AppColors.activity,
              ),
              Positioned(
                top: 10, left: 10,
                child: _badge(activity.categoryName ?? 'Acara', Colors.black54, Colors.white),
              ),
              Positioned(
                top: 10, right: 10,
                child: _badge(
                  activity.isActive ? 'Aktif' : 'Nonaktif',
                  activity.isActive ? AppColors.success : AppColors.textSecondary,
                  Colors.white,
                ),
              ),
              if (activity.isEventPassed)
                Positioned(
                  bottom: 10, left: 10,
                  child: _badge('Sudah Berlalu', AppColors.error, Colors.white),
                ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.name,
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
                      activity.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ]),
                if (activity.eventDate != null) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textHint),
                    const SizedBox(width: 3),
                    Text(
                      formatDate(activity.eventDate),
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ]),
                ],

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
                            activity.isFree ? 'Gratis' : formatRupiah(activity.price),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.activity,
                            ),
                          ),
                          Text(
                            '${activity.availableSlots}/${activity.capacity} slot  ·  ${activity.bookingsCount} booking',
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textHint),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onToggle,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: activity.isActive ? AppColors.textSecondary : AppColors.success,
                          side: BorderSide(color: activity.isActive ? AppColors.border : AppColors.success),
                          minimumSize: const Size(0, 38),
                        ),
                        icon: Icon(
                          activity.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 15,
                        ),
                        label: Text(
                          activity.isActive ? 'Nonaktifkan' : 'Aktifkan',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, color: AppColors.activity),
                      tooltip: 'Edit',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.activityLight,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 6),
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
    child: Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
  );
}

// ── Skeleton ──────────────────────────────────────────────
class _ActivitySkelCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: double.infinity, height: 150, borderRadius: 14),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SkeletonBox(width: 220, height: 16),
              const SizedBox(height: 8),
              SkeletonBox(width: 170, height: 13),
              const SizedBox(height: 6),
              SkeletonBox(width: 130, height: 13),
              const SizedBox(height: 12),
              SkeletonBox(width: 100, height: 18),
            ]),
          ),
        ],
      ),
    );
  }
}
