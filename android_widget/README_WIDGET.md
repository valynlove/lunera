# Widget layar utama Lunera (Android)

Tiga widget: **Lama terapi**, **Jadwal**, dan **Level** (grafik). Data dikirim dari aplikasi
(`lib/widget_sync.dart`), jadi widget ikut diperbarui saat kamu mencatat dosis atau hasil lab.

## Pasang
1. Salin `lib/` dan `pubspec.yaml` dari zip, lalu `flutter pub get`.
2. Dari folder proyek, jalankan (PowerShell):
   ```
   cd android_widget
   powershell -ExecutionPolicy Bypass -File .\install.ps1
   ```
   Skrip ini menyalin file Kotlin (dengan menyesuaikan baris `package` ke `MainActivity` milikmu),
   menyalin layout/xml/drawable/string, dan menambahkan tiga `<receiver>` ke `AndroidManifest.xml`.
3. Hentikan aplikasi lalu jalankan ulang (bukan hot reload). Buka aplikasi sekali supaya data terkirim.
4. Tahan layar utama, pilih **Widget**, cari **Lunera**.

## Manual (jika skrip gagal)
- Salin `kotlin/*.kt` ke folder yang sama dengan `MainActivity.kt`. Ganti baris `package com.example.ritme`
  di tiap file agar sama dengan baris `package` di `MainActivity.kt`.
- Salin isi `res/` ke `android/app/src/main/res/` (gabungkan folder yang sudah ada).
- Tempel isi `AndroidManifest.snippet.xml` ke dalam `<application>`, sebelum `</application>`.

## Catatan
- Widget memakai `java.time`. Di Android lama ini butuh *core library desugaring*, yang sudah kamu nyalakan untuk notifikasi.
- Widget memperbarui teks tiap jam sendiri (mis. "Menjalani terapi 1 tahun" bertambah dengan sendirinya); grafik diperbarui saat aplikasi dibuka.
- Widget tampil di layar utama, bahkan saat aplikasi terkunci PIN. Jika layar utamamu bisa dilihat orang lain,
  nyalakan **Pengaturan > Sembunyikan detail di widget**.
