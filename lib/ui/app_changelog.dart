import 'package:flutter/material.dart';

import '../l10n.dart';
import '../theme.dart';
import '../update_checker.dart';

/// Type of change in release notes.
enum ChangeType { added, changed, fixed }

/// Individual change entry with bilingual support (EN/ID).
class ChangeItem {
  final ChangeType type;
  final String textEn;
  final String textId;

  const ChangeItem({
    required this.type,
    required this.textEn,
    required this.textId,
  });
}

/// Release version entry.
class ReleaseEntry {
  final String version;
  final String dateEn;
  final String dateId;
  final bool isCurrent;
  final List<ChangeItem> changes;

  const ReleaseEntry({
    required this.version,
    required this.dateEn,
    required this.dateId,
    this.isCurrent = false,
    required this.changes,
  });
}

/// Lunera offline release changelog history.
class AppChangelog {
  static const List<ReleaseEntry> releases = [
    ReleaseEntry(
      version: '1.11.6',
      dateEn: 'October 31, 2026',
      dateId: '31 Oktober 2026',
      isCurrent: true,
      changes: [
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'Fixed Gemini GA endpoint routing: targeting official v1 GA endpoint for gemini-1.5-flash with v1beta fallback for preview models, and capturing complete Google API error details.',
          textId: 'Perbaikan perutean endpoint Gemini GA: menargetkan endpoint resmi v1 GA untuk gemini-1.5-flash dengan fallback v1beta untuk model pratinjau, serta menangkap detail lengkap pesan error Google API.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.5',
      dateEn: 'October 31, 2026',
      dateId: '31 Oktober 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'Dynamic Gemini Flash model discovery & resilient fallback: auto-detects active models and migrates from retired gemini-1.5-flash to gemini-2.5-flash / gemini-2.0-flash.',
          textId: 'Pendeteksian model Gemini Flash dinamis & fallback tangguh: otomatis mendeteksi model aktif dan bermigrasi dari gemini-1.5-flash ke gemini-2.5-flash / gemini-2.0-flash.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.4',
      dateEn: 'October 31, 2026',
      dateId: '31 Oktober 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Celestial mode switcher: easily switch between Shared Star (Bintang Bersama - free community connection) and Personal Star (Bintang Pribadi - private key connection).',
          textId: 'Pengalih mode bintang: beralih dengan mudah antara Bintang Bersama (koneksi komunitas gratis) dan Bintang Pribadi (koneksi kunci mandiri).',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Gentle and friendly celestial terminology replacing technical developer jargon across all chat dialogs and settings.',
          textId: 'Terminologi surgawi yang ramah dan lembut menggantikan istilah teknis di seluruh dialog percakapan dan pengaturan.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Seamless bidirectional quota fallback: one-tap switching between Shared and Personal Star when either reaches its resting limit.',
          textId: 'Peralihan kuota dua arah otomatis: beralih dalam satu ketukan antara Bintang Bersama dan Pribadi saat salah satunya sedang beristirahat.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.3',
      dateEn: 'October 31, 2026',
      dateId: '31 Oktober 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Seamless hybrid Asteria architecture: built-in public key injected via GitHub Actions Secret for zero-setup instant chat.',
          textId: 'Arsitektur Asteria hibrida: kunci publik bawaan disuntikkan via GitHub Actions Secret agar pengguna awam bisa langsung curhat tanpa setup.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Gentle "Asteria is resting" quota handler with live status indicators when public daily quota is exhausted.',
          textId: 'Penanganan kuota lembut "Asteria sedang beristirahat" lengkap dengan indikator status jika kuota harian publik tercapai.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.2',
      dateEn: 'October 31, 2026',
      dateId: '31 Oktober 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Asteria AI Companion: empathetic, supportive conversational sanctuary powered by Google Gemini.',
          textId: 'Pendamping AI Asteria: ruang curhat reflektif dan penuh empati yang ditenagai oleh Google Gemini.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Home screen Floating Action Button (FAB) for instant one-tap access to heart-to-heart venting.',
          textId: 'Tombol mengambang (FAB) di Beranda untuk akses cepat curhat dan berbagi perasaan.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Reflective session summarizer: automatically creates warm journal entries with mood score and clears chat history.',
          textId: 'Rangkuman sesi reflektif: merangkum curhat otomatis ke Jurnal bersama skor mood dan membersihkan ruang obrolan.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Graceful offline lock: automatically protects the chat interface when device has no internet connection.',
          textId: 'Kunci mode offline: melindungi antarmuka obrolan secara anggun saat perangkat tidak terhubung internet.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.1',
      dateEn: 'October 31, 2026',
      dateId: '31 Oktober 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'Fixed squashed and flattened ("gepeng") body silhouette overview on tablet and wide-screen landscape displays.',
          textId: 'Perbaikan siluet tubuh yang gepeng pada tampilan tablet dan lanskap layar lebar.',
        ),
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'Centered anatomical overview diagram with responsive width constraint and locked aspect ratio proportions.',
          textId: 'Diagram anatomi tubuh kini berada di tengah dengan batas lebar responsif dan proporsi aspek rasio terkunci.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.0',
      dateEn: 'October 31, 2026',
      dateId: '31 Oktober 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Body measurement progression trend charts (WHR, Bust & Ribcage, Waist & Hips, Weight, Legs) with baseline comparison.',
          textId: 'Kurva tren perkembangan ukuran tubuh (WHR, Dada & Bawah Dada, Pinggang & Pinggul, Berat Badan, Kaki) dengan perbandingan awal.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Interactive anatomical injection site map & tissue rest heatmap (Front and Back perspectives) with smart rotation guidance.',
          textId: 'Peta anatomi titik suntik interaktif & heatmap istirahat jaringan (sudut pandang Depan & Belakang) dengan panduan rotasi cerdas.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.10.2',
      dateEn: 'October 31, 2026',
      dateId: '31 Oktober 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Multi-standard shoe size calculator and foot length tracking (EU/ID, US Women, US Men, UK) with live preview.',
          textId: 'Kalkulator ukuran sepatu multi-standar & pelacakan panjang kaki (EU/ID, US Wanita, US Pria, UK) dengan pratinjau langsung.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.10.1',
      dateEn: 'October 31, 2026',
      dateId: '31 Oktober 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Lower body measurements tracking (Thigh, Calf, and Inseam) with enhanced pants sizing calculation.',
          textId: 'Pelacakan ukuran tubuh bagian bawah (Paha, Betis, dan Panjang Kaki) dengan estimasi ukuran celana yang lebih presisi.',
        ),
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'Home screen profile sync: greeting and avatar now accurately reflect custom nickname and profile photo.',
          textId: 'Sinkronisasi profil beranda: sapaan nama dan avatar kini sesuai dengan foto profil dan nama panggilan.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.10.0',
      dateEn: 'October 31, 2026',
      dateId: '31 Oktober 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Native Android bilingual home screen widgets (HRT counter, schedule, levels) dynamically synced with active app language.',
          textId: 'Widget layar utama Android bilingual bawaan (lama terapi, jadwal, level) tersinkron otomatis dengan bahasa aplikasi aktif.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Body Measurements & Clothing Sizing calculator with dual-standard Bra fit (US/UK, EU/ID, sister sizes), top/shirt, and pants sizing.',
          textId: 'Kalkulator ukuran badan & pakaian dengan estimasi ukuran bra dual standar (US/UK, EU/ID, sister sizes), ukuran baju, dan celana.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Biometric security authentication (fingerprint / face unlock) with grace period and cloud-synced PIN security.',
          textId: 'Autentikasi keamanan biometrik (sidik jari / wajah) dengan masa tenggang dan kunci PIN tersinkron cloud.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'High-performance global translation architecture (L10n with tr) with comprehensive 600+ entry bilingual dictionary.',
          textId: 'Arsitektur penerjemahan global performa tinggi (L10n dengan tr) dengan kamus dwibahasa komprehensif 600+ entri.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.9.0',
      dateEn: 'October 31, 2026',
      dateId: '31 Oktober 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'Comprehensive bilingual localization audit across all screens, eliminating language leakage between English and Indonesian.',
          textId: 'Audit lokalisasi dwibahasa menyeluruh di seluruh layar, memperbaiki kebocoran bahasa antara Bahasa Inggris dan Bahasa Indonesia.',
        ),
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'Dynamic date & time formatting respecting active app locale instead of hardcoded locale formats in Calendar and Levels.',
          textId: 'Format tanggal dan waktu dinamis yang mengikuti bahasa aktif aplikasi tanpa memaksakan format lokal statis di Kalender dan Level.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Web Landing Page enhanced with celestial panoramic banner and locked into the unified Celestial Midnight & Pastel theme.',
          textId: 'Pembaruan Landing Page web dengan banner panorama celestial baru dan penguncian tema terpadu Celestial Midnight & Pastel.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.8.0',
      dateEn: 'October 31, 2026',
      dateId: '31 Oktober 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Unified signature "Celestial Midnight & Pastel" theme with Atmospheric Midnight Canvas (#0B0D21) and Velvet Surface (#16193E).',
          textId: 'Tema eksklusif terpadu "Celestial Midnight & Pastel" dengan kanvas malam danau (#0B0D21) dan permukaan kartu beludru (#16193E).',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Celestial Pastel palette infusion across hero countdown cards, mood markers, dose dial ticks, and therapeutic target zones.',
          textId: 'Sentuhan palet warna pastel surgawi pada kartu countdown dosis, penanda suasana hati, piringan jam, dan area target terapeutik.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Redesigned Appearance settings featuring the bespoke signature aesthetic and celestial Phase Accents.',
          textId: 'Pembaruan menu Tampilan dengan kartu tema signature dan pilihan Aksen Fase surgawi.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.7.0',
      dateEn: 'October 31, 2026',
      dateId: '31 Oktober 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'In-app Version Changelog viewer in Settings & More dashboard to inspect patch history and release notes offline anytime.',
          textId: 'Fitur Catatan Pembaruan (Changelog) bawaan aplikasi pada menu Pengaturan & Lainnya untuk meninjau riwayat rilis secara offline kapan saja.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Reactive available update state with real-time "NEW" badges and version transition indicators.',
          textId: 'Notifikasi pembaruan aplikasi reaktif dengan badge "BARU" dan penanda transisi versi secara real-time.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn: 'Revamped Settings dashboard with unified "About & Support" card and full bilingual localization.',
          textId: 'Pembaruan menu Pengaturan dengan kartu terpadu "Tentang & Dukungan" serta lokalisasi multibahasa menyeluruh.',
        ),
        ChangeItem(
          type: ChangeType.fixed,
          textEn: 'CI/CD and Gradle build hardening with Google Cloud Maven mirror and automated build retry loop.',
          textId: 'Penguatan pipeline build CI/CD dan Gradle dengan mirror Maven Google Cloud dan perulangan build otomatis.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.6.0',
      dateEn: 'October 30, 2026',
      dateId: '30 Oktober 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'In-app animated nighttime lake splash screen with starry skies, mountain horizon, water reflections, and crescent moon.',
          textId: 'Layar splash animasi danau malam hari dengan langit berbintang, barisan pegunungan, pantulan air, dan bulan sabit.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Enhanced vector moon logo with elliptical orbital ring rendered seamlessly in front of and behind the crescent moon.',
          textId: 'Penyempurnaan logo vektor bulan dengan cincin orbit elips yang melingkari bulan sabit secara artistik.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Lake landscape scenery component integrated into Welcome and authentication views for visual continuity.',
          textId: 'Komponen lanskap danau malam yang terintegrasi pada layar Selamat Datang dan otentikasi.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.5.0',
      dateEn: 'October 29, 2026',
      dateId: '29 Oktober 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Cloud-synchronized 6-digit PIN security with salted SHA-256 cryptographic hashing across all devices.',
          textId: 'Keamanan PIN 6 digit tersinkronisasi cloud dengan hashing kriptografi SHA-256 tersiram garam di semua perangkat.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'English default localization with full runtime language switcher to Bahasa Indonesia.',
          textId: 'Lokalisasi standar Bahasa Inggris dengan pengalih bahasa dinamis ke Bahasa Indonesia.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.4.0',
      dateEn: 'October 29, 2026',
      dateId: '29 Oktober 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Native Android home screen widgets: HRT duration counter, upcoming dose schedule, and pharmacokinetic level chart.',
          textId: 'Widget layar utama Android bawaan: penghitung lama terapi, jadwal dosis mendatang, dan grafik level farmakokinetik.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Privacy switch to mask sensitive medical details on home screen widgets.',
          textId: 'Sakelar privasi untuk menyamarkan rincian medis sensitif pada widget layar utama.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.3.0',
      dateEn: 'October 29, 2026',
      dateId: '29 Oktober 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Dedicated user profile customization with custom Nickname and avatar photo cached locally and synced to cloud.',
          textId: 'Kustomisasi profil pengguna dengan Nama Panggilan dan foto avatar yang tersimpan lokal dan tersinkron ke cloud.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Interactive UserAvatar on Home and More dashboards with personalized greeting header.',
          textId: 'Avatar interaktif pada Beranda dan Lainnya lengkap dengan salam sapaan yang dipersonalisasi.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.2.0',
      dateEn: 'October 29, 2026',
      dateId: '29 Oktober 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Interactive Body Changes visualizer with anatomical callouts and observation timelines.',
          textId: 'Visualisasi perubahan tubuh interaktif dengan panduan anatomi dan linimasa observasi.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Insights & cycle correlation engine analyzing dose adherence and mood trends relative to dosage intervals.',
          textId: 'Mesin analisis dan korelasi siklus yang memantau kepatuhan dosis dan tren suasana hati terhadap interval konsumsi.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Quick 1-tap mood check-in on Home screen and mood indicator dots on pharmacokinetic curves.',
          textId: 'Pencatatan suasana hati 1 ketukan pada Beranda dan titik indikator suasana pada kurva farmakokinetik.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.1.0',
      dateEn: 'October 29, 2026',
      dateId: '29 Oktober 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Comprehensive 5-tab navigation shell (Home, Calendar, Levels, Supplies, More) with Midnight UI design.',
          textId: 'Navigasi 5 tab komprehensif (Beranda, Kalender, Level, Stok, Lainnya) dengan desain antarmuka Midnight UI.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Weekly strip date selector with schedule indicators and dose history switcher.',
          textId: 'Pemilih tanggal mingguan dengan indikator jadwal dan pengalih riwayat konsumsi dosis.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Automated stock depletion and medication expiration advance alerts.',
          textId: 'Pengingat otomatis saat stok menipis dan peringatan dini sebelum obat kedaluwarsa.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.0.1',
      dateEn: 'October 28, 2026',
      dateId: '28 Oktober 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Graceful back navigation and exit confirmation dialog matching Wall o\' Pay.',
          textId: 'Navigasi tombol kembali bertahap dan dialog konfirmasi keluar aplikasi seperti Wall o\' Pay.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.0.0',
      dateEn: 'October 28, 2026',
      dateId: '28 Oktober 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn: 'Initial release of Lunera: Pharmacokinetic simulations, schedule tracking, inventory management, biometric security, and dual local/cloud backups.',
          textId: 'Rilis perdana Lunera: Simulasi farmakokinetik, pencatatan jadwal, manajemen inventaris, keamanan biometrik, dan cadangan ganda lokal/cloud.',
        ),
      ],
    ),
  ];
}

/// Displays the modal changelog bottom sheet.
void showAppChangelogSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const AppChangelogSheet(),
  );
}

class AppChangelogSheet extends StatelessWidget {
  const AppChangelogSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final isIndonesian = AppLocale.code == 'id';
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: dark ? C.midnight : theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: C.peony.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.history_edu_rounded,
                        color: C.peony,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('Version Changelog'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.tr(
                              "What's new in Lunera v{version}",
                              {'version': UpdateCheckerService.currentVersion},
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(color: muted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: context.tr('Close'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  itemCount: AppChangelog.releases.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final release = AppChangelog.releases[index];
                    return _ReleaseCard(
                      release: release,
                      isIndonesian: isIndonesian,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReleaseCard extends StatelessWidget {
  const _ReleaseCard({
    required this.release,
    required this.isIndonesian,
  });

  final ReleaseEntry release;
  final bool isIndonesian;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Container(
      decoration: BoxDecoration(
        color: dark ? C.deepCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: release.isCurrent
              ? C.peony.withValues(alpha: 0.5)
              : (dark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
          width: release.isCurrent ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'v${release.version}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: release.isCurrent ? C.peony : null,
                ),
              ),
              const SizedBox(width: 8),
              if (release.isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: C.peony,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isIndonesian ? 'TERBARU' : 'LATEST',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                isIndonesian ? release.dateId : release.dateEn,
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...release.changes.map((item) => _ChangeItemRow(item: item, isIndonesian: isIndonesian)),
        ],
      ),
    );
  }
}

class _ChangeItemRow extends StatelessWidget {
  const _ChangeItemRow({
    required this.item,
    required this.isIndonesian,
  });

  final ChangeItem item;
  final bool isIndonesian;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color badgeBg;
    Color badgeFg;
    String badgeLabel;

    switch (item.type) {
      case ChangeType.added:
        badgeBg = Pastel.mint.withValues(alpha: 0.18);
        badgeFg = Pastel.mint;
        badgeLabel = isIndonesian ? 'BARU' : 'ADDED';
        break;
      case ChangeType.changed:
        badgeBg = Pastel.sky.withValues(alpha: 0.18);
        badgeFg = Pastel.sky;
        badgeLabel = isIndonesian ? 'UBAH' : 'CHANGED';
        break;
      case ChangeType.fixed:
        badgeBg = Pastel.rose.withValues(alpha: 0.18);
        badgeFg = Pastel.rose;
        badgeLabel = isIndonesian ? 'PERBAIKAN' : 'FIXED';
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badgeLabel,
              style: TextStyle(
                color: badgeFg,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isIndonesian ? item.textId : item.textEn,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
