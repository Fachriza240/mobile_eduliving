class ApiConstants {
  ApiConstants._();

  // ============================================================
  // Ganti IP sesuai kondisi kamu:
  // - Android Emulator  → 10.0.2.2
  // - Device fisik      → IP Wi-Fi komputer (cek ipconfig/ifconfig)
  // Contoh device fisik : 'http://192.168.1.10:8000/api/v1'
  // ============================================================
  static const String baseUrl = 'http://192.168.1.6:8000/api/v1';

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
  static const String categories = '/categories';
  static const String search = '/search';

  static String residenceDetail(int id) => '/residences/$id';
  static String activityDetail(int id) => '/activities/$id';

  // ── USER ─────────────────────────────────────────────
  static const String userProfile = '/user/profile';
  static const String userBookings = '/user/bookings';

  static String userBookingDetail(int id) => '/user/bookings/$id';
  static String userBookingCancel(int id) => '/user/bookings/$id/cancel';

  static const String userBookmarks = '/user/bookmarks';
  static const String userBookmarksToggle = '/user/bookmarks/toggle';

  // ── PROVIDER HUNIAN ───────────────────────────────────
  static const String providerResidenceDashboard =
      '/provider/residence/dashboard';
  static const String providerResidences = '/provider/residence/residences';

  static String providerResidenceDetail(int id) =>
      '/provider/residence/residences/$id';
  static String providerResidenceUpdate(int id) =>
      '/provider/residence/residences/$id';
  static String providerResidenceDelete(int id) =>
      '/provider/residence/residences/$id';
  static String providerResidenceToggle(int id) =>
      '/provider/residence/residences/$id/toggle-status';

  static const String providerResidenceBookings =
      '/provider/residence/bookings';
  static String providerResidenceBookingDetail(int id) =>
      '/provider/residence/bookings/$id';
  static String providerResidenceBookingApprove(int id) =>
      '/provider/residence/bookings/$id/approve';
  static String providerResidenceBookingReject(int id) =>
      '/provider/residence/bookings/$id/reject';

  // ── PROVIDER ACARA ────────────────────────────────────
  static const String providerEventDashboard = '/provider/event/dashboard';
  static const String providerActivities = '/provider/event/activities';

  static String providerActivityDetail(int id) =>
      '/provider/event/activities/$id';
  static String providerActivityUpdate(int id) =>
      '/provider/event/activities/$id';
  static String providerActivityDelete(int id) =>
      '/provider/event/activities/$id';
  static String providerActivityToggle(int id) =>
      '/provider/event/activities/$id/toggle-status';

  static const String providerEventBookings = '/provider/event/bookings';
  static String providerEventBookingDetail(int id) =>
      '/provider/event/bookings/$id';
  static String providerEventBookingApprove(int id) =>
      '/provider/event/bookings/$id/approve';
  static String providerEventBookingReject(int id) =>
      '/provider/event/bookings/$id/reject';

// ── PROVIDER MARKETPLACE ─────────────────────────
  static const String providerMarketplaceProducts =
      '/provider/marketplace/products';
  static String providerMarketplaceProductUpdate(int id) =>
      '/provider/marketplace/products/$id';
  static String providerMarketplaceProductDelete(int id) =>
      '/provider/marketplace/products/$id';
  static String providerMarketplaceProductToggle(int id) =>
      '/provider/marketplace/products/$id/toggle-status';

  static const String providerMarketplaceOrders =
      '/provider/marketplace/orders';
  static String providerMarketplaceOrderDetail(int id) =>
      '/provider/marketplace/orders/$id';
  static String providerMarketplaceOrderConfirm(int id) =>
      '/provider/marketplace/orders/$id/confirm';
  static String providerMarketplaceOrderShip(int id) =>
      '/provider/marketplace/orders/$id/ship';
  static String providerMarketplaceOrderComplete(int id) =>
      '/provider/marketplace/orders/$id/complete';
  static String providerMarketplaceOrderReject(int id) =>
      '/provider/marketplace/orders/$id/reject';

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
