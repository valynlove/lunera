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
- **Major Release (`(+1).0.0+B`)**: Perombakan arsitektur besar, perubahan skema database/backup tanpa backward-compatibility, atau perubahan fundamental pada alur aplikasi.
- **Minor Feature (`X.(+1).0+B`)**: Penambahan modul atau fitur baru (contoh: integrasi tipe terapi baru, penambahan visualisasi grafik farmakokinetik baru, fitur export baru).
- **Patch / Bug Fix (`X.Y.(+1)+B`)**: Perbaikan bug, penyesuaian styling UI/tema, perbaikan teks/lokalisasi, atau optimasi notifikasi & performa.

---

## 2. Alur Rilis Otomatis (GitHub Actions Auto Release)
Repositori ini dilengkapi GitHub Actions workflow pada `.github/workflows/release.yml`.
- Setiap kali branch `main` menerima `push` (commit baru) atau pembuatan tag `v*`:
  1. Workflow akan membaca nomor versi terbaru dari `pubspec.yaml`.
  2. Mengekstrak seluruh catatan perubahan dari `CHANGELOG.md` sejak rilis GitHub terakhir (menggabungkan semua versi perantara yang belum pernah dirilis).
  3. Memeriksa apakah GitHub Release untuk tag `vX.Y.Z` sudah ada.
  4. Jika belum ada, GitHub Actions akan melakukan kompilasi APK rilis Flutter (`flutter build apk --release`) dan membuat **GitHub Release** secara otomatis lengkap dengan lampiran file `Lunera.apk` dan `Lunera_${TAG}.apk` serta gabungan catatan perubahan (*release notes*).
  5. Mendeploy direktori `./docs` secara otomatis ke GitHub Pages sebagai *Web Landing Page*.

---

## 3. Standar Kode & Estetika
- **Design Token & Tema**: Gunakan selalu token warna dari `lib/theme.dart` (`C.midnight`, `C.surface`, `C.lavender`, `C.indigo`, `C.moonlight`). Hindari warna *hardcoded* sembarangan dan dukung pemilihan aksen dinamis (`applyAccent`).
- **Standard Bahasa**: Seluruh string antarmuka pengguna (*UI text*), jadwal, nama injeksi, label grafik, dan notifikasi menggunakan Bahasa Inggris profesional yang ramah dan inklusif.
- **Keamanan & Privasi Biometrik**: Jaga integritas penguncian privasi biometrik (`local_auth` dan `pin_lock_gate.dart`). Pastikan *grace period* 3 detik tetap aktif saat berpindah ke dialog eksternal (seperti pemilih file/foto).
- **Notifikasi Presisi**: Pastikan notifikasi jadwal obat selalu menggunakan receiver yang terdaftar di `AndroidManifest.xml` (`ScheduledNotificationReceiver`) dan channel `doses` dengan `Importance.max`.
- **Integritas Dual Backup & Offline-First**: Operasi dosis, jurnal, stok, dan simulasi harus berjalan lancar tanpa jaringan internet. Ekspor JSON offline (`lib/ui/data_page.dart`) dan Cloud Firestore (`lib/repo.dart`) harus selalu divalidasi dengan fungsi `validate()`.
- **Pemisahan Web & Landing Page**:
  - Direktori `web/` dikhususkan murni untuk runtime **Flutter Web** (`web/index.html` dengan `flutter_bootstrap.js`).
  - Direktori `docs/` adalah library/direktori tersendiri untuk **Web Landing Page & Showcase** (HTML/CSS/JS mandiri) yang dideploy ke GitHub Pages.

