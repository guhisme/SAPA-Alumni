# SAPA Alumni — Panduan Setup (Tahap 1: Alumni)

Isi paket ini:

```
lib/                     kode aplikasi Flutter (sudah jadi untuk role Alumni)
pubspec.yaml             daftar dependency
firestore.rules          Firebase Security Rules
functions/               Cloud Functions: Fonnte WhatsApp + push notification
SETUP.md                 file ini
```

---

## 1. Buat project Flutter

```bash
flutter create sapa_alumni
cd sapa_alumni
```

Lalu **timpa** `lib/` dan `pubspec.yaml` bawaan dengan yang ada di paket ini, dan salin
`firestore.rules` serta folder `functions/` ke root project.

```bash
flutter pub get
```

Butuh Flutter 3.24 atau lebih baru (kode memakai `Color.withValues`).
Cek dengan `flutter --version`.

---

## 2. Siapkan project Firebase

1. Buka https://console.firebase.google.com → **Add project** → beri nama, misal `sapa-alumni`.
2. Di menu **Build → Authentication → Sign-in method**, aktifkan **Email/Password**.
3. Di menu **Build → Firestore Database**, klik **Create database**, pilih lokasi
   `asia-southeast2 (Jakarta)`, mulai dengan **production mode**.
4. Di menu **Build → Storage**, klik **Get started** (opsional, untuk foto profil nanti).

## 3. Hubungkan Flutter ke Firebase

```bash
npm install -g firebase-tools
firebase login

dart pub global activate flutterfire_cli
flutterfire configure
```

Pilih project Firebase Anda dan centang platform **android**. Perintah ini otomatis
menulis ulang `lib/firebase_options.dart` (yang sekarang masih berisi placeholder) dan
menaruh `android/app/google-services.json`.

**Jangan mengisi firebase_options.dart secara manual.**

### Penyesuaian Android

Di `android/app/build.gradle` (atau `build.gradle.kts`), pastikan:

```gradle
android {
    compileSdk 35
    defaultConfig {
        minSdk 23          // wajib minimal 23 untuk firebase_auth
        targetSdk 35
        multiDexEnabled true
    }
}
```

## 4. Pasang Security Rules

```bash
firebase init firestore     # pilih project yang sama, arahkan ke firestore.rules
firebase deploy --only firestore:rules
```

## 5. Buat index Firestore

Aplikasi memakai query gabungan. Index bisa dibuat otomatis: jalankan aplikasi,
buka halaman Lowongan/Lamaran, lalu **klik tautan yang muncul di Debug Console**
("The query requires an index..."). Index yang dibutuhkan:

| Collection   | Field                              |
|--------------|------------------------------------|
| jobs         | status (asc) + createdAt (desc)    |
| applications | alumniId (asc) + status (asc)      |
| notifications| userId (asc) + isRead (asc)        |

## 6. Cloud Functions (Fonnte + push notification)

```bash
firebase init functions      # pilih JavaScript, JANGAN timpa index.js yang sudah ada
cd functions && npm install
```

Simpan token Fonnte sebagai secret — **tidak pernah masuk ke kode Flutter**:

```bash
firebase functions:secrets:set FONNTE_TOKEN
# tempel token dari dashboard Fonnte (https://md.fonnte.com/ → menu Device)
```

Deploy:

```bash
firebase deploy --only functions
```

Functions yang terpasang:

- `sendWhatsapp` — dipanggil Admin/BKK dari Flutter (dipakai di tahap berikutnya)
- `onApplicationStatusChanged` — push notifikasi ke alumni saat status lamaran berubah
- `onJobCreated`, `onScholarshipCreated`, `onTrainingCreated`, `onAnnouncementCreated` — broadcast ke topik `alumni`

Catatan: Cloud Functions memerlukan project Firebase berpaket **Blaze** (pay as you go).
Kalau belum mau upgrade, aplikasi Alumni tetap jalan penuh — hanya push notification
otomatis dan WhatsApp yang belum aktif.

## 7. Jalankan aplikasi

```bash
flutter run
```

Alur uji: **Daftar alumni → isi data diri → home**.

## 8. Isi data contoh (agar ada yang tampil)

Belum ada halaman Admin/BKK, jadi untuk sementara tambahkan dokumen lewat
Firebase Console → Firestore → Start collection.

**Collection `jobs`** (ID dokumen: auto):

| Field        | Tipe      | Contoh isi                                  |
|--------------|-----------|---------------------------------------------|
| id           | string    | *(salin ID dokumennya)*                     |
| title        | string    | Staff Administrasi                          |
| company      | string    | PT Maju Bersama                             |
| description  | string    | Mengelola dokumen dan arsip kantor.         |
| requirements | string    | Lulusan SMK, teliti, bisa Excel.            |
| location     | string    | Bandung                                     |
| deadline     | timestamp | pilih tanggal beberapa minggu ke depan      |
| bkkId        | string    | bkk_demo                                    |
| status       | string    | open                                        |
| createdAt    | timestamp | sekarang                                    |

**Collection `announcements`**: `id`, `title`, `content`, `createdAt` (timestamp).

**Collection `scholarships`**: `id`, `title`, `provider`, `description`, `requirements`,
`benefits`, `deadline` (timestamp), `link`, `createdAt` (timestamp).

**Collection `trainings`**: `id`, `title`, `provider`, `description`, `schedule`,
`duration`, `mode`, `deadline` (timestamp), `link`, `createdAt` (timestamp).

### Membuat akun Admin / BKK

Daftar lewat aplikasi seperti biasa, lalu di Firestore ubah field `role` pada
dokumen `users/{uid}` dari `alumni` menjadi `admin` atau `bkk`.

---

## Yang sudah berfungsi (lengkap: Alumni, BKK, Admin)

**Alumni** — splash, onboarding, register, login, lupa password, isi data diri (tanpa email),
home + ringkasan lamaran, daftar/cari/filter lowongan, detail lowongan, lamar (cek deadline,
lowongan tertutup, lamar ganda, sudah diterima), daftar & detail lamaran + timeline status,
batalkan lamaran, beasiswa, pelatihan, pengumuman, bookmark, notifikasi, profil, edit profil, logout.

**BKK** — dashboard + statistik, profil BKK & edit, tambah/edit/hapus lowongan, buka-tutup
lowongan, daftar lowongan miliknya sendiri, daftar pelamar (per lowongan atau seluruhnya),
detail pelamar + profil alumni, ubah status lamaran dengan catatan, kirim WhatsApp ke satu
pelamar atau ke seluruh pelamar terfilter.

**Admin** — dashboard + hitungan seluruh data, daftar pengguna (semua/alumni/BKK) dengan
pencarian, detail pengguna, ubah role, verifikasi & cabut verifikasi BKK, CRUD beasiswa,
CRUD pelatihan, CRUD pengumuman, pilih penerima lalu kirim WhatsApp massal, logout.

---

## Cara membuat akun BKK dan Admin

1. Daftar lewat aplikasi seperti alumni biasa.
2. Buka Firestore Console → `users/{uid}` → ubah `role` menjadi `bkk` atau `admin`.
3. Untuk BKK: login, lengkapi Profil BKK, lalu minta admin memverifikasi lewat
   menu **Lainnya → Verifikasi BKK**. Selama belum terverifikasi, Security Rules tetap
   mengizinkan membuat lowongan; kalau ingin memaksa verifikasi lebih dulu, tambahkan
   pengecekan `verified` pada rules `jobs`.

## Index Firestore tambahan untuk BKK dan Admin

| Collection   | Field                          |
|--------------|--------------------------------|
| jobs         | bkkId (asc)                    |
| applications | jobId (asc) / bkkId (asc)      |
| users        | role (asc)                     |
| bkk_profiles | verified (asc)                 |

Query field tunggal biasanya sudah otomatis terindeks. Kalau muncul pesan
"The query requires an index" di Debug Console, klik tautannya.

## Alur uji cepat seluruh sistem

1. Akun BKK membuat lowongan.
2. Akun alumni melihat lowongan itu di tab Lowongan, lalu menekan **Lamar sekarang**.
3. Akun BKK membuka tab Pelamar → detail pelamar → **Ubah status lamaran** menjadi Diproses.
4. Akun alumni membuka Notifikasi dan tab Lamaran; statusnya sudah berubah.
5. Akun BKK menekan **Kirim WhatsApp** (butuh Cloud Function `sendWhatsapp` sudah di-deploy).
6. Akun admin menambah pengumuman; alumni melihatnya di tab Informasi.
