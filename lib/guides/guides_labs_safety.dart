part of '../guides_data.dart';

const List<GuideArticle> _guidesLabsAndSafety = [
  GuideArticle(
    id: 'peak_trough',
    category: GuideCategory.labs,
    readMinutes: 4,
    icon: LucideIcons.activity,
    titleEn: 'Peak, Trough & Steady State Explained',
    titleId: 'Memahami Peak, Trough & Steady State',
    subtitleEn:
        'Why the exact timing of your blood test can make levels look artificially high or low.',
    subtitleId:
        'Mengapa waktu pengambilan sampel darah bisa membuat hasil lab tampak jauh lebih tinggi atau rendah.',
    takeawaysEn: [
      'Peak is your highest level shortly after a dose; trough is your lowest point right before your next scheduled dose.',
      'Most clinical and harm-reduction comparisons rely on trough bloodwork.',
      'It takes roughly 4–5 half-lives for a steady repeating schedule to reach steady state.',
    ],
    takeawaysId: [
      'Peak adalah kadar tertinggi sesaat setelah dosis; trough adalah titik terendah tepat sebelum dosis berikutnya.',
      'Sebagian besar evaluasi medis maupun mandiri berpatokan pada hasil darah di titik trough.',
      'Dibutuhkan sekitar 4–5 kali waktu paruh bagi jadwal rutin untuk mencapai kondisi stabil (steady state).',
    ],
    sections: [
      GuideSection(
        headingEn: 'When should blood be drawn?',
        headingId: 'Kapan waktu terbaik mengambil darah untuk lab?',
        paragraphsEn: [
          'For injections and oral/sublingual tablets, drawing blood right after a dose captures the temporary spike (peak), which can look alarmingly high even when your average exposure is moderate—or mask levels that drop too low before the next dose.',
          'Always aim to draw blood at trough: the morning of your next scheduled dose, BEFORE taking or injecting that dose.',
        ],
        paragraphsId: [
          'Untuk injeksi maupun tablet oral/sublingual, mengambil darah tepat setelah dosis hanya menangkap lonjakan sementara (peak), yang bisa terlihat terlalu tinggi padahal rata-ratanya normal—atau menutupi kadar yang sebenarnya sudah terlalu rendah sebelum dosis berikutnya.',
          'Usahakan selalu mengambil darah pada titik trough: pada hari jadwal dosis berikutnya, TEPAT SEBELUM kamu minum atau menyuntikkan dosis tersebut.',
        ],
        bulletsEn: [
          'Transdermal gel caution: never apply gel to the arm where blood will be drawn on lab day, as residual skin gel can wildly contaminate the blood sample.',
          'Wait 4–8 weeks after starting or changing a regimen (or longer for undecylate) before testing so you measure steady state rather than early buildup.',
        ],
        bulletsId: [
          'Perhatian untuk pengguna gel transdermal: jangan mengoleskan gel pada lengan yang akan ditusuk jarum lab di hari tes darah, karena sisa gel di kulit dapat mengkontaminasi sampel darah hingga terbaca sangat tinggi.',
          'Tunggu sekitar 4–8 minggu setelah memulai atau mengubah jadwal (atau lebih lama untuk undecylate) sebelum tes lab agar yang terukur adalah kadar stabil, bukan fase penumpukan awal.',
        ],
      ),
      GuideSection(
        headingEn: 'Understanding Lunera\'s steady-state projection',
        headingId: 'Memahami proyeksi steady state di Lunera',
        paragraphsEn: [
          'In the Levels tab, enabling "Include upcoming doses" previews how scheduled future doses build toward steady state and estimates your window peak and trough—useful for spotting wide swings before your next check-up.',
        ],
        paragraphsId: [
          'Di tab Levels, mengaktifkan "Sertakan dosis mendatang" menampilkan pratinjau bagaimana jadwal berikutnya membentuk kondisi stabil beserta estimasi peak dan trough—berguna untuk mendeteksi fluktuasi terlalu lebar.',
        ],
      ),
    ],
    references: [
      'UCSF Transgender Care Guidelines — Lab Monitoring',
      'Endocrine Society Clinical Practice Guideline (2017)',
    ],
    action: GuideActionType.addLab,
  ),
  GuideArticle(
    id: 'reading_labs',
    category: GuideCategory.labs,
    readMinutes: 5,
    icon: LucideIcons.flaskConical,
    titleEn: 'Reading Bloodwork & Lab Units',
    titleId: 'Membaca Hasil Lab & Konversi Satuan',
    subtitleEn:
        'Making sense of pg/mL vs pmol/L, ng/dL vs nmol/L, safety markers, and < / > results.',
    subtitleId:
        'Memahami pg/mL vs pmol/L, ng/dL vs nmol/L, penanda keamanan organ, serta hasil bertanda < / >.',
    takeawaysEn: [
      'Always check the unit printed next to a number—100 pg/mL equals ~367 pmol/L for Estradiol.',
      'Hormone numbers are only half the picture; organ and blood safety markers protect your long-term health.',
      'Results marked "<" or ">" mean the value fell beyond the lab machine\'s measurable range.',
    ],
    takeawaysId: [
      'Selalu periksa satuan yang tercetak di samping angka—100 pg/mL setara ~367 pmol/L untuk Estradiol.',
      'Angka hormon baru separuh cerita; penanda keamanan organ dan darah sama pentingnya untuk kesehatan jangka panjang.',
      'Hasil bertanda "<" atau ">" berarti nilainya berada di bawah atau di atas batas deteksi alat lab.',
    ],
    sections: [
      GuideSection(
        headingEn: 'Common hormone units & quick conversions',
        headingId: 'Satuan hormon umum & konversi cepat',
        bulletsEn: [
          'Estradiol (E2): 1 pg/mL = 3.671 pmol/L (1 ng/L = 1 pg/mL). Typical adult cis-female range / common clinical target sits roughly around 100–200 pg/mL (367–734 pmol/L) at trough.',
          'Testosterone (T): 1 nmol/L ≈ 28.84 ng/dL (1 ng/mL = 100 ng/dL). Typical feminizing target is suppressed (< 50 ng/dL or < 1.7 nmol/L); typical masculinizing target sits roughly around 300–1000 ng/dL (~10–35 nmol/L) depending on timing.',
          'LH & FSH: drop near zero (< 1–2 IU/L) when sex hormones effectively suppress endogenous gonadal production.',
          'Prolactin: especially relevant if taking Cyproterone acetate (CPA); persistently high prolactin warrants medical review.',
        ],
        bulletsId: [
          'Estradiol (E2): 1 pg/mL = 3,671 pmol/L (1 ng/L = 1 pg/mL). Target klinis umum feminisasi biasanya di kisaran ~100–200 pg/mL (367–734 pmol/L) pada titik trough.',
          'Testosteron (T): 1 nmol/L ≈ 28,84 ng/dL (1 ng/mL = 100 ng/dL). Target supresi feminisasi umumnya < 50 ng/dL (< 1,7 nmol/L); target maskulinisasi umumnya di kisaran ~300–1000 ng/dL (~10–35 nmol/L) sesuai waktu cek.',
          'LH & FSH: turun mendekati nol (< 1–2 IU/L) saat sinyal produksi hormon bawaan berhasil ditekan.',
          'Prolaktin: penting dipantau terutama bagi pengguna Cyproterone acetate (CPA); lonjakan tinggi yang menetap perlu evaluasi medis.',
        ],
      ),
      GuideSection(
        headingEn: 'Essential safety panels beyond E2 & T',
        headingId: 'Panel keamanan penting selain E2 & T',
        bulletsEn: [
          'Testosterone therapy: Complete Blood Count (CBC) / Hematocrit to ensure red blood cells do not thicken excessively, plus lipids.',
          'Spironolactone: Electrolytes (especially Potassium) and Kidney function (Creatinine/eGFR).',
          'CPA or Bicalutamide (or oral E2): Liver enzymes (AST / ALT) periodically to catch liver stress early.',
          'Censored values (< / >): If your report says "< 5 pg/mL" or "> 3000 pg/mL", log the "<" or ">" comparator in Lunera so charts record the boundary accurately without distorting curve calibration.',
        ],
        bulletsId: [
          'Terapi Testosteron: Darah Lengkap (CBC) / Hematokrit untuk memantau kekentalan sel darah merah, serta profil lipid.',
          'Spironolactone: Elektrolit (terutama Kalium) dan fungsi ginjal (Kreatinin/eGFR).',
          'CPA, Bicalutamide, atau E2 oral: Enzim hati (SGOT/AST & SGPT/ALT) secara berkala untuk mendeteksi beban hati lebih dini.',
          'Nilai batas deteksi (< / >): Jika hasil lab tertulis "< 5 pg/mL" atau "> 3000 pg/mL", catat komparator "<" atau ">" di Lunera agar riwayat tercatat akurat tanpa mengacaukan kalibrasi kurva.',
        ],
      ),
    ],
    references: [
      'Endocrine Society Clinical Practice Guideline (2017)',
      'WPATH Standards of Care Version 8 (SOC 8)',
    ],
    action: GuideActionType.addLab,
  ),
  GuideArticle(
    id: 'dosing_math',
    category: GuideCategory.safety,
    readMinutes: 4,
    icon: LucideIcons.ruler,
    titleEn: 'Dosing Math: Vial Concentration (mg/mL) & Syringe Scales',
    titleId: 'Hitungan Dosis: Konsentrasi Vial (mg/mL) & Skala Spuit',
    subtitleEn:
        'Prevent 10x dosing errors by mastering mg-to-mL calculations and reading syringe markings.',
    subtitleId:
        'Cegah kesalahan dosis 10x lipat dengan memahami konversi mg ke mL dan membaca garis spuit.',
    takeawaysEn: [
      'Formula: Volume to draw (mL) = Desired dose (mg) ÷ Vial concentration (mg/mL).',
      'The same 4 mg dose needs 0.4 mL from a 10 mg/mL vial, 0.2 mL from a 20 mg/mL vial, and only 0.1 mL from a 40 mg/mL vial.',
      'Always double-check whether syringe numbers are in mL or insulin "Units" (100 IU = 1 mL).',
    ],
    takeawaysId: [
      'Rumus: Volume tarikan (mL) = Dosis target (mg) ÷ Konsentrasi vial (mg/mL).',
      'Dosis 4 mg yang sama membutuhkan 0,4 mL dari vial 10 mg/mL, 0,2 mL dari vial 20 mg/mL, dan hanya 0,1 mL dari vial 40 mg/mL.',
      'Selalu pastikan apakah angka pada spuit menunjukkan mL atau "Unit" insulin (100 IU = 1 mL).',
    ],
    sections: [
      GuideSection(
        headingEn: 'Step-by-step mg to mL examples',
        headingId: 'Contoh konversi mg ke mL langkah demi langkah',
        paragraphsEn: [
          'Vials list concentration as milligrams per milliliter (mg/mL). Changing brands or concentrations changes the volume you must draw even when your dose in mg stays identical.',
        ],
        paragraphsId: [
          'Label vial mencantumkan konsentrasi dalam miligram per mililiter (mg/mL). Mengganti merek atau konsentrasi berarti mengubah volume mL yang ditarik meski dosis dalam mg tetap sama.',
        ],
        bulletsEn: [
          'Example A (E2 Valerate 20 mg/mL, dose 4 mg): 4 ÷ 20 = 0.20 mL.',
          'Example B (E2 Enanthate 40 mg/mL, dose 5 mg): 5 ÷ 40 = 0.125 mL.',
          'Example C (T Enanthate 250 mg/mL, dose 75 mg): 75 ÷ 250 = 0.30 mL.',
        ],
        bulletsId: [
          'Contoh A (E2 Valerate 20 mg/mL, dosis 4 mg): 4 ÷ 20 = 0,20 mL.',
          'Contoh B (E2 Enanthate 40 mg/mL, dosis 5 mg): 5 ÷ 40 = 0,125 mL.',
          'Contoh C (T Enanthate 250 mg/mL, dosis 75 mg): 75 ÷ 250 = 0,30 mL.',
        ],
      ),
      GuideSection(
        headingEn: 'Choosing & reading the right syringe size',
        headingId: 'Memilih & membaca ukuran spuit yang tepat',
        bulletsEn: [
          'For small volumes (under 0.5 mL, very common with concentrated E2 vials), a 1 mL syringe is far more accurate than a 3 mL syringe and wastes less oil in dead space.',
          'On a 1 mL (U-100 insulin) syringe: 0.10 mL = "10 units", 0.25 mL = "25 units". Do NOT confuse 0.1 mL with 0.01 mL.',
          'Inspect the vial before every draw: oil should be clear/pale yellow without floating particles or cloudiness. (Gentle hand-warming dissolves cold-weather crystals, never microwave or boil.)',
        ],
        bulletsId: [
          'Untuk volume kecil (di bawah 0,5 mL, sangat umum pada vial E2 berkonsentrasi tinggi), spuit 1 mL jauh lebih presisi daripada spuit 3 mL serta mengurangi sisa minyak terbuang (dead space).',
          'Pada spuit insulin 1 mL (U-100): 0,10 mL = "10 unit", 0,25 mL = "25 unit". Jangan sampai tertukar antara 0,1 mL dan 0,01 mL.',
          'Periksa isi vial sebelum menarik: minyak harus jernih/kuning pucat tanpa serpihan mengambang atau keruh. (Jika terbentuk kristal karena suhu dingin, hangatkan perlahan di telapak tangan—jangan pernah direbus atau di-microwave.)',
        ],
      ),
    ],
    references: [
      'UCSF Transgender Care Guidelines — Injection Administration & Dosing Safety',
      'WHO Best Practices for Injections and Related Procedures Toolkit',
    ],
  ),
  GuideArticle(
    id: 'safe_injection',
    category: GuideCategory.safety,
    readMinutes: 5,
    icon: LucideIcons.syringe,
    titleEn: 'Safe & Sterile Injection Guide',
    titleId: 'Panduan Suntik Aman & Steril',
    subtitleEn:
        'Aseptic steps, IM vs SubQ needle selection, drying alcohol, and preventing vial coring.',
    subtitleId:
        'Langkah aseptik, pemilihan jarum IM vs SubQ, menunggu alkohol kering, dan mencegah kerusakan tutup karet vial.',
    takeawaysEn: [
      'Wash hands, swab both the vial stopper and skin with 70% alcohol, and wait 30 seconds until dry before inserting.',
      'Use every needle and syringe strictly once—never re-insert a needle that touched skin back into a multi-dose vial.',
      'Swapping to a fresh needle after drawing keeps the tip razor-sharp for a gentler injection.',
    ],
    takeawaysId: [
      'Cuci tangan, usap tutup karet vial dan kulit dengan alkohol 70%, lalu tunggu 30 detik hingga kering sebelum menusuk.',
      'Gunakan setiap jarum dan spuit mutlak satu kali pakai—jangan pernah memasukkan kembali jarum yang sudah menyentuh kulit ke dalam vial.',
      'Mengganti jarum baru setelah menarik obat menjaga ujung jarum tetap tajam sehingga suntikan jauh lebih nyaman.',
    ],
    sections: [
      GuideSection(
        headingEn: 'IM vs. Subcutaneous (SubQ)',
        headingId: 'IM (Intramuskular) vs. SubQ (Subkutan)',
        bulletsEn: [
          'Intramuscular (IM): goes into deeper muscle (vastus lateralis thigh or ventrogluteal hip), typically 23G–25G needle, 1 to 1.5 inch length, inserted at 90°.',
          'Subcutaneous (SubQ): goes into the fat layer (abdomen at least 5 cm from navel, or outer thigh), typically 25G–30G needle, 1/2 to 5/8 inch length, inserted at 45°–90°. Works well for smaller oil volumes (< 0.5–1 mL).',
          'Draw needle: 18G–22G makes thick oil easier to draw; avoid 18G if your rubber stopper is thin, as oversized needles can punch rubber bits ("coring") into the vial. Insert at ~45° bevel-up to prevent coring.',
        ],
        bulletsId: [
          'Intramuskular (IM): disuntikkan ke otot dalam (paha samping vastus lateralis atau pinggul ventrogluteal), umumnya jarum 23G–25G panjang 1–1,5 inci, sudut 90°.',
          'Subkutan (SubQ): disuntikkan ke lapisan lemak (perut berjarak ≥ 5 cm dari pusar, atau paha luar), umumnya jarum 25G–30G panjang 1/2–5/8 inci, sudut 45°–90°. Nyaman untuk volume minyak kecil (< 0,5–1 mL).',
          'Jarum penarik (draw needle): 18G–22G memudahkan menarik minyak kental; hindari 18G jika karet vial tipis karena bisa merobek serpihan karet ke dalam botol (coring). Tusuk dengan sudut ~45° dengan lubang jarum menghadap atas untuk mencegah coring.',
        ],
      ),
      GuideSection(
        headingEn: 'Core sterile checklist',
        headingId: 'Daftar periksa sterilitas inti',
        bulletsEn: [
          'Clean surface & wash hands thoroughly with soap and water for at least 20 seconds.',
          'Wipe the vial rubber top with a fresh alcohol swab and let it air-dry completely.',
          'Swab the chosen skin site in an outward spiral and wait 30 seconds until dry (wet alcohol stings and carries surface bacteria inward).',
          'Push the plunger slowly and steadily; wait 5–10 seconds before withdrawing so oil stays inside.',
          'Apply gentle pressure with clean gauze or cotton—do not rub vigorously—and immediately drop uncapped sharps into a hard disposal container.',
        ],
        bulletsId: [
          'Bersihkan permukaan meja dan cuci tangan dengan sabun serta air minimal 20 detik.',
          'Usap tutup karet vial dengan alcohol swab baru dan biarkan mengering alami.',
          'Usap area kulit dengan gerakan melingkar dari dalam ke luar lalu tunggu 30 detik hingga kering (alkohol basah menimbulkan perih dan dapat membawa bakteri permukaan masuk).',
          'Tekan plunger perlahan dan stabil; tahan 5–10 detik sebelum mencabut jarum agar minyak tidak merembes keluar.',
          'Tekan lembut dengan kasa/kapas bersih—jangan digosok keras—lalu langsung masukkan jarum bekas tanpa ditutup ulang ke wadah keras tahan tusuk.',
        ],
        callout: GuideCallout(
          type: GuideCalloutType.tip,
          titleEn: 'Nervous before injecting?',
          titleId: 'Merasa tegang atau cemas sebelum menyuntik?',
          bodyEn:
              'Use Lunera\'s Guided Calm Injection tool in the More tab—it includes slow breathing pacing and a built-in 30-second alcohol drying timer.',
          bodyId:
              'Gunakan fitur Guided Calm Injection di tab More—tersedia panduan napas tenang dan timer pengeringan alkohol 30 detik.',
        ),
      ),
    ],
    references: [
      'WHO Best Practices for Injections and Related Procedures Toolkit',
      'Fenway Health — Self-Injection Guide for Hormone Therapy',
    ],
    action: GuideActionType.siteMap,
  ),
  GuideArticle(
    id: 'site_rotation',
    category: GuideCategory.safety,
    readMinutes: 3,
    icon: LucideIcons.bandage,
    titleEn: 'Site Rotation, Tissue Health & Sharps Disposal',
    titleId: 'Rotasi Titik Suntik, Kesehatan Jaringan & Pembuangan Jarum',
    subtitleEn:
        'Give each injection zone time to heal and keep used needles safe at home.',
    subtitleId:
        'Beri waktu pulih bagi tiap area jaringan dan kelola limbah jarum bekas secara aman di rumah.',
    takeawaysEn: [
      'Repeatedly injecting the exact same spot causes scar tissue, pain, lumps, and uneven hormone absorption.',
      'Rotating across at least 4 sites gives tissues plenty of rest between doses.',
      'Never throw loose needles into household trash or recycling.',
    ],
    takeawaysId: [
      'Menyuntik titik yang sama berulang kali memicu jaringan parut, benjolan, nyeri, dan penyerapan hormon yang tidak merata.',
      'Merotasi minimal 4 lokasi memberi waktu istirahat yang cukup bagi jaringan antar dosis.',
      'Jangan pernah membuang jarum lepas langsung ke tempat sampah rumah tangga.',
    ],
    sections: [
      GuideSection(
        headingEn: 'Why tissue rest matters',
        headingId: 'Mengapa jaringan butuh waktu istirahat',
        paragraphsEn: [
          'Every injection creates tiny localized inflammation while your body absorbs the carrier oil. Giving each site days to weeks to recover keeps tissues soft and absorption predictable.',
          'Lunera\'s Site Rotation Map automatically marks recently used areas as "Resting" and suggests the site that has rested longest.',
        ],
        paragraphsId: [
          'Setiap suntikan memicu peradangan mikro lokal selama tubuh menyerap minyak pembawa. Memberi jeda beberapa hari hingga minggu menjaga jaringan tetap lunak dan penyerapan konsisten.',
          'Peta Rotasi Suntik di Lunera otomatis menandai lokasi yang baru dipakai sebagai "Istirahat" dan merekomendasikan titik yang paling lama beristirahat.',
        ],
      ),
      GuideSection(
        headingEn: 'Safe sharps disposal anywhere',
        headingId: 'Pembuangan jarum bekas yang aman',
        bulletsEn: [
          'Use an approved red sharps container if available. If unavailable, use a thick-walled, puncture-resistant plastic bottle with a tight screw cap (like a heavy laundry detergent bottle) clearly taped and labeled "DO NOT RECYCLE — SHARPS".',
          'Never recap used needles with both hands—drop them directly into the container immediately after withdrawing.',
          'Follow local clinic, pharmacy, or municipal hazardous-waste take-back guidelines when 3/4 full.',
        ],
        bulletsId: [
          'Gunakan wadah limbah tajam medis (safety box) jika tersedia. Jika tidak ada, gunakan botol plastik tebal tahan tusuk bertutup ulir rapat (seperti botol deterjen cair tebal) yang disegel lakban dan diberi label jelas "LIMBAH TAJAM — JANGAN DIDAUR ULANG".',
          'Jangan menutup ulang (recap) jarum bekas dengan dua tangan—langsung jatuhkan ke wadah begitu selesai dipakai.',
          'Serahkan ke fasilitas kesehatan, puskesmas, apotek, atau layanan pengumpulan limbah medis setempat saat wadah sudah 3/4 penuh.',
        ],
      ),
    ],
    references: [
      'CDC Safe Community Needle Disposal Guidelines',
      'WHO Best Practices for Injections and Related Procedures Toolkit',
    ],
    action: GuideActionType.siteMap,
  ),
  GuideArticle(
    id: 'medical_red_flags',
    category: GuideCategory.safety,
    readMinutes: 4,
    icon: LucideIcons.triangleAlert,
    titleEn: 'Medical Red Flags: When to Seek Urgent Care',
    titleId: 'Tanda Bahaya Medis: Kapan Harus Segera ke IGD/Dokter',
    subtitleEn:
        'Serious warning signs that should never be waited out, regardless of how you access HRT.',
    subtitleId:
        'Gejala serius yang tidak boleh ditunggu reda sendiri, terlepas dari bagaimana kamu mengakses HRT.',
    takeawaysEn: [
      'A swollen, warm, painful single leg, chest pain, or sudden shortness of breath requires immediate emergency care.',
      'Spreading redness, warmth, pus, or fever after an injection signals a possible infection—do not wait.',
      'Seek help right away for hives, throat tightness, yellowing eyes/skin, or overwhelming suicidal crisis.',
    ],
    takeawaysId: [
      'Satu betis/kaki bengkak hangat dan nyeri, nyeri dada, atau sesak napas mendadak memerlukan penanganan IGD segera.',
      'Kemerahan yang meluas, teraba panas, nanah, atau demam setelah suntik menandakan kemungkinan infeksi—jangan ditunda.',
      'Segera cari pertolongan medis jika muncul biduran/sesak alergi, mata/kulit menguning, atau krisis emosional berat.',
    ],
    sections: [
      GuideSection(
        headingEn: 'Emergency symptoms — go to the ER immediately',
        headingId: 'Gejala darurat — segera ke IGD rumah sakit',
        bulletsEn: [
          'Deep Vein Thrombosis (DVT) / Pulmonary Embolism: swelling, throbbing pain, warmth, or redness in one calf/thigh; sudden shortness of breath, sharp chest pain when breathing, or coughing blood.',
          'Stroke signs: sudden severe headache with vision loss, slurred speech, facial droop, or one-sided weakness.',
          'Severe allergic reaction (anaphylaxis) to carrier oil or medication: hives, lip/tongue swelling, wheezing, or dizziness.',
        ],
        bulletsId: [
          'Pembekuan darah (DVT / Emboli Paru): bengkak, nyeri berdenyut, panas, atau kemerahan pada satu betis/paha; sesak napas mendadak, nyeri dada tajam saat menarik napas, atau batuk berdarah.',
          'Tanda stroke: sakit kepala berat mendadak disertai gangguan penglihatan, bicara pelo, wajah mencong, atau lemas di satu sisi tubuh.',
          'Reaksi alergi berat (anafilaksis) terhadap minyak pembawa atau obat: biduran menyeluruh, bibir/lidah bengkak, napas berbunyi mengi, atau pusing hampir pingsan.',
        ],
        callout: GuideCallout(
          type: GuideCalloutType.warning,
          titleEn: 'Your safety comes before privacy fears',
          titleId: 'Keselamatanmu jauh lebih utama daripada rasa takut',
          bodyEn:
              'Emergency clinicians need accurate information about what medications you have taken so they can treat you safely. Never delay emergency care for a blood clot, infection, or allergic reaction.',
          bodyId:
              'Dokter IGD membutuhkan informasi akurat tentang obat apa yang kamu gunakan agar bisa menangani secara tepat. Jangan pernah menunda ke IGD saat ada dugaan pembekuan darah, infeksi, atau alergi berat.',
        ),
      ),
      GuideSection(
        headingEn: 'Prompt medical evaluation (within 24–48 hours)',
        headingId: 'Evaluasi medis segera (dalam 24–48 jam)',
        bulletsEn: [
          'Infection / Abscess at injection site: redness expanding outward, intense localized heat, throbbing tenderness, pus, or fever. (Mild soreness for 1–2 days without spreading heat or fever is usually normal tissue irritation.)',
          'Liver warning signs (especially on oral meds, CPA, or bicalutamide): dark tea-colored urine, yellowing skin or eyes (jaundice), persistent upper-right abdominal pain.',
          'Mental health crisis: if severe depression, panic, or self-harm thoughts arise, reach out to a trusted person, local crisis hotline, or healthcare professional immediately.',
        ],
        bulletsId: [
          'Infeksi / Abses di titik suntik: kemerahan meluas (bisa ditandai batasnya dengan pulpen), terasa sangat panas, nyeri berdenyut hebat, keluar nanah, atau demam. (Pegel ringan 1–2 hari tanpa panas meluas atau demam umumnya hanya iritasi otot biasa.)',
          'Tanda gangguan hati (terutama pada obat oral, CPA, atau bicalutamide): urine berwarna gelap seperti teh pekat, kulit/bagian putih mata menguning, nyeri perut kanan atas yang menetap.',
          'Krisis kesehatan mental: jika muncul depresi berat, panik tak terkendali, atau dorongan menyakiti diri, segera hubungi orang tepercaya, layanan konseling krisis, atau tenaga profesional.',
        ],
      ),
    ],
    references: [
      'Endocrine Society Clinical Practice Guideline (2017)',
      'UCSF Transgender Care Guidelines — Adverse Effects & Monitoring',
    ],
  ),
];
