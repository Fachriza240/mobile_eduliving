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
  static const String login    = '/auth/login';
  static const String register = '/auth/register';
  static const String logout   = '/auth/logout';
  static const String me       = '/auth/me';

  // ── PUBLIC ───────────────────────────────────────────
  static const String home       = '/';
  static const String residences = '/residences';
  static const String activities = '/activities';
  static const String categories = '/categories';
  static const String search     = '/search';

  static String residenceDetail(int id) => '/residences/$id';
  static String activityDetail(int id)  => '/activities/$id';

  // ── USER ─────────────────────────────────────────────
  static const String userProfile  = '/user/profile';
  static const String userBookings = '/user/bookings';

  static String userBookingDetail(int id) => '/user/bookings/$id';
  static String userBookingCancel(int id) => '/user/bookings/$id/cancel';

  static const String userBookmarks       = '/user/bookmarks';
  static const String userBookmarksToggle = '/user/bookmarks/toggle';

  // ── PROVIDER HUNIAN ───────────────────────────────────
  static const String providerResidenceDashboard = '/provider/residence/dashboard';
  static const String providerResidences         = '/provider/residence/residences';

  static String providerResidenceDetail(int id)  => '/provider/residence/residences/$id';
  static String providerResidenceUpdate(int id)  => '/provider/residence/residences/$id';
  static String providerResidenceDelete(int id)  => '/provider/residence/residences/$id';
  static String providerResidenceToggle(int id)  => '/provider/residence/residences/$id/toggle-status';

  static const String providerResidenceBookings          = '/provider/residence/bookings';
  static String providerResidenceBookingDetail(int id)   => '/provider/residence/bookings/$id';
  static String providerResidenceBookingApprove(int id)  => '/provider/residence/bookings/$id/approve';
  static String providerResidenceBookingReject(int id)   => '/provider/residence/bookings/$id/reject';

  // ── PROVIDER ACARA ────────────────────────────────────
  static const String providerEventDashboard = '/provider/event/dashboard';
  static const String providerActivities     = '/provider/event/activities';

  static String providerActivityDetail(int id)  => '/provider/event/activities/$id';
  static String providerActivityUpdate(int id)  => '/provider/event/activities/$id';
  static String providerActivityDelete(int id)  => '/provider/event/activities/$id';
  static String providerActivityToggle(int id)  => '/provider/event/activities/$id/toggle-status';

  static const String providerEventBookings         = '/provider/event/bookings';
  static String providerEventBookingDetail(int id)  => '/provider/event/bookings/$id';
  static String providerEventBookingApprove(int id) => '/provider/event/bookings/$id/approve';
  static String providerEventBookingReject(int id)  => '/provider/event/bookings/$id/reject';
}
