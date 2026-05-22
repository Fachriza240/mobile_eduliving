import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/common_widgets.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _api = ApiService();
  List _notifications = [];
  bool _isLoading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get('/user/notifications');
      setState(() {
        _notifications = res['data'] ?? [];
        _unreadCount = _notifications.where((n) => n['read_at'] == null).length;
      });
    } catch (_) {
      setState(() => _notifications = []);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _api.post('/user/notifications/read-all');
      setState(() {
        _notifications = _notifications
            .map((n) => {...n, 'read_at': DateTime.now().toIso8601String()})
            .toList();
        _unreadCount = 0;
      });
    } catch (_) {}
  }

  Future<void> _markRead(int index) async {
    final n = _notifications[index];
    if (n['read_at'] != null) return;
    try {
      await _api.post('/user/notifications/${n['id']}/read');
      setState(() {
        _notifications[index] = {
          ..._notifications[index],
          'read_at': DateTime.now().toIso8601String(),
        };
        _unreadCount = (_unreadCount - 1).clamp(0, 999);
      });
    } catch (_) {}
  }

  IconData _typeIcon(String? type) {
    if (type == null) return Icons.notifications_outlined;
    if (type.contains('Booking')) return Icons.calendar_today_outlined;
    if (type.contains('Activity')) return Icons.event_outlined;
    if (type.contains('Transaction')) return Icons.storefront_outlined;
    return Icons.notifications_outlined;
  }

  Color _typeColor(String? type) {
    if (type == null) return AppColors.primary;
    if (type.contains('Activity')) return AppColors.activity;
    if (type.contains('Transaction')) return AppColors.market;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        title: const Text('Notifikasi',
            style:
                TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Tandai semua dibaca',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'Poppins')),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _notifications.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _load,
                  child: ListView.separated(
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) => _buildTile(i),
                  ),
                ),
    );
  }

  Widget _buildTile(int i) {
    final n = _notifications[i];
    final isUnread = n['read_at'] == null;
    final type = n['type']?.toString().split('.').last;

    return InkWell(
      onTap: () => _markRead(i),
      child: Container(
        color: isUnread ? AppColors.primaryLight : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _typeColor(type).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_typeIcon(type), color: _typeColor(type), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n['data']?['title'] ?? 'Notifikasi',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight:
                            isUnread ? FontWeight.w700 : FontWeight.w500,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    n['data']?['message'] ?? '',
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatDate(DateTime.tryParse(n['created_at'] ?? '')),
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.textHint),
                  ),
                ],
              ),
            ),
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_outlined,
                size: 44, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text('Belum ada notifikasi',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          const Text('Aktivitas terbaru akan muncul di sini',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
