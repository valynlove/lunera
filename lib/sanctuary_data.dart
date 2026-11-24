import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n.dart';

/// A single bilingual multiple-choice question for Safety & Dosing Sense.
class SafetyQuizQuestion {
  const SafetyQuizQuestion({
    required this.id,
    required this.questionEn,
    required this.questionId,
    required this.optionsEn,
    required this.optionsId,
    required this.correctIndex,
    required this.explanationEn,
    required this.explanationId,
    this.relatedGuideId,
  });

  final String id;
  final String questionEn;
  final String questionId;
  final List<String> optionsEn;
  final List<String> optionsId;
  final int correctIndex;
  final String explanationEn;
  final String explanationId;
  final String? relatedGuideId;

  String get question => L10n.code == 'id' ? questionId : questionEn;
  List<String> get options => L10n.code == 'id' ? optionsId : optionsEn;
  String get explanation => L10n.code == 'id' ? explanationId : explanationEn;
}

/// Twelve practical, non-judgmental safety & dosing literacy questions.
const List<SafetyQuizQuestion> safetyQuizQuestions = [
  SafetyQuizQuestion(
    id: 'math_20mg_ml',
    questionEn:
        'Your vial concentration is 20 mg/mL and your dose is 4 mg. How many mL should you draw?',
    questionId:
        'Konsentrasi vialmu adalah 20 mg/mL dan dosismu 4 mg. Berapa mL yang harus ditarik?',
    optionsEn: ['0.04 mL', '0.20 mL', '0.40 mL', '0.80 mL'],
    optionsId: ['0,04 mL', '0,20 mL', '0,40 mL', '0,80 mL'],
    correctIndex: 1,
    explanationEn:
        'Volume (mL) = Dose (mg) ÷ Concentration (mg/mL). Here 4 ÷ 20 = 0.20 mL.',
    explanationId:
        'Volume (mL) = Dosis (mg) ÷ Konsentrasi (mg/mL). Jadi 4 ÷ 20 = 0,20 mL.',
    relatedGuideId: 'dosing_math',
  ),
  SafetyQuizQuestion(
    id: 'math_40mg_ml',
    questionEn:
        'You switch to a concentrated 40 mg/mL vial for a 5 mg dose. What volume equals 5 mg?',
    questionId:
        'Kamu beralih ke vial 40 mg/mL untuk dosis 5 mg. Berapa volume yang setara 5 mg?',
    optionsEn: ['0.125 mL', '0.25 mL', '0.50 mL', '0.08 mL'],
    optionsId: ['0,125 mL', '0,25 mL', '0,50 mL', '0,08 mL'],
    correctIndex: 0,
    explanationEn:
        '5 mg ÷ 40 mg/mL = 0.125 mL. Higher-concentration vials require noticeably smaller draw volumes.',
    explanationId:
        '5 mg ÷ 40 mg/mL = 0,125 mL. Vial berkonsentrasi lebih tinggi membutuhkan volume tarikan yang jauh lebih kecil.',
    relatedGuideId: 'dosing_math',
  ),
  SafetyQuizQuestion(
    id: 'syringe_u100_scale',
    questionEn:
        'On a standard 1 mL U-100 insulin syringe (marked 0 to 100 units), which mark equals 0.25 mL?',
    questionId:
        'Pada spuit insulin 1 mL U-100 (bertanda 0 sampai 100 unit), garis mana yang setara 0,25 mL?',
    optionsEn: ['2.5 units', '25 units', '50 units', '75 units'],
    optionsId: ['2,5 unit', '25 unit', '50 unit', '75 unit'],
    correctIndex: 1,
    explanationEn:
        '100 IU on a U-100 syringe equals 1.00 mL, so 0.25 mL corresponds to the 25-unit line.',
    explanationId:
        '100 IU pada spuit U-100 setara 1,00 mL, sehingga 0,25 mL tepat berada di garis 25 unit.',
    relatedGuideId: 'dosing_math',
  ),
  SafetyQuizQuestion(
    id: 'lab_trough_timing',
    questionEn:
        'When is the most informative time to draw blood for routine hormone lab testing?',
    questionId:
        'Kapan waktu terbaik untuk mengambil sampel darah pada tes lab hormon rutin?',
    optionsEn: [
      '1 hour right after a dose',
      'Right before your next scheduled dose (at trough)',
      'Midway through the afternoon on any random day',
      'Only after skipping two full weeks',
    ],
    optionsId: [
      '1 jam tepat setelah dosis',
      'Tepat sebelum jadwal dosis berikutnya (titik trough)',
      'Sore hari secara acak di hari apa saja',
      'Hanya setelah melewatkan dua minggu penuh',
    ],
    correctIndex: 1,
    explanationEn:
        'Testing at trough measures your lowest baseline before the next dose, avoiding misleading short-term spikes.',
    explanationId:
        'Tes di titik trough mengukur kadar terendah sebelum dosis berikutnya, sehingga terhindar dari lonjakan sesaat yang mengecoh.',
    relatedGuideId: 'peak_trough',
  ),
  SafetyQuizQuestion(
    id: 'gel_lab_contamination',
    questionEn:
        'If you use transdermal hormone gel, what should you avoid on the morning of a blood test?',
    questionId:
        'Jika kamu memakai gel hormon transdermal, apa yang harus dihindari di pagi hari saat tes darah?',
    optionsEn: [
      'Drinking plain water before the test',
      'Applying gel on the arm where blood will be drawn',
      'Checking the lab unit after results arrive',
      'Washing your hands after applying gel',
    ],
    optionsId: [
      'Minum air putih sebelum tes',
      'Mengoleskan gel di lengan yang akan ditusuk jarum lab',
      'Mengecek satuan hasil lab setelah keluar',
      'Mencuci tangan setelah mengoleskan gel',
    ],
    correctIndex: 1,
    explanationEn:
        'Trace gel left on skin over the vein can severely contaminate the blood draw and produce artificially high readings.',
    explanationId:
        'Sisa gel di permukaan kulit tepat di atas pembuluh darah dapat mengkontaminasi sampel dan membuat hasil terbaca sangat tinggi palsu.',
    relatedGuideId: 'peak_trough',
  ),
  SafetyQuizQuestion(
    id: 'e2_unit_conversion',
    questionEn:
        'An Estradiol lab report shows 100 pg/mL. Roughly how much is that in pmol/L?',
    questionId:
        'Hasil lab Estradiol menunjukkan 100 pg/mL. Kira-kira berapa nilainya dalam pmol/L?',
    optionsEn: ['~27 pmol/L', '~100 pmol/L', '~367 pmol/L', '~1000 pmol/L'],
    optionsId: ['~27 pmol/L', '~100 pmol/L', '~367 pmol/L', '~1000 pmol/L'],
    correctIndex: 2,
    explanationEn:
        '1 pg/mL of Estradiol equals about 3.671 pmol/L, so 100 pg/mL is approximately 367 pmol/L.',
    explanationId:
        '1 pg/mL Estradiol setara sekitar 3,671 pmol/L, jadi 100 pg/mL kira-kira 367 pmol/L.',
    relatedGuideId: 'reading_labs',
  ),
  SafetyQuizQuestion(
    id: 'alcohol_dry_wait',
    questionEn:
        'Why should you wait ~30 seconds after swabbing your skin with alcohol before injecting?',
    questionId:
        'Mengapa sebaiknya menunggu ~30 detik setelah mengusap kulit dengan alcohol swab sebelum menyuntik?',
    optionsEn: [
      'To let the alcohol evaporate so disinfection finishes and stinging is reduced',
      'To warm up the syringe needle',
      'Because wet alcohol blocks the hormone from entering muscle',
      'It makes no difference and is optional',
    ],
    optionsId: [
      'Agar alkohol menguap sehingga disinfeksi tuntas dan rasa perih berkurang',
      'Untuk menghangatkan jarum spuit',
      'Karena alkohol basah menghalangi hormon masuk ke otot',
      'Tidak berpengaruh apa-apa dan boleh dilewati',
    ],
    correctIndex: 0,
    explanationEn:
        'Alcohol disinfects as it dries. Injecting through wet alcohol stings and can carry skin bacteria inward.',
    explanationId:
        'Alkohol bekerja mendisinfeksi saat mengering. Menusuk saat kulit masih basah terasa perih dan bisa membawa bakteri permukaan masuk.',
    relatedGuideId: 'safe_injection',
  ),
  SafetyQuizQuestion(
    id: 'single_use_needle',
    questionEn:
        'If money is tight, what is the safest rule regarding needles, syringes, and alcohol swabs?',
    questionId:
        'Saat anggaran terbatas, aturan apa yang paling aman terkait jarum, spuit, dan alcohol swab?',
    optionsEn: [
      'Rinse a needle in boiling water and reuse it once',
      'Always use each needle, syringe, and swab strictly once',
      'Wipe a used needle with alcohol before reusing it',
      'Share one multi-dose vial and needle with a trusted friend',
    ],
    optionsId: [
      'Bilas jarum dengan air mendidih lalu pakai satu kali lagi',
      'Selalu gunakan tiap jarum, spuit, dan swab mutlak satu kali pakai',
      'Usap jarum bekas dengan alkohol sebelum dipakai ulang',
      'Berbagi satu vial dan jarum dengan teman tepercaya',
    ],
    correctIndex: 1,
    explanationEn:
        'Sterile supplies are low-cost compared to treating abscesses or bloodstream infections. Never reuse or share needles.',
    explanationId:
        'Perlengkapan steril jauh lebih murah dibanding mengobati abses atau infeksi berat. Jangan pernah memakai ulang atau berbagi jarum.',
    relatedGuideId: 'safe_injection',
  ),
  SafetyQuizQuestion(
    id: 'site_rotation_reason',
    questionEn:
        'Why does rotating injection sites (for example left/right thigh and glutes) matter?',
    questionId:
        'Mengapa merotasi lokasi suntik (misal paha kiri/kanan dan bokong) itu penting?',
    optionsEn: [
      'It prevents scar tissue buildup, painful lumps, and uneven absorption',
      'It doubles the medication strength',
      'It lets you skip alcohol swabs',
      'It removes the need for lab tests',
    ],
    optionsId: [
      'Mencegah penumpukan jaringan parut, benjolan nyeri, dan penyerapan tidak merata',
      'Melipatgandakan kekuatan obat',
      'Membuatmu tidak perlu memakai alcohol swab',
      'Menghilangkan kebutuhan tes lab',
    ],
    correctIndex: 0,
    explanationEn:
        'Giving each injection zone time to heal keeps tissues healthy and keeps hormone release predictable.',
    explanationId:
        'Memberi waktu pulih bagi tiap area suntik menjaga jaringan tetap sehat dan penyerapan hormon konsisten.',
    relatedGuideId: 'site_rotation',
  ),
  SafetyQuizQuestion(
    id: 'sharps_disposal_home',
    questionEn:
        'What is the safest way to dispose of used needles if you do not have a medical red sharps box?',
    questionId:
        'Apa cara paling aman membuang jarum bekas jika belum memiliki safety box medis?',
    optionsEn: [
      'Wrap them in tissue and put them in household trash',
      'Drop uncapped sharps into a thick, puncture-resistant screw-cap plastic bottle labeled clearly',
      'Bend the needle and flush it down the toilet',
      'Leave needles loose in a plastic grocery bag',
    ],
    optionsId: [
      'Bungkus tisu lalu buang ke tempat sampah biasa',
      'Masukkan langsung ke botol plastik tebal tahan tusuk bertutup ulir rapat dan beri label jelas',
      'Bengkokkan jarum lalu buang ke kloset',
      'Taruh jarum lepas di kantong plastik belanja',
    ],
    correctIndex: 1,
    explanationEn:
        'A heavy-duty screw-cap bottle (such as a thick detergent jug) sealed and clearly labeled prevents needle-stick injuries.',
    explanationId:
        'Botol plastik tebal bertutup ulir rapat (seperti botol deterjen cair tebal) yang disegel dan diberi label mencegah risiko tertusuk jarum.',
    relatedGuideId: 'site_rotation',
  ),
  SafetyQuizQuestion(
    id: 'red_flag_er',
    questionEn:
        'Which symptom after starting HRT warrants immediate emergency medical evaluation?',
    questionId:
        'Gejala mana yang memerlukan pemeriksaan medis darurat (IGD) segera?',
    optionsEn: [
      'Mild thigh soreness for 1 day after an IM shot',
      'Swelling, warmth, and pain in one calf, or sudden chest pain and shortness of breath',
      'Slightly softer skin after 6 weeks',
      'Feeling sleepy after evening oral progesterone',
    ],
    optionsId: [
      'Pegal ringan di paha selama 1 hari setelah suntik IM',
      'Satu betis bengkak hangat dan nyeri, atau nyeri dada dan sesak napas mendadak',
      'Kulit terasa sedikit lebih halus setelah 6 minggu',
      'Merasa mengantuk setelah minum progesteron malam',
    ],
    correctIndex: 1,
    explanationEn:
        'One-sided calf swelling/warmth, chest pain, or shortness of breath can signal a blood clot (DVT/PE) and needs urgent care.',
    explanationId:
        'Bengkak/panas di satu betis, nyeri dada, atau sesak napas mendadak bisa menandakan pembekuan darah (DVT/PE) dan butuh penanganan segera.',
    relatedGuideId: 'medical_red_flags',
  ),
  SafetyQuizQuestion(
    id: 'safe_mindset_ethinyl',
    questionEn:
        'When navigating HRT independently on a tight budget, which statement is true?',
    questionId:
        'Saat menavigasi HRT secara mandiri dengan dana terbatas, pernyataan mana yang benar?',
    optionsEn: [
      'Taking extra-high doses makes physical changes happen twice as fast',
      'Combined birth control pills (ethinylestradiol) are a safe, low-risk swap for bioidentical estradiol',
      'Steady physiological dosing is safer and more effective than mega-dosing; avoid ethinylestradiol',
      'Blood tests are never useful unless you have a prescription',
    ],
    optionsId: [
      'Memakai dosis ekstra tinggi membuat perubahan fisik terjadi dua kali lebih cepat',
      'Pil KB kombinasi (ethinylestradiol) adalah pengganti yang aman dan rendah risiko untuk estradiol bioidentik',
      'Dosis fisiologis yang stabil lebih aman dan hemat daripada dosis berlebih; hindari ethinylestradiol',
      'Tes darah tidak pernah berguna jika tanpa resep dokter',
    ],
    correctIndex: 2,
    explanationEn:
        'More is not faster: mega-dosing increases side effects and wastes money, and ethinylestradiol carries much higher clot risk than bioidentical estradiol.',
    explanationId:
        'Lebih banyak tidak berarti lebih cepat: dosis berlebih menaikkan risiko efek samping dan boros biaya, sementara ethinylestradiol berisiko pembekuan darah jauh lebih tinggi.',
    relatedGuideId: 'start_safely',
  ),
];

/// Returns [count] unique quiz questions in shuffled order for a practice round.
List<SafetyQuizQuestion> pickQuizRound({
  int count = 5,
  math.Random? random,
}) {
  final pool = List<SafetyQuizQuestion>.from(safetyQuizQuestions);
  pool.shuffle(random);
  final take = count.clamp(1, pool.length);
  return pool.take(take).toList(growable: false);
}

/// Persisted state for Moonlight Lantern & Safety Quiz without punishment mechanics.
class LanternState {
  const LanternState({
    this.sparks = 0,
    this.lastSparkDay,
    this.quizBest = 0,
  });

  final int sparks;
  final String? lastSparkDay;
  final int quizBest;

  bool canLightToday([DateTime? now]) {
    final today = SanctuaryStore.dayKey(now ?? DateTime.now());
    return lastSparkDay != today;
  }

  /// Gentle visual growth stage (0..4) that only progresses forward.
  int get stage {
    if (sparks <= 0) return 0;
    if (sparks <= 2) return 1;
    if (sparks <= 6) return 2;
    if (sparks <= 13) return 3;
    return 4;
  }
}

/// Offline-only SharedPreferences store for Twilight Sanctuary.
class SanctuaryStore {
  static const _baseSparksKey = 'sanctuary.lantern_sparks';
  static const _baseLastDayKey = 'sanctuary.last_spark_day';
  static const _baseQuizBestKey = 'sanctuary.quiz_best';

  static String? _authUid() {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  static String _key(String base, [String? uid]) {
    final effectiveUid = uid ?? _authUid();
    if (effectiveUid == null || effectiveUid.trim().isEmpty) return base;
    return '${base}_$effectiveUid';
  }

  static Future<void> _migrateIfLegacy(
    SharedPreferences prefs,
    String base,
    String scopedKey,
  ) async {
    if (base != scopedKey &&
        prefs.containsKey(base) &&
        !prefs.containsKey(scopedKey)) {
      final val = prefs.get(base);
      if (val is int) {
        await prefs.setInt(scopedKey, val);
      } else if (val is String) {
        await prefs.setString(scopedKey, val);
      }
      await prefs.remove(base);
    }
  }

  static String dayKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static Future<LanternState> load([String? uid]) async {
    final prefs = await SharedPreferences.getInstance();
    final sparksKey = _key(_baseSparksKey, uid);
    final lastDayKey = _key(_baseLastDayKey, uid);
    final quizBestKey = _key(_baseQuizBestKey, uid);
    await _migrateIfLegacy(prefs, _baseSparksKey, sparksKey);
    await _migrateIfLegacy(prefs, _baseLastDayKey, lastDayKey);
    await _migrateIfLegacy(prefs, _baseQuizBestKey, quizBestKey);

    final rawSparks = prefs.getInt(sparksKey) ?? 0;
    final rawBest = prefs.getInt(quizBestKey) ?? 0;
    return LanternState(
      sparks: rawSparks < 0 ? 0 : rawSparks,
      lastSparkDay: prefs.getString(lastDayKey),
      quizBest: rawBest < 0 ? 0 : rawBest,
    );
  }

  /// Lights today's gentle spark at most once per calendar day; never deducts sparks.
  static Future<LanternState> lightTodaySpark({DateTime? now, String? uid}) async {
    final prefs = await SharedPreferences.getInstance();
    final sparksKey = _key(_baseSparksKey, uid);
    final lastDayKey = _key(_baseLastDayKey, uid);
    final quizBestKey = _key(_baseQuizBestKey, uid);
    await _migrateIfLegacy(prefs, _baseSparksKey, sparksKey);
    await _migrateIfLegacy(prefs, _baseLastDayKey, lastDayKey);
    await _migrateIfLegacy(prefs, _baseQuizBestKey, quizBestKey);

    final today = dayKey(now ?? DateTime.now());
    final current = await load(uid);
    if (current.lastSparkDay == today) {
      return current;
    }
    final nextSparks = current.sparks + 1;
    await prefs.setInt(sparksKey, nextSparks);
    await prefs.setString(lastDayKey, today);
    return LanternState(
      sparks: nextSparks,
      lastSparkDay: today,
      quizBest: current.quizBest,
    );
  }

  /// Records the highest quiz score achieved without ever lowering it.
  static Future<int> recordQuizScore(int score, [String? uid]) async {
    final prefs = await SharedPreferences.getInstance();
    final quizBestKey = _key(_baseQuizBestKey, uid);
    await _migrateIfLegacy(prefs, _baseQuizBestKey, quizBestKey);

    final existing = prefs.getInt(quizBestKey) ?? 0;
    final best = math.max(existing, score);
    await prefs.setInt(quizBestKey, best);
    return best;
  }

  /// Clears local sanctuary data on this device upon sign out.
  static Future<void> clearLocal([String? uid]) async {
    final prefs = await SharedPreferences.getInstance();
    final effectiveUid = uid ?? _authUid();
    final keys = <String>[
      if (effectiveUid != null && effectiveUid.isNotEmpty) ...[
        '${_baseSparksKey}_$effectiveUid',
        '${_baseLastDayKey}_$effectiveUid',
        '${_baseQuizBestKey}_$effectiveUid',
      ],
      _baseSparksKey,
      _baseLastDayKey,
      _baseQuizBestKey,
    ];
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}

/// Calm, non-judgmental affirmations displayed alongside Moonlight Lantern.
const List<(String en, String id)> lanternAffirmations = [
  (
    'Every small step you take to care for yourself counts—even quiet pauses.',
    'Setiap langkah kecil untuk merawat dirimu tetap berarti—termasuk jeda yang tenang.',
  ),
  (
    'Your pace is your own. Nothing here wilts or judges if you need rest.',
    'Ritmemu adalah milikmu sendiri. Tak ada yang layu atau menghakimi saat kamu butuh istirahat.',
  ),
  (
    'You deserve patience, safety, and gentle kindness regardless of where you are on your path.',
    'Kamu berhak atas kesabaran, rasa aman, dan kelembutan di mana pun posisimu saat ini.',
  ),
  (
    'Breathe out what feels heavy tonight. Tomorrow is a fresh horizon.',
    'Hembuskan hal-hal yang terasa berat malam ini. Esok selalu membawa cakrawala baru.',
  ),
  (
    'Steady care over time shapes real change. Be gentle with your body while it grows.',
    'Perawatan yang tenang seiring waktu membawa perubahan nyata. Bersikaplah lembut pada tubuhmu yang sedang bertumbuh.',
  ),
  (
    'Even when your surroundings feel loud or uncertain, this little light stays yours.',
    'Bahkan saat sekitar terasa bising atau tak pasti, cahaya kecil ini tetap menjadi milikmu.',
  ),
];
