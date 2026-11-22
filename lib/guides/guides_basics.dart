part of '../guides_data.dart';

const List<GuideArticle> _guidesBasics = [
  GuideArticle(
    id: 'start_safely',
    category: GuideCategory.safety,
    isStartHere: true,
    readMinutes: 5,
    icon: LucideIcons.compass,
    titleEn: 'Starting HRT Safely & Navigating Independently',
    titleId: 'Memulai HRT dengan Aman & Menavigasi Secara Mandiri',
    subtitleEn:
        'A calm, non-judgmental starting point when access, money, or support feels out of reach.',
    subtitleId:
        'Titik awal yang tenang tanpa menghakimi saat akses medis, biaya, atau dukungan lingkungan terbatas.',
    takeawaysEn: [
      'Your path is valid whether you work with an affirming clinician or navigate care on your own.',
      'Higher doses do not speed up physical changes; steady, physiological levels protect your health and budget.',
      'Never compromise on single-use sterile needles, avoid ethinylestradiol birth control pills, and protect your digital privacy.',
    ],
    takeawaysId: [
      'Perjalananmu tetap valid, baik didampingi dokter maupun saat kamu harus menavigasi perawatan secara mandiri.',
      'Dosis lebih tinggi tidak mempercepat perubahan tubuh; kadar stabil dalam rentang fisiologis justru menjaga kesehatan dan biaya.',
      'Jangan pernah berkompromi soal jarum steril sekali pakai, hindari pil KB ethinylestradiol, dan lindungi privasi digitalmu.',
    ],
    sections: [
      GuideSection(
        headingEn: 'Take a breath — you do not have to rush',
        headingId: 'Tarik napas dulu — kamu tidak harus terburu-buru',
        paragraphsEn: [
          'When dysphoria is heavy and your environment feels unsupportive, it is completely understandable to feel desperate to start immediately. However, rushing without basic safety knowledge increases medical risk without giving faster results.',
          'Hormone therapy works at the pace of your biology over months and years. Starting carefully with accurate tracking protects both your long-term health and your peace of mind.',
        ],
        paragraphsId: [
          'Saat disforia terasa berat dan lingkungan sekitar belum mendukung, sangat wajar jika muncul rasa mendesak untuk segera memulai. Namun, terburu-buru tanpa memahami dasar keselamatan justru meningkatkan risiko kesehatan tanpa membuat hasil lebih cepat.',
          'Terapi hormon bekerja mengikuti ritme biologi tubuh selama berbulan-bulan hingga bertahun-tahun. Memulai dengan tenang dan pencatatan yang rapi melindungi kesehatan jangka panjang sekaligus ketenangan pikiranmu.',
        ],
        callout: GuideCallout(
          type: GuideCalloutType.tip,
          titleEn: 'More is not faster',
          titleId: 'Lebih banyak tidak berarti lebih cepat',
          bodyEn:
              'Taking excessive doses will not accelerate breast growth, voice changes, or fat redistribution. Above target ranges, extra hormones mainly increase side effects like blood clots, elevated prolactin, liver strain, or aromatization—and waste limited funds.',
          bodyId:
              'Menggunakan dosis berlebih tidak mempercepat pertumbuhan payudara, perubahan suara, maupun distribusi lemak. Di atas rentang target, kelebihan hormon terutama menaikkan risiko efek samping seperti pembekuan darah, lonjakan prolaktin, beban hati, atau aromatisasi—serta memboroskan biaya.',
        ),
      ),
      GuideSection(
        headingEn: 'Critical safety checks on a tight budget',
        headingId: 'Prioritas keselamatan saat anggaran terbatas',
        paragraphsEn: [
          'If money is tight or medical access is limited, focus your resources on the things that prevent irreversible harm:',
        ],
        paragraphsId: [
          'Jika dana terbatas atau akses medis sulit dijangkau, prioritaskan hal-hal yang paling penting untuk mencegah risiko fatal:',
        ],
        bulletsEn: [
          'Avoid synthetic birth control pills (ethinylestradiol): combined oral contraceptives carry a substantially higher blood clot and stroke risk than bioidentical estradiol (hemihydrate, valerate, cypionate, enanthate).',
          'Never reuse or share needles, syringes, or alcohol swabs: sterile supplies are inexpensive compared to treating an abscess or bloodstream infection.',
          'Know your baseline and focus lab tests: if you can only afford minimal bloodwork, test at trough (right before your next dose) after 1–3 months on a steady routine so one test gives maximum clarity.',
          'Verify concentrations clearly: always confirm whether a vial is 10 mg/mL, 20 mg/mL, 40 mg/mL, or 250 mg/mL before drawing a dose.',
        ],
        bulletsId: [
          'Hindari pil KB sintetis (ethinylestradiol): pil kontrasepsi kombinasi memiliki risiko pembekuan darah dan stroke jauh lebih tinggi dibanding estradiol bioidentik (hemihydrate, valerate, cypionate, enanthate).',
          'Jangan pernah memakai ulang atau berbagi jarum, spuit, maupun alcohol swab: perlengkapan steril jauh lebih murah daripada biaya mengobati abses atau infeksi berat.',
          'Fokuskan tes lab agar hemat dan bermakna: jika anggaran sangat terbatas, lakukan cek darah pada titik trough (tepat sebelum dosis berikutnya) setelah 1–3 bulan rutinitas stabil agar satu kali tes memberi gambaran paling akurat.',
          'Pastikan konsentrasi vial dengan teliti: selalu cek apakah vial berkonsentrasi 10 mg/mL, 20 mg/mL, 40 mg/mL, atau 250 mg/mL sebelum menarik cairan.',
        ],
      ),
      GuideSection(
        headingEn: 'Staying safe in an unsupportive environment',
        headingId: 'Menjaga keamanan di lingkungan yang belum mendukung',
        paragraphsEn: [
          'If you live with family, roommates, or people who do not know or do not support your transition, physical and digital privacy matter just as much as medical safety.',
        ],
        paragraphsId: [
          'Jika kamu tinggal bersama keluarga, teman sekamar, atau lingkungan yang belum mengetahui maupun mendukung transaksimu, privasi fisik dan digital sama pentingnya dengan keamanan medis.',
        ],
        bulletsEn: [
          'Enable Lunera\'s 6-digit PIN Lock and Decoy Calculator camouflage in Security Settings so opening the app around others looks ordinary.',
          'Keep Discreet Notifications and Home Widget detail hiding turned on (enabled by default in Lunera) so reminders never show medication names on your lock screen.',
          'Use encrypted JSON backups with a strong passphrase if you save backups on shared devices or cloud drives.',
          'Keep medications and sharps stored safely in an opaque container away from heat, moisture, and curious hands.',
        ],
        bulletsId: [
          'Aktifkan PIN 6 digit dan kamuflase Kalkulator Penyamaran (Decoy Calculator) di Pengaturan Keamanan Lunera agar aplikasi tetap terlihat biasa saat dibuka di dekat orang lain.',
          'Pertahankan Notifikasi Discreet dan penyembunyian detail Widget Layar Utama (aktif secara bawaan di Lunera) agar nama obat tidak muncul di layar kunci.',
          'Gunakan Backup Terenkripsi dengan kata sandi kuat jika menyimpan cadangan data di perangkat bersama atau penyimpanan cloud.',
          'Simpan obat dan wadah jarum bekas di tempat tertutup yang sejuk, kering, dan jauh dari jangkauan orang lain.',
        ],
        callout: GuideCallout(
          type: GuideCalloutType.warning,
          titleEn: 'Know when to seek urgent medical care',
          titleId: 'Kenali kapan harus segera mencari pertolongan medis',
          bodyEn:
              'Even if you keep your HRT private, seek emergency medical care immediately for sudden calf swelling/pain, chest pain, shortness of breath, severe headaches with vision changes, or spreading redness/pus at an injection site.',
          bodyId:
              'Meskipun kamu menjaga privasi HRT-mu, segera cari pertolongan medis darurat jika mengalami bengkak atau nyeri hangat di satu betis, nyeri dada, sesak napas, sakit kepala hebat disertai gangguan penglihatan, atau area suntik memerah meluas dan bernanah.',
        ),
      ),
    ],
    references: [
      'WPATH Standards of Care for the Health of Transgender and Gender Diverse People, Version 8 (SOC 8)',
      'UCSF Gender Affirming Health Program — Guidelines for the Primary and Gender-Affirming Care of Transgender and Gender Nonbinary People',
      'Endocrine Society Clinical Practice Guideline: Endocrine Treatment of Gender-Dysphoric/Gender-Incongruent Persons',
    ],
    action: GuideActionType.security,
  ),
  GuideArticle(
    id: 'hrt_101',
    category: GuideCategory.basics,
    readMinutes: 4,
    icon: LucideIcons.pill,
    titleEn: 'HRT 101: Estradiol, Testosterone & Blockers',
    titleId: 'Dasar HRT: Cara Kerja Estradiol, Testosteron & Blocker',
    subtitleEn:
        'How feminizing and masculinizing therapies shift your endocrine balance safely.',
    subtitleId:
        'Bagaimana terapi feminisasi dan maskulinisasi menggeser keseimbangan hormon secara bertahap.',
    takeawaysEn: [
      'Your body responds to hormone balance—raising target hormone levels while suppressing the endogenous dominant hormone.',
      'Feminizing therapy pairs bioidentical Estradiol with either an anti-androgen or sufficient E2 monotherapy.',
      'Masculinizing therapy relies on Testosterone, which naturally suppresses ovarian estradiol production over time.',
    ],
    takeawaysId: [
      'Tubuh merespons keseimbangan hormon—menaikkan hormon target sekaligus menekan hormon dominan bawaan.',
      'Terapi feminisasi memadukan Estradiol bioidentik dengan anti-androgen, atau menggunakan monoterapi E2 yang stabil.',
      'Terapi maskulinisasi menggunakan Testosteron, yang secara alami menekan produksi estradiol tubuh seiring waktu.',
    ],
    sections: [
      GuideSection(
        headingEn: 'How the HPG axis responds',
        headingId: 'Bagaimana poros hormon (HPG axis) merespons',
        paragraphsEn: [
          'Your pituitary gland regulates hormone production using LH and FSH signals. When steady bioidentical estradiol or testosterone enters the bloodstream, the pituitary sees enough sex hormone and dials down LH and FSH—which lowers endogenous testosterone or estrogen.',
        ],
        paragraphsId: [
          'Kelenjar pituitari mengatur produksi hormon melalui sinyal LH dan FSH. Saat estradiol atau testosteron bioidentik masuk secara stabil ke aliran darah, pituitari membaca bahwa hormon sudah cukup lalu menurunkan LH dan FSH—sehingga produksi hormon bawaan ikut turun.',
        ],
      ),
      GuideSection(
        headingEn: 'Common compounds in Lunera',
        headingId: 'Senyawa yang umum digunakan di Lunera',
        bulletsEn: [
          'Estradiol (E2): bioidentical estrogen (valerate, cypionate, enanthate, undecylate, benzoate, hemihydrate, or transdermal gel) that drives feminizing tissue changes.',
          'Testosterone (T): bioidentical testosterone (enanthate, cypionate, undecanoate, propionate, or gel) that drives masculinizing changes.',
          'Cyproterone acetate (CPA): potent progestin anti-androgen that suppresses LH/FSH and blocks androgen receptors; clinical guidelines favor low doses due to prolactin and rare meningioma risks at high cumulative exposure.',
          'Spironolactone: blocks androgen receptors and lowers testosterone activity while acting as a potassium-sparing diuretic.',
          'Bicalutamide: blocks androgen receptors without lowering serum T directly—meaning blood T numbers stay higher even though receptors are blocked; liver enzyme monitoring is important.',
          'GnRH agonists (e.g., Leuprorelin): halt LH/FSH signaling cleanly with minimal systemic side effects.',
          'Micronized Progesterone (P4): sometimes added later in feminizing regimens; evidence on long-term breast shape effects remains largely anecdotal.',
        ],
        bulletsId: [
          'Estradiol (E2): estrogen bioidentik (valerate, cypionate, enanthate, undecylate, benzoate, hemihydrate, atau gel transdermal) yang mendorong perubahan feminisasi.',
          'Testosteron (T): testosteron bioidentik (enanthate, cypionate, undecanoate, propionate, atau gel) yang mendorong perubahan maskulinisasi.',
          'Cyproterone acetate (CPA): anti-androgen progestin kuat yang menekan LH/FSH; pedoman klinis menyarankan dosis serendah mungkin karena risiko prolaktin dan meningioma pada paparan kumulatif tinggi.',
          'Spironolactone: memblokir reseptor androgen sekaligus bersifat diuretik hemat kalium (perlu memperhatikan kadar kalium & hidrasi).',
          'Bicalutamide: memblokir reseptor androgen tanpa menurunkan angka T di hasil lab—artinya angka T darah tetap terbaca tinggi meski efeknya terblokir; pemantauan fungsi hati sangat penting.',
          'Agonis GnRH (mis. Leuprorelin): menghentikan sinyal LH/FSH secara bersih dengan efek samping sistemik minimal.',
          'Micronized Progesterone (P4): kadang ditambahkan pada fase lanjutan terapi feminisasi; bukti ilmiah mengenai pengaruhnya pada bentuk payudara masih terbatas.',
        ],
      ),
    ],
    references: [
      'Endocrine Society Clinical Practice Guideline (2017)',
      'WPATH Standards of Care Version 8 (SOC 8)',
      'UCSF Transgender Care & Treatment Guidelines',
    ],
  ),
  GuideArticle(
    id: 'routes_compared',
    category: GuideCategory.basics,
    readMinutes: 4,
    icon: LucideIcons.layers,
    titleEn: 'Routes Compared: Oral, Sublingual, Gel, Patch & Injections',
    titleId: 'Perbandingan Rute: Oral, Sublingual, Gel, Patch & Injeksi',
    subtitleEn:
        'How administration routes differ in absorption, liver processing, and everyday safety.',
    subtitleId:
        'Perbedaan penyerapan, metabolisme hati, dan keamanan praktis tiap cara pemakaian obat.',
    takeawaysEn: [
      'Swallowed oral estradiol passes through the liver first, creating higher estrone (E1) and slightly higher clot risk than non-oral routes.',
      'Sublingual, transdermal (gel/patch), and injectable routes bypass first-pass liver metabolism.',
      'Transdermal gel requires skin-transfer precautions around partners, children, and pets.',
    ],
    takeawaysId: [
      'Estradiol oral yang ditelan melewati hati terlebih dahulu (first-pass), menghasilkan lebih banyak estron (E1) dan sedikit menaikkan risiko trombosis dibanding rute non-oral.',
      'Rute sublingual, transdermal (gel/patch), dan injeksi melewati metabolisme awal di hati.',
      'Gel transdermal memerlukan kehati-hatian agar tidak berpindah lewat kontak kulit ke pasangan, anak, atau hewan peliharaan.',
    ],
    sections: [
      GuideSection(
        headingEn: 'Oral vs. Sublingual tablets',
        headingId: 'Tablet Oral vs. Sublingual',
        paragraphsEn: [
          'When an estradiol tablet is swallowed (oral), it travels through the digestive tract to the liver before entering general circulation. Much of it converts into estrone (E1), a weaker estrogen, and stimulates liver clotting proteins.',
          'Dissolving micronized estradiol hemihydrate under the tongue (sublingual) lets a portion absorb directly into oral blood vessels, producing higher short-term E2 peaks with less liver strain—though levels drop faster, so doses are commonly split across the day.',
        ],
        paragraphsId: [
          'Saat tablet estradiol ditelan (oral), obat melewati saluran cerna dan hati sebelum masuk ke peredaran darah umum. Sebagian besar berubah menjadi estron (E1) yang lebih lemah dan merangsang faktor pembekuan hati.',
          'Melarutkan tablet estradiol hemihydrate di bawah lidah (sublingual) memungkinkan sebagian hormon langsung diserap pembuluh darah mulut sehingga puncak E2 lebih tinggi dengan beban hati lebih kecil—meski kadarnya juga turun lebih cepat sehingga sering dibagi beberapa kali sehari.',
        ],
      ),
      GuideSection(
        headingEn: 'Transdermal Gel & Patches',
        headingId: 'Gel Transdermal & Patch',
        paragraphsEn: [
          'Transdermal patches and gels (both E2 and T) deliver hormones steadily through the skin without liver first-pass effects, making them especially friendly for people with higher clot risk or smokers.',
        ],
        paragraphsId: [
          'Patch dan gel transdermal (baik E2 maupun T) menyalurkan hormon secara bertahap lewat kulit tanpa melewati metabolisme awal di hati, sehingga lebih aman bagi pemilik risiko pembekuan darah atau perokok.',
        ],
        bulletsEn: [
          'Apply gel to clean, dry skin (typically inner thighs, upper arms, or shoulders depending on product) and never to chest/breast tissue.',
          'Wash hands thoroughly with soap immediately after applying gel, and wait until completely dry before dressing or skin contact with others or pets.',
        ],
        bulletsId: [
          'Oleskan gel pada kulit bersih dan kering (umumnya paha bagian dalam, lengan atas, atau bahu sesuai jenis produk), jangan pernah di area dada/payudara.',
          'Cuci tangan bersih dengan sabun segera setelah mengoleskan gel, dan tunggu hingga benar-benar kering sebelum berpakaian atau bersentuhan kulit dengan orang lain maupun hewan peliharaan.',
        ],
      ),
      GuideSection(
        headingEn: 'Injections (IM & SubQ)',
        headingId: 'Injeksi (IM & SubQ)',
        paragraphsEn: [
          'Oil-based injections create a depot in muscle or subcutaneous fat that releases hormone over days or weeks. They bypass the liver, offer high bioavailability, and avoid daily pills—at the cost of needles and ester-dependent peaks and troughs.',
        ],
        paragraphsId: [
          'Injeksi berbasis minyak membentuk depot di otot atau jaringan lemak bawah kulit yang melepas hormon perlahan selama beberapa hari hingga minggu. Rute ini melewati hati, memiliki bioavailabilitas tinggi, dan bebas pil harian—dengan konsekuensi perlu teknik suntik steril serta fluktuasi peak-trough.',
        ],
      ),
    ],
    references: [
      'UCSF Transgender Care Guidelines — Overview of Feminizing & Masculinizing Medications',
      'Endocrine Society Clinical Practice Guideline (2017)',
    ],
  ),
  GuideArticle(
    id: 'esters_halflife',
    category: GuideCategory.basics,
    readMinutes: 4,
    icon: LucideIcons.clock,
    titleEn: 'Understanding Injection Esters & Half-Life',
    titleId: 'Memahami Ester Injeksi & Waktu Paruh (Half-Life)',
    subtitleEn:
        'Why benzoate, valerate, cypionate, enanthate, and undecylate need different schedules.',
    subtitleId:
        'Mengapa benzoate, valerate, cypionate, enanthate, dan undecylate memiliki jadwal suntik berbeda.',
    takeawaysEn: [
      'The ester chain controls how slowly your body releases the hormone from the injection depot—not what the active hormone does.',
      'Shorter half-life esters rise fast and drop fast, requiring shorter intervals to avoid harsh mood or energy crashes.',
      'Longer esters build up slowly and require patience to reach steady state.',
    ],
    takeawaysId: [
      'Rantai ester menentukan seberapa lambat tubuh melepas hormon dari depot suntikan—bukan mengubah fungsi hormon aktifnya.',
      'Ester dengan waktu paruh pendek naik dan turun cepat, sehingga butuh interval lebih rapat agar tidak mengalami drop energi/mood.',
      'Ester panjang menumpuk secara perlahan dan butuh kesabaran untuk mencapai kadar stabil (steady state).',
    ],
    sections: [
      GuideSection(
        headingEn: 'Estradiol (E2) injection esters',
        headingId: 'Ester injeksi Estradiol (E2)',
        bulletsEn: [
          'Estradiol Benzoate: very short depot (~1–2 days half-life); produces sharp spikes and drops unless dosed frequently.',
          'Estradiol Valerate (EV): medium-short half-life (~3.5–5 days); commonly dosed every 3.5 to 7 days because weekly intervals often produce low troughs by day 6–7.',
          'Estradiol Cypionate (EC) & Enanthate (EEn): medium-long half-life (~6–8 days); smoother weekly or 7–10 day curves.',
          'Estradiol Undecylate (EUn): very long half-life (~2–3+ weeks); takes longer to build up and longer to clear if adjustments are needed.',
        ],
        bulletsId: [
          'Estradiol Benzoate: depot sangat pendek (waktu paruh ~1–2 hari); cepat naik-turun jika tidak disuntik sangat sering.',
          'Estradiol Valerate (EV): waktu paruh pendek-menengah (~3,5–5 hari); umumnya memiliki kurva yang jauh lebih rata pada interval 3,5–5 hari dibanding mingguan penuh.',
          'Estradiol Cypionate (EC) & Enanthate (EEn): waktu paruh menengah-panjang (~6–8 hari); menghasilkan kurva mingguan hingga 7–10 hari yang lebih landai.',
          'Estradiol Undecylate (EUn): waktu paruh sangat panjang (~2–3+ minggu); butuh waktu lebih lama untuk stabil maupun turun jika dosis perlu diubah.',
        ],
      ),
      GuideSection(
        headingEn: 'Testosterone (T) injection esters',
        headingId: 'Ester injeksi Testosteron (T)',
        bulletsEn: [
          'Testosterone Propionate: short half-life (~1–2 days); rapid peaks and troughs.',
          'Testosterone Cypionate & Enanthate: medium half-life (~4.5–8 days); standard weekly or biweekly depot esters.',
          'Testosterone Undecanoate (e.g., Nebido): ultra-long depot used on multi-week medical schedules after a loading phase.',
        ],
        bulletsId: [
          'Testosterone Propionate: waktu paruh pendek (~1–2 hari); naik dan turun cepat.',
          'Testosterone Cypionate & Enanthate: waktu paruh menengah (~4,5–8 hari); ester standar untuk jadwal mingguan.',
          'Testosterone Undecanoate (mis. Nebido): depot sangat panjang untuk jadwal multi-minggu setelah fase awal.',
        ],
        callout: GuideCallout(
          type: GuideCalloutType.tip,
          titleEn: 'Use Lunera\'s PK chart as a guide, not an absolute lab replacement',
          titleId: 'Gunakan grafik PK Lunera sebagai gambaran, bukan pengganti lab',
          bodyEn:
              'Individual metabolism, injection depth, and body composition shift real absorption rates. Bloodwork calibrates Lunera\'s curve to your actual body.',
          bodyId:
              'Metabolisme tiap orang, kedalaman suntikan, dan komposisi tubuh memengaruhi laju penyerapan nyata. Hasil lab membantu mengkalibrasi kurva Lunera ke tubuhmu sendiri.',
        ),
      ),
    ],
    references: [
      'Transfeminine Science — Injectable Estradiol Pharmacokinetics Review',
      'Endocrine Society Clinical Practice Guideline (2017)',
    ],
  ),
];
