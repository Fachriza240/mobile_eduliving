---
trigger: always_on
---

# HANDOVER_SERREN.md

# EduLiving Mobile — Panduan Area Kerja Serren

## Tujuan Dokumen

Dokumen ini dibuat untuk menjelaskan pembagian tugas tim, alur pengembangan proyek, serta batas area kerja masing-masing anggota agar tidak terjadi konflik saat bekerja menggunakan GitHub. Fokus utama dokumen ini adalah menjelaskan tanggung jawab Serren pada aplikasi mobile Flutter.

---

# Gambaran Proyek

EduLiving merupakan platform layanan mahasiswa yang terdiri dari beberapa modul utama, yaitu:

* Hunian (Kos, Apartemen, Kontrakan, Rumah Sewa)
* Acara/Event
* Marketplace Barang
* Sistem Booking
* Sistem Penjual (Seller)
* Sistem Penyedia (Provider)
* Admin

Proyek terdiri dari dua platform utama:

1. Website (Laravel)
2. Mobile (Flutter)

---

# Pembagian Tugas Tim

## Ikbal (Website / Backend)

Ikbal bertanggung jawab terhadap seluruh fitur website dan backend Laravel.

Area yang dikerjakan:

* Mahasiswa (Website)
* Penyedia Hunian (Website)
* Penyedia Acara (Website)
* Penjual Barang (Website)
* Admin (Website)
* API Laravel
* Database
* Integrasi Backend

Apabila terdapat perubahan endpoint, struktur response API, validasi backend, atau penambahan fitur baru pada server, koordinasi dilakukan dengan Ikbal.

---

## Riza (Mobile Mahasiswa)

Riza bertanggung jawab terhadap seluruh fitur mahasiswa pada aplikasi mobile Flutter.

Area yang dikerjakan:

* Login & Register
* Beranda Mahasiswa
* Pencarian
* Detail Hunian
* Detail Acara
* Marketplace Mahasiswa
* Booking
* Bookmark
* Profil
* Notifikasi
* Riwayat Transaksi
* Riwayat Booking

Selain itu, Riza juga menjadi pihak yang perlu diajak koordinasi apabila terdapat perubahan pada folder:

```text
lib/core/
```

karena folder tersebut digunakan bersama oleh seluruh aplikasi mobile.

---

## Serren (Mobile Provider & Seller)

Serren bertanggung jawab terhadap seluruh fitur provider dan seller pada aplikasi mobile Flutter.

Area yang dikerjakan:

### Provider Hunian

* Dashboard Provider Hunian
* Tambah Hunian
* Edit Hunian
* Hapus Hunian
* Daftar Hunian Provider
* Booking Management Hunian
* Laporan Provider Hunian

### Provider Acara

* Dashboard Provider Acara
* Tambah Acara
* Edit Acara
* Hapus Acara
* Daftar Acara Provider
* Booking Management Acara
* Laporan Provider Acara

### Seller Marketplace

* Aktivasi Seller
* Dashboard Seller
* Kelola Produk
* Tambah Produk
* Edit Produk
* Hapus Produk
* Daftar Produk Seller
* Transaksi Seller
* Laporan Seller

Catatan:

Role Admin tidak tersedia pada aplikasi mobile sehingga bukan bagian dari pekerjaan Serren.

---

# Aturan Pengembangan

## Area Aman Untuk Serren

Serren dapat melakukan perubahan pada folder:

```text
lib/features/provider/
```

dan seluruh subfolder di dalamnya.

Perubahan pada area ini umumnya tidak akan berbenturan langsung dengan pekerjaan Riza.

---

## Area Yang Harus Dikoordinasikan

Sebelum melakukan perubahan pada file berikut, wajib melakukan koordinasi:

```text
lib/core/
```

Contoh:

* models
* services
* constants
* helpers
* storage
* widgets bersama

Karena seluruh fitur mahasiswa, provider, dan seller menggunakan folder tersebut secara bersamaan.

---

## File Yang Sering Konflik Saat Merge

Beberapa file sering mengalami konflik saat proses merge GitHub:

```text
lib/main.dart
lib/core/constants/api_constants.dart
```

Sebelum merge:

1. Pull branch terbaru.
2. Periksa perubahan dari Riza.
3. Pastikan provider tidak terdaftar dua kali.
4. Pastikan endpoint API tidak tertimpa.
5. Pastikan route tidak berubah secara tidak sengaja.

---

# Alur Komunikasi

Jika menemukan masalah pada:

### Backend / API

Hubungi:

```text
Ikbal
```

Contoh:

* Endpoint tidak tersedia
* Response API berubah
* Validasi backend gagal
* Database berubah

---

### Folder Core Mobile

Hubungi:

```text
Riza
```

Contoh:

* Model berubah
* Service API berubah
* SharedPreferences berubah
* Struktur aplikasi berubah

---

### Fitur Provider atau Seller

Menjadi tanggung jawab:

```text
Serren
```

Contoh:

* Dashboard Provider
* Kelola Hunian
* Kelola Acara
* Seller Marketplace
* Laporan Provider
* Laporan Seller

---

# Prinsip Kerja Tim

Sebelum melakukan perubahan di luar area tugas masing-masing:

1. Komunikasikan terlebih dahulu kepada pemilik area.
2. Hindari mengubah file bersama tanpa pemberitahuan.
3. Lakukan pull terbaru sebelum push.
4. Review konflik merge sebelum melakukan commit.
5. Dokumentasikan perubahan penting agar tim lain mengetahui dampaknya.

Dengan pembagian area yang jelas, pengembangan dapat berjalan lebih cepat, konflik GitHub dapat diminimalkan, dan integrasi antar fitur menjadi lebih mudah.
