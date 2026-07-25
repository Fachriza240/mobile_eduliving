import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import 'hunian_tab.dart';
import 'acara_tab.dart';
import '../../residence/screens/residence_detail_screen.dart';
import '../../activity/screens/activity_detail_screen.dart';
import '../../marketplace/screens/marketplace_screen.dart';
import '../../marketplace/screens/product_detail_screen.dart';
import '../search_screen.dart';
import '../../profile/screens/riwayat_screen.dart';

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
      // Fetch home data dan marketplace secara paralel
      final results = await Future.wait([
        _api.get(ApiConstants.home),
        _api.get(ApiConstants.marketplace,
            queryParameters: {'per_page': '6', 'page': '1'}),
      ]);

      final homeRes = results[0];
      final marketRes = results[1];

      setState(() {
        _homeData = {
          // API return { status, data: { featured_residences, featured_activities, categories } }
          'residences': homeRes['data']?['featured_residences'] ?? [],
          'activities': homeRes['data']?['featured_activities'] ?? [],
          'categories': homeRes['data']?['categories'] ?? [],
          // Produk dari marketplace endpoint
          'products': (marketRes['data'] as List?) ?? [],
        };
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadHome,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // ── Hero AppBar biru tua ──────────────
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: const Color(0xFF1E3A8A),
              // Logo tetap terlihat saat scroll
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/Infoma_Branding.png',
                    width: 32,
                    height: 32,
                    errorBuilder: (context, error, stackTrace) => Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.school_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'EduLiving',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              // Notif + Avatar tetap terlihat saat scroll
              actions: [
                // Notifikasi
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/notifications'),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(Icons.notifications_none_rounded,
                            color: Colors.white, size: 22),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            radius: 4,
                            backgroundColor: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Avatar foto profil
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                      image: user?.profilePicture != null
                          ? DecorationImage(
                              image: NetworkImage(user!.profilePicture!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: user?.profilePicture == null
                        ? Center(
                            child: Text(
                              (user?.name ?? 'M')[0].toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              // Search bar di bagian bawah appbar
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search,
                              color: Colors.white.withValues(alpha: 0.7),
                              size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Cari hunian, acara, atau barang...',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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

  Widget _buildBody() {
    final residences = (_homeData?['residences'] as List?) ?? [];
    final activities = (_homeData?['activities'] as List?) ?? [];
    final products = (_homeData?['products'] as List?) ?? [];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Sapaan & Welcome Card ─────────────
          _buildWelcomeCard(),
          const SizedBox(height: 24),

          // ── Menu Grid ───────────────────────
          _buildGridMenu(),
          const SizedBox(height: 32),

          // ── Hunian Terbaru ───────────────────
          SectionHeader(
            title: 'Hunian Terbaru',
            onSeeAll: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const HunianTab(showBackButton: true)),
            ),
          ),
          const SizedBox(height: 16),
          _buildResidenceRow(residences),
          const SizedBox(height: 32),

          // ── Acara Mendatang ──────────────────
          SectionHeader(
            title: 'Kegiatan Mendatang',
            seeAllColor: AppColors.activity,
            onSeeAll: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AcaraTab(showBackButton: true)),
            ),
          ),
          const SizedBox(height: 16),
          _buildActivityCol(activities),
          const SizedBox(height: 32),

          // ── Produk Marketplace ───────────────
          SectionHeader(
            title: 'Barang Terbaru',
            seeAllColor: AppColors.market,
            onSeeAll: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      const MarketplaceScreen(showBackButton: true)),
            ),
          ),
          const SizedBox(height: 16),
          _buildProductRow(products),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Welcome Card ────────────────────────────────
  Widget _buildWelcomeCard() {
    final user = context.watch<AuthProvider>().user;
    final firstName = (user?.name ?? 'Mahasiswa').split(' ').first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Halo, $firstName! 👋',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Selamat Datang di EduLiving',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Temukan hunian, kegiatan, dan produk terbaik',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  // ── Menu Utama 2x2 Grid ─────────────────────────────
  Widget _buildGridMenu() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _gridMenuCard(
                icon: Icons.business_rounded,
                title: 'Hunian',
                subtitle: 'Cari tempat tinggal',
                iconColor: Colors.blue,
                bgColor: Colors.blue.withValues(alpha: 0.1),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const HunianTab(showBackButton: true)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _gridMenuCard(
                icon: Icons.event_note_rounded,
                title: 'Kegiatan',
                subtitle: 'Ikuti kegiatan kampus',
                iconColor: Colors.green,
                bgColor: Colors.green.withValues(alpha: 0.1),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AcaraTab(showBackButton: true)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _gridMenuCard(
                icon: Icons.storefront_rounded,
                title: 'Barang',
                subtitle: 'Belanja produk',
                iconColor: Colors.orange,
                bgColor: Colors.orange.withValues(alpha: 0.1),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const MarketplaceScreen(showBackButton: true)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _gridMenuCard(
                icon: Icons.receipt_long_rounded,
                title: 'Transaksi',
                subtitle: 'Riwayat belanja',
                iconColor: Colors.deepPurpleAccent,
                bgColor: Colors.deepPurpleAccent.withValues(alpha: 0.1),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RiwayatScreen(
                          initialKategori: RiwayatKategori.barang)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _gridMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 1),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: AppColors.textHint,
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
          builder: (_) => ResidenceDetailScreen(id: data['id'] as int),
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
              width: double.infinity,
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
                  if (data['has_discount'] == true ||
                      data['has_discount'] == 1 ||
                      data['has_discount'] == '1' ||
                      data['discount_type'] != null)
                    Text(
                      _rupiah(data['price'],
                          period: data['rental_period'] ?? data['rent_period']),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: AppColors.textHint,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  Text(
                    _rupiah(
                        data['discounted_price'] ??
                            _calcDiscount(data['price'], data['discount_type'],
                                data['discount_value']),
                        period: data['rental_period'] ?? data['rent_period']),
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

  String _rupiah(dynamic p, {String? period}) {
    if (p == null) return 'Gratis';
    final v = double.tryParse(p.toString()) ?? 0;
    if (v == 0) return 'Gratis';
    final formatted = formatRupiah(v);
    if (period != null && period.isNotEmpty) {
      return '$formatted/${_shortPeriod(period)}';
    }
    if (v >= 10000000) return '$formatted/thn';
    return '$formatted/bln';
  }

  String _shortPeriod(String? p) {
    switch (p) {
      case 'monthly':
        return 'bln';
      case 'yearly':
        return 'thn';
      case 'daily':
        return 'hari';
      default:
        return 'bln';
    }
  }

  double _calcDiscount(dynamic priceVal, dynamic type, dynamic discountVal) {
    final p = double.tryParse(priceVal?.toString() ?? '0') ?? 0;
    if (type == null || discountVal == null) return p;
    final d = double.tryParse(discountVal.toString()) ?? 0;
    if (d <= 0) return p;
    if (type == 'percentage') {
      return p - (p * d / 100);
    }
    return p - d;
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
          builder: (_) => ActivityDetailScreen(id: data['id'] as int),
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
                  if (data['has_discount'] == true ||
                      data['has_discount'] == 1 ||
                      data['has_discount'] == '1' ||
                      data['discount_type'] != null)
                    Text(
                      _price(data['price']),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: AppColors.textHint,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  Text(
                    _price(data['discounted_price'] ??
                        _calcDiscount(data['price'], data['discount_type'],
                            data['discount_value'])),
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
    return formatRupiah(v);
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

  double _calcDiscount(dynamic priceVal, dynamic type, dynamic discountVal) {
    final p = double.tryParse(priceVal?.toString() ?? '0') ?? 0;
    if (type == null || discountVal == null) return p;
    final d = double.tryParse(discountVal.toString()) ?? 0;
    if (d <= 0) return p;
    if (type == 'percentage') {
      return p - (p * d / 100);
    }
    return p - d;
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
            Stack(
              children: [
                EduImage(
                  path: imgPath,
                  width: double.infinity,
                  height: 110,
                  borderRadius: 12,
                  placeholderIcon: Icons.storefront_outlined,
                  placeholderColor: AppColors.marketLight,
                  iconColor: AppColors.market,
                ),
                Builder(
                  builder: (ctx) {
                    final userId = ctx.read<AuthProvider>().user?.id;
                    final sellerId = data['seller']?['id'];
                    if (userId == null ||
                        sellerId == null ||
                        sellerId != userId) {
                      return const SizedBox.shrink();
                    }
                    return Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.market,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.storefront_rounded,
                                size: 9, color: Colors.white),
                            SizedBox(width: 2),
                            Text(
                              'Produk Anda',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
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
