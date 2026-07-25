import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bookmark_provider.dart';
import '../models/bookmark_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../residence/screens/residence_detail_screen.dart';
import '../../activity/screens/activity_detail_screen.dart';
import '../../marketplace/screens/product_detail_screen.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookmarkProvider>().fetchBookmarks();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Tersimpan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Hunian'),
            Tab(text: 'Acara'),
            Tab(text: 'Barang'),
          ],
        ),
      ),
      body: Consumer<BookmarkProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (provider.error != null) {
            return _ErrorView(
              message: provider.error!,
              onRetry: provider.fetchBookmarks,
            );
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _BookmarkList(
                items: provider.residenceBookmarks,
                emptyLabel: 'Belum ada hunian tersimpan',
                emptyIcon: Icons.home_outlined,
                accentColor: AppColors.residence,
              ),
              _BookmarkList(
                items: provider.activityBookmarks,
                emptyLabel: 'Belum ada acara tersimpan',
                emptyIcon: Icons.event_outlined,
                accentColor: AppColors.activity,
              ),
              _BookmarkList(
                items: provider.marketplaceBookmarks,
                emptyLabel: 'Belum ada produk tersimpan',
                emptyIcon: Icons.storefront_outlined,
                accentColor: AppColors.market,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BookmarkList extends StatelessWidget {
  final List<BookmarkModel> items;
  final String emptyLabel;
  final IconData emptyIcon;
  final Color accentColor;

  const _BookmarkList({
    required this.items,
    required this.emptyLabel,
    required this.emptyIcon,
    required this.accentColor,
  });

  void _navigateToDetail(BuildContext context, BookmarkModel bookmark) {
    final id = bookmark.bookmarkable.id;
    switch (bookmark.bookmarkableType) {
      case 'Residence':
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ResidenceDetailScreen(id: id),
            ));
        break;
      case 'Activity':
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ActivityDetailScreen(id: id),
            ));
        break;
      case 'MarketplaceProduct':
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(productId: id),
            ));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyState(
          label: emptyLabel, icon: emptyIcon, color: accentColor);
    }

    return RefreshIndicator(
      color: accentColor,
      onRefresh: () => context.read<BookmarkProvider>().fetchBookmarks(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final bookmark = items[index];
          return _BookmarkCard(
            bookmark: bookmark,
            accentColor: accentColor,
            onTap: () => _navigateToDetail(context, bookmark),
            onRemove: () => context.read<BookmarkProvider>().toggle(
                  bookmark.bookmarkableType,
                  bookmark.bookmarkable.id,
                ),
          );
        },
      ),
    );
  }
}

class _BookmarkCard extends StatelessWidget {
  final BookmarkModel bookmark;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _BookmarkCard({
    required this.bookmark,
    required this.accentColor,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final item = bookmark.bookmarkable;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: item.firstImage.isNotEmpty
                  ? EduImage(
                      path: item.firstImage,
                      width: 90,
                      height: 90,
                      placeholderIcon:
                          _getPlaceholderIcon(bookmark.bookmarkableType),
                      placeholderColor: accentColor.withOpacity(0.1),
                      iconColor: accentColor,
                    )
                  : _imagePlaceholder(accentColor),
            ),
            // Info
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (item.displayAddress.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              item.displayAddress,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[500]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppHelpers.formatPrice(item.price),
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        if (bookmark.bookmarkableType == 'Residence' &&
                            item.averageRating != null &&
                            item.averageRating! > 0)
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  size: 12, color: Colors.amber),
                              const SizedBox(width: 2),
                              Text(
                                item.averageRating!.toStringAsFixed(1),
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Tombol hapus bookmark
            IconButton(
              onPressed: onRemove,
              icon: Icon(Icons.bookmark, color: accentColor, size: 22),
              tooltip: 'Hapus dari tersimpan',
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder(Color color) {
    return Container(
      width: 90,
      height: 90,
      color: color.withOpacity(0.1),
      child:
          Icon(Icons.image_outlined, color: color.withOpacity(0.4), size: 28),
    );
  }

  IconData _getPlaceholderIcon(String type) {
    switch (type) {
      case 'Residence':
        return Icons.home_work_outlined;
      case 'Activity':
        return Icons.event_outlined;
      case 'MarketplaceProduct':
        return Icons.storefront_outlined;
      default:
        return Icons.image_outlined;
    }
  }
}

class _EmptyState extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _EmptyState(
      {required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Text(
            'Simpan yang kamu suka\nagar mudah ditemukan lagi',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}
