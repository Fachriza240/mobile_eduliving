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

Format response API secara umum memiliki struktur `{ "data": { ... } }`.
- **Marketplace List:** Response paginate Laravel -> `{ "data": [...], "meta": { "last_page": 3 } }` (Perhatikan `last_page` ada di dalam `meta`).
- **Booking Hunian:** Menggunakan `FormData` (multipart), karena perlu `documents[]` (KTP).
- **Booking Acara:** Menggunakan JSON biasa.
- **Bookmark & Notifikasi:** Return berupa JSON standar dengan `data.bookmarks` atau `data.notifications`.

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
