part of '../guides_data.dart';

const List<GuideArticle> _guidesCare = [
  GuideArticle(
    id: 'physical_timeline',
    category: GuideCategory.care,
    readMinutes: 4,
    icon: LucideIcons.sparkles,
    titleEn: 'Timeline of Physical Changes',
    titleId: 'Linimasa Perubahan Fisik (Apa yang Wajar Diharapkan)',
    subtitleEn:
        'A realistic month-by-month outlook for both feminizing and masculinizing HRT.',
    subtitleId:
        'Gambaran realistis perubahan bertahap untuk terapi feminisasi maupun maskulinisasi.',
    takeawaysEn: [
      'Physical transition unfolds like a second puberty over 2 to 5+ years—early months focus mostly on skin, mood, and subtle shifts.',
      'Genetics, age, nutrition, and consistent hormone levels shape your individual pace far more than chasing high doses.',
      'Tracking measurements and milestones in Lunera helps you notice subtle progress that mirrors sometimes hide.',
    ],
    takeawaysId: [
      'Transisi fisik berlangsung seperti pubertas kedua selama 2 hingga 5+ tahun—bulan-bulan awal lebih banyak menyentuh kulit, mood, dan perubahan halus.',
      'Genetik, usia, nutrisi, serta kestabilan hormon jauh lebih menentukan dibanding mengejar dosis tinggi.',
      'Mencatat ukuran tubuh dan pencapaian di Lunera membantu melihat progres bertahap yang sering tidak terasa dari hari ke hari.',
    ],
    sections: [
      GuideSection(
        headingEn: 'Feminizing HRT (Estradiol) typical milestones',
        headingId: 'Tahapan umum HRT Feminisasi (Estradiol)',
        bulletsEn: [
          '1–3 months: softer/less oily skin, reduced body odor, lower spontaneous erections, subtle breast bud tenderness.',
          '3–6 months: early breast tissue development, softening muscle tone, emotional shifts, slowing body hair growth.',
          '6–24+ months: continued breast maturation (takes 2–3+ years), fat redistribution to hips/thighs/face, thinning of facial/body hair (laser/electrolysis often still needed for existing facial hair).',
          'Note: HRT does not raise vocal pitch; voice training remains the primary path for feminizing voice.',
        ],
        bulletsId: [
          '1–3 bulan: kulit terasa lebih halus dan tidak terlalu berminyak, bau badan berkurang, penurunan ereksi spontan, mulai terasa nyeri/sensitif di area puting (breast budding).',
          '3–6 bulan: jaringan payudara mulai tumbuh bertahap, massa otot perlahan melunak, perubahan respons emosional, pertumbuhan rambut tubuh melambat.',
          '6–24+ bulan: perkembangan payudara berlanjut (matang penuh butuh 2–3+ tahun), distribusi lemak bergeser ke pinggul/paha/wajah, rambut tubuh menipis (rambut wajah yang sudah tebal umumnya tetap butuh laser/elektrolisis).',
          'Catatan: Estradiol tidak menaikkan nada suara; latihan vokal adalah jalur utama untuk suara feminim.',
        ],
      ),
      GuideSection(
        headingEn: 'Masculinizing HRT (Testosterone) typical milestones',
        headingId: 'Tahapan umum HRT Maskulinisasi (Testosteron)',
        bulletsEn: [
          '1–3 months: oilier skin/acne, increased energy/appetite, clitoral growth, early throat scratchiness as vocal cords thicken.',
          '3–6 months: noticeable voice deepening, menstrual cycle cessation (typically 1–6 months), increased facial/body hair sprouting.',
          '6–24+ months: fuller beard/body hair (continues for years), muscle gain, fat shifting toward abdomen, potential scalp hairline changes depending on genetics.',
        ],
        bulletsId: [
          '1–3 bulan: kulit lebih berminyak/berjerawat, energi dan nafsu makan naik, pertumbuhan klitoris, tenggorokan mulai terasa serak saat pita suara menebal.',
          '3–6 bulan: suara mulai turun lebih dalam, siklus menstruasi umumnya berhenti (kisaran 1–6 bulan), rambut wajah dan tubuh mulai tumbuh.',
          '6–24+ bulan: pertumbuhan janggut/rambut tubuh makin penuh (terus berlanjut bertahun-tahun), massa otot meningkat, lemak bergeser ke area perut, potensi perubahan garis rambut kepala sesuai genetik.',
        ],
      ),
    ],
    references: [
      'WPATH Standards of Care Version 8 (SOC 8)',
      'UCSF Transgender Care Guidelines — Expected Timeline Tables',
    ],
  ),
  GuideArticle(
    id: 'mood_cycle',
    category: GuideCategory.care,
    readMinutes: 3,
    icon: LucideIcons.heartPulse,
    titleEn: 'Mood, Energy & Cycle Fluctuations',
    titleId: 'Suasana Hati, Energi & Fluktuasi Siklus',
    subtitleEn:
        'Spotting how hormone highs and lows affect sleep, focus, and emotional wellbeing.',
    subtitleId:
        'Mengenali bagaimana naik-turunnya hormon memengaruhi tidur, fokus, dan emosi.',
    takeawaysEn: [
      'Feeling irritable, fatigued, or teary right before your next dose can be a sign of an overly steep trough.',
      'Early emotional adjustments in the first 1–3 months are normal while your brain adapts to a new hormone profile.',
      'Logging mood in Lunera\'s Journal lets Insights chart patterns across your cycle days.',
    ],
    takeawaysId: [
      'Merasa mudah lelah, sensitif, atau murung tepat sebelum jadwal dosis berikutnya bisa menandakan titik trough yang terlalu rendah.',
      'Adaptasi emosional di 1–3 bulan pertama adalah hal wajar saat otak menyesuaikan diri dengan profil hormon baru.',
      'Mencatat mood di Jurnal Lunera membantu fitur Insights memetakan pola di sepanjang hari siklusmu.',
    ],
    sections: [
      GuideSection(
        headingEn: 'Reading your cycle pattern',
        headingId: 'Membaca pola siklus emosionalmu',
        paragraphsEn: [
          'If you feel great on days 2–4 after an injection and consistently drained or anxious on day 6–7, your dosing interval may be slightly longer than your ester\'s smooth window—or your trough level may be dropping too low.',
          'Conversely, feeling over-stimulated, restless, or getting headaches right after a dose can happen when peak levels spike unnecessarily high.',
        ],
        paragraphsId: [
          'Jika kamu merasa sangat baik pada hari ke 2–4 setelah suntik lalu selalu merasa lelah atau cemas pada hari ke 6–7, bisa jadi interval suntikmu sedikit lebih panjang dari jendela stabil ester tersebut—atau kadar trough-nya turun terlalu rendah.',
          'Sebaliknya, merasa gelisah, berdebar, atau sakit kepala tepat setelah dosis bisa muncul ketika puncak (peak) melonjak terlalu tinggi.',
        ],
      ),
      GuideSection(
        headingEn: 'Supporting mental wellbeing',
        headingId: 'Menjaga kesehatan mental sepanjang perjalanan',
        bulletsEn: [
          'Track sleep, stress, and major life events alongside hormone days—not every bad day is caused by hormones.',
          'Stay hydrated, eat regular protein, and maintain gentle movement; physical routines stabilize mood and support tissue health.',
          'If you feel isolated in an unsupportive space, remember that safe peer communities and affirming support lines exist even when local options feel scarce.',
        ],
        bulletsId: [
          'Catat juga kualitas tidur, stres harian, dan kejadian penting di jurnal—tidak semua hari berat disebabkan oleh hormon.',
          'Jaga hidrasi, asupan protein, dan aktivitas fisik ringan; rutinitas dasar sangat membantu kestabilan mood dan kesehatan jaringan.',
          'Jika merasa sendirian di lingkungan yang kurang mendukung, ingat bahwa selalu ada ruang komunitas aman dan layanan konseling suportif yang bisa diakses.',
        ],
      ),
    ],
    references: [
      'WPATH Standards of Care Version 8 (SOC 8) — Mental Health & Wellbeing',
    ],
    action: GuideActionType.insights,
  ),
  GuideArticle(
    id: 'checkup_prep',
    category: GuideCategory.care,
    readMinutes: 4,
    icon: LucideIcons.fileText,
    titleEn: 'Preparing for a Check-up (or Self-Monitoring)',
    titleId: 'Persiapan Konsultasi Dokter (atau Pemantauan Mandiri)',
    subtitleEn:
        'How to bring clear clinical facts to an appointment—or organize regular self-checks safely.',
    subtitleId:
        'Cara membawa data klinis yang rapi ke dokter—atau menyusun checklist pemantauan mandiri yang aman.',
    takeawaysEn: [
      'Bringing a clean 3- or 6-month summary of doses, adherence, and lab results saves appointment time and prevents miscommunication.',
      'Lunera\'s Doctor Visit Summary exports only clinical history while keeping your private journal and supplies excluded.',
      'If you currently manage labs independently, keeping a 3-to-6-month rhythm keeps safety markers visible early.',
    ],
    takeawaysId: [
      'Membawa ringkasan 3 atau 6 bulan berisi dosis, kepatuhan, dan hasil lab menghemat waktu konsultasi dan mencegah salah paham.',
      'Fitur Ringkasan Konsultasi Dokter di Lunera hanya mengekspor data klinis tanpa menyertakan jurnal pribadi maupun stok alatmu.',
      'Jika saat ini kamu memantau secara mandiri, menjaga ritme cek berkala tiap 3–6 bulan membantu mendeteksi penanda keamanan sejak dini.',
    ],
    sections: [
      GuideSection(
        headingEn: 'For clinic or endocrinology visits',
        headingId: 'Saat berkonsultasi ke dokter atau klinik',
        bulletsEn: [
          'Open Settings → Doctor Visit Summary in Lunera to generate a clean 3- or 6-month clinical report you can share or print.',
          'Note the exact time between your last dose and your blood draw so your clinician knows whether numbers represent trough or mid-cycle.',
          'Write down 2–3 clear questions in advance (for example, side effects, target trough range, or switching routes).',
        ],
        bulletsId: [
          'Buka Pengaturan → Ringkasan Konsultasi Dokter di Lunera untuk membuat laporan klinis 3 atau 6 bulan yang rapi.',
          'Catat jeda waktu antara dosis terakhir dan pengambilan darah agar dokter tahu apakah angka tersebut mencerminkan titik trough atau tengah siklus.',
          'Siapkan 2–3 pertanyaan inti sebelum masuk ruangan (misal soal efek samping, rentang target trough, atau opsi ganti rute).',
        ],
      ),
      GuideSection(
        headingEn: 'For independent / DIY monitoring',
        headingId: 'Checklist pemantauan mandiri (DIY)',
        bulletsEn: [
          'First 6–12 months: aim to review hormone and basic organ safety labs around month 3, month 6, and month 12 after reaching a steady routine.',
          'Maintenance phase (stable ≥ 1 year): checking once every 6–12 months helps catch silent shifts like elevated hematocrit, prolactin, or liver enzymes.',
          'Log blood pressure periodically when possible, especially if taking estrogen or testosterone long-term.',
        ],
        bulletsId: [
          '6–12 bulan pertama: usahakan memeriksa lab hormon dan penanda keamanan dasar sekitar bulan ke-3, ke-6, dan ke-12 setelah rutinitas stabil.',
          'Fase pemeliharaan (stabil ≥ 1 tahun): pemeriksaan tiap 6–12 bulan sekali membantu mendeteksi perubahan senyap seperti kenaikan hematokrit, prolaktin, atau enzim hati.',
          'Pantau tekanan darah secara berkala bila memungkinkan, terutama pada penggunaan estrogen atau testosteron jangka panjang.',
        ],
      ),
    ],
    references: [
      'Endocrine Society Clinical Practice Guideline (2017)',
      'UCSF Transgender Care Guidelines — Follow-up Schedule',
    ],
  ),
];
