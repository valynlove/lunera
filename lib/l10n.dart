import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Active application locale for formatting dates and non-widget strings.
class AppLocale {
  static String code = 'en';
  static const supported = [Locale('en'), Locale('id')];
}

/// Simple, efficient translation engine:
/// English text is used directly as the key.
/// Indonesian translations are retrieved from [_id].
class AppStrings {
  AppStrings(this.code);

  final String code;

  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings) ?? AppStrings(AppLocale.code);

  static const LocalizationsDelegate<AppStrings> delegate = _AppStringsDelegate();

  String tr(String key, [Map<String, Object?>? args]) {
    var text = code == 'id' ? (_id[key] ?? key) : key;
    if (args != null) {
      args.forEach((k, v) => text = text.replaceAll('{$k}', '$v'));
    }
    return text;
  }
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'en' || locale.languageCode == 'id';

  @override
  Future<AppStrings> load(Locale locale) => SynchronousFuture(
        AppStrings(locale.languageCode == 'id' ? 'id' : 'en'),
      );

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppStrings> old) => false;
}

extension TrContext on BuildContext {
  /// Context-aware translation string.
  String tr(String key, [Map<String, Object?>? args]) =>
      AppStrings.of(this).tr(key, args);
}

/// Global translation without context.
String trG(String key, [Map<String, Object?>? args]) =>
    AppStrings(AppLocale.code).tr(key, args);

/// Indonesian translation dictionary (English key -> Indonesian translation).
const Map<String, String> _id = {
  // Brand & Taglines
  'Every Phase, Your Own.': 'Setiap fase, milikmu.',
  'Every phase,\nyour own.': 'Setiap fase,\nmilikmu.',

  // Navigation & Shell
  'Home': 'Beranda',
  'Calendar': 'Kalender',
  'Levels': 'Level',
  'Supplies': 'Stok',
  'More': 'Lainnya',
  'Settings': 'Pengaturan',
  'Security': 'Keamanan',
  'Insights': 'Wawasan',
  'Body & Changes': 'Tubuh & perubahan',
  'Account Profile': 'Profil Akun',
  'Import, export, backup': 'Impor, ekspor, cadangan',
  'Check for Updates': 'Periksa Pembaruan',
  'About {name}': 'Tentang {name}',
  'Sign out': 'Keluar',
  'Exit {name}?': 'Keluar dari {name}?',
  'Are you sure you want to exit the application?': 'Apakah kamu yakin ingin keluar dari aplikasi?',
  'Cancel': 'Batal',
  'Exit': 'Keluar',
  'Save': 'Simpan',
  'Delete': 'Hapus',
  'Close': 'Tutup',

  // Home Screen
  'Good morning': 'Selamat pagi',
  'Good afternoon': 'Selamat siang',
  'Good evening': 'Selamat sore',
  'Good night': 'Selamat malam',
  'How are you feeling today?': 'Bagaimana perasaanmu hari ini?',
  'Today you feel {mood}': 'Hari ini kamu merasa {mood}',
  'Add therapy': 'Tambah terapi',
  'No therapies yet': 'Belum ada terapi',
  'Add your first medicine to calculate schedules.': 'Tambahkan obat pertamamu untuk mulai menghitung jadwal.',
  'Low supply alert': 'Peringatan stok menipis',
  'Medicine expiring soon': 'Obat segera kedaluwarsa',
  'Take dose': 'Catat dosis',
  'Skip dose': 'Lewati',

  // Calendar & Schedule
  'Schedule': 'Jadwal',
  'History': 'Riwayat',
  'Journal': 'Jurnal',
  'No schedule for this day.': 'Tidak ada jadwal di hari ini.',
  'Add schedule': 'Tambah jadwal',
  'Write': 'Tulis',
  'All': 'Semua',
  'Mood': 'Suasana',
  'Body': 'Tubuh',
  'Notes': 'Catatan',
  'No entries yet. Record your mood, physical changes, or daily notes.': 'Belum ada entri. Catat suasana hati, perubahan tubuh, atau apa pun yang ingin kamu ingat.',

  // Levels & Labs
  'Lab results': 'Hasil lab',
  'Estimated {name}': 'Perkiraan {name}',
  'current': 'saat ini',
  'Adjust to lab results ({n})': 'Sesuaikan ke hasil lab ({n})',
  'estimated': 'perkiraan',
  'lab result': 'hasil lab',
  'Estimates use an average population model, not lab results. Individual levels vary; always consult your physician for dosage decisions.': 'Perkiraan memakai model rata-rata, bukan hasil lab. Level tiap orang berbeda, dan keputusan dosis tetap bersama dokter.',

  // Moods & Body Areas
  'Happy': 'Senang',
  'Calm': 'Tenang',
  'Neutral': 'Biasa',
  'Low': 'Murung',
  'Anxious': 'Cemas',
  'Hair': 'Rambut',
  'Breasts': 'Payudara',
  'Body shape': 'Bentuk tubuh',
  'Skin': 'Kulit',
  'Energy': 'Energi',
  'Sleep': 'Tidur',

  // Security & PIN
  'App PIN Lock': 'Kunci dengan PIN',
  'PIN protects your medical data and automatically syncs across your devices.': 'PIN melindungi data medismu dan otomatis tersinkron antar perangkat.',
  'Auto-lock timeout': 'Kunci lagi setelah ditinggalkan',
  'Immediately': 'Segera',
  '1 minute': '1 menit',
  '5 minutes': '5 menit',
  'Change PIN': 'Ubah PIN',
  'Enter old PIN': 'Masukkan PIN lama',
  'Enter PIN to disable': 'Masukkan PIN untuk mematikan',
  'Create 6-digit PIN': 'Buat PIN 6 digit',
  'Confirm 6-digit PIN': 'Ketik ulang PIN untuk memastikan',
  'Incorrect PIN. Try again.': 'PIN salah. Coba lagi.',
  'PIN does not match. Try again.': 'PIN tidak sama. Coba lagi.',
  'Enter your 6-digit PIN': 'Masukkan 6 digit PIN untuk membuka',
  'Please wait before trying again.': 'Tunggu sebentar sebelum mencoba lagi.',

  // Settings & Profile
  'Appearance': 'Tampilan',
  'Celestial Midnight & Pastel': 'Celestial Midnight & Pastel',
  'Signature nocturnal sanctuary with soft pastel highlights.': 'Suaka malam eksklusif dengan sentuhan pastel yang lembut.',
  'Phase accent': 'Aksen fase',
  'Theme': 'Tema',
  'System': 'Sistem',
  'Light': 'Terang',
  'Dark': 'Gelap',
  'Follow system': 'Ikuti sistem',
  'Accent Color': 'Warna Aksen',
  'Accent color': 'Warna aksen',
  'Language': 'Bahasa',
  'English (Default)': 'English (Default)',
  'Bahasa Indonesia': 'Bahasa Indonesia',
  'Reminders': 'Pengingat',
  'Dose Reminders': 'Pengingat Dosis',
  'Dose reminders': 'Pengingat dosis',
  'Notifications appear at scheduled times, even offline.': 'Notifikasi muncul pada jam jadwal, juga saat offline.',
  'Only available on Android and iOS apps.': 'Hanya tersedia di aplikasi Android dan iOS.',
  'Notification permission was denied. Enable it in system settings.': 'Izin notifikasi ditolak. Aktifkan lewat pengaturan sistem.',
  'Send test notification': 'Kirim notifikasi uji',
  'Hormone Level Units': 'Satuan Level Hormon',
  'Injection & Patch Sites': 'Lokasi Suntik & Patch',
  'Selection order determines next suggested site, alternating from top to bottom.': 'Urutan pemilihan menentukan saran lokasi berikutnya, bergantian dari atas ke bawah.',
  'Other location': 'Lokasi lain',
  'Days & Counters': 'Hari & Penghitung',
  'Count HRT therapy duration': 'Hitung lama menjalani terapi',
  'Show on History tab.': 'Tampil di tab Riwayat.',
  'Day starts at': 'Hari baru dimulai pukul',
  'Doses past midnight are counted for the previous day.': 'Dosis lewat tengah malam masih dihitung hari sebelumnya.',
  'Home Screen Widgets': 'Widget layar utama',
  'Home Screen Widget': 'Widget Layar Utama',
  'Long-press home screen, choose Widgets, then find Lunera: available HRT counter, schedule, and level chart widgets.': 'Tahan layar utama, pilih Widget, lalu cari Lunera: tersedia widget lama terapi, jadwal, dan grafik level.',
  'Hide details on widgets': 'Sembunyikan detail di widget',
  'Widgets only display the app name. Useful if your home screen is seen by others.': 'Widget hanya menampilkan nama aplikasi. Berguna jika layar utamamu terlihat orang lain.',
  'Sample Data': 'Data Contoh',
  'Populate your account with sample therapies, logs, lab results, and stock to test the app. All marked as "(sample)" and can be safely deleted.': 'Isi akunmu dengan terapi, catatan, hasil lab, dan stok contoh untuk mencoba aplikasi. Semuanya diberi tanda "(contoh)" dan bisa dihapus tanpa menyentuh datamu.',
  'Add': 'Tambah',
  'Add sample data to your account?': 'Tambahkan data contoh ke akunmu?',
  'Delete all sample data?': 'Hapus semua data contoh?',
  'Data & Storage': 'Data & Penyimpanan',
  'Data': 'Data',
  'Account': 'Akun',
  'Log out': 'Keluar',
  'About & Support': 'Tentang & Dukungan',
  'Version Changelog': 'Catatan Pembaruan',
  "See what's new in v{version} and past releases": "Lihat apa yang baru di v{version} dan rilis sebelumnya",
  "What's new in Lunera v{version}": "Apa yang baru di Lunera v{version}",
  'NEW': 'BARU',
  'Update Available!': 'Pembaruan Tersedia!',
  'Checking for updates...': 'Memeriksa pembaruan...',
  'GitHub Repository': 'Repositori GitHub',
  'View source code, release notes, and issue tracker.': 'Lihat kode sumber, catatan rilis, dan pelacak kendala.',
  'Medical Disclaimer': 'Disklaimer Medis',
  'Profile': 'Profil',
  'Nickname': 'Nama Panggilan (Nickname)',
  'Shown in greetings on the Home screen and profile card.': 'Ditampilkan pada salam Beranda dan kartu profil.',
  'Change photo': 'Ganti foto',
  'Remove photo': 'Hapus foto',
  'Save Profile': 'Simpan Profil',
  'Profile saved.': 'Profil berhasil disimpan.',
  'Profile photo updated.': 'Foto profil berhasil diperbarui.',
  'Profile photo removed.': 'Foto profil dihapus.',
  'Remove profile photo?': 'Hapus foto profil saat ini?',
  'Account username': 'Username akun',
  'Registered email': 'Email terdaftar',
  'Username and email are used for login authentication and cannot be changed.': 'Username dan email digunakan untuk otentikasi login dan tidak dapat diubah.',
};

