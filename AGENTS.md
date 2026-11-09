# Aturan Proyek Lunera (AI Agent Guidelines)

Panduan ini wajib dipatuhi oleh seluruh asisten AI (seperti Google Antigravity / Gemini) saat mengembangkan, memodifikasi, dan merilis pembaruan pada repositori **Lunera**.

---

## 1. Manajemen Versi Aplikasi
Setiap kali melakukan modifikasi kode, penambahan fitur, pembaruan UI, atau perbaikan *bug*, **selalu perbarui (naikkan / bump) nomor versi dan dokumentasikan perubahannya**:

1. **Perbarui Versi di `pubspec.yaml`**:
   - Cari baris `version: X.Y.Z+B` (contoh: `version: 1.0.0+1`).
   - Naikkan nomor versi sesuai kategori perubahan di bawah, dan naikkan *build number* (+1).
2. **Dokumentasikan di `CHANGELOG.md`**:
   - Tambahkan entri rilis baru di paling atas dengan format `## [X.Y.Z] - YYYY-MM-DD`.
   - Gunakan **Bahasa Inggris (English)** mengikuti standar *Keep a Changelog* (kategori: *Added*, *Changed*, *Fixed*, *Removed*).
3. **Sinkronkan Versi pada Dokumentasi & Showcase**:
   - Perbarui badge versi dan teks terkait di `README.md`.
   - Perbarui teks badge versi dan link download di `docs/index.html` serta konfigurasi di `docs/script.js`.

### Aturan Penomoran Versi (Semantic Versioning)
> [!IMPORTANT]
> **Kebijakan Siklus Versi Aktif `v2.0.x`**: Untuk pembaruan rutin ke depan (perbaikan bug, penyesuaian UI, maupun fitur baru biasa), **cukup naikkan nomor patch `x` saja** (`2.0.(x+1)+B`). Nomor minor hanya boleh dinaikkan jika pengguna secara eksplisit menyebut atau meminta "big patch".

- **Major Release (`(+1).0.0+B`)**: Perombakan arsitektur besar, perubahan skema database/backup tanpa backward-compatibility, atau perubahan fundamental pada alur aplikasi.
- **Minor Release / Big Patch (`1.(Y+1).0+B`)**: Hanya dinaikkan jika pengguna secara eksplisit menyebut atau meminta "big patch".
- **Patch / Bug Fix (`X.Y.(+1)+B`)**: Perbaikan bug, penyesuaian styling UI/tema, perbaikan teks, fitur baru biasa, atau optimasi performa ringan.

---

## 2. Alur Rilis Otomatis (GitHub Actions Auto Release)
Repositori ini dilengkapi GitHub Actions workflow pada `.github/workflows/release.yml`.
- Setiap kali branch `main` menerima `push` (commit baru) atau pembuatan tag `v*`:
  1. Workflow akan membaca nomor versi terbaru dari `pubspec.yaml`.
  2. Mengekstrak seluruh catatan perubahan dari `CHANGELOG.md` sejak rilis GitHub terakhir (menggabungkan semua versi perantara yang belum pernah dirilis).
  3. Memeriksa apakah GitHub Release untuk tag `vX.Y.Z` sudah ada.
  4. Jika belum ada, GitHub Actions akan melakukan kompilasi APK rilis Flutter (`flutter build apk --release`) dan membuat **GitHub Release** secara otomatis lengkap dengan lampiran file `Lunera.apk` dan `Lunera_${TAG}.apk` serta gabungan catatan perubahan (*release notes*).
  5. Mendeploy direktori `./docs` secara otomatis ke GitHub Pages sebagai *Web Landing Page*.

**Aturan untuk agent:** Jangan menjalankan `git push` (termasuk push tag `v*`) tanpa konfirmasi eksplisit
dari pengguna, dan jangan pernah menggunakan `--force` pada branch `main`.

---

## 3. Standar Kode & Estetika
- **Design Token & Tema**: Gunakan selalu token warna dari `lib/theme.dart` (`C.midnight`, `C.surface`, `C.lavender`, `C.indigo`, `C.moonlight`). Hindari warna *hardcoded* sembarangan dan dukung pemilihan aksen dinamis (`applyAccent`).
- **Standar Bahasa**: Seluruh string antarmuka pengguna (*UI text*), jadwal, nama injeksi, label grafik, dan notifikasi menggunakan Bahasa Inggris profesional yang ramah dan inklusif.
- **Keamanan & Privasi Biometrik**: Jaga integritas penguncian privasi biometrik (`local_auth` dan `pin_lock_gate.dart`). Pastikan *grace period* 3 detik tetap aktif saat berpindah ke dialog eksternal (seperti pemilih file/foto).
- **Notifikasi Presisi**: Pastikan notifikasi jadwal obat selalu menggunakan receiver yang terdaftar di `AndroidManifest.xml` (`ScheduledNotificationReceiver`) dan channel `doses` dengan `Importance.max`.
- **Integritas Dual Backup & Offline-First**: Operasi dosis, jurnal, stok, dan simulasi harus berjalan lancar tanpa jaringan internet. Ekspor JSON offline (`lib/ui/data_page.dart`) dan Cloud Firestore (`lib/repo.dart`) harus selalu divalidasi dengan fungsi `validate()`. Cloud Firestore bersifat pelengkap cadangan, bukan syarat agar aplikasi berfungsi.
- **Pemisahan Web & Landing Page**:
  - Direktori `web/` dikhususkan murni untuk runtime **Flutter Web** (`web/index.html` dengan `flutter_bootstrap.js`).
  - Direktori `docs/` adalah direktori tersendiri untuk **Web Landing Page & Showcase** (HTML/CSS/JS mandiri) yang dideploy ke GitHub Pages. Landing page harus selalu responsif, modern, menggunakan Bahasa Inggris profesional, dan mencerminkan fitur riil yang ada pada aplikasi.

---

## 4. Keamanan & Eskalasi Tugas Sensitif
Karena aplikasi ini menyimpan data kesehatan pribadi pengguna (dosis, jurnal, stok) dan setiap `push` ke `main` otomatis dirilis sebagai APK (lihat Bagian 2), perubahan di area sensitif harus ekstra hati-hati.

**Area sensitif:**
- Penguncian privasi: biometrik, PIN, dan autentikasi (`local_auth`, `pin_lock_gate.dart`, termasuk Firebase Auth jika digunakan)
- Format backup JSON, fungsi `validate()`, dan skema penyimpanan data lokal, termasuk kompatibilitas restore dari backup versi lama
- Sinkronisasi Cloud Firestore (`lib/repo.dart`) dan aturan aksesnya (security rules)
- Penanganan data kesehatan atau data pribadi pengguna
- Jadwal notifikasi dosis dan konfigurasi `AndroidManifest.xml` terkait (karena menyangkut keselamatan penggunaan obat)
- Secret, API key, keystore, `google-services.json`, dan GitHub Secrets pada workflow rilis

**Aturan:**
- Jika tugas menyentuh area sensitif di atas, **berhenti dan beri tahu pengguna terlebih dahulu**
  bahwa tugas ini sebaiknya dikerjakan dengan model yang lebih kuat yang tersedia di akun
  (misalnya Gemini 4 Argon atau Claude Opus 4.6/5.5), dengan effort High, sebelum dilanjutkan.
- Jangan pernah melakukan *hardcode* secret atau API key di kode, dan jangan commit file kredensial (keystore, `.env`, dsb.) ke repositori.
- Setiap perubahan skema data atau format backup wajib menyertakan migrasi yang aman agar data pengguna yang sudah ada tidak hilang, tetap bisa direstore dari backup lama, dan tetap mematuhi prinsip Offline-First.
- Validasi input pengguna sebelum disimpan secara lokal maupun dikirim ke Cloud Firestore.
- Jangan melonggarkan aturan akses Firebase (misalnya membuka baca/tulis publik) tanpa instruksi eksplisit dari pengguna.
- Jangan melemahkan penguncian privasi (misalnya memperpanjang atau menghapus *grace period*, atau melewati PIN/biometrik) tanpa instruksi eksplisit dari pengguna.
- Untuk perubahan di area sensitif, jelaskan alasan tiap keputusan dan daftar kasus uji yang perlu dicek pengguna sebelum di-*push* ke `main`.

---

## 5. Prinsip Coding Umum
Pedoman ini condong ke kehati-hatian dibanding kecepatan. Untuk tugas yang sepele, gunakan penilaian sendiri.

### 5.1 Pikir Dulu Sebelum Coding
- Nyatakan asumsi secara eksplisit. Jika ragu, tanya.
- Jika ada beberapa interpretasi, sajikan semuanya. Jangan memilih diam-diam.
- Jika ada pendekatan yang lebih sederhana, sampaikan dan boleh membantah permintaan bila perlu.

### 5.2 Sederhana Dulu
- Tulis kode seminimal mungkin yang menyelesaikan masalah. Tanpa fitur, abstraksi, atau konfigurasi spekulatif yang tidak diminta.
- Pengecualian: standar di Bagian 3 (design token, privasi biometrik, notifikasi presisi, Offline-First & validasi backup) bukan fitur tambahan dan selalu wajib dipenuhi.

### 5.3 Perubahan Bedah
- Jangan "memperbaiki" kode, komentar, atau format di sekitarnya. Ikuti gaya kode yang sudah ada.
- Jika menemukan dead code lama, sebutkan saja dan jangan dihapus. Hapus hanya import/variabel/fungsi yang menjadi tidak terpakai akibat perubahanmu.
- Setiap baris yang berubah harus berkaitan dengan permintaan pengguna, kecuali sinkronisasi versi dan dokumentasi di Bagian 1 yang selalu wajib.

### 5.4 Eksekusi Berorientasi Tujuan
- Tentukan kriteria sukses yang bisa diverifikasi. Jika area terkait sudah punya test, jalankan sebelum dan sesudah perubahan. Minimal jalankan `flutter analyze` sebelum menyatakan tugas selesai.
- Untuk perbaikan bug, jika wajar, buat test yang mereproduksi bug lalu pastikan lulus.
- Untuk tugas multi-langkah, tulis rencana singkat dengan pengecekan di tiap langkah.
