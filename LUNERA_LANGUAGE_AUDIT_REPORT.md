# Lunera — Language Consistency & Localization Audit Report

**Date of Audit:** 2026-11-24  
**Auditor:** Senior Flutter Engineer & Localization Auditor  
**Scope:** Full codebase audit (`lib/`, `assets/`, `android/`)  
**Status:** Audit & Analysis Only (Zero modifications applied)

---

## 1. Executive Summary & Coverage Metrics

Lunera employs a custom, lightweight reactive localization architecture powered by `ValueNotifier<String>` (`L10n`), `l10n_id.dart` (containing a 1,241-key dictionary `idStrings`), and the helper function `tr(String en, [dynamic args])`. The app defaults to English (`en`) and officially supports Indonesian (`id`).

While core therapeutic calculation and tracking pages (Dose Dial, Pharmacokinetic Simulator, Supplies Inventory) maintain excellent localization, a comprehensive static analysis revealed significant language leakage in newly introduced modules (Smart Consultation Prep, Care Alerts, About & Support, HRT Time-Lapse, and Moments Scrapbook).

### Key Metrics
- **Total Dictionary Keys (`idStrings`):** 1,241
- **Total `tr(...)` Invocations in Codebase:** 1,339
- **Unique Translation Keys Requested:** 1,073
- **Missing Translation Keys in `idStrings`:** **86 keys** (78 explicit `tr(...)` calls + 5 `AdminRoute` presets + 3 `HormonePreset` presets)
- **Dead / Orphan Keys in `idStrings`:** **112 keys** (obsolete strings never referenced in source code)
- **Placeholder / Morphology Mismatches:** **4 keys** (plural tokens `{0?day|days}` omitted in Indonesian)
- **Hardcoded UI Strings (Bypassing `tr`):** **6 instances**
- **Estimated Localization Coverage:** **91.9%** (1,070 localized / 1,164 total UI keys)

---

## 2. Detailed Findings by Severity

### Critical Severity (P0 / P1)
*Issues causing complete feature screens or essential clinical actions to fail translation, forcing English UI in Indonesian mode.*

| File | Location | Current Text | Expected Language | Issue | Suggested Correction |
|---|---|---|---|---|---|
| `lib/care_alerts.dart` | L68 | `Log Dose` | Indonesian | Missing key in `idStrings`. Primary action button remains English. | Add `'Log Dose': 'Catat Dosis'` |
| `lib/care_alerts.dart` | L90 | `View Supplies` | Indonesian | Missing key in `idStrings`. Supply alert button remains English. | Add `'View Supplies': 'Lihat Stok'` |
| `lib/care_alerts.dart` | L133 | `View Calendar` | Indonesian | Missing key in `idStrings`. Calendar navigation button remains English. | Add `'View Calendar': 'Buka Kalender'` |
| `lib/care_alerts.dart` | L145 | `Doctor Visit` | Indonesian | Missing key in `idStrings`. Critical alert title remains English. | Add `'Doctor Visit': 'Kunjungan Dokter'` |
| `lib/models.dart` | L126 | `Oral` | Indonesian | Route preset missing from `idStrings`. Dose logging route leaks English. | Add `'Oral': 'Oral'` |
| `lib/models.dart` | L127 | `Sublingual` | Indonesian | Route preset missing from `idStrings`. Route selector leaks English. | Add `'Sublingual': 'Sublingual'` |
| `lib/models.dart` | L128 | `Patch` | Indonesian | Route preset missing from `idStrings`. Transdermal patch leaks English. | Add `'Patch': 'Koyo / Patch'` |
| `lib/models.dart` | L129 | `Gel` | Indonesian | Route preset missing from `idStrings`. Topical gel leaks English. | Add `'Gel': 'Gel'` |
| `lib/models.dart` | L134 | `Other` | Indonesian | Route preset missing from `idStrings`. Custom route leaks English. | Add `'Other': 'Lainnya'` |
| `lib/consultation_prep.dart` | L199 | `Recent blood work / lab results printout or digital copy` | Indonesian | Missing key in `idStrings`. Default checklist item leaks English. | Add `'Recent blood work / lab results printout or digital copy': 'Salinan cetak atau digital hasil lab / tes darah terkini'` |
| `lib/consultation_prep.dart` | L204 | `Current HRT medication list with exact dose and schedule` | Indonesian | Missing key in `idStrings`. Checklist item leaks English. | Add `'Current HRT medication list with exact dose and schedule': 'Daftar obat HRT saat ini lengkap dengan dosis dan jadwal pasti'` |
| `lib/consultation_prep.dart` | L209 | `Government photo ID and insurance / clinic card` | Indonesian | Missing key in `idStrings`. Checklist item leaks English. | Add `'Government photo ID and insurance / clinic card': 'KTP / identitas resmi dan kartu asuransi / klinik'` |
| `lib/consultation_prep.dart` | L214 | `Prescription refill quantities and preferred pharmacy` | Indonesian | Missing key in `idStrings`. Checklist item leaks English. | Add `'Prescription refill quantities and preferred pharmacy': 'Jumlah tebus resep dan apotek yang dituju'` |
| `lib/consultation_prep.dart` | L219 | `Printed or digital Lunera Doctor Summary Report` | Indonesian | Missing key in `idStrings`. Checklist item leaks English. | Add `'Printed or digital Lunera Doctor Summary Report': 'Laporan Ringkasan Dokter Lunera (cetak atau digital)'` |
| `lib/consultation_prep.dart` | L226 | `Review recent hormone blood test levels against target ranges` | Indonesian | Missing key in `idStrings`. Suggested topic leaks English. | Add `'Review recent hormone blood test levels against target ranges': 'Tinjau kadar hormon hasil lab terkini terhadap rentang target'` |
| `lib/consultation_prep.dart` | L227 | `Discuss dosage adjustment or regimen optimization` | Indonesian | Missing key in `idStrings`. Suggested topic leaks English. | Add `'Discuss dosage adjustment or regimen optimization': 'Diskusikan penyesuaian dosis atau optimasi rejimen'` |
| `lib/consultation_prep.dart` | L228 | `Evaluate energy, mood rhythm, and physical changes` | Indonesian | Missing key in `idStrings`. Suggested topic leaks English. | Add `'Evaluate energy, mood rhythm, and physical changes': 'Evaluasi energi, ritme suasana hati, dan perubahan fisik'` |
| `lib/consultation_prep.dart` | L229 | `Check injection site tissue and needle supplies renewal` | Indonesian | Missing key in `idStrings`. Suggested topic leaks English. | Add `'Check injection site tissue and needle supplies renewal': 'Periksa kondisi jaringan lokasi suntik dan pembaruan stok jarum'` |
| `lib/consultation_prep.dart` | L230 | `Request prescription renewal for the next 3–6 months` | Indonesian | Missing key in `idStrings`. Suggested topic leaks English. | Add `'Request prescription renewal for the next 3–6 months': 'Minta pembaruan resep obat untuk 3–6 bulan ke depan'` |
| `lib/consultation_prep.dart` | L298 | `Frequently occurs within 1–2 days after dose` | Indonesian | Missing key in `idStrings`. Cluster correlation leaks English. | Add `'Frequently occurs within 1–2 days after dose': 'Sering terjadi 1–2 hari setelah dosis'` |
| `lib/consultation_prep.dart` | L300 | `Tends to occur late in dose cycle (near trough)` | Indonesian | Missing key in `idStrings`. Cluster correlation leaks English. | Add `'Tends to occur late in dose cycle (near trough)': 'Cenderung muncul di akhir siklus dosis (dekat titik trough)'` |
| `lib/consultation_prep.dart` | L302 | `Frequently occurs mid-cycle` | Indonesian | Missing key in `idStrings`. Cluster correlation leaks English. | Add `'Frequently occurs mid-cycle': 'Sering terjadi di pertengahan siklus'` |
| `lib/consultation_prep.dart` | L308 | `I noticed {0} ({1}x recently, {2}). Is this expected or related to my dosage rhythm?` | Indonesian | Missing key in `idStrings`. Auto-generated doctor question leaks English. | Add `'I noticed {0} ({1}x recently, {2}). Is this expected or related to my dosage rhythm?': 'Saya merasakan {0} ({1}x belakangan ini, {2}). Apakah ini wajar atau terkait dengan ritme dosis saya?'` |
| `lib/consultation_prep.dart` | L313 | `I experienced {0} {1} times in recent weeks. Should we explore managing this?` | Indonesian | Missing key in `idStrings`. Auto-generated doctor question leaks English. | Add `'I experienced {0} {1} times in recent weeks. Should we explore managing this?': 'Saya mengalami {0} sebanyak {1} kali dalam beberapa pekan terakhir. Apakah perlu penanganan khusus?'` |
| `lib/consultation_prep.dart` | L318 | `I experienced {0} recently. Is this common with my current regimen?` | Indonesian | Missing key in `idStrings`. Auto-generated doctor question leaks English. | Add `'I experienced {0} recently. Is this common with my current regimen?': 'Saya merasakan {0} baru-baru ini. Apakah ini umum terjadi pada rejimen saya?'` |
| `lib/ui/data_page.dart` & `settings_page.dart` | L48, L199 | `Merge: records from the file are added or updated, and your current data stays.\n\n` | Indonesian | Missing key in `idStrings`. Backup import warning leaks English. | Add `'Merge: records from the file are added or updated, and your current data stays.\n\n': 'Gabungkan: catatan dari file akan ditambahkan atau diperbarui, dan datamu saat ini tetap aman.\n\n'` |
| `lib/ui/settings_page.dart` | L376 | `Injection Site Rotation & Health` | Indonesian | Missing key in `idStrings`. Settings item title leaks English. | Add `'Injection Site Rotation & Health': 'Rotasi Lokasi & Kesehatan Titik Suntik'` |
| `lib/ui/settings_page.dart` | L377 | `Inspect zone health, rest countdowns, and rotation history.` | Indonesian | Missing key in `idStrings`. Settings description leaks English. | Add `'Inspect zone health, rest countdowns, and rotation history.': 'Pantau kesehatan area, hitung mundur istirahat, dan riwayat rotasi.'` |

---

### High Severity
*Issues affecting entire feature interfaces, section headers, dialogs, and exported clinical documents.*

| File | Location | Current Text | Expected Language | Issue | Suggested Correction |
|---|---|---|---|---|---|
| `lib/ui/consultation_prep_page.dart` | L84 | `Export Doctor Report` | Indonesian | Missing key in `idStrings`. Sheet header button leaks English. | Add `'Export Doctor Report': 'Ekspor Laporan Dokter'` |
| `lib/ui/consultation_prep_page.dart` | L85 | `Export clinical summary and include your prepared consultation questions.` | Indonesian | Missing key in `idStrings`. Dialog subtitle leaks English. | Add `'Export clinical summary and include your prepared consultation questions.': 'Ekspor ringkasan klinis dan sertakan pertanyaan konsultasi yang telah disiapkan.'` |
| `lib/ui/consultation_prep_page.dart` | L137, L169 | `Lunera Consultation & Clinical Summary` | Indonesian | Missing key in `idStrings`. Export document title leaks English. | Add `'Lunera Consultation & Clinical Summary': 'Ringkasan Klinis & Konsultasi Lunera'` |
| `lib/ui/consultation_prep_page.dart` | L176 | `Failed to export: {0}` | Indonesian | Missing key in `idStrings`. Error message leaks English. | Add `'Failed to export: {0}': 'Gagal mengekspor: {0}'` |
| `lib/ui/consultation_prep_page.dart` | L185 | `No questions prepared yet.` | Indonesian | Missing key in `idStrings`. Empty state text leaks English. | Add `'No questions prepared yet.': 'Belum ada pertanyaan yang disiapkan.'` |
| `lib/ui/consultation_prep_page.dart` | L206 | `Questions copied to clipboard.` | Indonesian | Missing key in `idStrings`. SnackBar text leaks English. | Add `'Questions copied to clipboard.': 'Pertanyaan berhasil disalin ke papan klip.'` |
| `lib/ui/consultation_prep_page.dart` | L215 | `Reset Consultation Prep?` | Indonesian | Missing key in `idStrings`. Confirm dialog title leaks English. | Add `'Reset Consultation Prep?': 'Atur Ulang Persiapan Konsultasi?'` |
| `lib/ui/consultation_prep_page.dart` | L216 | `This will clear current questions and notes for a fresh consultation appointment.` | Indonesian | Missing key in `idStrings`. Confirm dialog text leaks English. | Add `'This will clear current questions and notes for a fresh consultation appointment.': 'Tindakan ini akan menghapus pertanyaan dan catatan saat ini untuk jadwal konsultasi baru.'` |
| `lib/ui/consultation_prep_page.dart` | L252, `more.dart:681` | `Smart Consultation Prep` | Indonesian | Missing key in `idStrings`. App bar and card title leak English. | Add `'Smart Consultation Prep': 'Persiapan Konsultasi Dokter'` |
| `lib/ui/consultation_prep_page.dart` | L256 | `Copy Questions` | Indonesian | Missing key in `idStrings`. Action button leaks English. | Add `'Copy Questions': 'Salin Pertanyaan'` |
| `lib/ui/consultation_prep_page.dart` | L261 | `Reset Session` | Indonesian | Missing key in `idStrings`. Action button leaks English. | Add `'Reset Session': 'Atur Ulang Sesi'` |
| `lib/ui/consultation_prep_page.dart` | L284 | `Clinical Appointment` | Indonesian | Missing key in `idStrings`. Section title leaks English. | Add `'Clinical Appointment': 'Jadwal Janji Medis'` |
| `lib/ui/consultation_prep_page.dart` | L292 | `Prepare topics, check-ins, and questions` | Indonesian | Missing key in `idStrings`. Subtitle leaks English. | Add `'Prepare topics, check-ins, and questions': 'Siapkan topik bahasan, keluhan, dan pertanyaan'` |
| `lib/ui/consultation_prep_page.dart` | L306 | `Upcoming` | Indonesian | Missing key in `idStrings`. Badge label leaks English. | Add `'Upcoming': 'Mendatang'` |
| `lib/ui/consultation_prep_page.dart` | L335 | `Doctor or Clinic Name` | Indonesian | Missing key in `idStrings`. Form input label leaks English. | Add `'Doctor or Clinic Name': 'Nama Dokter atau Klinik'` |
| `lib/ui/consultation_prep_page.dart` | L336 | `e.g. Dr. Emily Thorne (Endocrinology)` | Indonesian | Missing key in `idStrings`. Form placeholder leaks English. | Add `'e.g. Dr. Emily Thorne (Endocrinology)': 'mis. dr. Maya Sari, Sp.And'` |
| `lib/ui/consultation_prep_page.dart` | L368 | `Tap to set consultation date` | Indonesian | Missing key in `idStrings`. Date picker prompt leaks English. | Add `'Tap to set consultation date': 'Ketuk untuk mengatur tanggal konsultasi'` |
| `lib/ui/consultation_prep_page.dart` | L408 | `Observed Symptom Patterns` | Indonesian | Missing key in `idStrings`. Header title leaks English. | Add `'Observed Symptom Patterns': 'Pola Gejala yang Teramati'` |
| `lib/ui/consultation_prep_page.dart` | L424 | `{0} patterns` | Indonesian | Missing key in `idStrings`. Subtitle badge leaks English. | Add `'{0} patterns': '{0} pola'` |
| `lib/ui/consultation_prep_page.dart` | L443 | `No recurring symptoms found in recent journal logs. Continue logging symptoms in your daily journal to detect cycle correlations.` | Indonesian | Missing key in `idStrings`. Empty state text leaks English. | Add `'No recurring symptoms found in recent journal logs. Continue logging symptoms in your daily journal to detect cycle correlations.': 'Tidak ditemukan pola gejala berulang pada jurnal terkini. Lanjutkan mencatat gejala harian untuk mendeteksi korelasi siklus.'` |
| `lib/ui/consultation_prep_page.dart` | L492 | `{0} entries in last 90 days` | Indonesian | Missing key in `idStrings`. Symptom count leaks English. | Add `'{0} entries in last 90 days': '{0} catatan dalam 90 hari terakhir'` |
| `lib/ui/consultation_prep_page.dart` | L521 | `Added` | Indonesian | Missing key in `idStrings`. Button state leaks English. | Add `'Added': 'Sudah Ditambah'` |
| `lib/ui/consultation_prep_page.dart` | L522 | `Add to Questions` | Indonesian | Missing key in `idStrings`. Action button leaks English. | Add `'Add to Questions': 'Tambah ke Pertanyaan'` |
| `lib/ui/consultation_prep_page.dart` | L570 | `Questions & Discussion Points` | Indonesian | Missing key in `idStrings`. Section title leaks English. | Add `'Questions & Discussion Points': 'Daftar Pertanyaan & Poin Diskusi'` |
| `lib/ui/consultation_prep_page.dart` | L596 | `No questions prepared yet. Use suggested topics below or write your own.` | Indonesian | Missing key in `idStrings`. Empty state text leaks English. | Add `'No questions prepared yet. Use suggested topics below or write your own.': 'Belum ada pertanyaan yang disiapkan. Gunakan saran topik di bawah atau tulis pertanyaanmu sendiri.'` |
| `lib/ui/consultation_prep_page.dart` | L662 | `Add question for clinician...` | Indonesian | Missing key in `idStrings`. Form input placeholder leaks English. | Add `'Add question for clinician...': 'Tambah pertanyaan untuk dokter...'` |
| `lib/ui/consultation_prep_page.dart` | L700 | `Quick Suggested Topics:` | Indonesian | Missing key in `idStrings`. Suggestions header leaks English. | Add `'Quick Suggested Topics:': 'Saran Topik Cepat:'` |
| `lib/ui/consultation_prep_page.dart` | L743 | `Documents & Visit Checklist` | Indonesian | Missing key in `idStrings`. Section title leaks English. | Add `'Documents & Visit Checklist': 'Dokumen & Ceklis Kunjungan'` |
| `lib/ui/consultation_prep_page.dart` | L821 | `Add checklist item...` | Indonesian | Missing key in `idStrings`. Form input placeholder leaks English. | Add `'Add checklist item...': 'Tambah perlengkapan / ceklis...'` |
| `lib/ui/consultation_prep_page.dart` | L859 | `Post-Visit Clinical Notes` | Indonesian | Missing key in `idStrings`. Section title leaks English. | Add `'Post-Visit Clinical Notes': 'Catatan Pasca-Konsultasi'` |
| `lib/ui/consultation_prep_page.dart` | L865 | `Record doctor adjustments, lab test orders, or follow-up instructions...` | Indonesian | Missing key in `idStrings`. Text area placeholder leaks English. | Add `'Record doctor adjustments, lab test orders, or follow-up instructions...': 'Catat anjuran dokter, pengantar tes lab, atau jadwal kontrol berikutnya...'` |
| `lib/ui/consultation_prep_page.dart` | L879 | `Export Doctor Summary Report (PDF / Text)` | Indonesian | Missing key in `idStrings`. Big button label leaks English. | Add `'Export Doctor Summary Report (PDF / Text)': 'Ekspor Ringkasan Dokter (PDF / Teks)'` |
| `lib/ui/consultation_prep_page.dart` | L887 | `Includes therapies, adherence, lab trends, and your prepared questions.` | Indonesian | Missing key in `idStrings`. Button subtitle leaks English. | Add `'Includes therapies, adherence, lab trends, and your prepared questions.': 'Mencakup terapi aktif, kepatuhan, tren lab, dan pertanyaan yang telah kamu siapkan.'` |
| `lib/doctor_report.dart` | L233, L363 | `Prepared Consultation Questions` | Indonesian | Missing key in `idStrings`. Exported PDF and text header leaks English. | Add `'Prepared Consultation Questions': 'Pertanyaan Konsultasi yang Disiapkan'` |
| `lib/ui/about_sheet.dart` | L283 | `Fast local storage with zero network dependency and complete data ownership.` | Indonesian | Missing key in `idStrings`. About sheet feature description leaks English. | Add `'Fast local storage with zero network dependency and complete data ownership.': 'Penyimpanan lokal cepat tanpa ketergantungan internet dan kepemilikan data penuh.'` |
| `lib/ui/about_sheet.dart` | L289 | `Instant privacy shield, decoy calculator mode, and discreet masked push alerts.` | Indonesian | Missing key in `idStrings`. Feature description leaks English. | Add `'Instant privacy shield, decoy calculator mode, and discreet masked push alerts.': 'Perlindungan privasi instan, mode kalkulator samaran, dan notifikasi tersamar.'` |
| `lib/ui/about_sheet.dart` | L295 | `Step-by-step calming assistant with injection angle guidance and breathing pacing.` | Indonesian | Missing key in `idStrings`. Feature description leaks English. | Add `'Step-by-step calming assistant with injection angle guidance and breathing pacing.': 'Panduan suntik tenang bertahap dengan arahan sudut jarum dan ritme napas.'` |
| `lib/ui/about_sheet.dart` | L300 | `Precision Reminders` | Indonesian | Missing key in `idStrings`. Feature title leaks English. | Add `'Precision Reminders': 'Pengingat Presisi'` |
| `lib/ui/about_sheet.dart` | L301 | `Alarm-manager powered scheduled doses and automatic supply pickup alerts.` | Indonesian | Missing key in `idStrings`. Feature description leaks English. | Add `'Alarm-manager powered scheduled doses and automatic supply pickup alerts.': 'Jadwal dosis berbasis alarm-manager dan pengingat otomatis ambil paket stok.'` |
| `lib/ui/calendar.dart` | L220 | `Previous month` | Indonesian | Missing key in `idStrings`. Navigation tooltip leaks English. | Add `'Previous month': 'Bulan sebelumnya'` |
| `lib/ui/calendar.dart` | L280 | `Next month` | Indonesian | Missing key in `idStrings`. Navigation tooltip leaks English. | Add `'Next month': 'Bulan berikutnya'` |
| `lib/ui/moments_page.dart` | L385 | `Edit` | Indonesian | Missing key in `idStrings`. Card action leaks English. | Add `'Edit': 'Ubah'` |
| `lib/ui/moments_page.dart` | L744 | `Save Changes` | Indonesian | Missing key in `idStrings`. Form submit button leaks English. | Add `'Save Changes': 'Simpan Perubahan'` |
| `lib/ui/more.dart` | L683 | `Symptom clusters, visit checklist & doctor report` | Indonesian | Missing key in `idStrings`. Menu subtitle leaks English. | Add `'Symptom clusters, visit checklist & doctor report': 'Klaster gejala, ceklis kunjungan & laporan dokter'` |
| `lib/ui/more.dart` | L744 | `Version, mission, and medical disclaimer` | Indonesian | Missing key in `idStrings`. Menu subtitle leaks English. | Add `'Version, mission, and medical disclaimer': 'Versi, misi aplikasi, dan disklaimer medis'` |
| `lib/ui/pickup_assistant_sheet.dart` | L299 | `• Ask seller to describe package neutrally (e.g. "Health Vitamins / Supplement").\n• Track package until "Arrived at Drop Point", then go directly to pick it up with your tracking receipt & ID.` | Indonesian | Missing key in `idStrings`. Discreet pickup guide leaks English. | Add `'• Ask seller to describe package neutrally (e.g. "Health Vitamins / Supplement").\n• Track package until "Arrived at Drop Point", then go directly to pick it up with your tracking receipt & ID.': '• Minta penjual mencantumkan deskripsi netral pada paket (mis. "Suplemen / Vitamin Kesehatan").\n• Lacak paket hingga berstatus "Tiba di Drop Point", lalu segera ambil langsung dengan bukti resi dan identitasmu.'` |
| `lib/ui/sheets.dart` | L220 | `{0} dose ({1})` | Indonesian | Missing key in `idStrings`. Therapy selector subtitle leaks English. | Add `'{0} dose ({1})': 'Dosis {0} ({1})'` |
| `lib/ui/levels/level_panel.dart` | L295 | `Estimated level now` | Indonesian | Missing key in `idStrings`. Serum chart card leaks English. | Add `'Estimated level now': 'Perkiraan kadar saat ini'` |
| `lib/ui/levels/level_panel.dart` | L298 | `No recent data` | Indonesian | Missing key in `idStrings`. Empty state text leaks English. | Add `'No recent data': 'Belum ada data terbaru'` |
| `lib/ui/levels/level_panel.dart` | L645 | `lab result` | Indonesian | Key whitespace mismatch. In `idStrings` it is `' lab result'` (with leading space), but in code it calls `'lab result'`. | Add `'lab result': 'hasil lab'` |
| `lib/ui/sanctuary/hrt_timelapse_page.dart` | L17 | `Feminizing (MtF)` | Indonesian | Missing key in `idStrings`. Category tab leaks English. | Add `'Feminizing (MtF)': 'Feminisme (MtF)'` |
| `lib/ui/sanctuary/hrt_timelapse_page.dart` | L17 | `Masculinizing (FtM)` | Indonesian | Missing key in `idStrings`. Category tab leaks English. | Add `'Masculinizing (FtM)': 'Maskulinisasi (FtM)'` |
| `lib/ui/sanctuary/hrt_timelapse_page.dart` | L249 | `HRT Time-Lapse` | Indonesian | Missing key in `idStrings`. Header title leaks English. | Add `'HRT Time-Lapse': 'Time-Lapse HRT'` |
| `lib/ui/sanctuary/hrt_timelapse_page.dart` | L318 | `General educational reference only. Every body responds at its own pace depending on genetics, dosage, and lab levels.` | Indonesian | Missing key in `idStrings`. Medical notice leaks English. | Add `'General educational reference only. Every body responds at its own pace depending on genetics, dosage, and lab levels.': 'Hanya sebagai referensi edukasi umum. Setiap tubuh merespons dengan ritmenya masing-masing bergantung pada genetika, dosis, dan hasil lab.'` |
| `lib/ui/sanctuary/hrt_timelapse_page.dart` | L521 | `Stage` | Indonesian | Missing key in `idStrings`. Stage badge label leaks English. | Add `'Stage': 'Tahap'` |

---

### Medium Severity
*Morphological placeholder discrepancies, debug-mode missing presets, and hardcoded UI literals.*

| File | Location | Current Text | Expected Language | Issue | Suggested Correction |
|---|---|---|---|---|---|
| `lib/l10n_id.dart` | L941 | `hari lalu` | Indonesian | Key is `{0?day|days} ago`. The Indonesian translation drops `{0}`. In dial painter where the number is placed in a separate upper `Text`, this renders correctly, but if called inline with arg, `{0}` is lost. | Keep consistent or document context: `'hari lalu'` is used below top-level number counter. |
| `lib/l10n_id.dart` | L942 | `hari terlambat` | Indonesian | Key is `{0?day|days} late`. Drops `{0}` because number is rendered on line above in `home.dart:409`. | Document context or add `{0} hari terlambat` for inline usage. |
| `lib/l10n_id.dart` | L943 | `hari lagi` | Indonesian | Key is `{0?day|days} left`. Drops `{0}` because number is rendered above. | Document context. |
| `lib/l10n_id.dart` | L944 | `hari sejak dosis terakhir` | Indonesian | Key is `{0?day|days} since last dose`. Drops `{0}`. | Document context. |
| `lib/models.dart` | L45 | `Estradiol` | Indonesian | Missing from `idStrings`. Triggers `debugPrint` fallback in Indonesian mode. | Add `'Estradiol': 'Estradiol'` |
| `lib/models.dart` | L48 | `LH` | Indonesian | Missing from `idStrings`. Triggers `debugPrint` fallback in Indonesian mode. | Add `'LH': 'LH'` |
| `lib/models.dart` | L49 | `FSH` | Indonesian | Missing from `idStrings`. Triggers `debugPrint` fallback in Indonesian mode. | Add `'FSH': 'FSH'` |
| `lib/ui/sanctuary/voice_pitch_page.dart` | L1584 | `65 Hz` | All | Hardcoded `Text('65 Hz')` without `tr()`. | Fine for SI unit, but should be consistent. |
| `lib/ui/sanctuary/voice_pitch_page.dart` | L1590 | `280 Hz` | All | Hardcoded `Text('280 Hz')` without `tr()`. | Fine for SI unit. |
| `lib/ui/body.dart` | L352 | `(US/UK • EU/ID)` | All | Hardcoded `Text('(US/UK • EU/ID)')` without `tr()`. | Wrap in `tr()` for consistency. |
| `lib/ui/body.dart` | L1264 | `US Men ${liveShoe.usMen} • UK ${liveShoe.uk} • ${fmt(liveShoe.footCm)} cm` | All | Formatted label lacks localized prefix. | Localize label tokens. |
| `lib/ui/about_sheet.dart` | L151 | `v${UpdateCheckerService.currentVersion} • Eternal Dusk Edition` | English | "Eternal Dusk Edition" is hardcoded in `Text(...)`. | Wrap "Eternal Dusk Edition" in `tr()`. |

---

### Low Severity (Code Hygiene & Optimization)
*Dead translation keys in `idStrings` that are never referenced by any active Dart file.*

A total of **112 completely dead keys** exist in `lib/l10n_id.dart`. Examples:
- `' estimated   '` (leading/trailing whitespace error)
- `' lab result'` (leading whitespace error, code calls `'lab result'`)
- `'Accent color'`
- `'Account Profile'`
- `'Active compound (chemical / ester):'`
- `'Active compound:'`
- `'Add supply'`
- `'Adherence and mood patterns'`
- `'App PIN lock protection'`
- `'Appearance'`
- `'Appearance, units, injection sites, reminders'`
- `'Arcane Astral'`
- `'Arcane Astral & Honey Gold'`
- `'Are you sure you want to remove your profile photo?'`
- `'at {0}'`
- `'Blue and orange'`
- `'Celestial Lilac & Mint'`
- `'Change photo and nickname'`
- `'Dark'`
- `'Day and counter'`
- `'Decoy Calculator on'`
- `'Details'`
- `'Doses after midnight still count toward the previous day.'`
- `'Estimated Bra & Chest Size'`
- `'Estimated estradiol, {0} pg/mL now'`

*Recommendation:* Retain during audit stage; clean up or prune in the next version bump to reduce memory footprint.

---

## 3. Summary of Affected Files

| Component / Subsystem | Files Affected | Missing Keys Count |
|---|---|---|
| Consultation Prep | `lib/consultation_prep.dart`, `lib/ui/consultation_prep_page.dart` | 49 |
| Care Alerts & Monitoring | `lib/care_alerts.dart` | 4 |
| Route Presets & Hormone Presets | `lib/models.dart` | 8 |
| Sanctuary & HRT Time-Lapse | `lib/ui/sanctuary/hrt_timelapse_page.dart`, `voice_pitch_page.dart` | 7 |
| About & Support | `lib/ui/about_sheet.dart` | 6 |
| Navigation & Calendar | `lib/ui/calendar.dart` | 2 |
| Moments Scrapbook | `lib/ui/moments_page.dart` | 2 |
| Data & Settings Pages | `lib/ui/data_page.dart`, `lib/ui/settings_page.dart` | 3 |
| Hormone Levels Panel | `lib/ui/levels/level_panel.dart` | 3 |
| More Menu & Pickup Sheet | `lib/ui/more.dart`, `lib/ui/pickup_assistant_sheet.dart` | 3 |
| **Total** | **12 Files** | **86 Missing Keys** |
