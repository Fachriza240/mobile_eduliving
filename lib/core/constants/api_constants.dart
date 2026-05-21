class ApiConstants {
  ApiConstants._();

  // ============================================================
  // Ganti IP sesuai kondisi kamu:
  // - Android Emulator  → 10.0.2.2
  // - Device fisik      → IP Wi-Fi komputer (cek via ipconfig)
  // Contoh device fisik : 'http://192.168.1.10:8000/api/v1'
  // ============================================================
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // ── AUTH ─────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // ── PUBLIC ───────────────────────────────────────────
  static const String home = '/';
  static const String residences = '/residences';
  static const String activities = '/activities';

  static String residenceDetail(int id) => '/residences/$id';
  static String activityDetail(int id) => '/activities/$id';

  // ── USER ─────────────────────────────────────────────
  static const String userProfile = '/user/profile';
  static const String userBookings = '/user/bookings';

  static String userBookingDetail(int id) => '/user/bookings/$id';
  static String userBookingCancel(int id) => '/user/bookings/$id/cancel';

  static const String userBookmarks = '/user/bookmarks';
  static const String userBookmarksToggle = '/user/bookmarks/toggle';

// ── MARKETPLACE ──────────────────────────────────
  static const String marketplace = '/marketplace';
  static String marketplaceDetail(int id) => '/marketplace/$id';
  static const String userTransactions = '/user/transactions';
  static String userTransactionDetail(int id) => '/user/transactions/$id';
  static String userTransactionCancel(int id) =>
      '/user/transactions/$id/cancel';
  static String userTransactionPayment(int id) =>
      '/user/transactions/$id/payment-proof';
  static String buyProduct(int productId) => '/user/transactions/$productId';
}

class AppStrings {
  AppStrings._();

  static const String appName = 'EduLiving';
  static const String appTagline = 'Platform Layanan Mahasiswa';

  // Nav
  static const String navHome = 'Beranda';
  static const String navResidence = 'Hunian';
  static const String navActivity = 'Acara';
  static const String navProfile = 'Profil';

  // Common
  static const String loading = 'Memuat...';
  static const String retry = 'Coba Lagi';
  static const String cancel = 'Batal';
  static const String save = 'Simpan';
  static const String seeAll = 'Lihat Semua';
  static const String noData = 'Belum ada data';
  static const String gratis = 'Gratis';

  // Error
  static const String errorNetwork = 'Tidak dapat terhubung ke server.';
  static const String errorServer = 'Terjadi kesalahan pada server.';
  static const String errorUnauthorized = 'Sesi habis. Silakan masuk kembali.';
  static const String errorGeneral = 'Terjadi kesalahan. Coba lagi.';
}
