import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_colors.dart';
import '../constants/api_constants.dart';
import '../utils/storage_helper.dart';

// ============================================================
// HELPER FUNCTIONS
// ============================================================

String buildImageUrl(String path) {
  if (path.isEmpty) return '';

  // Kalau sudah full URL langsung return
  if (path.startsWith('http')) return path;

  // Hapus slash di awal jika ada
  String cleanPath = path.startsWith('/') ? path.substring(1) : path;

  // Hapus prefix 'storage/' jika ada (Laravel menyimpan di storage/app/public)
  // tapi route /file/ sudah handle ini
  // Jangan double-prefix: jika sudah 'api/v1/file/...' jangan tambah lagi
  if (cleanPath.startsWith('api/')) {
    final baseHost = ApiConstants.baseUrl.replaceAll('/api/v1', '');
    return '$baseHost/$cleanPath';
  }

  // Gunakan route /api/v1/file/ (bypass symlink Windows)
  final base = ApiConstants.baseUrl; // sudah include /api/v1
  return '$base/file/$cleanPath';
}

/// Mendapatkan header auth untuk request gambar.
/// Dipanggil async karena token disimpan di SharedPreferences.
Future<Map<String, String>> getImageAuthHeaders() async {
  final token = await StorageHelper.getToken();
  if (token != null && token.isNotEmpty) {
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }
  return {'Accept': 'application/json'};
}

String formatRupiah(double amount, {String suffix = ''}) {
  if (amount == 0) return 'Gratis';
  final f = amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
  return suffix.isNotEmpty ? 'Rp $f$suffix' : 'Rp $f';
}

String formatDate(DateTime? date) {
  if (date == null) return '-';
  const months = [
    '',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember'
  ];
  return '${date.day} ${months[date.month]} ${date.year}';
}

String formatDateShort(DateTime? date) {
  if (date == null) return '-';
  const months = [
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
  return '${date.day} ${months[date.month]} ${date.year}';
}

// ============================================================
// SKELETON LOADING
// ============================================================

class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _anim = Tween(begin: 0.35, end: 0.9).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// NETWORK IMAGE
// ============================================================

class EduImage extends StatefulWidget {
  final String? path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final IconData placeholderIcon;
  final Color? placeholderColor;
  final Color? iconColor;

  const EduImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.placeholderIcon = Icons.image_outlined,
    this.placeholderColor,
    this.iconColor,
  });

  @override
  State<EduImage> createState() => _EduImageState();
}

class _EduImageState extends State<EduImage> {
  Map<String, String>? _headers;
  bool _headersLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadHeaders();
  }

  Future<void> _loadHeaders() async {
    final headers = await getImageAuthHeaders();
    if (mounted) {
      setState(() {
        _headers = headers;
        _headersLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = (widget.path != null && widget.path!.isNotEmpty)
        ? buildImageUrl(widget.path!)
        : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: url != null && _headersLoaded
          ? CachedNetworkImage(
              imageUrl: url,
              httpHeaders: _headers,
              width: widget.width,
              height: widget.height,
              fit: widget.fit,
              memCacheWidth: (widget.width != null && widget.width!.isFinite) 
                  ? (widget.width! * 2).toInt() 
                  : 800,
              placeholder: (context, url) => _placeholder(),
              errorWidget: (context, url, error) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        width: widget.width,
        height: widget.height,
        color: widget.placeholderColor ?? AppColors.primaryLight,
        child: Icon(
          widget.placeholderIcon,
          color: widget.iconColor ?? AppColors.primary,
          size: 28,
        ),
      );
}

// ============================================================
// STATUS BADGE
// ============================================================

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
  });

  factory StatusBadge.booking(String status) {
    final colors = {
      'pending': AppColors.warning,
      'approved': AppColors.success,
      'rejected': AppColors.error,
      'cancelled': AppColors.textHint,
      'completed': AppColors.primary,
    };
    final labels = {
      'pending': 'Menunggu',
      'approved': 'Disetujui',
      'rejected': 'Ditolak',
      'cancelled': 'Dibatalkan',
      'completed': 'Selesai',
    };
    return StatusBadge(
      label: labels[status] ?? status,
      color: colors[status] ?? AppColors.textHint,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ============================================================
// INFO ROW
// ============================================================

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor ?? AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.textHint)),
                Text(value,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION HEADER
// ============================================================

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  final Color? seeAllColor;

  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
    this.seeAllColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: Row(
              children: [
                Text('Lihat Semua',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: seeAllColor ?? AppColors.primary)),
                const SizedBox(width: 2),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 11, color: seeAllColor ?? AppColors.primary),
              ],
            ),
          ),
      ],
    );
  }
}

// ============================================================
// EMPTY STATE
// ============================================================

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color? iconColor;
  // Gunakan action (Widget) ATAU actionLabel+onAction (String+callback)
  final Widget? action;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_rounded,
    this.iconColor,
    this.action,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.textHint).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: iconColor ?? AppColors.textHint),
            ),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5)),
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ] else if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(minimumSize: const Size(140, 44)),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ERROR STATE
// ============================================================

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  size: 48, color: AppColors.error),
            ),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5)),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(160, 44)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// STAR RATING
// ============================================================

class StarRating extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final double size;

  const StarRating({
    super.key,
    required this.rating,
    this.reviewCount = 0,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: size, color: const Color(0xFFF59E0B)),
        const SizedBox(width: 3),
        Text(
          rating > 0 ? rating.toStringAsFixed(1) : '0.0',
          style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: size - 2,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
        ),
        if (reviewCount > 0) ...[
          const SizedBox(width: 3),
          Text('($reviewCount)',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: size - 3,
                  color: AppColors.textHint)),
        ],
      ],
    );
  }
}

// ============================================================
// EDU APP BAR
// ============================================================

class EduAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;
  final Color? backgroundColor;

  const EduAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? AppColors.white,
      title: Text(title),
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      automaticallyImplyLeading: showBack,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// ============================================================
// SEARCH BAR
// ============================================================

class EduSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final Duration debounceDuration;

  const EduSearchBar({
    super.key,
    required this.controller,
    this.hint = 'Cari...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.debounceDuration = const Duration(milliseconds: 500),
  });

  @override
  State<EduSearchBar> createState() => _EduSearchBarState();
}

class _EduSearchBarState extends State<EduSearchBar> {
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    // Rebuild agar clear button muncul/hilang
    if (mounted) setState(() {});
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(widget.debounceDuration, () {
      widget.onChanged?.call(value);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: widget.controller,
        onChanged: _onChanged,
        onSubmitted: widget.onSubmitted,
        style: const TextStyle(
            fontFamily: 'Poppins', fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(
              fontFamily: 'Poppins', fontSize: 14, color: AppColors.textHint),
          prefixIcon:
              const Icon(Icons.search, color: AppColors.textHint, size: 20),
          suffixIcon: widget.controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear,
                      size: 18, color: AppColors.textHint),
                  onPressed: () {
                    widget.controller.clear();
                    _debounce?.cancel();
                    widget.onClear?.call();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}


// ============================================================
// FILTER CHIP
// ============================================================

class FilterChipWidget extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? selectedColor;

  const FilterChipWidget({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = selectedColor ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}