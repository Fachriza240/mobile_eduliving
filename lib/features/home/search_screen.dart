import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
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

  List _residences = [];
  List _activities = [];
  List _products  = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) return;
    setState(() { _isLoading = true; _hasSearched = true; });

    try {
      final res = await _api.get('/search', queryParameters: {'q': q.trim()});
      setState(() {
        _residences = res['data']?['residences'] ?? [];
        _activities = res['data']?['activities'] ?? [];
        _products   = res['data']?['products']   ?? [];
      });
    } catch (_) {
      setState(() {
        _residences = []; _activities = []; _products = [];
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  int get _total => _residences.length + _activities.length + _products.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: TextField(
          controller: _ctrl,
          focusNode: _focus,
          style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
          decoration: InputDecoration(
            hintText: 'Cari hunian, acara, atau barang...',
            hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontFamily: 'Poppins',
                fontSize: 14),
            border: InputBorder.none,
            suffixIcon: _ctrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () {
                      _ctrl.clear();
                      setState(() { _hasSearched = false; });
                    },
                  )
                : null,
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: _search,
          onChanged: (v) => setState(() {}),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : !_hasSearched
              ? _buildHint()
              : _total == 0
                  ? _buildEmpty()
                  : _buildResults(),
    );
  }

  Widget _buildHint() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.search, size: 56, color: AppColors.textHint),
        const SizedBox(height: 12),
        const Text('Ketik lalu tekan Enter untuk mencari',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: AppColors.textSecondary)),
      ]),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.search_off_outlined, size: 48, color: AppColors.textHint),
        const SizedBox(height: 12),
        Text('Tidak ada hasil untuk "${_ctrl.text}"',
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: AppColors.textSecondary)),
      ]),
    );
  }

  Widget _buildResults() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_residences.isNotEmpty) ...[
          _sectionLabel('Hunian', AppColors.residence, '${_residences.length}'),
          ..._residences.map((e) => _ResultTile(
            icon: Icons.home_work_outlined,
            color: AppColors.residence,
            title: e['name'] ?? '',
            subtitle: e['address'] ?? '',
            price: e['price'],
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ResidenceDetailScreen(id: e['id']),
            )),
          )),
          const SizedBox(height: 16),
        ],
        if (_activities.isNotEmpty) ...[
          _sectionLabel('Acara', AppColors.activity, '${_activities.length}'),
          ..._activities.map((e) => _ResultTile(
            icon: Icons.event_outlined,
            color: AppColors.activity,
            title: e['name'] ?? '',
            subtitle: e['location'] ?? '',
            price: e['price'],
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ActivityDetailScreen(id: e['id']),
            )),
          )),
          const SizedBox(height: 16),
        ],
        if (_products.isNotEmpty) ...[
          _sectionLabel('Marketplace', AppColors.market, '${_products.length}'),
          ..._products.map((e) => _ResultTile(
            icon: Icons.storefront_outlined,
            color: AppColors.market,
            title: e['name'] ?? '',
            subtitle: e['seller']?['name'] ?? '',
            price: e['price'],
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ProductDetailScreen(productId: e['id']),
            )),
          )),
        ],
      ],
    );
  }

  Widget _sectionLabel(String label, Color color, String count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Container(
          width: 4, height: 16,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Text(count,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ),
      ]),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final dynamic price;
  final VoidCallback onTap;

  const _ResultTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.onTap,
  });

  String _rupiah(dynamic p) {
    if (p == null) return 'Gratis';
    final v = double.tryParse(p.toString()) ?? 0;
    if (v == 0) return 'Gratis';
    return 'Rp ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              if (subtitle.isNotEmpty)
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.textSecondary)),
            ]),
          ),
          Text(_rupiah(price),
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ]),
      ),
    );
  }
}