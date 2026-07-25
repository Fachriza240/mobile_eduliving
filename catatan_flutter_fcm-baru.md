# 📱 Catatan untuk Tim Flutter — FCM Push Notification

> **Dari**: Ikbal (Backend Laravel)
> **Branch**: `notifRating`
> **Untuk**: Fachriza (role Mahasiswa) & Serren (role Provider)

---

## Ringkasan

Backend Laravel sudah siap untuk push notification via **Firebase Cloud Messaging (FCM)**.
Setiap kali ada notifikasi (booking disetujui, pesanan baru, dll), Laravel akan otomatis
kirim push notification ke HP kalian — **asalkan FCM token sudah tersimpan di server**.

---

## 1. Yang Perlu Dilakukan di Flutter

### A. Setup Firebase

1. **Minta file konfigurasi Firebase** dari Ikbal (atau buat sendiri di Firebase Console project yang sama)
2. Tambah dependency ke `pubspec.yaml`:
   ```yaml
   dependencies:
     firebase_core: ^3.x.x
     firebase_messaging: ^15.x.x
   ```
3. Taruh `google-services.json` di folder `android/app/`
4. Inisialisasi Firebase di `main.dart`:
   ```dart
   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );
   ```

---

### B. Kirim FCM Token ke Server setelah Login

Setelah user berhasil login dan dapat Sanctum token, **langsung ambil FCM token lalu kirim ke server**.

```dart
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> uploadFcmToken(String sanctumToken) async {
  final fcmToken = await FirebaseMessaging.instance.getToken();
  if (fcmToken == null) return;

  await http.post(
    Uri.parse('https://domain-server.com/api/v1/fcm-token'),
    headers: {
      'Authorization': 'Bearer $sanctumToken',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: jsonEncode({'fcm_token': fcmToken}),
  );
}
```

**Kapan wajib dipanggil:**
- ✅ Setelah login berhasil
- ✅ Saat `FirebaseMessaging.instance.onTokenRefresh` terpanggil
- ✅ Saat app dibuka pertama kali setelah install ulang

---

### C. Hapus FCM Token saat Logout

```dart
Future<void> logout(String sanctumToken) async {
  // 1. Hapus FCM token dari server dulu
  await http.delete(
    Uri.parse('https://domain-server.com/api/v1/fcm-token'),
    headers: {
      'Authorization': 'Bearer $sanctumToken',
      'Accept': 'application/json',
    },
  );

  // 2. Baru logout Sanctum
  await http.post(
    Uri.parse('https://domain-server.com/api/v1/auth/logout'),
    headers: {'Authorization': 'Bearer $sanctumToken'},
  );

  // 3. Bersihkan local storage
  // ...
}
```

---

### D. Setup Handler Notifikasi (3 State)

```dart
void setupFcmHandlers() {
  // 1. FOREGROUND — app sedang terbuka
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Notif foreground: ${message.notification?.title}');
    // Tampilkan sebagai dialog / snackbar / local notification
    showLocalNotification(message);
  });

  // 2. BACKGROUND — app berjalan di background, user klik notif
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    handleNotificationTap(message.data);
  });

  // 3. TERMINATED — app tutup, user klik notif
  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null) {
      handleNotificationTap(message.data);
    }
  });

  // 4. Refresh token otomatis
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    // Kirim token baru ke server
    uploadFcmToken(newToken);
  });
}
```

---

### E. Navigasi Berdasarkan Tipe Notifikasi

Setiap notifikasi membawa field `data.type` dan `data.url`. Gunakan ini untuk navigasi:

```dart
void handleNotificationTap(Map<String, dynamic> data) {
  final type = data['type'] ?? '';

  switch (type) {
    case 'booking.disetujui':
    case 'booking.ditolak':
    case 'booking.kadaluarsa':
    case 'sewa.perpanjang':
      // Arahkan ke halaman detail booking user
      Navigator.pushNamed(context, '/user/bookings');
      break;

    case 'booking.baru':
    case 'booking.dibatalkan':
    case 'booking.pembayaran':
      // Arahkan ke halaman booking management provider
      Navigator.pushNamed(context, '/provider/bookings');
      break;

    case 'pesanan.baru':
      // Arahkan ke halaman pesanan seller
      Navigator.pushNamed(context, '/seller/orders');
      break;

    case 'pesanan.update':
      // Arahkan ke halaman transaksi buyer
      Navigator.pushNamed(context, '/user/transactions');
      break;

    case 'seller.disetujui':
      Navigator.pushNamed(context, '/user/marketplace/seller/home');
      break;

    case 'seller.ditolak':
      Navigator.pushNamed(context, '/user/marketplace/sell');
      break;

    case 'provider.disetujui':
    case 'provider.ditolak':
      Navigator.pushNamed(context, '/provider/dashboard');
      break;
  }
}
```

---

## 2. Format Payload yang Dikirim Laravel

Setiap push notification yang dikirim Laravel punya struktur ini:

```json
{
  "notification": {
    "title": "EduLiving",
    "body":  "Booking kamu di \"Kos Mawar\" telah disetujui..."
  },
  "data": {
    "type":  "booking.disetujui",
    "url":   "https://server.com/user/bookings/42",
    "color": "green",
    "icon":  "fa-check-circle"
  }
}
```

---

## 3. Semua Nilai `type` yang Mungkin

| `type` | Penerima | Artinya |
|--------|----------|---------|
| `booking.baru` | Provider | Ada booking baru masuk |
| `booking.disetujui` | User/Mahasiswa | Booking disetujui, segera bayar |
| `booking.ditolak` | User/Mahasiswa | Booking ditolak |
| `booking.dibatalkan` | Provider | Booking dibatalkan oleh user |
| `booking.pembayaran` | Provider | Pembayaran booking diterima |
| `booking.pembayaran_manual` | Provider | Bukti transfer manual diunggah oleh mahasiswa |
| `booking.pembayaran_ditolak` | User/Mahasiswa | Bukti transfer manual ditolak oleh provider |
| `booking.kadaluarsa` | User/Mahasiswa | Booking di-cancel karena tidak bayar |
| `sewa.perpanjang` | User/Mahasiswa | Reminder — masa sewa hampir habis |
| `sewa.rating_reminder` | User/Mahasiswa | Pengingat bahwa user sudah bisa mengisi ulasan hunian (H-7) |
| `ulasan.baru` | Provider | Ulasan rating baru diberikan oleh customer |
| `ulasan.dibalas` | User/Mahasiswa | Ulasan rating dibalas oleh provider |
| `pesanan.baru` | Seller (Mahasiswa) | Ada pesanan marketplace baru |
| `pesanan.update` | Buyer (Mahasiswa) | Status pesanan diupdate |
| `seller.disetujui` | User/Mahasiswa | Pengajuan seller disetujui |
| `seller.ditolak` | User/Mahasiswa | Pengajuan seller ditolak |
| `provider.disetujui` | Provider | Akun provider disetujui |
| `provider.ditolak` | Provider | Akun provider ditolak |

---

## 4. Endpoint API FCM Token

| Method | URL | Keterangan |
|--------|-----|------------|
| `POST` | `/api/v1/fcm-token` | Simpan/update FCM token |
| `DELETE` | `/api/v1/fcm-token` | Hapus FCM token (saat logout) |

**Header wajib untuk kedua endpoint:**
```
Authorization: Bearer {sanctum_token}
Accept: application/json
```

**Request body untuk POST:**
```json
{ "fcm_token": "token_dari_firebase_sdk" }
```

**Response sukses:**
```json
{ "status": "success", "message": "FCM token berhasil diperbarui." }
```

---

## 5. Catatan Penting

> ⚠️ **Token bisa berubah** — Firebase bisa perbarui FCM token kapan saja.
> Selalu handle `onTokenRefresh` dan langsung kirim token baru ke server.

> ⚠️ **Request permission di iOS** — Di iOS, notifikasi butuh izin eksplisit dari user.
> Panggil `FirebaseMessaging.instance.requestPermission()` saat onboarding.

> ℹ️ **Background handler harus top-level function** — Handler untuk notifikasi
> background (`onBackgroundMessage`) harus berupa fungsi top-level di Dart,
> bukan method di dalam class.

```dart
// ✅ BENAR — top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Background message: ${message.messageId}");
}

// Di main():
FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
```

---

## 6. Testing FCM Token

Untuk test apakah token sudah tersimpan, bisa gunakan Postman:

```
POST https://server.com/api/v1/fcm-token
Authorization: Bearer {token_sanctum_setelah_login}
Content-Type: application/json

{ "fcm_token": "test_token_123" }
```

Cek di database tabel `users` kolom `fcm_token` — harus terisi.

