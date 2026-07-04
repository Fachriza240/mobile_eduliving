import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../residence/screens/residence_detail_screen.dart';
import '../activity/screens/activity_detail_screen.dart';
import '../marketplace/screens/product_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _api = ApiService();
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;

  List _residences = [];
  List _activities = [];
  List _products = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() {
        _hasSearched = false;
        _residences = [];
        _activities = [];
        _products = [];
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 600), () => _search(q));
  }

  Future<void> _search(String q) async {
    final query = q.trim();
    if (query.isEmpty) return;
    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _lastQuery = query;
    });

    try {
      // Panggil 3 endpoint sekaligus secara paralel
      // Gunakan endpoint dedicated agar hasil pencarian seakurat mungkin
      final results = await Future.wait([
        _api.get('/residences', queryParameters: {'search': query, 'per_page': 20}),
        _api.get('/activities', queryParameters: {'search': query, 'per_page': 20}),
        _api.get('/marketplace', queryParameters: {'search': query, 'per_page': 20}),
      ]);

      List extract(dynamic val) {
        if (val == null) return [];
        if (val is List) return val;
        if (val is Map && val['data'] is List) return val['data'] as List;
        return [];
      }

      setState(() {
        _residences = extract(results[0]['data']);
        _activities = extract(results[1]['data']);
        _products   = extract(results[2]['data']);
      });
    } catch (e) {
      debugPrint('[SEARCH] ERROR: $e');
      setState(() {
        _residences = [];
        _activities = [];
        _products = [];
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clear() {
    _ctrl.clear();
    _debounce?.cancel();
    setState(() {
      _hasSearched = false;
      _residences = [];
      _activities = [];
      _products = [];
    });
    _focus.requestFocus();
  }

  int get _total => _residences.length + _activities.length + _products.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: Column(
        children: [
          _buildSearchHeader(context),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : !_hasSearched
                    ? _buildHint()
                    : _total == 0
                        ? _buildEmpty()
                        : _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Row(
        children: [
          // Tombol kembali
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          // Search input
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _ctrl,
                focusNode: _focus,
                style: const TextStyle(
                  color: Colors.black87,
                  fontFamily: 'Poppins',
                  fontSize: 14,
                ),
                cursorColor: AppColors.primary,
                decoration: InputDecoration(
                  hintText: 'Cari hunian, acara, barang...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontFamily: 'Poppins',
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: Colors.grey.shade400, size: 20),
                  suffixIcon: _ctrl.text.isNotEmpty
                      ? GestureDetector(
                          onTap: _clear,
                          child: Icon(Icons.cancel_rounded,
                              color: Colors.grey.shade400, size: 20),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                  isDense: true,
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: _search,
                onChanged: _onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHint() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.search_rounded,
              size: 40, color: AppColors.primary),
        ),
        const SizedBox(height: 20),
        const Text('Cari apa yang kamu butuhkan',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B))),
        const SizedBox(height: 8),
        // Chip kategori
        Wrap(
          spacing: 8,
          children: [
            _chipHint('Hunian'),
            _chipHint('Acara'),
            _chipHint('Barang'),
          ],
        ),
      ]),
    );
  }

  Widget _chipHint(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)
        ],
      ),
      child: Text(label,
          style: const TextStyle(
              fontFamily: 'Poppins', fontSize: 13, color: Color(0xFF475569))),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.search_off_rounded,
              size: 40, color: Color(0xFFEF4444)),
        ),
        const SizedBox(height: 20),
        const Text('Tidak ada hasil',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Pencarian "$_lastQuery" tidak ditemukan',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontFamily: 'Poppins', fontSize: 13, color: Color(0xFF64748B))),
        const SizedBox(height: 4),
        const Text('Coba gunakan kata kunci lain',
            style: TextStyle(
                fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF94A3B8))),
      ]),
    );
  }

  Widget _buildResults() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Ringkasan hasil
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Ditemukan $_total hasil untuk "$_lastQuery"',
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Color(0xFF475569))),
            ],
          ),
        ),
        if (_residences.isNotEmpty) ...[
          _sectionLabel('Hunian', const Color(0xFF2563EB),
              Icons.home_work_rounded, _residences.length),
          const SizedBox(height: 8),
          ..._residences.map((e) {
            final imgs = e['images'] as List?;
            final imgPath = (imgs != null && imgs.isNotEmpty) ? imgs[0].toString() : null;
            return _ResultTile(
              imageUrl: imgPath != null ? _buildUrl(imgPath) : null,
              icon: Icons.home_work_outlined,
              iconBg: const Color(0xFFEFF6FF),
              color: const Color(0xFF2563EB),
              title: e['name'] ?? '',
              subtitle: e['address'] ?? '',
              priceLabel: _rupiah(e['price'], suffix: '/bln'),
              badge: e['category']?['name'] ?? e['residence_type'],
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => ResidenceDetailScreen(id: e['id']),
              )),
            );
          }),
          const SizedBox(height: 20),
        ],
        if (_activities.isNotEmpty) ...[
          _sectionLabel('Acara', const Color(0xFF059669),
              Icons.event_available_rounded, _activities.length),
          const SizedBox(height: 8),
          ..._activities.map((e) {
            final imgs = e['images'] as List?;
            final imgPath = (imgs != null && imgs.isNotEmpty) ? imgs[0].toString() : null;
            final price = e['ticket_price'] ?? e['price'];
            // Format tanggal event
            String dateStr = '';
            if (e['event_date'] != null) {
              final dt = DateTime.tryParse(e['event_date'].toString());
              if (dt != null) {
                const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
                dateStr = '${dt.day} ${months[dt.month - 1]} ${dt.year}';
              }
            }
            return _ResultTile(
              imageUrl: imgPath != null ? _buildUrl(imgPath) : null,
              icon: Icons.event_outlined,
              iconBg: const Color(0xFFECFDF5),
              color: const Color(0xFF059669),
              title: e['name'] ?? '',
              subtitle: e['location'] ?? '',
              priceLabel: _rupiah(price),
              badge: dateStr.isNotEmpty ? dateStr : e['category']?['name'],
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => ActivityDetailScreen(id: e['id']),
              )),
            );
          }),
          const SizedBox(height: 20),
        ],
        if (_products.isNotEmpty) ...[
          _sectionLabel('Marketplace', const Color(0xFFEA580C),
              Icons.storefront_rounded, _products.length),
          const SizedBox(height: 8),
          ..._products.map((e) {
            final imgs = e['images'] as List?;
            final imgPath = (imgs != null && imgs.isNotEmpty) ? imgs[0].toString() : null;
            return _ResultTile(
              imageUrl: imgPath != null ? _buildUrl(imgPath) : null,
              icon: Icons.storefront_outlined,
              iconBg: const Color(0xFFFFF7ED),
              color: const Color(0xFFEA580C),
              title: e['name'] ?? '',
              subtitle: e['seller']?['name'] ?? e['user']?['name'] ?? '',
              priceLabel: _rupiah(e['price']),
              badge: e['condition'] == 'new' ? 'Baru'
                   : e['condition'] == 'used' ? 'Bekas' : e['condition'],
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => ProductDetailScreen(productId: e['id']),
              )),
            );
          }),
        ],
      ],
    );
  }

  // Helpers
  String _buildUrl(String path) {
    if (path.startsWith('http')) return path;
    final clean = path.startsWith('/') ? path.substring(1) : path;
    return '${ApiConstants.baseUrl}/file/$clean';
  }

  String _rupiah(dynamic p, {String suffix = ''}) {
    if (p == null) return 'Gratis';
    final v = double.tryParse(p.toString()) ?? 0;
    if (v == 0) return 'Gratis';
    final formatted = v.toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return 'Rp $formatted$suffix';
  }

  Widget _sectionLabel(String label, Color color, IconData icon, int count) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20)),
          child: Text('$count',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ),
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  final String? imageUrl;
  final IconData icon;
  final Color iconBg;
  final Color color;
  final String title;
  final String subtitle;
  final String priceLabel;
  final String? badge;
  final VoidCallback onTap;

  const _ResultTile({
    this.imageUrl,
    required this.icon,
    required this.iconBg,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.priceLabel,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail gambar atau ikon fallback
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
              child: SizedBox(
                width: 80,
                height: 80,
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: iconBg,
                          child: Icon(icon, color: color, size: 28),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: iconBg,
                          child: Icon(icon, color: color, size: 28),
                        ),
                      )
                    : Container(
                        color: iconBg,
                        child: Icon(icon, color: color, size: 28),
                      ),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (badge != null && badge!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge!,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 11, color: Colors.grey.shade400),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      priceLabel,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.chevron_right_rounded,
                  color: Colors.grey.shade300, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
