import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../residence/screens/residence_list_screen.dart';
import '../../activity/screens/activity_list_screen.dart';
import '../../marketplace/screens/marketplace_screen.dart';
import '../../marketplace/screens/product_detail_screen.dart';
import '../search_screen.dart';

class BerandaTab extends StatefulWidget {
  const BerandaTab({super.key});

  @override
  State<BerandaTab> createState() => _BerandaTabState();
}

class _BerandaTabState extends State<BerandaTab> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _homeData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHome();
  }

  Future<void> _loadHome() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await _api.get(ApiConstants.home);
      setState(() {
        _homeData = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat data. Tarik untuk muat ulang.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final firstName = (user?.name ?? 'Mahasiswa').split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadHome,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // ── Hero AppBar biru tua ──────────────
            SliverAppBar(
              expandedHeight: 185,
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: AppColors.primaryDark,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHero(firstName),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: _buildSearchBar(),
              ),
            ),

            // ── Konten ───────────────────────────
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: ErrorState(
                  message: _error!,
                  onRetry: _loadHome,
                ),
              )
            else
              SliverToBoxAdapter(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ── Hero gradient biru tua ────────────────────────
  Widget _buildHero(String firstName) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF1E40AF),
            Color(0xFF2563EB),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, $firstName! 👋',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Temukan kebutuhan kampusmu',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.80),
                  ),
                ),
              ],
            ),
          ),
          // Notifikasi
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  // ── Search bar ────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      color: AppColors.primaryDeep,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SearchScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: AppColors.textHint, size: 20),
              SizedBox(width: 10),
              Text(
                'Cari hunian, acara, atau barang...',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final residences = (_homeData?['residences'] as List?) ?? [];
    final activities = (_homeData?['activities'] as List?) ?? [];
    final products = (_homeData?['products'] as List?) ?? [];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Quick Menu ───────────────────────
          const Text('Menu Utama',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          _buildQuickMenu(),
          const SizedBox(height: 24),

          // ── Hunian Terbaru ───────────────────
          SectionHeader(
            title: 'Hunian Terbaru',
            onSeeAll: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ResidenceListScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _buildResidenceRow(residences),
          const SizedBox(height: 24),

          // ── Acara Mendatang ──────────────────
          SectionHeader(
            title: 'Acara Mendatang',
            seeAllColor: AppColors.activity,
            onSeeAll: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ActivityListScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _buildActivityCol(activities),
          const SizedBox(height: 24),

          // ── Produk Marketplace ───────────────
          SectionHeader(
            title: 'Produk Terbaru',
            seeAllColor: AppColors.market,
            onSeeAll: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MarketplaceScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _buildProductRow(products),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Quick Menu 4 item ─────────────────────────────
  Widget _buildQuickMenu() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _menuItem(
          icon: Icons.home_work_rounded,
          label: 'Hunian',
          color: AppColors.residence,
          bg: AppColors.residenceLight,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ResidenceListScreen()),
          ),
        ),
        _menuItem(
          icon: Icons.event_rounded,
          label: 'Acara',
          color: AppColors.activity,
          bg: AppColors.activityLight,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ActivityListScreen()),
          ),
        ),
        _menuItem(
          icon: Icons.store_rounded,
          label: 'Barang',
          color: AppColors.market,
          bg: AppColors.marketLight,
          onTap: () => Navigator.pushNamed(context, '/marketplace'),
        ),
        _menuItem(
          icon: Icons.bookmark_rounded,
          label: 'Bookmark',
          color: AppColors.primary,
          bg: AppColors.primaryLight,
          onTap: () => Navigator.pushNamed(context, '/bookmarks'),
        ),
      ],
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  // ── Hunian horizontal scroll ──────────────────────
  Widget _buildResidenceRow(List items) {
    if (items.isEmpty) {
      return _emptyCard('Belum ada hunian tersedia', Icons.home_work_outlined);
    }
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length > 5 ? 5 : items.length,
        itemBuilder: (_, i) =>
            _ResidenceHCard(data: items[i] as Map<String, dynamic>),
      ),
    );
  }

  // ── Acara vertikal ────────────────────────────────
  Widget _buildActivityCol(List items) {
    if (items.isEmpty) {
      return _emptyCard('Belum ada acara mendatang', Icons.event_outlined);
    }
    return Column(
      children: items.take(3).map((item) {
        return _ActivityHCard(data: item as Map<String, dynamic>);
      }).toList(),
    );
  }

  // ── Produk horizontal scroll ──────────────────────
  Widget _buildProductRow(List items) {
    if (items.isEmpty) {
      return _emptyCard('Belum ada produk tersedia', Icons.storefront_outlined);
    }
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length > 5 ? 5 : items.length,
        itemBuilder: (_, i) =>
            _ProductHCard(data: items[i] as Map<String, dynamic>),
      ),
    );
  }

  Widget _emptyCard(String msg, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.textHint),
          const SizedBox(height: 8),
          Text(msg,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ── Card Hunian Horizontal ────────────────────────────
class _ResidenceHCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ResidenceHCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final images = data['images'] as List?;
    final imgPath =
        images != null && images.isNotEmpty ? images.first.toString() : null;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResidenceListScreen(initialId: data['id'] as int?),
        ),
      ),
      child: Container(
        width: 175,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EduImage(
              path: imgPath,
              height: 110,
              borderRadius: 12,
              placeholderIcon: Icons.home_work_outlined,
              placeholderColor: AppColors.residenceLight,
              iconColor: AppColors.residence,
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['name'] ?? '-',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 11, color: AppColors.textHint),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(data['address'] ?? '-',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              color: AppColors.textSecondary)),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Text(
                    _rupiah(data['price']),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.residence,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _rupiah(dynamic p) {
    if (p == null) return 'Gratis';
    final v = double.tryParse(p.toString()) ?? 0;
    if (v == 0) return 'Gratis';
    return 'Rp ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}/bln';
  }
}

// ── Card Acara Vertikal ───────────────────────────────
class _ActivityHCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ActivityHCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final images = data['images'] as List?;
    final imgPath =
        images != null && images.isNotEmpty ? images.first.toString() : null;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActivityListScreen(initialId: data['id'] as int?),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.8),
        ),
        child: Row(
          children: [
            EduImage(
              path: imgPath,
              width: 70,
              height: 70,
              borderRadius: 10,
              placeholderIcon: Icons.event_outlined,
              placeholderColor: AppColors.activityLight,
              iconColor: AppColors.activity,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['name'] ?? '-',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 11, color: AppColors.activity),
                    const SizedBox(width: 4),
                    Text(
                      _date(data['event_date']),
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.activity),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    _price(data['price']),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.activity,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.activityLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${data['available_slots'] ?? 0} slot',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.activity,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _price(dynamic p) {
    if (p == null) return 'Gratis';
    final v = double.tryParse(p.toString()) ?? 0;
    if (v == 0) return 'Gratis';
    return 'Rp ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  String _date(dynamic d) {
    if (d == null) return '-';
    try {
      final dt = DateTime.parse(d.toString());
      const m = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des'
      ];
      return '${dt.day} ${m[dt.month]} ${dt.year}';
    } catch (_) {
      return d.toString();
    }
  }
}

// ── Card Produk Horizontal ───────────────────────────
class _ProductHCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ProductHCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final images = data['images'] as List?;
    final imgPath =
        images != null && images.isNotEmpty ? images.first.toString() : null;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(productId: data['id'] as int),
        ),
      ),
      child: Container(
        width: 175,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EduImage(
              path: imgPath,
              height: 110,
              borderRadius: 12,
              placeholderIcon: Icons.storefront_outlined,
              placeholderColor: AppColors.marketLight,
              iconColor: AppColors.market,
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['name'] ?? '-',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.store_outlined,
                        size: 11, color: AppColors.textHint),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(data['seller']?['name'] ?? '-',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              color: AppColors.textSecondary)),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Text(
                    _priceFormat(data['price']),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.market,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _priceFormat(dynamic p) {
    if (p == null) return 'Gratis';
    final v = double.tryParse(p.toString()) ?? 0;
    if (v == 0) return 'Gratis';
    return 'Rp ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }
}
