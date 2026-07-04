# PANDUAN KONSEP ALUR API (MOBILE & WEB BACKEND)

Dokumen ini adalah panduan konseptual (berlaku universal untuk project apa pun) yang menjelaskan bagaimana sebuah aplikasi Mobile berkomunikasi dengan Backend (Web Server) melalui REST API. Gunakan dokumen ini sebagai referensi dasar atau *prompt* untuk AI saat memulai arsitektur aplikasi baru.

---

## 1. Konsep Dasar

Aplikasi **Mobile (Klien)** dan **Web/Backend (Server)** adalah dua entitas yang benar-benar terpisah. Keduanya tidak membagikan variabel atau *database* yang sama. Mereka hanya berkomunikasi dengan cara bertukar teks berformat **JSON** melalui jalur HTTP/HTTPS. Jalur ini disebut **API (*Application Programming Interface*)**.

*   **Request:** Mobile mengirim permintaan (misal: "Beri saya daftar produk").
*   **Response:** Backend merespons (misal: "Ini JSON daftar produknya").

---

## 2. Struktur Dasar di Sisi Backend (Web Server)

Agar AI memahami di folder mana file API harus diletakkan (terutama pada *framework* seperti Laravel, Express, atau Django), berikut adalah lapisan dan struktur umumnya:

### A. Routes (Jalur Masuk)
*   **Lokasi (Laravel):** `routes/api.php`
*   **Fungsi:** Mendefinisikan URL *endpoint* (Contoh: `Route::post('/login', [AuthController::class, 'login'])`).

### B. Controllers (Otak Logika)
*   **Lokasi:** `app/Http/Controllers/Api/`
*   **Fungsi:** Menerima *request* dari *Routes*, memvalidasi *input*, dan memanggil *Database*.

### C. Models (Penghubung Database)
*   **Lokasi:** `app/Models/`
*   **Fungsi:** Representasi tabel *Database* (misal: model `User.php` terhubung ke tabel `users`).

### D. API Resources / Formatters (Penerjemah JSON)
*   **Lokasi:** `app/Http/Resources/`
*   **Fungsi:** Mengubah data kasar dari *Database* menjadi teks **JSON** yang rapi agar siap dikirim ke *Mobile*. Mencegah data sensitif (seperti *password*) ikut terkirim.

---

## 3. Struktur Dasar di Sisi Mobile (Klien)

Untuk bisa mengobrol dengan *backend*, aplikasi *mobile* (seperti Flutter, React Native, Android Native) biasanya membagi kodenya menjadi 5 lapisan folder/file berikut:

### A. Constants / Config (Buku Alamat)
Menyimpan **Base URL** (alamat server utama, misal: `https://api.namaserver.com/v1`) dan daftar *endpoint* agar tidak terjadi *typo* saat mengetik ulang di berbagai tempat.

### B. HTTP Service / Client (Sang Kurir)
Sebuah kelas tunggal (*Singleton*) yang menangani logika pengiriman HTTP (menggunakan library seperti `Dio` atau `http`). Lapisan ini bertugas:
*   Mengeksekusi perintah GET, POST, PUT, DELETE.
*   Secara otomatis menyematkan **Bearer Token (Kunci Otentikasi)** ke setiap *header request* jika pengguna sudah *login*.
*   Menangani *error* secara global (misal: jika server mati, beri *throw error* ke UI).

### C. Local Storage (Brankas Token)
Berfungsi menyimpan data otentikasi (Token) ke penyimpanan memori perangkat secara permanen (*SharedPreferences* / *Secure Storage*). Tanpa ini, pengguna harus *login* setiap kali membuka aplikasi.

### D. Data Models (Penerjemah Bahasa)
*Backend* mengirim data dalam bentuk *String/Map* berformat JSON. Lapisan Model bertugas memetakan (*parsing*) JSON tersebut ke dalam **Objek bawaan bahasa pemrograman** (misal: Objek Dart di Flutter). Jika ada perbedaan nama properti (contoh: di backend `user_name`, di mobile `userName`), diselesaikan di lapisan ini.

### E. State Management / Provider / BLoC (Sang Jembatan)
Ini adalah penghubung antara Antarmuka Pengguna (UI) dan logika Kurir (HTTP Service). 
*   **Fungsi:** Menyimpan status (*Loading*, *Success*, *Error*) dan menampung data dari Model.
*   **Cara Kerja:** Layar/UI hanya memanggil fungsi di *State Management* -> *State* menyuruh HTTP Service mengambil data -> Saat data datang, *State* memperbarui diri -> UI otomatis merender ulang layarnya.

---

## 4. Siklus Lengkap Sebuah Komunikasi (Contoh Kasus: Login)

1.  **[Mobile - UI]** Pengguna mengetik email & sandi, lalu menekan tombol "Login".
2.  **[Mobile - State]** UI memicu fungsi `login(email, sandi)` di lapisan *State Management*. Layar memunculkan *loading spinner*.
3.  **[Mobile - HTTP]** *State* meneruskan data ke HTTP Service untuk mengirim *request* `POST /api/login`.
4.  **[Backend - Route]** Server menerima *request* di jalur `/api/login` dan melemparnya ke `AuthController`.
5.  **[Backend - Controller]** Mengecek apakah email & sandi cocok di *Database*. Jika cocok, server membuatkan string acak bernama **Token**.
6.  **[Backend - Response]** Mengirim respons kembali ke *mobile* berformat JSON: `{"status": "sukses", "token": "xyz123"}`.
7.  **[Mobile - HTTP]** Menerima JSON dan mengembalikannya ke *State*.
8.  **[Mobile - State]** Menyuruh **Local Storage** untuk menyimpan "xyz123" tersebut selamanya. Kemudian memberitahu UI bahwa proses berhasil.
9.  **[Mobile - UI]** *Loading spinner* hilang, layar berpindah ke halaman Beranda.

> **Tips Ekstra:** Untuk setiap proses (Get Data, Create Data, dsb), siklusnya akan selalu mengulang pola yang sama: **UI -> State -> HTTP -> (Jaringan Internet) -> Backend -> (Jaringan Internet) -> HTTP -> Model -> State -> UI**.
