---
trigger: always_on
---

# HANDOVER DOCUMENT — EduLiving Mobile (Riza)

> Paste file ini sebagai konteks pertama saat memulai sesi baru di Claude/Antigravity.
> Letakkan di: `docs/HANDOVER_MOBILE_RIZA.md` di repository GitHub.

---

## 1. Gambaran Umum Proyek

| Item                  | Detail                                                  |
| --------------------- | ------------------------------------------------------- |
| Nama Proyek           | EduLiving (sebelumnya: Infoma)                          |
| Tujuan                | Platform layanan mahasiswa — hunian, acara, marketplace |
| Backend               | Laravel 12, MySQL (database: `inf_new`), Sanctum Auth   |
| Mobile                | Flutter, Dio, Provider, SharedPreferences               |
| Base URL Emulator     | `http://10.0.2.2:8000/api/v1`                           |
| Base URL Device Fisik | `http://<IP-WiFi-Komputer>:8000/api/v1`                 |
| API Prefix            | `/api/v1`                                               |
| Versi Dokumen         | Juni 2026                                               |

**Cara jalankan backend:**

```bash
php artisan serve --host=0.0.0.0 --port=8000
```

**NDK Android** — tambahkan di `android/app/build.gradle.kts`:

```kotlin
android {
    ndkVersion = "27.0.12077973"
}
```

---

## 2. Tim & Pembagian Tugas

| Nama                | Tugas                                                          | Platform       |
| ------------------- | -------------------------------------------------------------- | -------------- |
| **Fachriza (Riza)** | Mobile Flutter — Role Mahasiswa + Setup API awal               | Flutter Mobile |
| **Ikbal**           | Backend Laravel — Web + API v2/v3                              | Laravel Web    |
| **Serren**          | Mobile Flutter — Role Penyedia (Provider) + Seller Marketplace | Flutter Mobile |

### Penting saat merge dengan tim:

- **Merge Serren:** Selalu cek `api_constants.dart` (base URL sering berubah ke IP Serren), cek `main.dart` (provider sering duplikat), route `/home` harus ke `RootScreen` bukan `HomeScreen`
- **RootScreen** bertugas redirect: role mahasiswa → `HomeScreen`, role penyedia → `ProviderHomeScreen`
- **Merge Ikbal:** Pull web terbaru sebelum test API baru, update model Dart jika ada field baru di response

---

## 3. Struktur Folder Flutter

```
lib/
├── core/
│   ├── constants/
│   │   ├── api_constants.dart      ← SEMUA endpoint API
│   │   └── app_colors.dart
│   ├── models/
│   │   ├── booking_model.dart
│   │   ├── residence_model.dart
│   │   ├── activity_model.dart
│   │   └── user_model.dart
│   ├── services/
│   │   └── api_service.dart        ← Dio singleton, GET/POST/PUT/DELETE/FormData
│   ├── utils/
│   │   ├── app_helpers.dart
│   │   └── storage_helper.dart     ← Token disimpan via SharedPreferences
│   └── widgets/
│       └── common_widgets.dart     ← EduImage, InfoRow, StarRating, EduSearchBar, dll
├── features/
│   ├── auth/                       ← Login, Register, AuthProvider
│   ├── home/
│   │   ├── tabs/
│   │   │   ├── beranda_tab.dart    ← Home utama mahasiswa
│   │   │   ├── hunian_tab.dart
│   │   │   ├── acara_tab.dart
│   │   │   └── profil_tab.dart
│   │   ├── search_screen.dart
│   │   └── home_screen.dart
│   ├── residence/                  ← List, Detail, Booking hunian
│   ├── activity/                   ← List, Detail, Booking acara
│   ├── bookmark/                   ← Model, Provider, Screen (3 tab)
│   ├── marketplace/                ← Model, Provider, List, Detail, Transaksi
│   ├── notification/               ← notification_screen.dart
│   ├── profile/                    ← BookingList, BookingDetail, EditProfile, Rating, ChangePassword
│   ├── provider/                   ← Semua fitur role penyedia (SERREN)
│   └── splash/
└── main.dart                       ← Provider & Route registration
```

---

## 4. Semua Endpoint API (Role Mahasiswa)

### Auth

```
POST /auth/login
POST /auth/register
POST /auth/logout
GET  /auth/me
```

### Public

```
GET  /                              ← Home: featured_residences, featured_activities, categories
GET  /residences                    ← Params: search, residence_type, page
GET  /residences/{id}
GET  /activities                    ← Params: search, category, page
GET  /activities/{id}
GET  /marketplace                   ← Params: search, condition, category_id, page, per_page
GET  /marketplace/{id}
GET  /search?q=                     ← Return: { data: { residences, activities, products } }
```

### User (butuh Bearer Token)

```
GET  /user/profile
PUT  /user/profile                  ← Edit profil + ubah password
POST /user/profile (multipart)      ← Upload foto profil

GET  /user/bookings                 ← Params: status
GET  /user/bookings/{id}
POST /user/bookings                 ← Hunian: multipart, Acara: JSON
POST /user/bookings/{id}/cancel
GET  /user/bookings/{id}/payment
POST /user/bookings/{id}/payment    ← Params: payment_method, payment_proof(file opsional)

GET  /user/bookmarks                ← Return: { data: { bookmarks: [...], pagination: {...} } }
POST /user/bookmarks/toggle         ← Body: { type: "residence"|"activity"|"marketplace_product", id: int }

GET  /user/transactions
GET  /user/transactions/{id}
POST /user/transactions/{productId} ← Beli produk
POST /user/transactions/{id}/payment-proof

POST /user/ratings                  ← Body: { booking_id, rating, comment }

GET  /user/notifications
POST /user/notifications/{id}/read
POST /user/notifications/read-all

POST /user/seller/activate          ← Jadi seller marketplace
GET  /user/seller/status
```

---

## 5. Format Response API Penting

### Bookmark List

```json
{
  "status": "success",
  "data": {
    "bookmarks": [
      {
        "id": 1,
        "type": "Residence",
        "created_at": "...",
        "item": {
          "id": 10, "name": "...", "price": "59900000.00",
          "images": [...], "address": "...", "available_slots": 5
        }
      }
    ],
    "pagination": { "current_page": 1, "last_page": 1 }
  }
}
```

### Marketplace List (Laravel Resource Collection paginate)

```json
{
  "data": [...],
  "meta": { "current_page": 1, "last_page": 3 },
  "links": {...}
}
// ⚠️ last_page ada di dalam "meta", BUKAN di root
```

### Home

```json
{
  "data": {
    "featured_residences": [...],
    "featured_activities": [...],
    "categories": [...]
  }
}
```

### Booking Store — Hunian (FormData multipart)

```
bookable_type   = "residence"
bookable_id     = 10
check_in_date   = "2026-06-01"
check_out_date  = "2026-07-01"
duration_months = 1
documents[]     = File(KTP)    ← wajib
documents[]     = File(KK)     ← opsional
```

### Booking Store — Acara (JSON)

```json
{
  "bookable_type": "activity",
  "bookable_id": 5,
  "check_in_date": "2026-06-15",
  "participant_name": "Nama Peserta",
  "participant_email": "email@example.com",
  "participant_phone": "081234567890"
}
```

### Notifikasi

```json
{
  "data": {
    "notifications": [
      {
        "id": 1,
        "type": "BookingApproved",
        "title": "Booking Disetujui",
        "message": "...",
        "is_unread": true,
        "created_at": "...",
        "url": "..."
      }
    ],
    "unread_count": 3
  }
}
```

---

## 6. Fitur yang Sudah Selesai

### ✅ Autentikasi

- Login, Register, Logout, Cek status login (SplashScreen)

### ✅ Beranda

- Hero greeting dengan nama & avatar foto profil
- Search bar → SearchScreen global
- Menu utama (Hunian, Acara, Barang, Bookmark)
- Section: Hunian Terbaru, Acara Mendatang, Barang Terbaru
- Data dari `GET /` + `GET /marketplace?per_page=6` secara paralel

### ✅ Hunian

- List dengan filter tipe (Kos/Kontrakan/Apartemen/Rumah Sewa) + search
- Detail (galeri, fasilitas, info provider)
- Booking: pilih tanggal, durasi sewa dropdown, upload KTP+KK, S&K checkbox
- Toggle bookmark (reaktif, optimistic update)

### ✅ Acara

- List dengan tab Mendatang/Sudah Selesai + filter kategori + search
- Detail (speaker, benefit, jadwal, slot tersedia)
- Daftar: form data peserta pre-fill dari user, S&K checkbox
- Toggle bookmark

### ✅ Marketplace (Barang)

- List dengan search + filter 5 kondisi (Baru/Seperti Baru/Baik/Cukup/Perlu Perbaikan)
- Detail produk
- Beli produk + riwayat transaksi
- Aktivasi jadi seller (BecomeProviderMarketplaceScreen)

### ✅ Bookmark

- List 3 tab: Hunian, Acara, Marketplace
- Toggle dari detail screen (ikon berubah reaktif)
- Sync antara mobile dan web

### ✅ Booking & Pembayaran

- Riwayat booking semua status
- Detail booking: kode booking, timeline status, info peserta, periode sewa
- Pembayaran: pilih metode + upload bukti bayar
- Batal booking

### ✅ Rating & Ulasan

- Form rating bintang + komentar muncul di detail booking berstatus "completed"

### ✅ Profil & Akun

- Tampil profil + foto profil dari server
- Edit profil (nama, telepon, alamat)
- Upload foto profil (multipart)
- Ubah kata sandi
- Statistik booking (Menunggu/Aktif/Selesai)

### ✅ Search Global

- Cari semua kategori sekaligus, hasil dikelompokkan per tipe
- Navigasi ke detail dari hasil search

### ✅ Notifikasi

- List notifikasi dengan badge unread
- Tandai dibaca (satu/semua)

---

## 7. Masalah yang Pernah Ditemui & Solusi

| Masalah                                                        | Solusi                                                                |
| -------------------------------------------------------------- | --------------------------------------------------------------------- |
| `price` dari Laravel decimal → String, crash `.toDouble()`     | `double.tryParse(json['price'].toString()) ?? 0.0`                    |
| Dio return `Map<String, Object?>` bukan `Map<String, dynamic>` | `Map<String, dynamic>.from(e as Map)`                                 |
| Base URL berubah ke IP Serren setelah merge                    | Kembalikan ke `10.0.2.2` untuk emulator                               |
| Route `/home` duplikat setelah merge                           | Hapus `HomeScreen` route, biarkan `RootScreen` saja                   |
| Provider duplikat di `main.dart`                               | Hapus duplikat, pastikan tiap provider hanya 1x                       |
| NDK version mismatch                                           | `ndkVersion = "27.0.12077973"` di `build.gradle.kts`                  |
| `getPaymentDeadlineLabel()` tidak ada di model Booking         | Ganti dengan inline Carbon logic di `BookingResource.php`             |
| `last_page` tidak terbaca di Marketplace                       | Baca dari `data['meta']?['last_page'] ?? data['last_page'] ?? 1`      |
| Gambar terpotong aneh di card hunian/acara                     | Gunakan `ClipRRect` dengan hanya rounded sudut atas                   |
| Login timeout setelah merge                                    | Base URL bukan `0.0.0.0`, jalankan `php artisan serve --host=0.0.0.0` |

---

## 8. Perbaikan Backend yang Dilakukan (koordinasi dengan Ikbal)

| File Backend                      | Perubahan                                                                      |
| --------------------------------- | ------------------------------------------------------------------------------ |
| `ActivityResource.php`            | Tambah `speakers`, `benefits`, `ratings_count`                                 |
| `ResidenceResource.php`           | Tambah `residence_type`, `kos_type`, ratings detail                            |
| `BookingResource.php`             | Inline Carbon untuk `payment_deadline` (ganti method yang tidak ada di model)  |
| `UserResource.php`                | `profile_picture` via `/api/v1/file/`, tambah `is_banned`, `terms_accepted_at` |
| `ResidenceApiController.php`      | Filter `search`, `residence_type`, `kos_type` + `orderBy created_at desc`      |
| `MarketplaceProductResource.php`  | Tambah `average_rating`, `ratings_count`                                       |
| `MarketplaceController.php`       | Tambah filter `condition`                                                      |
| `Api/User/BookmarkController.php` | **Dibuat baru** — return JSON (controller lama return view)                    |

---

## 9. Yang Belum Selesai / Perlu Dilanjutkan

| Item                                                          | Prioritas | Catatan                                                         |
| ------------------------------------------------------------- | --------- | --------------------------------------------------------------- |
| Test beli produk & rating end-to-end                          | Tinggi    | Perlu booking berstatus `completed` di DB                       |
| Mapping field peserta booking acara                           | Tinggi    | Backend kirim `participant_name`, mobile model pakai `fullName` |
| Notifikasi push (FCM/Firebase)                                | Sedang    | Butuh setup Firebase + koordinasi Ikbal                         |
| Ulasan/komentar di detail hunian & acara                      | Sedang    | Tampilkan review dari user lain                                 |
| Seller mode mahasiswa (kelola produk)                         | Sedang    | `BecomeProviderMarketplaceScreen` sudah ada                     |
| Hapus `_showRegSheet` di `activity_detail_screen.dart:384`    | Rendah    | Method tidak dipakai                                            |
| Hapus `import 'dart:convert'` di `auth_provider.dart:2`       | Rendah    | Import tidak dipakai                                            |
| Bug Ikbal: `checkProfileComplete` di `ActivityController` web | Backend   | Method tidak ada, harus ditambah atau dipanggil berbeda         |

---

## 10. Cara Membuka Sesi Baru di Claude/Antigravity

Paste teks berikut sebagai pesan pertama:

```
Halo, saya lanjut progres project EduLiving — aplikasi mobile Flutter untuk mahasiswa.
Berikut adalah handover document dari sesi sebelumnya:

[PASTE ISI FILE INI DI SINI]

Project ini Laravel 12 (backend) + Flutter (mobile). Saya Riza, mengerjakan role mahasiswa di Flutter.
Tim: Ikbal (backend), Serren (mobile provider/seller).
Sekarang saya ingin lanjut ke: [SEBUTKAN FITUR YANG INGIN DIKERJAKAN]
```

---

_EduLiving • Tim Mobile Riza • Juni 2026_
