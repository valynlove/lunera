import 'package:flutter/material.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';
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
      version: '2.2.30',
      dateEn: 'November 24, 2026',
      dateId: '24 November 2026',
      isCurrent: true,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Segmented PillTabs in Settings: Introduced top category filter tabs (All, General, Clinical, Privacy, Data) to segment the extensive 1,000+ line settings page, dramatically cutting scroll fatigue while keeping all settings instantly reachable.',
          textId:
              'PillTabs Segmentasi pada Pengaturan: Menghadirkan tab penyaring kategori atas (Semua, Umum, Klinis, Privasi, Data) untuk menyaring hierarki menu pengaturan, memangkas kelelahan scrolling dengan tetap menjaga kemudahan akses semua pengaturan.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Responsive Tablet & Wide-Screen Constraints: Enforced 640–680dp max-width centering across main navigation shell, bottom sheets, body page, and settings, ensuring elegant proportional card layouts and optimal reading line length on tablets and foldables.',
          textId:
              'Pembatas Lebar Responsif Tablet & Layar Lebar: Menerapkan pemusatan batas lebar 640–680dp pada shell navigasi utama, modal sheet, layar tubuh, dan pengaturan, menjaga tampilan kartu tetap proporsional dan nyaman dibaca pada tablet maupun ponsel lipat.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Sticky Bottom Action Bar in Body Page: Relocated measurement and milestone action buttons from the end of the scroll list into a pinned, thumb-accessible bottom navigation bar for effortless logging.',
          textId:
              'Bilah Aksi Melayang pada Layar Tubuh: Memindahkan tombol catat ukuran dan milestone dari ujung bawah list ke bilah bawah yang selalu terlihat dan mudah dijangkau ibu jari.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Sticky Header CTAs in TherapySheet & LabSheet: Added top-bar quick-save buttons and TextInputAction.done keyboard submissions to prevent buttons getting obscured during virtual keyboard entry.',
          textId:
              'Tombol Aksi Cepat Header pada TherapySheet & LabSheet: Menambahkan tombol simpan di header atas serta aksi keyboard TextInputAction.done untuk mencegah tombol terdorong saat mengetik.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.2.29',
      dateEn: 'November 24, 2026',
      dateId: '24 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Reduced-Motion Accessibility Support: Integrated MediaQuery.maybeDisableAnimationsOf(context) and tranquil static glow fallbacks across the Eternal Dusk chibi companion, honoring user system accessibility preferences (WCAG 2.1 SC 2.3.3) while preserving gentle ambient breathing pulses during normal animation mode.',
          textId:
              'Dukungan Aksesibilitas Gerak Berkurang (Reduced-Motion): Mengintegrasikan MediaQuery.maybeDisableAnimationsOf(context) dan tampilan cahaya tenang statis pada chibi companion Eternal Dusk, mematuhi preferensi aksesibilitas sistem pengguna (WCAG 2.1 SC 2.3.3) serta menjaga denyut napas ambien yang halus saat animasi aktif.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Sticky Header CTA & Keyboard Submission in DoseSheet: Added a top-bar quick-save button and enabled TextInputAction.done with immediate keyboard submission on dose text fields, allowing users on compact screens to effortlessly log doses without scrolling past extended clinical forms.',
          textId:
              'Tombol Aksi Cepat Header & Submisi Keyboard pada DoseSheet: Menambahkan tombol simpan cepat di header dan mendukung TextInputAction.done dengan aksi langsung dari keyboard virtual pada field dosis, memungkinkan pencatatan dosis tanpa perlu scroll melewati formulir klinis lanjutan di layar ringkas.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.2.28',
      dateEn: 'November 24, 2026',
      dateId: '24 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Home Dashboard Modular Architecture: Refactored the monolithic 1,376-line home dashboard into focused, isolated sub-widgets (DoseCard, SlotTile, AlertsCard, WeekCard, OnboardingStepTile) under lib/ui/home/, slashing main file complexity by 77% while preserving seamless public exports.',
          textId:
              'Arsitektur Modular Home Dashboard: Merefaktor home dashboard monolitik 1.376 baris menjadi sub-widget terisolasi dan modular (DoseCard, SlotTile, AlertsCard, WeekCard, OnboardingStepTile) di dalam lib/ui/home/, memangkas kompleksitas file utama hingga 77% dengan mempertahankan kompatibilitas ekspor publik penuh.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.2.27',
      dateEn: 'November 24, 2026',
      dateId: '24 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Moments Image Memory Optimization: Implemented bounded raster decoding (cacheWidth: 600 for album grid cards and preview sheets, 1080 for fullscreen views) across local base64 photo streams, eliminating GPU bitmap bloat and ensuring butter-smooth 60/120 FPS scrolling.',
          textId:
              'Optimasi Memori Foto Moments: Mengimplementasikan raster decoding berbatas (cacheWidth: 600 untuk kartu album dan preview sheet, 1080 untuk fullscreen) pada stream foto lokal base64, mencegah lonjakan memori GPU bitmap dan menjaga kelancaran scroll 60/120 FPS.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.2.26',
      dateEn: 'November 24, 2026',
      dateId: '24 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Mobile Navigation Bar Ergonomics: Upgraded floating navigation bar touch targets to meet WCAG ergonomic standards (min 48dp height), refined icon containers and bounding padding, enhanced label typography legibility (10.5sp with optical letter spacing), and integrated accessibility semantics support.',
          textId:
              'Ergonomi Bilah Navigasi Mobile: Memperbarui target sentuh bilah navigasi bawah sesuai standar ergonomi WCAG (tinggi minimal 48dp), menyempurnakan kontainer ikon dan padding batas, meningkatkan keterbacaan tipografi label (10.5sp dengan optical letter spacing), serta mengintegrasikan dukungan semantik aksesibilitas.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.2.25',
      dateEn: 'November 24, 2026',
      dateId: '24 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Web Showcase Feature Suite: Added interactive Multi-Route Selector (Injections, Patches, Gels, Sublingual/Oral), Android Home Screen Widgets showcase, interactive 7-Day Cycle Timeline Scrubber, and Voice Pitch Studio / Twilight Sanctuary vignettes.',
          textId:
              'Rangkaian Fitur Web Showcase: Menambahkan Multi-Route Selector interaktif (Injeksi, Patch, Gel, Sublingual/Oral), showcase Widget Home Screen Android, Scrubber Timeline Siklus 7-Hari interaktif, serta vignetted Voice Pitch Studio & Twilight Sanctuary.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.2.24',
      dateEn: 'November 24, 2026',
      dateId: '24 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Web Showcase Triad Design Redesign: Integrated Art Direction (Linear/Figma caliber), Design System (Eternal Dusk obsidian and luminous accents), and snappy motion principles (<300ms spring easing curves) across the showcase landing page.',
          textId:
              'Redesain Terpadu Web Showcase: Mengintegrasikan Art Direction berkelas Linear/Figma, Design System Eternal Dusk (obsidian pekat dan aksen bercahaya), serta prinsip gerak snappy (<300ms kurva spring) pada seluruh landing page showcase.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.2.23',
      dateEn: 'November 24, 2026',
      dateId: '24 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Web Showcase Taste-Skill Visual Refresh: Overhauled docs landing page with Apple and Linear caliber typography, modular whitespace rhythm, architectural telemetry proof strip, and interactive bento grid.',
          textId:
              'Penyegaran Visual Showcase Berstandar Taste-Skill: Merombak landing page docs dengan tipografi sekelas Apple dan Linear, ritme spasi modular, strip telemetri arsitektural, dan bento grid interaktif.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.2.22',
      dateEn: 'November 24, 2026',
      dateId: '24 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.fixed,
          textEn:
              'Notification Timezone Scheduling: Snoozed dose reminders initialize local timezone properly on Android to avoid negative offset scheduling.',
          textId:
              'Penjadwalan Zona Waktu Notifikasi: Pengingat tunda dosis menginisialisasi zona waktu lokal dengan benar di Android untuk mencegah jadwal bernilai negatif.',
        ),
        ChangeItem(
          type: ChangeType.fixed,
          textEn:
              'Lab Target Stream & Widget Chart Safety: Safely handled missing cloud target fields and guarded target bands against index errors during widget sync.',
          textId:
              'Keamanan Aliran Target Lab & Grafik Widget: Penanganan aman data target cloud yang tidak lengkap dan pencegahan error indeks batas target saat sinkronisasi widget.',
        ),
        ChangeItem(
          type: ChangeType.fixed,
          textEn:
              'Sanctuary Key Migration & Widget Overdue Fix: Awaited local storage key migration and added instant same-day timestamp overdue detection for Android widgets.',
          textId:
              'Migrasi Kunci Suaka & Deteksi Terlambat Widget: Memastikan migrasi kunci lokal selesai sepenuhnya dan menambahkan deteksi keterlambatan waktu nyata hari ini pada widget Android.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.2.21',
      dateEn: 'November 24, 2026',
      dateId: '24 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.fixed,
          textEn:
              'Ambient Companion Dose Priority: Imminent upcoming dose reminders take priority over past recovery states, with shorter recovery windows for oral medication.',
          textId:
              'Prioritas Dosis Pendamping Ambien: Pengingat jadwal dosis terdekat diprioritaskan sebelum status pemulihan, dengan jeda pemulihan lebih singkat untuk obat oral.',
        ),
        ChangeItem(
          type: ChangeType.fixed,
          textEn:
              'Smart Consultation Regimen Correlation: Symptom cycle correlations adapt dynamically to active regimen cycle length and avoid false alerts on daily therapies.',
          textId:
              'Korelasi Regimen Konsultasi Pintar: Analisis korelasi siklus gejala beradaptasi secara dinamis dengan panjang siklus terapi dan mencegah peringatan keliru pada terapi harian.',
        ),
        ChangeItem(
          type: ChangeType.fixed,
          textEn:
              'Moments Memory Optimization: Automatic downscaling and compression on fallback photo pickers to prevent memory bloat.',
          textId:
              'Optimasi Memori Momen: Penurunan skala dan kompresi otomatis pada pemilih foto alternatif untuk mencegah pemborosan memori.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.2.20',
      dateEn: 'November 24, 2026',
      dateId: '24 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Celestial Wallpaper for Home Screen Widgets: Added high-definition celestial wallpaper with layered frosted glass scrim overlay and lavender rim stroke for all Android widgets.',
          textId:
              'Wallpaper Langit Malam Widget Layar Utama: Menambahkan latar belakang langit malam beresolusi tinggi dengan lapisan kaca buram dan aksen lavender untuk seluruh widget Android.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.2.19',
      dateEn: 'November 24, 2026',
      dateId: '24 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Android Home Screen Widgets Visual Refresh: Added cosmic gradients, luminous lavender hairline borders, jewel badge icons, translucent row containers, and overdue dose coloring.',
          textId:
              'Penyegaran Visual Widget Android: Menambahkan gradien kosmik, bingkai lavender tipis bercahaya, lencana ikon permata, wadah baris transparan, dan pewarnaan dosis terlambat.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Card Atmosphere & Depth: Multi-stop diagonal cosmic gradients for in-app cards providing subtle tactile depth while preserving the Eternal Dusk backdrop.',
          textId:
              'Kedalaman & Atmosfer Kartu: Gradien kosmik diagonal berlapis untuk kartu aplikasi memberikan kedalaman visual yang elegan dengan latar Senja Abadi.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.2.18',
      dateEn: 'November 24, 2026',
      dateId: '24 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.fixed,
          textEn:
              'Cross-Account Data Isolation: Scoped all local storage keys by authenticated user UID and automated complete local cache clearing on sign-out.',
          textId:
              'Isolasi Data Lintas Akun: Mengikat seluruh kunci penyimpanan lokal dengan UID pengguna terotentikasi dan pembersihan cache otomatis saat keluar akun.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Full Offline JSON Backup Parity: Extended JSON backup export and import to encompass Milestones, Moments, and Consultation data with full legacy backward compatibility.',
          textId:
              'Paritas Cadangan JSON Offline Penuh: Memperluas ekspor dan impor cadangan JSON mencakup Milestones, Moments, dan Konsultasi dengan kompatibilitas penuh versi terdahulu.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.2.17',
      dateEn: 'November 24, 2026',
      dateId: '24 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Lunera Moments: Private milestone keepsake and photo scrapbook celebrating transition milestones, affirming outfits, and reflections with offline-first local storage.',
          textId:
              'Momen Lunera: Album kenangan visual dan scrapbook pencapaian pribadi untuk merayakan tonggak transisi, gaya busana, dan refleksi dengan penyimpanan lokal aman.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Smart Reminder Drawer: Unified care notification center with actionable alerts for overdue doses, critical/depleted supplies, upcoming trough windows, and clinical visits.',
          textId:
              'Laci Pengingat Perawatan Cerdas: Pusat notifikasi terpadu dengan peringatan tindakan untuk dosis terlewat, stok menipis/habis, jendela lab trough, dan kontrol dokter.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.2.16',
      dateEn: 'November 24, 2026',
      dateId: '24 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Smart Consultation Prep & Symptom Clustering: Clinical appointment prep assistant clustering journal symptoms, correlating complaints with dose and trough rhythms, pre-visit checklist, and one-tap Doctor Report integration with prepared questions.',
          textId:
              'Persiapan Konsultasi Pintar & Klaster Gejala: Asisten persiapan dokter yang mengelompokkan gejala jurnal, mengkorelasikan keluhan dengan ritme dosis dan trough, daftar periksa kunjungan, dan integrasi ekspor Laporan Dokter lengkap dengan daftar pertanyaan.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.2.15',
      dateEn: 'November 24, 2026',
      dateId: '24 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Pharmacokinetic-Aware Timeline: Full-month calendar grid toggle with multi-category event dots (dose, trough, journal, supply depletion), automated Trough Lab Testing Window detection prior to cyclical/injection doses, and selected-day clinical highlight cards.',
          textId:
              'Linimasa Kalender Berbasis Farmakokinetik: Opsi tampilan grid kalender bulanan penuh dengan indikator titik multi-kategori (dosis, trough, jurnal, stok habis), deteksi otomatis Jendela Tes Lab Trough sebelum dosis siklus/injeksi, dan kartu sorotan klinis harian.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.2.14',
      dateEn: 'November 24, 2026',
      dateId: '24 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Predictive Supply & Refill Horizon: Refill forecasting engine calculating depleted, critical (<=7 days), reorder window (8–14 days with delivery buffer), and healthy tiers; integrated smart Refill Horizon banner and actionable status chips on medication and equipment cards.',
          textId:
              'Cakrawala Stok & Pemesanan Ulang Prediktif: Mesin proyeksi pemesanan ulang untuk status habis, kritis (<=7 hari), jendela pesan ulang (8–14 hari dengan jeda pengiriman), dan stok aman; banner pintar Refill Horizon dan badge status interaktif pada kartu obat dan peralatan.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.2.13',
      dateEn: 'November 24, 2026',
      dateId: '24 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Empathetic Ambient Companion: Contextual micro-companion on Home with 20 moods, time-of-day greetings, post-dose recovery support, gentle dose horizon prompts, interactive affirmation cycling, and daily dismissal support.',
          textId:
              'Pendamping Ambien Empatis: Pendamping mikro kontekstual di Home dengan 20 ekspresi avatar, sapaan waktu hari, dukungan pemulihan pasca-dosis, pengingat lembut jadwal dosis, pergantian afirmasi interaktif, dan opsi sembunyikan harian.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.2.12',
      dateEn: 'November 24, 2026',
      dateId: '24 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Twilight Sanctuary: Temporarily deactivated the HRT Time-Lapse visual explorer card pending complete illustration asset readiness.',
          textId:
              'Suaka Senja: Menonaktifkan kartu penjelajah visual Time-Lapse HRT untuk sementara waktu hingga kesiapan aset ilustrasi terpenuhi.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.2.11',
      dateEn: 'November 23, 2026',
      dateId: '23 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Larger Body & Injection Map Avatar Framing: Expanded the center avatar lane in Injection Site Rotation (front & back) and tightened the Body & Changes Overview container framing so the character fills vertical space more naturally with minimal empty gap.',
          textId:
              'Proporsi Avatar Lebih Besar & Rapi: Memperlebar ruang avatar tengah pada Rotasi Lokasi Suntik (depan & belakang) serta merapikan bingkai diagram Ringkasan Tubuh & Perubahan agar karakter tampil lebih besar dengan ruang kosong minimal.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.2.10',
      dateEn: 'November 23, 2026',
      dateId: '23 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'HRT Time-Lapse Stage Ordering: Remapped the 5-stage Feminizing (MtF) and Masculinizing (FtM) sprite progressions to depict a full pre-HRT to post-HRT transition across stage_0 through stage_4.',
          textId:
              'Urutan Tahap Time-Lapse HRT: Menyelaraskan urutan 5 tahap progresi sprite Feminizing (MtF) dan Masculinizing (FtM) agar menggambarkan transisi lengkap pra-HRT hingga pasca-HRT dari stage_0 hingga stage_4.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.2.9',
      dateEn: 'November 23, 2026',
      dateId: '23 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'HRT Time-Lapse Sprites & Portal Frame: Sliced and baseline-aligned 5 Feminizing (MtF) and 5 Masculinizing (FtM) stage sprites, standardized thigh-high socks on mtf_stage_3, and extracted portal_frame.png.',
          textId:
              'Sprite Time-Lapse HRT & Bingkai Portal: Memotong dan menyelaraskan 5 sprite tahap Feminizing (MtF) dan 5 Masculinizing (FtM), menyamakan kaus kaki paha pada mtf_stage_3, dan mengekstrak portal_frame.png.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.2.8',
      dateEn: 'November 23, 2026',
      dateId: '23 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'HRT Time-Lapse Visual Explorer: Interactive visual progression explorer inside Twilight Sanctuary with Feminizing and Masculinizing pathway toggles, 5-stage timeline scrubber (Day 1 to 12–24+ Mo), smooth crossfades, and milestone tips.',
          textId:
              'Eksplorasi Visual Time-Lapse HRT: Penjelajah progresi visual interaktif di Suaka Senja dengan pilihan jalur Feminisasi dan Maskulinisasi, penggeser linimasa 5-tahap (Hari 1 hingga 12–24+ Bulan), transisi crossfade mulus, dan tip tonggak perkembangan.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.2.7',
      dateEn: 'November 23, 2026',
      dateId: '23 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Body Diagram Midriff Outfit Update: Updated front and back Lunera body diagram artwork (assets/images/body_front.png, assets/images/body_back.png) to the sports-bra & shorts outfit so abdominal subcutaneous injection sites and body waist contours remain clearly visible.',
          textId:
              'Pembaruan Ilustrasi Tubuh Sporty: Memperbarui aset depan dan belakang (body_front.png, body_back.png) ke outfit sports-bra & celana pendek agar area suntik perut dan lekuk pinggang terlihat lebih jelas.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.2.6',
      dateEn: 'November 23, 2026',
      dateId: '23 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Body & Injection Map Chibi Avatar Upgrade: Replaced the vector silhouettes on Injection Site Rotation (front & back views) and the Body & Changes Overview diagram with Lunera front/back sporty chibi artwork and recalibrated callout pointers.',
          textId:
              'Pembaruan Avatar Rotasi Injeksi & Ringkasan Tubuh: Mengganti siluet vektor pada Rotasi Lokasi Injeksi (tampak depan & belakang) serta diagram Ringkasan Tubuh & Perubahan dengan ilustrasi chibi depan/belakang beserta kalibrasi titik penunjuk.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.2.5',
      dateEn: 'November 23, 2026',
      dateId: '23 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Expanded Lunera Companion Expressions: Cleaned and registered 8 new chibi companion moods (annoyed, confused, cry, facepalm, laugh, love, shocked, shy) in CompanionMood — expanding the set to 20 expressions while preserving all floating expression icons.',
          textId:
              'Ekspresi Pendamping Lunera Diperluas: Membersihkan dan mendaftarkan 8 ekspresi chibi baru (annoyed, confused, cry, facepalm, laugh, love, shocked, shy) ke CompanionMood menjadi total 20 ekspresi dengan seluruh ikon melayang tetap terjaga.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Contextual Companion Art Integration: Added mood expressions across Care Guides search empty state (confused), Private Milestones empty state on Body (love), and Voice Pitch Studio warm-up completion (laugh).',
          textId:
              'Integrasi Kontekstual Pendamping: Menampilkan ekspresi Lunera pada status pencarian kosong di Panduan (confused), tab Milestone privat di Tubuh (love), dan penyelesaian pemanasan Voice Pitch Studio (laugh).',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.2.4',
      dateEn: 'November 23, 2026',
      dateId: '23 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Search, Calculators & Lab Timing: Added keyword search to Care Guides, 30/90-day filters in History, interactive unit conversion in Lab entry, a vial & syringe mL calculator in Dose logging, and scheduled 2-hour-prior trough bloodwork reminders.',
          textId:
              'Pencarian, Kalkulator & Pengingat Lab: Menambahkan pencarian kata kunci di Panduan, filter 30/90 hari di Riwayat, konverter satuan lab interaktif, kalkulator volume vial & syringe di form suntikan, serta pengingat terjadwal 2 jam sebelum jadwal lab trough.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Structured Symptom Check-ins & Private Milestones: Added filterable symptom presets in Journal with automatic summary inclusion in the Doctor Visit Report (Markdown & PDF), plus a pin-locked Milestones & Progress Photo gallery on the Body page.',
          textId:
              'Check-in Gejala & Galeri Milestone Privat: Menambahkan pilihan gejala terstruktur di Jurnal yang terangkum otomatis ke Laporan Dokter (Markdown & PDF), serta tab Milestone & foto progres lokal di balik kunci PIN/biometrik pada halaman Tubuh.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.2.3',
      dateEn: 'November 23, 2026',
      dateId: '23 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Voice Pitch Studio Stage 2 (Resonance, Weight & Guided SOVTE): Added live in-RAM Voice Size/Brightness and Vocal Weight meters, 4-step SOVTE Guided Quiet Warm-up, Gentle Reference Tone (Pitch Pipe), and optional Session Context Tags.',
          textId:
              'Pengembangan Voice Pitch Studio Tahap 2 (Resonansi, Ketebalan & Pemanasan Terpandu): Menambahkan indikator langsung Kecerahan/Ruang Suara dan Ketebalan Suara (di RAM), rutinitas Pemanasan Tenang 4 langkah bergaya SOVTE, Nada Referensi lembut, dan tag kondisi sesi opsional.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.2.2',
      dateEn: 'November 23, 2026',
      dateId: '23 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Voice Pitch Studio Expansion (Stage 1): Expanded pitch ranges into 8 plain-language tiers, added multi-sentence article reading passages, live pitch contour tracing, customizable target comfort zones, session stability metrics, and a historical progress trend chart.',
          textId:
              'Pengembangan Voice Pitch Studio (Tahap 1): Memperluas kategori suara menjadi 8 rentang berbahasa awam, menambah wacana bacaan gaya artikel, jejak nada langsung (live contour), zona target kustom, metrik intonasi, dan grafik tren progres.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.2.1',
      dateEn: 'November 23, 2026',
      dateId: '23 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Voice Pitch Studio Cloud & Backup Sync: Synchronizes numeric-only Voice Pitch Studio session results across devices via Cloud Firestore and includes them in JSON backups without ever storing audio.',
          textId:
              'Sinkronisasi Awan & Cadangan Voice Pitch Studio: Menyinkronkan hasil angka Voice Pitch Studio antar perangkat melalui Cloud Firestore serta menyertakannya dalam cadangan JSON tanpa menyimpan audio.',
        ),
        ChangeItem(
          type: ChangeType.fixed,
          textEn:
              'Cross-Device Studio Auto-Unlock & Delete Protection: Signing into another device automatically unlocks Voice Pitch Studio when synced results exist and keeps local or cross-device deletions in sync.',
          textId:
              'Auto-Unlock Studio & Sinkronisasi Penghapusan Antar Perangkat: Login di perangkat lain otomatis membuka Voice Pitch Studio bila ada hasil tersinkron dan menjaga status penghapusan tetap konsisten.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.2.0',
      dateEn: 'November 23, 2026',
      dateId: '23 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Chibi Companion Sprite Suite: Integrated 12-expression transparent chibi companion avatar across Home onboarding, Care Guides, Guided Calm Injection, and Twilight Sanctuary.',
          textId:
              'Koleksi Karakter Pendamping Chibi: Menghadirkan karakter pendamping chibi 12 ekspresi transparan di onboarding Beranda, Panduan Perawatan, Panduan Injeksi Tenang, dan Twilight Sanctuary.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Glassmorphic Eternal Dusk Profile Card: Overhauled MorePage with a horizontal glassmorphic membership banner, glowing avatar frame, adherence statistics, and quick edit pill.',
          textId:
              'Kartu Profil Glassmorphic Eternal Dusk: Merombak halaman More dengan kartu profil bergaya keanggotaan kaca transparan berlatar senja, bingkai avatar bercahaya, dan statistik kepatuhan.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Eternal Dusk Showcase & Web Landing Page: Added soft-blurred panoramic dusk backdrop, framed 2-column hero showcase card, and companion character highlights.',
          textId:
              'Showcase & Halaman Web Eternal Dusk: Menambahkan latar panorama senja berpendar lembut, kartu showcase hero 2-kolom berbingkai, dan sorotan karakter pendamping.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.1.19',
      dateEn: 'November 22, 2026',
      dateId: '22 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Next Dose Day & Date on Home Cards: Dose cards now display the exact weekday, date, and time of the upcoming scheduled dose alongside the countdown dial.',
          textId:
              'Hari & Tanggal Dosis Berikutnya di Kartu Beranda: Kartu dosis kini menampilkan hari, tanggal, dan jam jadwal berikutnya secara jelas bersama dial hitung mundur.',
        ),
        ChangeItem(
          type: ChangeType.fixed,
          textEn:
              'Decoy Calculator Tablet Layout & Back Navigation: Made the Decoy Calculator keypad responsive across landscape tablets without button cutoff, and enabled system Back exit from the lock screen while keeping the session locked.',
          textId:
              'Tata Letak Tablet & Tombol Kembali Kalkulator Penyamaran: Membuat grid tombol Kalkulator Penyamaran responsif pada layar tablet lanskap tanpa terpotong, serta mengizinkan keluar aplikasi lewat tombol Back sistem sambil tetap menjaga sesi terkunci.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.1.18',
      dateEn: 'November 22, 2026',
      dateId: '22 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Gentle 3-Step Onboarding: Empty Home dashboard now guides new users calmly through adding a first therapy, reviewing PIN/Decoy privacy settings, and opening the Start Here safety guide.',
          textId:
              'Onboarding 3 Langkah Tenang: Layar Home kosong kini memandu pengguna baru menambah terapi pertama, mengatur kunci PIN/Decoy, dan membaca panduan Mulai di Sini.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Notification "Mark Taken" Action: Dose reminders now include a foreground "Mark taken" action (alongside 15/30-min snooze) that opens the pre-filled confirmation sheet safely behind LockGate.',
          textId:
              'Aksi Notifikasi "Tandai Diminum": Pengingat dosis kini memiliki tombol cepat "Tandai diminum" (bersama tunda 15/30 mnt) yang membuka konfirmasi dosis secara aman setelah LockGate.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Supply Run-Out Forecast & Trough Bloodwork Timing: Supplies display estimated weeks/days remaining based on therapy cadence, and Levels highlights the next trough blood-draw window alongside 3-month lab reminders.',
          textId:
              'Perkiraan Stok Habis & Waktu Cek Lab Trough: Halaman Supplies menampilkan perkiraan minggu/hari tersisa, dan tab Levels menampilkan waktu terbaik ambil darah trough serta pengingat cek rutin 3 bulan.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Doctor Visit Summary PDF Export: Share or download a clean A4 print-ready PDF alongside Markdown from Settings -> Doctor Visit Summary.',
          textId:
              'Ekspor PDF Ringkasan Konsultasi Dokter: Bagikan atau unduh PDF A4 siap cetak selain format teks Markdown dari Pengaturan -> Ringkasan Konsultasi Dokter.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.1.17',
      dateEn: 'November 22, 2026',
      dateId: '22 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Voice Training Guide & Easter-Egg Voice Pitch Studio: Added a 14th Care Guide covering comfort, resonance, and voice dysphoria, plus a 5-tap Developer Mode unlock revealing the optional Voice Pitch Studio in Twilight Sanctuary (quiet warm-up, random reading prompts, live on-device Hz categories, and numeric-only history without storing audio).',
          textId:
              'Panduan Latihan Suara & Easter-Egg Voice Pitch Studio: Menambahkan panduan ke-14 tentang kenyamanan, resonansi, dan disforia suara, serta pemicu ketuk 5x ala Developer Mode untuk membuka Voice Pitch Studio opsional di Suaka Senja (pemanasan tenang, kalimat latihan acak, kategori Hz langsung di perangkat, dan riwayat angka tanpa menyimpan rekaman audio).',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.1.16',
      dateEn: 'November 22, 2026',
      dateId: '22 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Twilight Sanctuary Mini-Experiences: Added Starlight Ripples & Breath (calming 4-4-6 touch ripple canvas), Safety & Dosing Sense (5-question interactive practice linking back to guides), and Moonlight Lantern (gentle, no-punishment daily light companion) under More -> Care & Assistant Tools.',
          textId:
              'Suaka Senja (Twilight Sanctuary): Menambahkan Riak Bintang & Napas Tenang (kanvas riak sentuh 4-4-6), Kepekaan Keamanan & Dosis (latihan 5 soal interaktif yang tertaut ke panduan), dan Lentera Cahaya Bulan (pendamping cahaya harian tanpa penalti) di menu More -> Care & Assistant Tools.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.1.15',
      dateEn: 'November 22, 2026',
      dateId: '22 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Care & HRT Guides Library: Added 13 offline-first, bilingual (EN/ID) educational and harm-reduction guides accessible via shortcut cards, including a non-judgmental starting guide, dosing math, lab units, safe injection & rotation, medical red flags, and physical/emotional timelines.',
          textId:
              'Pustaka Panduan Perawatan & HRT: Menambahkan 13 panduan edukasi dan harm reduction dwibahasa (EN/ID) yang sepenuhnya offline melalui kartu pintasan langsung, mencakup panduan memulai dengan aman tanpa menghakimi, hitungan dosis, satuan lab, teknik suntik & rotasi aman, tanda bahaya medis, serta linimasa perubahan fisik/emosional.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Contextual Guide Links: Added quick guide shortcuts inside the Levels page and Injection Site Rotation sheet for instant reference.',
          textId:
              'Tautan Panduan Kontekstual: Menambahkan pintasan panduan cepat langsung dari halaman Levels dan panel Rotasi Titik Suntik.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.1.14',
      dateEn: 'November 21, 2026',
      dateId: '21 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Upcoming Dose Projection & Peak/Trough: Preview scheduled doses ahead on hormone charts along with window peak and trough estimates, plus a rough PK profile for Estradiol gel.',
          textId:
              'Proyeksi Jadwal & Puncak/Terendah: Pratinjau dosis terjadwal ke depan di grafik hormon beserta estimasi puncak dan titik terendah, serta profil PK perkiraan untuk gel Estradiol.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Doctor Visit Summary: Share a clean 3- or 6-month text summary of therapies, adherence, and lab results without exposing private journal or free-text notes.',
          textId:
              'Ringkasan Konsultasi Dokter: Bagikan ringkasan teks 3 atau 6 bulan berisi terapi, kepatuhan, dan hasil lab tanpa menyertakan catatan pribadi atau jurnal.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Optional Encrypted Backups: Protect exported JSON backups with PBKDF2 + AES-256-GCM passphrase encryption while retaining plain JSON restore compatibility.',
          textId:
              'Backup Terenkripsi Opsional: Lindungi berkas ekspor JSON dengan enkripsi kata sandi PBKDF2 + AES-256-GCM sambil tetap mendukung restore backup JSON biasa.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Dose Notification Snooze: Added 15- and 30-minute snooze actions on dose reminders that preserve discreet notification masking and clear automatically when logged.',
          textId:
              'Tunda Notifikasi Dosis: Menambahkan aksi cepat tunda 15 dan 30 menit pada pengingat dosis dengan tetap menjaga mode privasi notifikasi.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Modular Levels UI: Split levels.dart into focused part files and added controller disposal in LabSheet.',
          textId:
              'Modularisasi UI Kadar Hormon: Memecah levels.dart menjadi sub-file terstruktur dan menambahkan pembersihan controller di LabSheet.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.1.13',
      dateEn: 'November 21, 2026',
      dateId: '21 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'New Lab Units (ng/L & µg/L): Added ng/L for Estradiol and µg/L for Testosterone, Progesterone, and Prolactin.',
          textId:
              'Satuan Lab Baru (ng/L & µg/L): Menambahkan ng/L untuk Estradiol dan µg/L untuk Testosteron, Progesteron, serta Prolaktin.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Lab Comparators (< / >): Support recording and displaying below/above threshold lab results across cards, charts, and widgets while excluding them from curve calibration.',
          textId:
              'Komparator Hasil Lab (< / >): Mendukung pencatatan dan tampilan hasil lab di bawah/atas ambang batas di kartu, grafik, dan widget tanpa memengaruhi kalibrasi kurva.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Pharmacokinetic Simulator Accuracy & Performance: Extended long-acting ester windows (Estradiol Undecylate & Testosterone Undecanoate) past 150 days using a dynamic 1e-6 decay threshold, added equal-rate limit guards, and pre-filtered active intakes once per simulation.',
          textId:
              'Akurasi & Performa Simulator Farmakokinetik: Memperpanjang jendela ester kerja panjang (Estradiol Undecylate & Testosterone Undecanoate) melewati 150 hari dengan ambang peluruhan 1e-6 dinamis, guard limit laju setara, dan filter asupan satu kali sebelum simulasi.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.1.12',
      dateEn: 'November 21, 2026',
      dateId: '21 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.fixed,
          textEn:
              'Android Lint FullBackupContent Fix: Removed redundant database exclusion in backup_rules.xml and data_extraction_rules.xml to fix release APK lintVitalRelease builds.',
          textId:
              'Perbaikan Lint Android FullBackupContent: Menghapus aturan pengecualian database yang redundan pada backup_rules.xml dan data_extraction_rules.xml agar build APK rilis (lintVitalRelease) berjalan lancar.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.1.11',
      dateEn: 'November 21, 2026',
      dateId: '21 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.fixed,
          textEn:
              'Release CI Flutter SDK & Analyzer Stability: Pinned GitHub Actions Flutter SDK to 3.47.9 and configured flutter analyze --no-fatal-infos so info-level SDK deprecation notices do not fail release builds.',
          textId:
              'Stabilitas CI Rilis & Analyzer Flutter: Mengunci versi Flutter SDK di GitHub Actions ke 3.47.9 dan menambahkan --no-fatal-infos pada flutter analyze agar peringatan info SDK tidak menggagalkan build rilis.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.1.10',
      dateEn: 'November 21, 2026',
      dateId: '21 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Privacy-First Defaults: Discreet notifications (Wellness & Routine) and Home Screen Widget privacy masking are now enabled by default for new setups.',
          textId:
              'Bawaan Ramah Privasi: Notifikasi tersamar (Hidrasi & Rutinitas) dan penyembunyian detail widget layar utama kini aktif secara bawaan.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Sign-Out Local Cleanup & Warning: Signing out now warns if offline changes are pending, and clears local Firestore cache, profile preferences, and device lock state while preserving cloud data.',
          textId:
              'Peringatan & Pembersihan Keluar Akun: Keluar dari akun kini menampilkan konfirmasi (termasuk peringatan perubahan offline tertunda) serta membersihkan cache Firestore, profil lokal, dan kunci perangkat tanpa menghapus data cloud.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Selective Android Backup & Input Hardening: Added Android backup/data-extraction rules excluding sensitive databases and keystore storage, enforced HTTPS GitHub URL allowlisting in the update launcher, hardened backup JSON validation, and sanitized CSV dose units.',
          textId:
              'Cadangan Android Selektif & Penguatan Validasi: Menambahkan aturan cadangan Android untuk mengecualikan basis data dan keystore sensitif, menerapkan allowlist URL HTTPS GitHub pada pembaruan, memperketat validasi cadangan JSON, dan mengamankan unit dosis pada ekspor CSV.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.1.9',
      dateEn: 'November 21, 2026',
      dateId: '21 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Standalone Dose History Import (CSV & JSON): Import and merge injection and dose administration logs from CSV or JSON history files directly from the History tab or Settings → Manual Backup & Export, preserving existing history and current supply stock.',
          textId:
              'Impor Riwayat Dosis Mandiri (CSV & JSON): Impor dan gabungkan catatan suntikan serta dosis dari berkas CSV atau JSON langsung dari tab Riwayat atau Pengaturan → Cadangan Manual & Ekspor tanpa menghapus riwayat lama atau memotong stok saat ini.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.1.7',
      dateEn: 'November 21, 2026',
      dateId: '21 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Eternal Dusk Splash Screen Redesign: Adopted the staged Wall o\' Pay splash architecture with coordinated background fade-in, centered 3D Lunera emblem scale/glow pulse, LUNERA display wordmark, "Your Journey, In Every Phase." tagline, minimal 48×3 progress bar, reduced-motion support, and matching Android/iOS native launch screens.',
          textId:
              'Desain Ulang Layar Splash Eternal Dusk: Mengadopsi arsitektur splash bertahap ala Wall o\' Pay dengan animasi latar belakang, lambang 3D Lunera berpendar halus, wordmark LUNERA, tagline "Perjalananmu, Di Setiap Fase.", indikator progres minimalis, dukungan reduced motion, serta layar peluncur native Android/iOS yang serasi.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.1.6',
      dateEn: 'November 21, 2026',
      dateId: '21 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Transparent Home Screen Launcher Icon: Updated Android launcher icons (mipmap-mdpi through mipmap-xxxhdpi), web favicon/icons, and showcase logos to render the Eternal Dusk orbital crescent emblem on a clean transparent background.',
          textId:
              'Ikon Peluncur Layar Utama Transparan: Memperbarui ikon peluncur Android, favicon/ikon web, dan logo showcase agar menampilkan lambang bulan sabit Eternal Dusk di atas latar transparan.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.1.5',
      dateEn: 'November 21, 2026',
      dateId: '21 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Eternal Dusk Profile Avatar Border: Updated the circular profile avatar frame overlay to the new Eternal Dusk orbital crescent moon and violet-coral neon ring across Home, More, and Profile.',
          textId:
              'Bingkai Avatar Profil Eternal Dusk: Memperbarui bingkai avatar melingkar dengan cincin orbit bulan sabit dan sorotan ungu-koral Eternal Dusk di Beranda, Lainnya, dan Profil.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.1.4',
      dateEn: 'November 21, 2026',
      dateId: '21 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Unified Lucide Icon System: Standardized all functional UI icons across screens, navigation dock, forms, dialogs, and sheets onto Lucide outline icons (2px stroke) with consistent #A29BBE default, #C7B8FF active, and selective Aurora Violet highlights.',
          textId:
              'Sistem Ikon Lucide Terpadu: Menstandarkan seluruh ikon antarmuka fungsional di setiap layar, bilah navigasi, formulir, dialog, dan lembar ke ikon garis Lucide dengan warna baku #A29BBE, aktif #C7B8FF, dan sorotan Aurora Violet.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.1.3',
      dateEn: 'November 21, 2026',
      dateId: '21 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Eternal Dusk Visual Rebranding & Asset Integration: Transformed global theme tokens, Instrument Serif + Plus Jakarta Sans typography, splash screen, launcher icons, home widgets, and UI surfaces with the new Midnight Aurora & sunset palette and supplied Eternal Dusk brand assets.',
          textId:
              'Rebranding Visual & Integrasi Aset Eternal Dusk: Memperbarui token tema global, tipografi Instrument Serif + Plus Jakarta Sans, layar splash, ikon peluncur, widget beranda, serta komponen antarmuka dengan palet Midnight Aurora dan aset brand Eternal Dusk terbaru.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.1.2',
      dateEn: 'November 21, 2026',
      dateId: '21 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Standalone Dose History Export (CSV & JSON): Export your injection and dose administration logs directly from the History tab or Settings → Manual Backup & Export, with spreadsheet formula-injection protection and an isolated JSON schema separate from full device backups.',
          textId:
              'Ekspor Riwayat Dosis Mandiri (CSV & JSON): Ekspor catatan suntikan dan riwayat dosis langsung dari tab Riwayat atau Pengaturan → Cadangan Manual & Ekspor, lengkap dengan perlindungan formula spreadsheet dan skema JSON terpisah dari cadangan penuh.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.1.1',
      dateEn: 'November 21, 2026',
      dateId: '21 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Encrypted Keystore/Keychain PIN Storage: Migrated PIN hashes, salts, and brute-force lockout counters from SharedPreferences to flutter_secure_storage with automatic legacy migration.',
          textId:
              'Penyimpanan PIN Terenkripsi Keystore/Keychain: Memigrasikan hash PIN, salt, dan status lockout dari SharedPreferences ke flutter_secure_storage secara otomatis.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Per-Account Lock Isolation & Tiered Lockout: Scoped local lock credentials per user UID, added exponential brute-force penalties (30s → 120s → 300s) with clock-rollback guard, and clamped remote cloud sync timestamps.',
          textId:
              'Isolasi Kunci Per-Akun & Lockout Bertingkat: Memisahkan kredensial kunci lokal per UID akun, penalti brute-force eksponensial (30 dtk → 120 dtk → 300 dtk) dengan penjaga manipulasi jam, serta pembatasan timestamp sinkronisasi cloud.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Enhanced Biometric & LockGate Security: Live Face/Fingerprint hardware detection on SecurityPage resume, 1200ms post-biometric lifecycle cooldown, automatic modal route dismissal on re-lock, and dynamic lockout countdowns.',
          textId:
              'Peningkatan Biometrik & LockGate: Deteksi sensor Wajah/Sidik Jari langsung saat kembali ke halaman Keamanan, cooldown 1200ms pasca-dialog biometrik, penutupan otomatis modal saat terkunci ulang, dan hitung mundur lockout dinamis.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '2.1.0',
      dateEn: 'November 10, 2026',
      dateId: '10 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Major 2.1.0 Milestone: Arcane Astral celestial redesign, ornate avatar frame, 42 custom celestial sprite icons, Decoy Calculator lock, Wall o\' Pay PIN keypad, and full combination medication support.',
          textId:
              'Pencapaian Besar 2.1.0: Perombakan celestial Arcane Astral, bingkai avatar anggun, 42 ikon sprite celestial kustom, Kunci Kalkulator Samaran, papan PIN Wall o\' Pay, dan dukungan penuh obat kombinasi.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Dreamy Celestial Splash & Launch Screen: Full-screen celestial starry backdrop with glowing crescent moon crest, starlight divider, and solid #171A35 cold-start background.',
          textId:
              'Layar Splash & Pembuka Celestial: Latar belakang langit berbintang penuh dengan lambang bulan sabit bercahaya, pembatas bintang, dan layar pembuka solid #171A35.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Streamlined UI/UX & Clinical Flow: Minimalist Levels cards, streamlined injection site selection chips, Guided Calm Injection assistant, Restock Pickup assistant, and immersive About Lunera sheet.',
          textId:
              'Penyederhanaan UI/UX & Alur Klinis: Kartu Kadar minimalis, chip pemilihan lokasi injeksi praktis, Asisten Injeksi Tenang, Asisten Pengambilan Stok, dan lembar Tentang Lunera yang mendalam.',
        ),
        ChangeItem(
          type: ChangeType.fixed,
          textEn:
              'Hardened Security & Layout Resilience: Fixed screen-off biometric collision, protected external dialogs with grace windows, eliminated route transition flicker, and resolved all RenderFlex overflows.',
          textId:
              'Peningkatan Keamanan & Ketahanan Tampilan: Mengatasi tabrakan biometrik saat layar mati, melindungi dialog eksternal dengan masa tenggang, menghilangkan kedipan transisi rute, dan memperbaiki seluruh error overflow.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.49',
      dateEn: 'November 9, 2026',
      dateId: '9 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Enhanced More and Settings UI: elevated typography contrast across all setting tiles and descriptions, expanded header layout, and integrated tactile haptic feedback across switches, tabs, chips, and backup actions.',
          textId:
              'Peningkatan UI Pusat Fitur & Pengaturan: meningkatkan kontras tipografi pada seluruh ubin dan deskripsi pengaturan, memperluas tata letak header, serta mengintegrasikan getaran haptic pada sakelar, tab, chip, dan aksi cadangan.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.48',
      dateEn: 'November 9, 2026',
      dateId: '9 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Streamlined Calendar & History UI: anchored the weekly day selector into a dedicated Arcane Astral card with an instant Today jump button, added daily completion status badges, introduced a serene rest-day empty state, and added tactile haptics across all interactions.',
          textId:
              'Penyederhanaan UI Kalender & Riwayat: menyatukan pemilih hari mingguan ke dalam kartu Arcane Astral khusus dengan tombol lompat instan Hari Ini, menambahkan lencana status penyelesaian harian, menghadirkan tampilan istirahat yang tenang saat tidak ada jadwal, dan menambahkan getaran haptic pada seluruh interaksi.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.47',
      dateEn: 'November 9, 2026',
      dateId: '9 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Overhauled Levels screen UI: decluttered dense chart cards, eliminated duplicate hormone listings, streamlined compact level panels with target range badges, and added tactile haptic feedback throughout lab sheets and actions.',
          textId:
              'Pembaruan UI layar Level: merapikan kartu grafik yang padat, menghilangkan duplikasi kartu hormon, menyederhanakan panel level ringkas dengan lencana rentang target, dan menambahkan umpan balik getar haptic pada formulir dan aksi lab.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.46',
      dateEn: 'November 9, 2026',
      dateId: '9 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Streamlined Home dashboard layout: removed redundant slot lists, introduced a compact high-priority missed dose banner with dedicated review sheet, elevated text contrast, and added tactile haptic feedback.',
          textId:
              'Penyederhanaan tata letak beranda: menghilangkan daftar dosis berulang, menghadirkan banner ringkas dosis terlewat dengan sheet tinjauan khusus, meningkatkan kontras teks, dan menambahkan umpan balik getar haptic.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.45',
      dateEn: 'November 9, 2026',
      dateId: '9 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Restructured Supplies screen header: elevated the Supplies title onto its own line and positioned Add Supply and Pickup Assistant actions into a clean, balanced dual-button action row below.',
          textId:
              'Menata ulang header layar Stok: menempatkan judul Stok secara leluasa di baris tersendiri dan memindahkan tombol Tambah Stok serta Asisten Titik Ambil ke baris aksi ganda yang rapi di bawahnya.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.44',
      dateEn: 'November 9, 2026',
      dateId: '9 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Streamlined web landing page architecture and redesigned the interactive mobile mockup to faithfully match the authentic in-app Home and floating Arcane Astral dock.',
          textId:
              'Menyederhanakan arsitektur landing page web dan merancang ulang mockup ponsel interaktif agar merefleksikan tampilan Beranda dan dock floating Arcane Astral autentik.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.43',
      dateEn: 'November 9, 2026',
      dateId: '9 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Overhauled "About Lunera" into an immersive Arcane Astral modal sheet inspired by Wall o\' Pay, featuring illuminated brand aura, 4 Celestial Lore Pillars, Core Principles, Medical Disclaimer, and open-source project metadata.',
          textId:
              'Merombak "Tentang Lunera" menjadi modal sheet imersif berestetika Arcane Astral terinspirasi dari Wall o\' Pay, lengkap dengan aura merek bercahaya, 4 Pilar Lore Lunera, Prinsip Utama, Penafian Medis, dan metadata proyek open source.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.42',
      dateEn: 'November 9, 2026',
      dateId: '9 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.fixed,
          textEn:
              'Resolved English string leaks in Indonesian language mode by adding 40 missing translations across Settings, Profile, Body Measurements, and Home.',
          textId:
              'Mengatasi kebocoran teks Bahasa Inggris pada mode Bahasa Indonesia dengan menambahkan 40 terjemahan di Pengaturan, Profil, Ukuran Tubuh, dan Beranda.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.41',
      dateEn: 'November 9, 2026',
      dateId: '9 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Optimized splash screen display logic and extracted navigation bar and exit confirmation dialog components.',
          textId:
              'Mengoptimalkan logika tampilan layar pembuka serta mengekstrak komponen navigation bar dan dialog konfirmasi keluar.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.40',
      dateEn: 'November 9, 2026',
      dateId: '9 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Revamped the application splash and loading screen with the celestial Arcane Astral atmosphere, glowing starlight aura, pulsing loader indicator, and updated in-app celestial crescent moon emblem with orbital rings while preserving the current home screen launcher icon.',
          textId:
              'Merombak layar pembuka dan pemuatan aplikasi dengan atmosfer celestial Arcane Astral, aura starlight bercahaya, indikator pemuatan berdenyut halus, dan pembaruan lambang bulan sabit celestial dalam aplikasi dengan cincin orbit sembari mempertahankan ikon launcher layar utama saat ini.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.39',
      dateEn: 'November 8, 2026',
      dateId: '8 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Overhauled the official Web Landing Page and Showcase with the Arcane Astral aesthetic, integrating the celestial crescent moon emblem, 3-tier typography (Cinzel, Cormorant Garamond, Manrope), nocturnal glassmorphism, thin gold borders, and an interactive mobile mockup with the signature floating celestial navigation dock.',
          textId:
              'Merombak Web Landing Page dan Showcase resmi dengan estetika Arcane Astral, mengintegrasikan lambang bulan sabit celestial, tipografi 3-tingkat (Cinzel, Cormorant Garamond, Manrope), glassmorphism nocturnal berbingkai emas tipis, dan mockup ponsel dengan floating celestial dock khas Lunera.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.38',
      dateEn: 'November 8, 2026',
      dateId: '8 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Revamped the exit confirmation dialog and application update dialog with Lunera\'s celestial Arcane Astral aesthetic, featuring glowing orbit halo emblems, starlight borders, version transition chips, and refined action buttons.',
          textId:
              'Merombak kartu konfirmasi keluar dan kartu pembaruan aplikasi dengan estetika celestial Arcane Astral khas Lunera, dilengkapi lambang halo orbit bercahaya, bingkai bias emas starlight, lencana transisi versi, dan tombol aksi yang disempurnakan.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.37',
      dateEn: 'November 8, 2026',
      dateId: '8 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Revamped the PIN Lock and PIN Creation screens with the celestial Arcane Astral theme, glowing animated dot indicators, frosted glass circular keys with letter guides, and streamlined security feedback badges.',
          textId:
              'Merombak layar Kunci PIN dan Pembuatan PIN dengan tema celestial Arcane Astral, indikator titik bercahaya dinamis, tombol kaca buram melingkar dengan panduan huruf, dan lencana status keamanan.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.36',
      dateEn: 'November 8, 2026',
      dateId: '8 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Replaced legacy auth background with the high-resolution Arcane Astral celestial artwork (AuthScene) featuring deep atmospheric gradient scrims across Welcome, Sign In, and Sign Up screens.',
          textId:
              'Mengganti latar belakang layar autentikasi (Welcome, Sign In, Sign Up) dengan ilustrasi celestial Arcane Astral beresolusi tinggi (AuthScene) lengkap dengan scrim gradien atmosferik.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.35',
      dateEn: 'November 8, 2026',
      dateId: '8 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Integrated 3-tier typography system: Cinzel for brand wordmarks, Cormorant Garamond for decorative headings, and Manrope for the full Android UI.',
          textId:
              'Menerapkan sistem tipografi 3 lapis: Cinzel untuk logo merek, Cormorant Garamond untuk heading dekoratif, dan Manrope untuk seluruh UI Android.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Updated Android app launcher icon, web icons, splash screen, and in-app brand logos to the new celestial crescent moon emblem with orbital rings.',
          textId:
              'Memperbarui ikon peluncur aplikasi Android, ikon web, layar pembuka, dan logo aplikasi ke lambang bulan sabit kosmik berorbit cincin emas.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.34',
      dateEn: 'November 8, 2026',
      dateId: '8 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Added subtle celestial gold border tint to cards and refined the navbar capsule into a slimmer, more compact and proportional profile.',
          textId:
              'Menambahkan warna emas tipis pada bingkai kartu dan merampingkan ukuran kapsul navbar agar lebih kompak, proporsional, dan elegan.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.33',
      dateEn: 'November 8, 2026',
      dateId: '8 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Removed container frame and background from the center Beranda (Home) navbar button, allowing the 56px celestial astrological artwork to display full-size with radiant glow.',
          textId:
              'Menghilangkan bingkai dan latar belakang kotak dari tombol Beranda tengah, menampilkan karya seni bintang astrologi kosmik 56px secara penuh dengan pendaran cahaya alami.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.32',
      dateEn: 'November 8, 2026',
      dateId: '8 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Customized navbar with celestial icon set and enlarged the center Beranda (Home) button into an elevated 58px floating orb with gold & amethyst halo glows inspired by Pay o\' Wall.',
          textId:
              'Mengkustomisasi navbar dengan kumpulan ikon kosmik celestial serta memperbesar tombol tengah Beranda menjadi lingkaran melayang 58px ber-halo emas & amestik ala Pay o\' Wall.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.31',
      dateEn: 'November 8, 2026',
      dateId: '8 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Added full-bleed Arcane Astral wallpaper background artwork with an atmospheric dark gradient scrim to preserve text contrast and clinical card readability.',
          textId:
              'Menambahkan gambar latar belakang kosmik Arcane Astral dengan lapisan peredup gradien atmosferik untuk menjaga kontras teks dan kenyamanan membaca kartu klinis.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.30',
      dateEn: 'November 8, 2026',
      dateId: '8 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Transformed all therapy selectors (category, administration route, injection method, patch unit, combination categories, and repeat schedule) into a clean, unified dropdown experience.',
          textId:
              'Mengubah seluruh pemilih di sheet terapi (kategori, rute konsumsi, metode suntik, satuan patch, kategori kombinasi, dan jadwal pengulangan) menjadi format dropdown yang rapi dan seragam.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.29',
      dateEn: 'November 8, 2026',
      dateId: '8 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Streamlined active compound selection in therapy sheet into a clean single-line dropdown with automatic route and profile configuration.',
          textId:
              'Menyederhanakan pemilihan senyawa aktif di sheet terapi menjadi dropdown 1 baris yang rapi dengan konfigurasi otomatis rute dan profil.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Cleaned up form height by hiding redundant pharmacokinetic simulation chips when a standard active compound is selected.',
          textId:
              'Memangkas tinggi formulir dengan menyembunyikan chip simulasi farmakokinetik saat senyawa aktif standar dipilih.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.28',
      dateEn: 'November 8, 2026',
      dateId: '8 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Standardized active pharmaceutical compound catalog for Estradiol, Testosterone, Progesterone, and Anti-androgens / Blockers.',
          textId:
              'Katalog senyawa aktif farmasi standar untuk Estradiol, Testosteron, Progesteron, dan Anti-androgen / Blocker.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Interactive active compound chips in therapy sheet with automatic administration route and pharmacokinetic preset configuration.',
          textId:
              'Chip pemilihan senyawa aktif interaktif di sheet terapi dengan konfigurasi otomatis rute konsumsi dan profil simulasi farmakokinetik.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Secondary active compound selection for combination medications (e.g. Cyclofem with Estradiol cypionate and Medroxyprogesterone acetate).',
          textId:
              'Dukungan pemilihan senyawa aktif kedua untuk obat kombinasi (contoh: Cyclofem dengan Estradiol cypionate dan Medroxyprogesterone acetate).',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Separated user-customized brand/product names (Progynova, Androcur, Utrogestan, etc.) from active chemical compounds.',
          textId:
              'Memisahkan nama produk/merk obat dari nama senyawa aktif kimia.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.27',
      dateEn: 'November 8, 2026',
      dateId: '8 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Removed heart symbol from Home greeting header and calibrated nickname typography and spacing to prevent colliding with right-side action buttons.',
          textId:
              'Menghapus simbol hati di header Beranda serta menyesuaikan ukuran dan jarak nama pengguna agar tidak bertabrakan dengan tombol aksi kanan.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.26',
      dateEn: 'November 8, 2026',
      dateId: '8 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Redesigned More page profile header into a centered Arcane Astral hero card with glowing halo avatar, identity subtitle, and top-right Settings shortcut.',
          textId:
              'Mendesain ulang kartu profil di halaman More menjadi kartu hero Arcane Astral terpusat dengan avatar ber-halo kosmik, subtitle identitas, dan pintasan Pengaturan.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Tapping user avatar on Home now navigates directly to ProfilePage.',
          textId:
              'Mengetuk foto profil di Beranda kini langsung mengalihkan ke halaman profil pengguna.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Swapped Home and Levels navigation bar positions: Home is now the central tab with the astrological star icon, while Levels moves to tab 0 with clinical insights iconography.',
          textId:
              'Menukar posisi Beranda dan Level di navbar: Beranda kini di tombol tengah dengan ikon bintang astrologi, sementara Level berada di tab 0 dengan ikon wawasan klinis.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.25',
      dateEn: 'November 8, 2026',
      dateId: '8 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Reworked DoseCard into a compact, horizontal 100px dial card saving over 50% vertical space while keeping all rotation, countdown, and logging controls intact.',
          textId:
              'Merombak DoseCard menjadi kartu horizontal kompak berdiameter 100px yang menghemat lebih dari 50% ruang layar dengan tetap mempertahankan fitur countdown, lokasi rotasi, dan pencatatan.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Reordered Home dashboard by clinical urgency: Alerts, Missed Doses, Active Cards, Today\'s Schedule, Hormone Trend, Mood Check-in, and Upcoming Schedule.',
          textId:
              'Menata ulang kartu Beranda berdasarkan prioritas klinis: Peringatan Stok, Dosis Terlewat, Kartu Terapi Aktif, Jadwal Hari Ini, Tren Hormon, Suasana Hati, dan Jadwal Mendatang.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.24',
      dateEn: 'November 8, 2026',
      dateId: '8 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Consolidated app appearance into a single unified Arcane Astral aesthetic, removing redundant phase accent chips from Settings and displaying an elegant 5-color palette showcase.',
          textId:
              'Menyatukan tampilan aplikasi ke dalam satu tema tunggal Arcane Astral, menghapus chip aksen fase di Pengaturan dan menampilkan kartu showcase 5-warna palet yang elegan.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Locked theme accent enforcement to Arcane Astral while ensuring full backward compatibility for stored preferences and backup files.',
          textId:
              'Mengunci tema aplikasi secara permanen pada Arcane Astral dengan tetap menjaga kompatibilitas penuh untuk preferensi tersimpan dan berkas cadangan.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.23',
      dateEn: 'November 8, 2026',
      dateId: '8 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Transformed bottom navigation into a floating frosted glass pill dock featuring an 8-point astrological Compass Starburst for the center Levels tab.',
          textId:
              'Mentransformasi bilah navigasi bawah menjadi floating frosted glass pill dock yang melayang, dilengkapi tombol bintang kompas astrologi 8-arah di tab tengah.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Polished Home hero greeting with delicate phase heart, starlight subtitle, and Arcane Astral typography hierarchy.',
          textId:
              'Menyempurnakan sapaan beranda dengan sentuhan hati fase rembulan, subjudul starlight, dan hierarki tipografi Arcane Astral.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.22',
      dateEn: 'November 8, 2026',
      dateId: '8 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Upgraded Hormone Trend and Levels visualizations with Arcane Astral dual-tone aesthetics: Estradiol in Mystical Amethyst, Progesterone in Celestial Honey Gold, and smooth gradient area shading.',
          textId:
              'Memperbarui visualisasi Tren Hormon dan Level dengan estetika dua warna Arcane Astral: Estradiol dalam Mystical Amethyst, Progesteron dalam Celestial Honey Gold, dan arsiran gradien halus.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Harmonized clinical target ranges, adherence indicators, and journal mood highlights with Sage Astral Mint and warm celestial amber tones.',
          textId:
              'Menyelaraskan rentang target klinis, indikator kepatuhan dosis, dan penanda suasana hati jurnal dengan Sage Astral Mint dan aksen amber hangat.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.21',
      dateEn: 'November 8, 2026',
      dateId: '8 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Transformed Lunera\'s primary color system and visual aesthetic to Arcane Astral, featuring Deep Astral Midnight canvas, Velvet Arcane card surfaces, Mystical Amethyst primary accents, and Celestial Honey Gold warm highlights.',
          textId:
              'Mentransformasi sistem warna utama dan estetika visual Lunera menjadi Arcane Astral dengan kanvas Deep Astral Midnight, permukaan beludru kaca Velvet Arcane, aksen utama Mystical Amethyst, dan sentuhan hangat Celestial Honey Gold.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Upgraded theme design tokens and AppCard/cardBox starlight contours, with warm moonlight cream lunar logo accents and full agent aesthetic token compliance.',
          textId:
              'Memperbarui token desain tema dan kontur starlight pada AppCard/cardBox, dilengkapi aksen rembulan moonlight cream pada logo dan kepatuhan penuh standar token estetika.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.20',
      dateEn: 'November 8, 2026',
      dateId: '8 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Redesigned More tab into a dedicated Care & Feature Hub inspired by Wall o\' Pay, featuring organized card sections with colorful icon badges for Health & Journey, Care & Assistant Tools, and System.',
          textId:
              'Mendesain ulang tab Lainnya menjadi Pusat Fitur & Terapi (Feature Hub) bergaya Wall o\' Pay dengan kartu terkelompok dan badge ikon warna-warni.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Re-architected Settings page into an all-in-one control center integrating Preferences, Appearance, Reminders & privacy, Therapy units, live PIN & biometrics security status, and Cloud Firestore sync & backup.',
          textId:
              'Merombak halaman Pengaturan menjadi pusat kendali lengkap yang menyatukan Preferensi, Tampilan, Notifikasi, Satuan terapi, status Keamanan PIN/biometrik, dan sinkronisasi Cloud Firestore.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Introduced AppCard, SectionHeader, and iconBadge reusable design system components in theme.dart with nocturnal velvet styling and pastel accents.',
          textId:
              'Menambahkan komponen desain terpadu AppCard, SectionHeader, dan iconBadge di theme.dart dengan nuansa beludru malam dan aksen pastel.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.19',
      dateEn: 'November 8, 2026',
      dateId: '8 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.fixed,
          textEn:
              'Fixed UI thread lockup and dark overlay crash when tapping "Log injection" caused by unbounded PillTabs layout constraints in InjectionSiteMap.',
          textId:
              'Memperbaiki aplikasi macet/ANR dan layar gelap saat menekan "Catat suntikan" akibat flex tak terbatas pada PillTabs di InjectionSiteMap.',
        ),
        ChangeItem(
          type: ChangeType.fixed,
          textEn:
              'Protected stream provider lookups in dose and rotation sheets with valueOrNull, avoiding unhandled Riverpod exception crashes.',
          textId:
              'Melindungi pembacaan stream provider pada lembar dosis dan rotasi menggunakan valueOrNull untuk mencegah crash.',
        ),
        ChangeItem(
          type: ChangeType.fixed,
          textEn:
              'Added scrollable viewport wrapper to SiteRotationSheet to avoid layout overflow on smaller screens.',
          textId:
              'Menambahkan wrapper scrollable pada SiteRotationSheet agar tidak overflow pada layar berukuran kecil.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.18',
      dateEn: 'November 8, 2026',
      dateId: '8 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Dedicated Debug & Release build variants: side-by-side install with .debug suffix and distinct app label "Lunera Dev".',
          textId:
              'Varian build Debug & Release terpisah: instalasi berdampingan dengan akhiran .debug dan nama aplikasi "Lunera Dev".',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Multi-client Firebase configuration in google-services.json for seamless release and debug development.',
          textId:
              'Konfigurasi multi-client Firebase di google-services.json untuk kelancaran pengembangan versi release dan debug.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Developer mode visual indicator in home screen and automatic Privacy Shield screenshot bypass in debug mode.',
          textId:
              'Indikator visual mode developer di layar utama dan bypass screenshot otomatis untuk Privacy Shield saat mode debug.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.17',
      dateEn: 'November 8, 2026',
      dateId: '8 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Privacy Shield (FLAG_SECURE): integrated native Android window security to hide app contents in Recent Apps and block screenshots for sensitive medical therapy records.',
          textId:
              'Perisai Privasi (FLAG_SECURE): mengintegrasikan keamanan layar native Android untuk menyamarkan konten aplikasi di Aplikasi Terkini dan mencegah tangkapan layar data medis.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Security Settings & Lifecycle Sync: added Privacy Shield toggle in Security settings with automatic startup state enforcement and cleanup on PIN disable.',
          textId:
              'Pengaturan Keamanan & Siklus Hidup: menambahkan saklar Perisai Privasi di menu Keamanan dengan penerapan otomatis saat mulai dan pelepasan saat PIN dinonaktifkan.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.16',
      dateEn: 'November 8, 2026',
      dateId: '8 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Debounced Background Auto-Sync: introduced a 1,500ms debounce queue and reactive SyncState to coalesce rapid mutations into smooth background synchronization.',
          textId:
              'Auto-Sync Latar Belakang Berjeda Debounce: menghadirkan antrean debounce 1.500ms dan SyncState reaktif untuk menyatukan mutasi beruntun ke sinkronisasi awan yang mulus.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Non-Blocking Safe Writes: wrapped repository mutations in bounded 4-second timeout protection, guaranteeing instant offline persistence without UI freezes.',
          textId:
              'Operasi Tulis Aman Non-Blocking: membungkus mutasi repositori dengan proteksi batas waktu 4 detik, memastikan persistensi offline instan tanpa jeda antarmuka.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.15',
      dateEn: 'November 8, 2026',
      dateId: '8 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Interactive Profile Photo Cropper: introduced pure Flutter circular photo cropper with pan, pinch-to-zoom (0.8x-4.0x), 90° rotation, and rule-of-thirds grid guides.',
          textId:
              'Pemotong Foto Profil Interaktif: menghadirkan fitur crop foto melingkar murni Flutter dengan kontrol geser, zoom (0.8x-4.0x), rotasi 90°, dan garis pandu grid.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Full-Screen Photo Viewer & Action Sheet: added full-screen interactive photo viewer with Hero animation and a WhatsApp-styled photo picker sheet.',
          textId:
              'Penampil Foto Layar Penuh & Lembar Aksi: menambahkan penampil foto layar penuh dengan animasi Hero dan lembar pemilih foto bergaya modern.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Pre-Decoded Avatar Caching & Tactile Haptics: cached MemoryImage in profile state to eliminate redundant base64 decoding on redraws, and added light haptic feedback to PIN numpads and avatar touches.',
          textId:
              'Caching Avatar Ter-decode & Haptic Taktil: menyimpan MemoryImage di state profil untuk menghilangkan decoding base64 berulang saat redraw, serta getaran halus pada keypad PIN dan sentuhan avatar.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.14',
      dateEn: 'November 8, 2026',
      dateId: '8 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Multi-Hormone Pharmacokinetics & Regimens: expanded simulation models to support Testosterone (ng/dL) and Progesterone (ng/mL) alongside Estradiol curves.',
          textId:
              'Farmakokinetik Multi-Hormon & Regimen Universal: memperluas simulasi ke Testosteron (ng/dL) dan Progesteron (ng/mL) melengkapi kurva Estradiol.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Combination Medication Support: added dual-ingredient tracking for combination injections (e.g. Cyclofem) with simultaneous curve distribution.',
          textId:
              'Dukungan Obat Kombinasi: mendukung pelacakan obat kombinasi dua bahan aktif (mis. Cyclofem) secara simultan tanpa duplikasi stok.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.13',
      dateEn: 'November 5, 2026',
      dateId: '5 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Codebase Modularization & Housekeeping: partitioned the test suite into focused domain test files, pruned root duplicate android_widget folder, renamed legacy project module, and localized app update dialog.',
          textId:
              'Modularisasi & Perapian Basis Kode: memisahkan suite pengujian ke file pengujian domain terarah, membersihkan folder duplikat android_widget di root, memperbarui konfigurasi modul proyek, dan melokalisasi dialog pembaruan aplikasi.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.12',
      dateEn: 'November 5, 2026',
      dateId: '5 November 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.fixed,
          textEn:
              'Discreet Supply & Expiry Alerts: extended lockscreen notification masking (Wellness & Routine and Minimal modes) to low-stock and medication expiry reminders so medication names remain private.',
          textId:
              'Privasi Pengingat Stok & Kedaluwarsa: memperluas penyamaran teks layar kunci (mode Hidrasi & Rutinitas serta Minimalis) ke pengingat stok menipis dan masa simpan obat agar nama obat tetap terlindungi.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'PBKDF2 PIN Hardening & Persistent Lockout: upgraded PIN hashing to 60,000-iteration PBKDF2-HMAC-SHA256 with automatic legacy migration and persistent brute-force cooldown across the Moon PIN pad and Decoy Calculator.',
          textId:
              'Penguatan PIN PBKDF2 & Batas Percobaan Persisten: meningkatkan enkripsi PIN ke PBKDF2-HMAC-SHA256 (60.000 iterasi) dengan migrasi otomatis serta jeda penguncian persisten di layar PIN dan Kalkulator Samaran.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Pure Celestial Dark Theme & Backup Validation: locked app styling to Lunera\'s signature nocturnal sanctuary with dynamic phase accents, and added strict per-row backup integrity checks.',
          textId:
              'Tema Tunggal Celestial Dark & Validasi Backup: mengunci tema aplikasi ke nuansa malam khas Lunera dengan aksen dinamis, serta memperketat validasi integritas data cadangan.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Release Signing & CI Quality Gate: migrated Android release signing in CI to encrypted GitHub Secrets, enforced automated analyze/test checks before APK builds, and cleaned up legacy Asteria remnants.',
          textId:
              'Keamanan Rilis & Gate Pengujian CI: memindahkan penandatanganan APK rilis ke GitHub Secrets terenkripsi, mewajibkan lolos analisis & pengujian otomatis sebelum kompilasi, serta membersihkan sisa kode lama Asteria.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.11',
      dateEn: 'November 1, 2026',
      dateId: '1 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Guided Calm Injection: 4-stage guided injection session with calming breath guide, 30-second alcohol dry countdown timer, technique angles (90° IM vs 45° SubQ), affirmation, and 1-tap logging.',
          textId:
              'Panduan Suntik Tenang: sesi injeksi terpandu 4 langkah dengan panduan napas, timer 30 detik pengeringan alkohol, panduan teknik & sudut suntik (90° IM vs 45° SubQ), afirmasi, dan pencatatan 1 sentuhan.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Restock & Pickup Assistant: discreet "Hold at Location" delivery template generator for logistics agencies (J&T, JNE, SiCepat, Pos) with 1-tap clipboard copy and safety checklist.',
          textId:
              'Asisten Titik Ambil & Stok: pembuat format alamat "Ambil Sendiri di Agen Ekspedisi" (J&T, JNE, SiCepat, Pos) dengan salin cepat ke papan klip dan tips privasi paket.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Supplies Restock Banner: real-time low supply alert and quick shortcut to the Pickup Assistant directly from the Supplies tab.',
          textId:
              'Banner Peringatan Stok: pemberitahuan stok menipis dan akses cepat ke Asisten Titik Ambil langsung dari tab Perlengkapan.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.10',
      dateEn: 'November 1, 2026',
      dateId: '1 November 2026',
      changes: [
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Decoy Calculator Lock: stealth lock screen disguise functioning as an authentic working calculator with secret PIN & "=" unlock and configurable settings toggle.',
          textId:
              'Kunci Kalkulator Samaran: penyamaran layar kunci sebagai kalkulator fungsional nyata dengan buka kunci rahasia PIN & "=" serta opsi sakelar di Pengaturan.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Discreet Notifications: lockscreen notification masking with customizable modes (Standard, Wellness & Routine, and Minimal) for full privacy in public and family environments.',
          textId:
              'Privasi Notifikasi: penyamaran teks pengingat layar kunci dengan mode yang dapat disesuaikan (Standar, Hidrasi & Rutinitas, serta Minimalis) demi privasi penuh.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.9',
      dateEn: 'October 31, 2026',
      dateId: '31 Oktober 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Removed Asteria AI Chatbot feature to streamline application performance and maintain focus on lightweight, offline-first health tracking.',
          textId:
              'Menghapus fitur AI Chatbot Asteria untuk merampingkan performa aplikasi dan menjaga fokus pada pelacakan kesehatan offline-first yang ringan.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.8',
      dateEn: 'October 31, 2026',
      dateId: '31 Oktober 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.fixed,
          textEn:
              'Ultra-low latency Asteria responses: tuned Gemini 3.8 and Gemini 2.5 Flash thinking configurations for instant conversational replies without prolonged reasoning pauses.',
          textId:
              'Respons secepat kilat Asteria: konfigurasi pemikiran model Gemini 3.8 & Gemini 2.5 Flash disesuaikan untuk percakapan instan tanpa jeda perenungan yang lama.',
        ),
        ChangeItem(
          type: ChangeType.fixed,
          textEn:
              'Separated internal thought tokens from user-facing responses, and added socket/HTTP timeout safeguards preventing hang states on slow mobile connections.',
          textId:
              'Pemisahan token pemikiran internal dari teks balasan pengguna, serta pengamanan batas waktu koneksi untuk mencegah Asteria menggantung pada jaringan lambat.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.7',
      dateEn: 'October 31, 2026',
      dateId: '31 Oktober 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.fixed,
          textEn:
              'Upgraded flagship candidate priority to Gemini 3.8 Flash & Gemini 3.6 Flash with automated universal model discovery.',
          textId:
              'Peningkatan prioritas kandidat utama ke Gemini 3.8 Flash & Gemini 3.6 Flash dilengkapi penemuan model universal otomatis.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'In-dialog connection test tool: one-tap diagnostics pinging Google Gemini directly to display active models or detailed server response.',
          textId:
              'Alat uji koneksi interaktif di dialog: diagnosa satu ketukan yang memverifikasi Google Gemini secara langsung dan menampilkan model aktif atau respon server.',
        ),
      ],
    ),
    ReleaseEntry(
      version: '1.11.6',
      dateEn: 'October 31, 2026',
      dateId: '31 Oktober 2026',
      isCurrent: false,
      changes: [
        ChangeItem(
          type: ChangeType.fixed,
          textEn:
              'Fixed Gemini GA endpoint routing: targeting official v1 GA endpoint for gemini-1.5-flash with v1beta fallback for preview models, and capturing complete Google API error details.',
          textId:
              'Perbaikan perutean endpoint Gemini GA: menargetkan endpoint resmi v1 GA untuk gemini-1.5-flash dengan fallback v1beta untuk model pratinjau, serta menangkap detail lengkap pesan error Google API.',
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
          textEn:
              'Dynamic Gemini Flash model discovery & resilient fallback: auto-detects active models and migrates from retired gemini-1.5-flash to gemini-2.5-flash / gemini-2.0-flash.',
          textId:
              'Pendeteksian model Gemini Flash dinamis & fallback tangguh: otomatis mendeteksi model aktif dan bermigrasi dari gemini-1.5-flash ke gemini-2.5-flash / gemini-2.0-flash.',
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
          textEn:
              'Celestial mode switcher: easily switch between Shared Star (Bintang Bersama - free community connection) and Personal Star (Bintang Pribadi - private key connection).',
          textId:
              'Pengalih mode bintang: beralih dengan mudah antara Bintang Bersama (koneksi komunitas gratis) dan Bintang Pribadi (koneksi kunci mandiri).',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Gentle and friendly celestial terminology replacing technical developer jargon across all chat dialogs and settings.',
          textId:
              'Terminologi surgawi yang ramah dan lembut menggantikan istilah teknis di seluruh dialog percakapan dan pengaturan.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Seamless bidirectional quota fallback: one-tap switching between Shared and Personal Star when either reaches its resting limit.',
          textId:
              'Peralihan kuota dua arah otomatis: beralih dalam satu ketukan antara Bintang Bersama dan Pribadi saat salah satunya sedang beristirahat.',
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
          textEn:
              'Seamless hybrid Asteria architecture: built-in public key injected via GitHub Actions Secret for zero-setup instant chat.',
          textId:
              'Arsitektur Asteria hibrida: kunci publik bawaan disuntikkan via GitHub Actions Secret agar pengguna awam bisa langsung curhat tanpa setup.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Gentle "Asteria is resting" quota handler with live status indicators when public daily quota is exhausted.',
          textId:
              'Penanganan kuota lembut "Asteria sedang beristirahat" lengkap dengan indikator status jika kuota harian publik tercapai.',
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
          textEn:
              'Asteria AI Companion: empathetic, supportive conversational sanctuary powered by Google Gemini.',
          textId:
              'Pendamping AI Asteria: ruang curhat reflektif dan penuh empati yang ditenagai oleh Google Gemini.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Home screen Floating Action Button (FAB) for instant one-tap access to heart-to-heart venting.',
          textId:
              'Tombol mengambang (FAB) di Beranda untuk akses cepat curhat dan berbagi perasaan.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Reflective session summarizer: automatically creates warm journal entries with mood score and clears chat history.',
          textId:
              'Rangkuman sesi reflektif: merangkum curhat otomatis ke Jurnal bersama skor mood dan membersihkan ruang obrolan.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Graceful offline lock: automatically protects the chat interface when device has no internet connection.',
          textId:
              'Kunci mode offline: melindungi antarmuka obrolan secara anggun saat perangkat tidak terhubung internet.',
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
          textEn:
              'Fixed squashed and flattened ("gepeng") body silhouette overview on tablet and wide-screen landscape displays.',
          textId:
              'Perbaikan siluet tubuh yang gepeng pada tampilan tablet dan lanskap layar lebar.',
        ),
        ChangeItem(
          type: ChangeType.fixed,
          textEn:
              'Centered anatomical overview diagram with responsive width constraint and locked aspect ratio proportions.',
          textId:
              'Diagram anatomi tubuh kini berada di tengah dengan batas lebar responsif dan proporsi aspek rasio terkunci.',
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
          textEn:
              'Body measurement progression trend charts (WHR, Bust & Ribcage, Waist & Hips, Weight, Legs) with baseline comparison.',
          textId:
              'Kurva tren perkembangan ukuran tubuh (WHR, Dada & Bawah Dada, Pinggang & Pinggul, Berat Badan, Kaki) dengan perbandingan awal.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Interactive anatomical injection site map & tissue rest heatmap (Front and Back perspectives) with smart rotation guidance.',
          textId:
              'Peta anatomi titik suntik interaktif & heatmap istirahat jaringan (sudut pandang Depan & Belakang) dengan panduan rotasi cerdas.',
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
          textEn:
              'Multi-standard shoe size calculator and foot length tracking (EU/ID, US Women, US Men, UK) with live preview.',
          textId:
              'Kalkulator ukuran sepatu multi-standar & pelacakan panjang kaki (EU/ID, US Wanita, US Pria, UK) dengan pratinjau langsung.',
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
          textEn:
              'Lower body measurements tracking (Thigh, Calf, and Inseam) with enhanced pants sizing calculation.',
          textId:
              'Pelacakan ukuran tubuh bagian bawah (Paha, Betis, dan Panjang Kaki) dengan estimasi ukuran celana yang lebih presisi.',
        ),
        ChangeItem(
          type: ChangeType.fixed,
          textEn:
              'Home screen profile sync: greeting and avatar now accurately reflect custom nickname and profile photo.',
          textId:
              'Sinkronisasi profil beranda: sapaan nama dan avatar kini sesuai dengan foto profil dan nama panggilan.',
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
          textEn:
              'Native Android bilingual home screen widgets (HRT counter, schedule, levels) dynamically synced with active app language.',
          textId:
              'Widget layar utama Android bilingual bawaan (lama terapi, jadwal, level) tersinkron otomatis dengan bahasa aplikasi aktif.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Body Measurements & Clothing Sizing calculator with dual-standard Bra fit (US/UK, EU/ID, sister sizes), top/shirt, and pants sizing.',
          textId:
              'Kalkulator ukuran badan & pakaian dengan estimasi ukuran bra dual standar (US/UK, EU/ID, sister sizes), ukuran baju, dan celana.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Biometric security authentication (fingerprint / face unlock) with grace period and cloud-synced PIN security.',
          textId:
              'Autentikasi keamanan biometrik (sidik jari / wajah) dengan masa tenggang dan kunci PIN tersinkron cloud.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'High-performance global translation architecture (L10n with tr) with comprehensive 600+ entry bilingual dictionary.',
          textId:
              'Arsitektur penerjemahan global performa tinggi (L10n dengan tr) dengan kamus dwibahasa komprehensif 600+ entri.',
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
          textEn:
              'Comprehensive bilingual localization audit across all screens, eliminating language leakage between English and Indonesian.',
          textId:
              'Audit lokalisasi dwibahasa menyeluruh di seluruh layar, memperbaiki kebocoran bahasa antara Bahasa Inggris dan Bahasa Indonesia.',
        ),
        ChangeItem(
          type: ChangeType.fixed,
          textEn:
              'Dynamic date & time formatting respecting active app locale instead of hardcoded locale formats in Calendar and Levels.',
          textId:
              'Format tanggal dan waktu dinamis yang mengikuti bahasa aktif aplikasi tanpa memaksakan format lokal statis di Kalender dan Level.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Web Landing Page enhanced with celestial panoramic banner and locked into the unified Celestial Midnight & Pastel theme.',
          textId:
              'Pembaruan Landing Page web dengan banner panorama celestial baru dan penguncian tema terpadu Celestial Midnight & Pastel.',
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
          textEn:
              'Unified signature "Celestial Midnight & Pastel" theme with Atmospheric Midnight Canvas (#0B0D21) and Velvet Surface (#16193E).',
          textId:
              'Tema eksklusif terpadu "Celestial Midnight & Pastel" dengan kanvas malam danau (#0B0D21) dan permukaan kartu beludru (#16193E).',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Celestial Pastel palette infusion across hero countdown cards, mood markers, dose dial ticks, and therapeutic target zones.',
          textId:
              'Sentuhan palet warna pastel surgawi pada kartu countdown dosis, penanda suasana hati, piringan jam, dan area target terapeutik.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Redesigned Appearance settings featuring the bespoke signature aesthetic and celestial Phase Accents.',
          textId:
              'Pembaruan menu Tampilan dengan kartu tema signature dan pilihan Aksen Fase surgawi.',
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
          textEn:
              'In-app Version Changelog viewer in Settings & More dashboard to inspect patch history and release notes offline anytime.',
          textId:
              'Fitur Catatan Pembaruan (Changelog) bawaan aplikasi pada menu Pengaturan & Lainnya untuk meninjau riwayat rilis secara offline kapan saja.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Reactive available update state with real-time "NEW" badges and version transition indicators.',
          textId:
              'Notifikasi pembaruan aplikasi reaktif dengan badge "BARU" dan penanda transisi versi secara real-time.',
        ),
        ChangeItem(
          type: ChangeType.changed,
          textEn:
              'Revamped Settings dashboard with unified "About & Support" card and full bilingual localization.',
          textId:
              'Pembaruan menu Pengaturan dengan kartu terpadu "Tentang & Dukungan" serta lokalisasi multibahasa menyeluruh.',
        ),
        ChangeItem(
          type: ChangeType.fixed,
          textEn:
              'CI/CD and Gradle build hardening with Google Cloud Maven mirror and automated build retry loop.',
          textId:
              'Penguatan pipeline build CI/CD dan Gradle dengan mirror Maven Google Cloud dan perulangan build otomatis.',
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
          textEn:
              'In-app animated nighttime lake splash screen with starry skies, mountain horizon, water reflections, and crescent moon.',
          textId:
              'Layar splash animasi danau malam hari dengan langit berbintang, barisan pegunungan, pantulan air, dan bulan sabit.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Enhanced vector moon logo with elliptical orbital ring rendered seamlessly in front of and behind the crescent moon.',
          textId:
              'Penyempurnaan logo vektor bulan dengan cincin orbit elips yang melingkari bulan sabit secara artistik.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Lake landscape scenery component integrated into Welcome and authentication views for visual continuity.',
          textId:
              'Komponen lanskap danau malam yang terintegrasi pada layar Selamat Datang dan otentikasi.',
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
          textEn:
              'Cloud-synchronized 6-digit PIN security with salted SHA-256 cryptographic hashing across all devices.',
          textId:
              'Keamanan PIN 6 digit tersinkronisasi cloud dengan hashing kriptografi SHA-256 tersiram garam di semua perangkat.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'English default localization with full runtime language switcher to Bahasa Indonesia.',
          textId:
              'Lokalisasi standar Bahasa Inggris dengan pengalih bahasa dinamis ke Bahasa Indonesia.',
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
          textEn:
              'Native Android home screen widgets: HRT duration counter, upcoming dose schedule, and pharmacokinetic level chart.',
          textId:
              'Widget layar utama Android bawaan: penghitung lama terapi, jadwal dosis mendatang, dan grafik level farmakokinetik.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Privacy switch to mask sensitive medical details on home screen widgets.',
          textId:
              'Sakelar privasi untuk menyamarkan rincian medis sensitif pada widget layar utama.',
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
          textEn:
              'Dedicated user profile customization with custom Nickname and avatar photo cached locally and synced to cloud.',
          textId:
              'Kustomisasi profil pengguna dengan Nama Panggilan dan foto avatar yang tersimpan lokal dan tersinkron ke cloud.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Interactive UserAvatar on Home and More dashboards with personalized greeting header.',
          textId:
              'Avatar interaktif pada Beranda dan Lainnya lengkap dengan salam sapaan yang dipersonalisasi.',
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
          textEn:
              'Interactive Body Changes visualizer with anatomical callouts and observation timelines.',
          textId:
              'Visualisasi perubahan tubuh interaktif dengan panduan anatomi dan linimasa observasi.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Insights & cycle correlation engine analyzing dose adherence and mood trends relative to dosage intervals.',
          textId:
              'Mesin analisis dan korelasi siklus yang memantau kepatuhan dosis dan tren suasana hati terhadap interval konsumsi.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Quick 1-tap mood check-in on Home screen and mood indicator dots on pharmacokinetic curves.',
          textId:
              'Pencatatan suasana hati 1 ketukan pada Beranda dan titik indikator suasana pada kurva farmakokinetik.',
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
          textEn:
              'Comprehensive 5-tab navigation shell (Home, Calendar, Levels, Supplies, More) with Midnight UI design.',
          textId:
              'Navigasi 5 tab komprehensif (Beranda, Kalender, Level, Stok, Lainnya) dengan desain antarmuka Midnight UI.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Weekly strip date selector with schedule indicators and dose history switcher.',
          textId:
              'Pemilih tanggal mingguan dengan indikator jadwal dan pengalih riwayat konsumsi dosis.',
        ),
        ChangeItem(
          type: ChangeType.added,
          textEn:
              'Automated stock depletion and medication expiration advance alerts.',
          textId:
              'Pengingat otomatis saat stok menipis dan peringatan dini sebelum obat kedaluwarsa.',
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
          textEn:
              'Graceful back navigation and exit confirmation dialog matching Wall o\' Pay.',
          textId:
              'Navigasi tombol kembali bertahap dan dialog konfirmasi keluar aplikasi seperti Wall o\' Pay.',
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
          textEn:
              'Initial release of Lunera: Pharmacokinetic simulations, schedule tracking, inventory management, biometric security, and dual local/cloud backups.',
          textId:
              'Rilis perdana Lunera: Simulasi farmakokinetik, pencatatan jadwal, manajemen inventaris, keamanan biometrik, dan cadangan ganda lokal/cloud.',
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
                        LucideIcons.bookOpen,
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
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: muted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x),
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
              : (dark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.08)),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
          ...release.changes.map(
              (item) => _ChangeItemRow(item: item, isIndonesian: isIndonesian)),
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
