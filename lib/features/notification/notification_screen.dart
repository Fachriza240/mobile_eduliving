import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/widgets/common_widgets.dart';
import '../profile/screens/riwayat_screen.dart';
import 'package:provider/provider.dart';
import '../auth/providers/auth_provider.dart';
import '../provider/screens/booking_mgmt/provider_booking_list_screen.dart';

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
      final res = await _api.get('/notifications');
      // Backend return: [ status, pagination, notifications [...], unread_count: N ]
      final data = res['data'];
      setState(() {
        if (data is Map) {
          _notifications = data['notifications'] ?? data['data'] ?? [];
          _unreadCount = data['unread_count'] ?? 0;
        } else if (data is List) {
          _notifications = data;
          _unreadCount =
              _notifications.where((n) => n['read_at'] == null).length;
        } else {
          _notifications = [];
        }
      });
    } catch (_) {
      setState(() => _notifications = []);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _api.patch('/notifications/read-all');
      setState(() {
        _notifications = _notifications
            .map((n) => {...n, 'is_unread': false})
            .toList();
        _unreadCount = 0;
      });
    } catch (_) {}
  }

  Future<void> _markRead(int index) async {
    final n = _notifications[index];
    if (n['is_unread'] == false) return;
    try {
      await _api.patch('/notifications/${n['id']}/read');
      setState(() {
        _notifications[index] = {
          ..._notifications[index],
          'is_unread': false,
        };
        _unreadCount = (_unreadCount - 1).clamp(0, 999);
      });
    } catch (_) {}
  }

  IconData _typeIcon(String? iconStr) {
    if (iconStr == null) return Icons.notifications_rounded;
    if (iconStr.contains('check')) return Icons.check_circle_rounded;
    if (iconStr.contains('times') || iconStr.contains('xmark')) return Icons.cancel_rounded;
    if (iconStr.contains('shopping') || iconStr.contains('box') || iconStr.contains('cart')) return Icons.local_mall_rounded;
    if (iconStr.contains('home') || iconStr.contains('building')) return Icons.home_work_rounded;
    if (iconStr.contains('star')) return Icons.star_rounded;
    if (iconStr.contains('calendar')) return Icons.calendar_month_rounded;
    if (iconStr.contains('exclamation') || iconStr.contains('warning')) return Icons.warning_rounded;
    if (iconStr.contains('money') || iconStr.contains('wallet')) return Icons.account_balance_wallet_rounded;
    return Icons.notifications_rounded;
  }

  Color _typeColor(String? colorStr) {
    if (colorStr == null) return AppColors.primary;
    final c = colorStr.toLowerCase();
    if (c.contains('green')) return Colors.green;
    if (c.contains('blue')) return Colors.blue;
    if (c.contains('red')) return Colors.red;
    if (c.contains('orange')) return Colors.orange;
    if (c.contains('yellow')) return Colors.amber;
    if (c.contains('purple')) return Colors.purple;
    return AppColors.primary;
  }

  void _handleNavigation(String? url) {
    if (url == null || url.isEmpty || url == '/') return;
    
    // Konversi URL backend menjadi Route mobile
    if (url.contains('provider/bookings')) {
      final user = context.read<AuthProvider>().user;
      final isRes = user?.isProviderResidence ?? false;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProviderBookingListScreen(isResidence: isRes),
        ),
      );
    } else if (url.contains('provider/dashboard') || url.contains('seller/orders')) {
      Navigator.pushNamed(context, '/home');
    } else if (url.contains('user/transactions')) {
      // Notif transaksi barang → Riwayat tab Barang
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => const RiwayatScreen(initialKategori: RiwayatKategori.barang),
      ));
    } else if (url.contains('user/bookings')) {
      // Notif booking/rating/perpanjang → Riwayat tab Hunian
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => const RiwayatScreen(initialKategori: RiwayatKategori.hunian),
      ));
    } else if (url.contains('marketplace')) {
      Navigator.pushNamed(context, '/marketplace');
    }
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
    final isUnread = n['is_unread'] == true;
    
    final message = n['message']?.toString() ?? n['data']?['message'] ?? 'Ada pemberitahuan baru';
    final timeStr = n['time']?.toString() ?? formatDate(DateTime.tryParse(n['created_at'] ?? ''));
    
    final iconStr = n['icon']?.toString();
    final colorStr = n['color']?.toString();
    final urlStr = n['url']?.toString() ?? n['data']?['url']?.toString();

    return InkWell(
      onTap: () {
        _markRead(i);
        _handleNavigation(urlStr);
      },
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
                color: _typeColor(colorStr).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_typeIcon(iconStr), color: _typeColor(colorStr), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight:
                            isUnread ? FontWeight.w600 : FontWeight.w400,
                        color: AppColors.textPrimary,
                        height: 1.4),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    timeStr,
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
