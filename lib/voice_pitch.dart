import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/material.dart' show Color;
import 'package:flutter/services.dart' show MethodChannel;
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n.dart';
import 'theme.dart';

/// Soft, non-judgmental voice pitch range categories for self-reference only.
enum VoicePitchCategory {
  veryDeep,
  deep,
  low,
  midLow,
  neutral,
  softHigh,
  bright,
  veryHigh,
}

extension VoicePitchCategoryMeta on VoicePitchCategory {
  String get label {
    switch (this) {
      case VoicePitchCategory.veryDeep:
        return tr('Very Deep Voice');
      case VoicePitchCategory.deep:
        return tr('Deep Voice');
      case VoicePitchCategory.low:
        return tr('Low Conversational');
      case VoicePitchCategory.midLow:
        return tr('Balanced Low-Mid');
      case VoicePitchCategory.neutral:
        return tr('Neutral Middle');
      case VoicePitchCategory.softHigh:
        return tr('Soft Warm Feminine');
      case VoicePitchCategory.bright:
        return tr('Bright Clear Feminine');
      case VoicePitchCategory.veryHigh:
        return tr('Very Light & High');
    }
  }

  String get description {
    switch (this) {
      case VoicePitchCategory.veryDeep:
        return tr('Very low, heavy speaking tone');
      case VoicePitchCategory.deep:
        return tr('Steady, deep speaking voice');
      case VoicePitchCategory.low:
        return tr('Relaxed, everyday lower voice');
      case VoicePitchCategory.midLow:
        return tr('Middle voice leaning slightly low');
      case VoicePitchCategory.neutral:
        return tr('Balanced gender-neutral middle tone');
      case VoicePitchCategory.softHigh:
        return tr('Gentle, natural feminine speaking voice');
      case VoicePitchCategory.bright:
        return tr('Light, bright everyday feminine voice');
      case VoicePitchCategory.veryHigh:
        return tr('Very high, airy speaking tone');
    }
  }

  String get rangeHint => switch (this) {
        VoicePitchCategory.veryDeep => '~65–100 Hz',
        VoicePitchCategory.deep => '~100–125 Hz',
        VoicePitchCategory.low => '~125–150 Hz',
        VoicePitchCategory.midLow => '~150–170 Hz',
        VoicePitchCategory.neutral => '~170–190 Hz',
        VoicePitchCategory.softHigh => '~190–215 Hz',
        VoicePitchCategory.bright => '~215–245 Hz',
        VoicePitchCategory.veryHigh => '~245+ Hz',
      };

  Color get color => switch (this) {
        VoicePitchCategory.veryDeep => C.aurora,
        VoicePitchCategory.deep => C.violet,
        VoicePitchCategory.low => C.violet,
        VoicePitchCategory.midLow => C.lavender,
        VoicePitchCategory.neutral => Pastel.mint,
        VoicePitchCategory.softHigh => C.rose,
        VoicePitchCategory.bright => C.magenta,
        VoicePitchCategory.veryHigh => C.coral,
      };

  String get key => name;

  static VoicePitchCategory fromKey(String? raw) {
    if (raw == 'high') return VoicePitchCategory.softHigh;
    for (final c in VoicePitchCategory.values) {
      if (c.name == raw) return c;
    }
    return VoicePitchCategory.neutral;
  }
}

/// Maps fundamental frequency [hz] to a gentle 8-tier pitch category.
VoicePitchCategory categorizePitchHz(double hz) {
  if (hz < 100.0) return VoicePitchCategory.veryDeep;
  if (hz < 125.0) return VoicePitchCategory.deep;
  if (hz < 150.0) return VoicePitchCategory.low;
  if (hz < 170.0) return VoicePitchCategory.midLow;
  if (hz < 190.0) return VoicePitchCategory.neutral;
  if (hz < 215.0) return VoicePitchCategory.softHigh;
  if (hz < 245.0) return VoicePitchCategory.bright;
  return VoicePitchCategory.veryHigh;
}

/// Detects fundamental frequency (F0 in Hz) from little-endian 16-bit mono PCM
/// bytes entirely in memory using a YIN-style normalized difference function.
/// Returns null on silence, unvoiced noise, or buffers too short to analyze.
double? detectPitchFromPcm16(
  Uint8List pcmBytes, {
  int sampleRate = 16000,
  double minHz = 65.0,
  double maxHz = 380.0,
}) {
  final sampleCount = pcmBytes.length ~/ 2;
  if (sampleRate <= 0 || sampleCount < 128) return null;

  final data = ByteData.sublistView(pcmBytes);
  final samples = Float64List(sampleCount);
  var sumSq = 0.0;
  var mean = 0.0;

  for (var i = 0; i < sampleCount; i++) {
    final s = data.getInt16(i * 2, Endian.little) / 32768.0;
    samples[i] = s;
    mean += s;
  }
  mean /= sampleCount;

  for (var i = 0; i < sampleCount; i++) {
    final centered = samples[i] - mean;
    samples[i] = centered;
    sumSq += centered * centered;
  }

  final rms = math.sqrt(sumSq / sampleCount);
  if (rms < 0.015) return null; // Silence / room noise gate

  final minLag = math.max(2, (sampleRate / maxHz).floor());
  final maxLag = math.min(
    (sampleRate / minHz).ceil(),
    (sampleCount ~/ 2) - 2,
  );
  if (maxLag <= minLag + 2) return null;

  final window = sampleCount - maxLag - 1;
  if (window < minLag * 2) return null;

  final cmndf = Float64List(maxLag + 1);
  cmndf[0] = 1.0;
  var runningSum = 0.0;

  for (var tau = 1; tau <= maxLag; tau++) {
    var diff = 0.0;
    for (var j = 0; j < window; j++) {
      final delta = samples[j] - samples[j + tau];
      diff += delta * delta;
    }
    runningSum += diff;
    cmndf[tau] = runningSum == 0.0 ? 1.0 : (diff * tau) / runningSum;
  }

  // Prefer the first clear dip below threshold 0.25 to avoid octave-doubling.
  const threshold = 0.25;
  var bestTau = -1;
  for (var tau = minLag; tau < maxLag; tau++) {
    if (cmndf[tau] < threshold) {
      while (tau + 1 < maxLag && cmndf[tau + 1] < cmndf[tau]) {
        tau++;
      }
      bestTau = tau;
      break;
    }
  }

  // Fallback to global minimum if moderately periodic (< 0.45).
  if (bestTau == -1) {
    var minVal = double.infinity;
    for (var tau = minLag; tau < maxLag; tau++) {
      if (cmndf[tau] < minVal) {
        minVal = cmndf[tau];
        bestTau = tau;
      }
    }
    if (bestTau == -1 || minVal >= 0.45) return null;
  }

  // Parabolic interpolation around bestTau for sub-sample frequency precision.
  var refinedTau = bestTau.toDouble();
  if (bestTau > minLag && bestTau < maxLag) {
    final s0 = cmndf[bestTau - 1];
    final s1 = cmndf[bestTau];
    final s2 = cmndf[bestTau + 1];
    final denom = 2.0 * (2.0 * s1 - s2 - s0);
    if (denom.abs() > 1e-9) {
      final shift = (s2 - s0) / denom;
      refinedTau += shift.clamp(-0.5, 0.5);
    }
  }

  if (refinedTau <= 0) return null;
  final hz = sampleRate / refinedTau;
  if (!hz.isFinite || hz < minHz || hz > maxHz) return null;
  return hz;
}

/// Generates synthetic 16-bit little-endian PCM sine audio for deterministic tests.
Uint8List synthesizePcm16Sine({
  required double frequencyHz,
  int sampleRate = 16000,
  int durationMs = 80,
  double amplitude = 0.5,
}) {
  final count = (sampleRate * durationMs / 1000).round();
  final out = ByteData(count * 2);
  final clampedAmp = amplitude.clamp(0.0, 0.99);
  for (var i = 0; i < count; i++) {
    final sample =
        math.sin(2.0 * math.pi * frequencyHz * i / sampleRate) * clampedAmp;
    out.setInt16(i * 2, (sample * 32767).round(), Endian.little);
  }
  return out.buffer.asUint8List();
}

/// Calm, neutral reading prompts (EN/ID) for users who are unsure what to say.
const List<(String en, String id)> voiceReadingPrompts = [
  (
    'The twilight sky turns lavender above the quiet lake.',
    'Langit senja perlahan berubah menjadi ungu lembut di atas danau yang tenang.',
  ),
  (
    'Every small breath helps my shoulders relax a little more.',
    'Setiap tarikan napas pelan membantu bahuku terasa lebih rileks.',
  ),
  (
    'Morning rain taps softly against the window glass.',
    'Hujan pagi mengetuk lembut kaca jendela dengan irama yang tenang.',
  ),
  (
    'I am taking my time today and moving at my own pace.',
    'Hari ini aku berjalan santai dan mengikuti ritmeku sendiri.',
  ),
  (
    'Warm tea and quiet music make the evening feel peaceful.',
    'Teh hangat dan musik pelan membuat suasana malam terasa damai.',
  ),
  (
    'Soft clouds drift slowly across the horizon after sunset.',
    'Awan lembut bergerak pelan melintasi cakrawala setelah matahari terbenam.',
  ),
  (
    'One calm sentence at a time is plenty for today.',
    'Satu kalimat yang tenang pada satu waktu sudah lebih dari cukup untuk hari ini.',
  ),
  (
    'The streetlights glow softly along the empty road.',
    'Lampu jalan berpendar lembut di sepanjang jalan yang lengang.',
  ),
  (
    'Light footsteps echo gently in a quiet hallway.',
    'Langkah kaki ringan bergema pelan di lorong yang sunyi.',
  ),
  (
    'Rest is part of care, and my voice deserves patience.',
    'Istirahat adalah bagian dari perawatan, dan suaraku berhak mendapat kesabaran.',
  ),
];

String pickVoicePrompt({int? index, math.Random? random}) {
  final i = index != null
      ? index % voiceReadingPrompts.length
      : (random ?? math.Random()).nextInt(voiceReadingPrompts.length);
  final pair = voiceReadingPrompts[i];
  return L10n.code == 'id' ? pair.$2 : pair.$1;
}

/// Multi-sentence editorial reading passage (EN/ID) for longer natural speech practice.
class VoiceReadingPassage {
  const VoiceReadingPassage({
    required this.titleEn,
    required this.titleId,
    required this.topicEn,
    required this.topicId,
    required this.bodyEn,
    required this.bodyId,
    required this.estSeconds,
  });

  final String titleEn;
  final String titleId;
  final String topicEn;
  final String topicId;
  final String bodyEn;
  final String bodyId;
  final int estSeconds;

  bool get _isId => L10n.code == 'id';
  String get title => _isId ? titleId : titleEn;
  String get topic => _isId ? topicId : topicEn;
  String get body => _isId ? bodyId : bodyEn;
}

const List<VoiceReadingPassage> voiceReadingPassages = [
  VoiceReadingPassage(
    titleEn: 'Evening Green Spaces in Modern Cities',
    titleId: 'Ruang Hijau Kota Menjelang Senja',
    topicEn: 'Urban Feature',
    topicId: 'Liputan Kota',
    estSeconds: 40,
    bodyEn:
        'As afternoon heat begins to fade, small neighborhood parks often turn into the calmest corners of a busy city. Commuters pause along shaded benches, cyclists roll home past rows of rain trees, and warm streetlamps flicker to life one by one. Urban planners note that even modest pocket gardens noticeably soften traffic noise, invite unhurried conversation, and give residents a natural place to breathe before evening settles in.',
    bodyId:
        'Ketika panas siang mulai mereda, taman lingkungan sering berubah menjadi sudut paling tenang di tengah kota yang padat. Para pekerja singgah sejenak di bangku teduh, pesepeda melintas pulang di bawah deretan trembesi, dan lampu jalan hangat mulai menyala satu per satu. Perencana kota mencatat bahwa taman saku berukuran kecil sekalipun efektif meredam kebisingan lalu lintas sekaligus menghadirkan ruang nyaman untuk berbincang santai menjelang malam.',
  ),
  VoiceReadingPassage(
    titleEn: 'Patience Behind a Slow Morning Pour-Over',
    titleId: 'Ketelitian di Balik Seduhan Kopi Pagi',
    topicEn: 'Culture & Craft',
    topicId: 'Gaya Hidup',
    estSeconds: 38,
    bodyEn:
        'Stepping inside a quiet coffee bar before rush hour reveals a surprisingly steady rhythm. Rather than hurrying through orders, baristas weigh freshly ground beans, watch the water bloom slowly over the filter, and check the aroma rising with the steam. Regular guests say the appeal is only partly about flavor. Much of the comfort comes from spending three unhurried minutes watching simple craft unfold cleanly from start to finish.',
    bodyId:
        'Memasuki kedai kopi kecil sebelum jam sibuk memperlihatkan ritme kerja yang terasa tenang dan terukur. Alih-alih terburu-buru mengejar pesanan, peracik kopi menimbang biji sangrai, membiarkan air panas menyeduh secara perlahan di atas kertas saring, lalu memastikan aroma yang keluar tetap seimbang. Banyak pelanggan setia mengaku bahwa daya tariknya bukan semata rasa, melainkan momen singkat menyaksikan ketelitian sederhana dari awal hingga selesai.',
  ),
  VoiceReadingPassage(
    titleEn: 'Looking Up at Dark-Sky Sanctuaries',
    titleId: 'Menatap Langit Gelap di Cagar Bintang',
    topicEn: 'Science Desk',
    topicId: 'Laporan Sains',
    estSeconds: 42,
    bodyEn:
        'Far beyond highway billboards and bright storefronts, several coastal towns now dim outdoor lighting after nine o’clock to protect clear night skies. Within weeks of installing shielded warm lamps, residents noticed familiar constellations returning overhead along with fireflies near the reeds. Astronomers visiting the area explain that lower glare also helps nocturnal birds navigate safely, proving that small lighting adjustments can quickly restore a sense of stillness.',
    bodyId:
        'Jauh dari papan reklame jalan utama dan deretan pertokoan terang, beberapa kota pesisir mulai meredupkan lampu luar ruangan setelah pukul sembilan malam demi menjaga kejernihan langit. Dalam beberapa pekan setelah pemasangan lampu hangat berpenutup arah, rasi bintang kembali terlihat jelas bersama kunang-kunang di sekitar rerumputan. Para astronom menjelaskan bahwa berkurangnya silau juga membantu navigasi burung malam secara alami dan mengembalikan ketenangan suasana malam.',
  ),
  VoiceReadingPassage(
    titleEn: 'How Neighborhood Libraries Stay Relevant',
    titleId: 'Bagaimana Perpustakaan Warga Tetap Hidup',
    topicEn: 'Community Notes',
    topicId: 'Wacana Komunitas',
    estSeconds: 40,
    bodyEn:
        'On Saturday mornings, the wooden reading room down the avenue fills with an unexpected mix of visitors. Students spread notebooks beside sunlit windows, retirees trade newspaper clippings over tea, and younger readers browse illustrated science books near the corner shelves. Volunteers say the space thrives not because it chases trends, but because it stays warm, accessible, and genuinely welcoming to anyone looking for quiet company.',
    bodyId:
        'Setiap Sabtu pagi, ruang baca berkayu di ujung jalan itu dipenuhi pengunjung dari berbagai usia. Pelajar membuka buku catatan di dekat jendela yang terang, warga senior bertukar kliping berita sambil menikmati teh hangat, sementara pembaca muda memilih buku sains bergambar di sudut ruangan. Para relawan menilai tempat ini bertahan bukan karena mengejar tren, melainkan karena tetap hangat, mudah diakses, dan ramah bagi siapa pun.',
  ),
  VoiceReadingPassage(
    titleEn: 'Unhurried Rituals for Calmer Mornings',
    titleId: 'Kebiasaan Sederhana untuk Pagi yang Tenang',
    topicEn: 'Wellness Column',
    topicId: 'Kolom Keseharian',
    estSeconds: 36,
    bodyEn:
        'Before checking overnight notifications, taking five calm minutes near an open window can change the pace of an entire day. Stretching gently, drinking a glass of room-temperature water, and speaking your first words softly help both posture and breath stay relaxed. Habits researchers emphasize that consistency matters far more than intensity, turning small everyday pauses into reliable anchors throughout busy weeks.',
    bodyId:
        'Sebelum memeriksa deretan notifikasi ponsel, meluangkan lima menit tenang di dekat jendela terbuka sering mengubah suasana seharian penuh. Peregangan ringan, segelas air putih hangat, dan berbicara dengan nada santai membantu bahu serta napas terasa lebih lepas. Peneliti kebiasaan menegaskan bahwa konsistensi jauh lebih bermakna daripada target besar, sehingga jeda kecil setiap pagi perlahan menjadi jangkar yang menenangkan.',
  ),
  VoiceReadingPassage(
    titleEn: 'Reading Coastal Tides Under Moonlight',
    titleId: 'Membaca Pasang Surut Laut di Bawah Bulan',
    topicEn: 'Nature & Climate',
    topicId: 'Sains & Alam',
    estSeconds: 42,
    bodyEn:
        'Along rocky coves and wooden piers, every rise and fall of the tide follows an ancient gravitational conversation between Earth, Sun, and Moon. Local weather stations record subtle shifts hour by hour, allowing ferries and small fishing boats to plan safe crossings without guesswork. Standing by the shoreline at dusk, observers can watch calm ripples trace that steady celestial timing right up to the sand.',
    bodyId:
        'Di sepanjang teluk berbatu dan dermaga kayu, setiap naik turunnya air laut mengikuti tarikan gravitasi teratur antara Bumi, Matahari, dan Bulan. Stasiun cuaca pesisir mencatat perubahan tinggi muka air dari jam ke jam agar kapal penyeberangan serta perahu nelayan dapat merencanakan perjalanan dengan aman. Saat berdiri di tepi pantai menjelang malam, riak tenang tersebut memperlihatkan keteraturan alam semesta di depan mata.',
  ),
];

VoiceReadingPassage pickVoicePassage({int? index, math.Random? random}) {
  final i = index != null
      ? index % voiceReadingPassages.length
      : (random ?? math.Random()).nextInt(voiceReadingPassages.length);
  return voiceReadingPassages[i];
}

/// Customizable pitch comfort zone (in Hz) for real-time feedback and trend charts.
class VoiceTargetRange {
  const VoiceTargetRange({this.minHz = 165.0, this.maxHz = 215.0});

  static const masculine = VoiceTargetRange(minHz: 100.0, maxHz: 145.0);
  static const neutral = VoiceTargetRange(minHz: 155.0, maxHz: 185.0);
  static const feminine = VoiceTargetRange(minHz: 185.0, maxHz: 230.0);

  final double minHz;
  final double maxHz;

  bool contains(double hz) => hz >= minHz && hz <= maxHz;

  @override
  bool operator ==(Object other) =>
      other is VoiceTargetRange && other.minHz == minHz && other.maxHz == maxHz;

  @override
  int get hashCode => Object.hash(minHz, maxHz);
}

/// Computed pitch stats for a live or finished voice session (RAM only).
class VoiceSessionMetrics {
  const VoiceSessionMetrics({
    required this.avgHz,
    required this.minHz,
    required this.maxHz,
    required this.inTargetPercent,
    required this.spreadHz,
    required this.intonationLabel,
  });

  final double avgHz;
  final double minHz;
  final double maxHz;
  final double inTargetPercent;
  final double spreadHz;
  final String intonationLabel;
}

VoiceSessionMetrics? computeVoiceSessionMetrics(
  List<double> samples,
  VoiceTargetRange target,
) {
  if (samples.isEmpty) return null;
  var sum = 0.0;
  var minVal = samples.first;
  var maxVal = samples.first;
  var inTarget = 0;
  for (final hz in samples) {
    sum += hz;
    if (hz < minVal) minVal = hz;
    if (hz > maxVal) maxVal = hz;
    if (target.contains(hz)) inTarget++;
  }
  final avg = sum / samples.length;
  final spread = maxVal - minVal;
  final pct = (inTarget * 100.0) / samples.length;
  final label = spread < 18.0
      ? tr('Steady / Flat')
      : (spread <= 55.0
          ? tr('Natural Inflection')
          : tr('Expressive Range'));
  return VoiceSessionMetrics(
    avgHz: avg,
    minHz: minVal,
    maxHz: maxVal,
    inTargetPercent: pct,
    spreadHz: spread,
    intonationLabel: label,
  );
}

/// Real-time spectral estimate of vocal size (brightness) and vocal fold weight (RAM only).
class VoiceToneAnalysis {
  const VoiceToneAnalysis({
    required this.brightnessScore,
    required this.weightScore,
  });

  /// Normalized 0.0 (warm / larger space) to 1.0 (bright / smaller space).
  final double brightnessScore;

  /// Normalized 0.0 (light & soft) to 1.0 (thick / heavy).
  final double weightScore;

  String get brightnessLabel {
    if (brightnessScore < 0.36) return tr('Warm / Larger Space');
    if (brightnessScore <= 0.64) return tr('Balanced Resonance');
    return tr('Bright / Smaller Space');
  }

  String get weightLabel {
    if (weightScore < 0.36) return tr('Light & Soft');
    if (weightScore <= 0.64) return tr('Balanced Weight');
    return tr('Thick / Heavy');
  }
}

void _fftInPlace(Float64List re, Float64List im) {
  final n = re.length;
  var j = 0;
  for (var i = 1; i < n; i++) {
    var bit = n >> 1;
    while ((j & bit) != 0) {
      j ^= bit;
      bit >>= 1;
    }
    j ^= bit;
    if (i < j) {
      final tr = re[i];
      re[i] = re[j];
      re[j] = tr;
      final ti = im[i];
      im[i] = im[j];
      im[j] = ti;
    }
  }
  for (var len = 2; len <= n; len <<= 1) {
    final ang = -2.0 * math.pi / len;
    final wLenRe = math.cos(ang);
    final wLenIm = math.sin(ang);
    for (var i = 0; i < n; i += len) {
      var wRe = 1.0;
      var wIm = 0.0;
      final half = len >> 1;
      for (var k = 0; k < half; k++) {
        final uRe = re[i + k];
        final uIm = im[i + k];
        final vIdx = i + k + half;
        final vRe = re[vIdx] * wRe - im[vIdx] * wIm;
        final vIm = re[vIdx] * wIm + im[vIdx] * wRe;
        re[i + k] = uRe + vRe;
        im[i + k] = uIm + vIm;
        re[vIdx] = uRe - vRe;
        im[vIdx] = uIm - vIm;
        final nextWRe = wRe * wLenRe - wIm * wLenIm;
        wIm = wRe * wLenIm + wIm * wLenRe;
        wRe = nextWRe;
      }
    }
  }
}

/// Estimates spectral brightness (resonance proxy) and harmonic tilt (vocal weight proxy)
/// entirely in memory from little-endian 16-bit mono PCM audio. Returns null on silence.
VoiceToneAnalysis? analyzeVoiceToneFromPcm16(
  Uint8List pcmBytes, {
  int sampleRate = 16000,
  double? f0Hz,
}) {
  const fftSize = 1024;
  final sampleCount = pcmBytes.length ~/ 2;
  if (sampleRate <= 0 || sampleCount < fftSize) return null;

  final data = ByteData.sublistView(pcmBytes);
  final startOffset = (sampleCount - fftSize) ~/ 2;

  var mean = 0.0;
  var energy = 0.0;
  final raw = Float64List(fftSize);
  for (var i = 0; i < fftSize; i++) {
    final s = data.getInt16((startOffset + i) * 2, Endian.little) / 32768.0;
    raw[i] = s;
    mean += s;
    energy += s * s;
  }
  if (math.sqrt(energy / fftSize) < 0.008) return null;
  mean /= fftSize;

  final re = Float64List(fftSize);
  final im = Float64List(fftSize);
  for (var i = 0; i < fftSize; i++) {
    final hann = 0.5 * (1.0 - math.cos(2.0 * math.pi * i / (fftSize - 1)));
    re[i] = (raw[i] - mean) * hann;
  }
  _fftInPlace(re, im);

  final binHz = sampleRate / fftSize;
  const half = fftSize ~/ 2;
  final mag = Float64List(half);

  var weightedFreqSum = 0.0;
  var totalBandMag = 0.0;
  var peakF0Mag = 0.0;
  double? estimatedF0 = (f0Hz != null && f0Hz >= 60.0 && f0Hz <= 400.0) ? f0Hz : null;

  for (var k = 1; k < half; k++) {
    final m = math.sqrt(re[k] * re[k] + im[k] * im[k]);
    mag[k] = m;
    final freq = k * binHz;
    if (freq >= 85.0 && freq <= 4500.0) {
      weightedFreqSum += freq * m;
      totalBandMag += m;
    }
    if (estimatedF0 == null && freq >= 65.0 && freq <= 380.0 && m > peakF0Mag) {
      peakF0Mag = m;
      estimatedF0 = freq;
    }
  }

  if (totalBandMag <= 1e-9) return null;
  final centroid = weightedFreqSum / totalBandMag;
  final brightness = ((centroid - 450.0) / 1400.0).clamp(0.0, 1.0);

  var weight = 0.5;
  if (estimatedF0 != null) {
    final f0 = estimatedF0;
    final h1Min = f0 * 0.72;
    final h1Max = f0 * 1.38;
    final h2Min = f0 * 1.5;
    final h2Max = math.min(2600.0, f0 * 8.5);
    var h1Sum = 0.0;
    var h2PlusSum = 0.0;
    for (var k = 1; k < half; k++) {
      final freq = k * binHz;
      if (freq >= h1Min && freq <= h1Max) {
        h1Sum += mag[k];
      } else if (freq >= h2Min && freq <= h2Max) {
        h2PlusSum += mag[k];
      }
    }
    final denom = h1Sum + h2PlusSum;
    if (denom > 1e-9) {
      final harmonicRatio = h2PlusSum / denom;
      weight = ((harmonicRatio - 0.15) / 0.68).clamp(0.0, 1.0);
    }
  }

  return VoiceToneAnalysis(
    brightnessScore: brightness,
    weightScore: weight,
  );
}

/// Generates a synthetic harmonic PCM16 waveform in RAM for testing spectral balance.
Uint8List synthesizePcm16Harmonic({
  required double frequencyHz,
  required List<double> harmonicWeights,
  int sampleRate = 16000,
  int durationMs = 80,
  double amplitude = 0.5,
}) {
  final count = (sampleRate * durationMs / 1000).round();
  final out = ByteData(count * 2);
  final weightSum = harmonicWeights.fold<double>(0.0, (s, w) => s + w.abs());
  final norm = weightSum > 1e-9 ? weightSum : 1.0;
  final clampedAmp = amplitude.clamp(0.0, 0.99);
  for (var i = 0; i < count; i++) {
    var v = 0.0;
    for (var h = 0; h < harmonicWeights.length; h++) {
      v += harmonicWeights[h] *
          math.sin(2.0 * math.pi * frequencyHz * (h + 1) * i / sampleRate);
    }
    final sample = (v / norm) * clampedAmp;
    out.setInt16(i * 2, (sample * 32767).round().clamp(-32768, 32767),
        Endian.little);
  }
  return out.buffer.asUint8List();
}

/// Guided silent/SOVTE warm-up step (zero microphone required).
class VoiceWarmupStep {
  const VoiceWarmupStep({
    required this.titleEn,
    required this.titleId,
    required this.subtitleEn,
    required this.subtitleId,
    required this.tipEn,
    required this.tipId,
    required this.durationSeconds,
  });

  final String titleEn;
  final String titleId;
  final String subtitleEn;
  final String subtitleId;
  final String tipEn;
  final String tipId;
  final int durationSeconds;

  bool get _isId => L10n.code == 'id';
  String get title => _isId ? titleId : titleEn;
  String get subtitle => _isId ? subtitleId : subtitleEn;
  String get tip => _isId ? tipId : tipEn;
}

const List<VoiceWarmupStep> voiceWarmupSteps = [
  VoiceWarmupStep(
    titleEn: 'Neck, Jaw & Shoulder Release',
    titleId: 'Rilekskan Leher, Rahang & Bahu',
    subtitleEn:
        'Let your shoulders drop and gently unclench your jaw for a tension-free start.',
    subtitleId:
        'Turunkan bahumu perlahan dan kendurkan rahang agar tenggorokan bebas ketegangan.',
    tipEn:
        'Roll shoulders back twice and take 3 slow breaths through your mouth like fogging glass.',
    tipId:
        'Putar bahu ke belakang dua kali dan tarik 3 napas pelan seperti mengembun kaca.',
    durationSeconds: 20,
  ),
  VoiceWarmupStep(
    titleEn: 'SOVTE: Straw or Lip Trill',
    titleId: 'SOVTE: Sedotan atau Getar Bibir',
    subtitleEn:
        'Hum softly into an imaginary straw or do gentle lip trills to lighten vocal weight.',
    subtitleId:
        'Bergumam pelan lewat sedotan imajiner atau getarkan bibir ringan untuk meringankan suara.',
    tipEn:
        'Keep airflow steady and easy—if it tickles or feels tight, soften the volume.',
    tipId:
        'Jaga aliran udara tetap ringan—kalau terasa mengganjal, kecilkan volume.',
    durationSeconds: 30,
  ),
  VoiceWarmupStep(
    titleEn: 'Small Space Resonance Glide',
    titleId: 'Geser Resonansi Ruang Kecil',
    subtitleEn:
        'Whisper softly from "ahh" toward "ih/ee" without forcing pitch, feeling sound move forward.',
    subtitleId:
        'Berbisik pelan dari "ahh" ke "ih/ee" tanpa memaksa nada tinggi, rasakan suara maju ke depan.',
    tipEn: 'Think of sounding smaller and lighter rather than louder.',
    tipId: 'Bayangkan ruang mulut terasa lebih kecil dan ringan, bukan lebih keras.',
    durationSeconds: 25,
  ),
  VoiceWarmupStep(
    titleEn: 'Hydration & Soft Hum',
    titleId: 'Minum Air & Gumam Nyaman',
    subtitleEn:
        'Take a sip of room-temperature water and end with an easy conversational hum.',
    subtitleId:
        'Minum seteguk air bersuhu ruang lalu akhiri dengan gumam santai di nada bicara nyaman.',
    tipEn: 'Hydrated vocal folds vibrate smoothly with noticeably less effort.',
    tipId: 'Pita suara yang terhidrasi bergetar lebih halus dengan usaha jauh lebih ringan.',
    durationSeconds: 15,
  ),
];

/// Preset pitch-pipe frequency button metadata.
class VoiceReferenceTone {
  const VoiceReferenceTone({
    required this.hz,
    required this.labelKey,
    required this.color,
  });

  final double hz;
  final String labelKey;
  final Color color;

  String get label => tr(labelKey);
}

const List<VoiceReferenceTone> voiceReferenceTones = [
  VoiceReferenceTone(hz: 125.0, labelKey: 'Deep tone', color: C.violet),
  VoiceReferenceTone(hz: 165.0, labelKey: 'Neutral pitch', color: Pastel.mint),
  VoiceReferenceTone(hz: 195.0, labelKey: 'Warm femme', color: C.rose),
  VoiceReferenceTone(hz: 225.0, labelKey: 'Bright femme', color: C.magenta),
];

const MethodChannel _voiceAudioChannel =
    MethodChannel('com.example.ritme/app_utils');

/// Plays a brief soft sine reference tone on supported devices (returns false otherwise).
Future<bool> playVoiceReferenceTone(double hz, {int durationMs = 1400}) async {
  try {
    final ok = await _voiceAudioChannel.invokeMethod<bool>(
      'playReferenceTone',
      {'hz': hz, 'durationMs': durationMs},
    );
    return ok ?? false;
  } catch (_) {
    return false;
  }
}

/// Optional short condition tags users can attach to a saved pitch result.
const List<(String key, String en, String id)> voiceContextTags = [
  ('morning', 'Morning', 'Pagi hari'),
  ('warmed_up', 'Warmed up', 'Sudah pemanasan'),
  ('relaxed', 'Relaxed', 'Santai'),
  ('tired', 'Tired', 'Lelah'),
];

String? voiceContextTagLabel(String? key) {
  if (key == null) return null;
  for (final item in voiceContextTags) {
    if (item.$1 == key) return L10n.code == 'id' ? item.$3 : item.$2;
  }
  return null;
}

/// Numeric-only voice pitch session summary. Never stores raw audio recordings.
class VoiceTestResult {
  const VoiceTestResult({
    required this.id,
    required this.at,
    required this.avgHz,
    required this.minHz,
    required this.maxHz,
    required this.category,
    this.contextTag,
  });

  final String id;
  final DateTime at;
  final double avgHz;
  final double minHz;
  final double maxHz;
  final VoicePitchCategory category;
  final String? contextTag;

  static DateTime? _parseDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    if (v is Map && v[r'$ts'] is String) {
      return DateTime.tryParse(v[r'$ts'] as String);
    }
    return null;
  }

  static double? _finitePositive(dynamic v) {
    if (v is num) {
      final d = v.toDouble();
      return (d.isFinite && d > 0) ? d : null;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'at': at.toIso8601String(),
        'avgHz': double.parse(avgHz.toStringAsFixed(1)),
        'minHz': double.parse(minHz.toStringAsFixed(1)),
        'maxHz': double.parse(maxHz.toStringAsFixed(1)),
        'category': category.key,
        if (contextTag != null) 'contextTag': contextTag,
      };

  /// Numeric-only Firestore map. Never stores raw audio recordings.
  Map<String, dynamic> toMap() => {
        'at': Timestamp.fromDate(at),
        'avgHz': double.parse(avgHz.toStringAsFixed(1)),
        'minHz': double.parse(minHz.toStringAsFixed(1)),
        'maxHz': double.parse(maxHz.toStringAsFixed(1)),
        'category': category.key,
        if (contextTag != null) 'contextTag': contextTag,
      };

  static VoiceTestResult? tryFrom(String id, Map<String, dynamic> m) {
    final cleanId = id.trim();
    final at = _parseDate(m['at']);
    final avg = _finitePositive(m['avgHz']);
    final min = _finitePositive(m['minHz']);
    final max = _finitePositive(m['maxHz']);
    if (cleanId.isEmpty ||
        at == null ||
        avg == null ||
        min == null ||
        max == null) {
      return null;
    }
    final rawTag = m['contextTag'];
    final tag = (rawTag is String && rawTag.trim().isNotEmpty)
        ? rawTag.trim()
        : null;
    return VoiceTestResult(
      id: cleanId,
      at: at,
      avgHz: avg,
      minHz: min,
      maxHz: max,
      category: VoicePitchCategoryMeta.fromKey(m['category'] as String?),
      contextTag: tag,
    );
  }

  factory VoiceTestResult.from(String id, Map<String, dynamic> m) =>
      tryFrom(id, m) ??
      VoiceTestResult(
        id: id,
        at: DateTime.fromMillisecondsSinceEpoch(0),
        avgHz: 0,
        minHz: 0,
        maxHz: 0,
        category: VoicePitchCategoryMeta.fromKey(m['category'] as String?),
      );

  static VoiceTestResult? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String) return null;
    return tryFrom(id, json);
  }
}

/// Offline SharedPreferences store for the hidden Voice Pitch Studio & numeric results.
class VoiceStore {
  static const _baseUnlockedKey = 'sanctuary.voice_unlocked';
  static const _baseResultsKey = 'sanctuary.voice_results';
  static const _baseSyncedIdsKey = 'sanctuary.voice_synced_ids';
  static const _baseTargetMinKey = 'sanctuary.voice_target_min';
  static const _baseTargetMaxKey = 'sanctuary.voice_target_max';
  static const _maxSaved = 50;

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

  static void _migrateIfLegacy(
    SharedPreferences prefs,
    String base,
    String scopedKey,
  ) {
    if (base != scopedKey &&
        prefs.containsKey(base) &&
        !prefs.containsKey(scopedKey)) {
      final val = prefs.get(base);
      if (val is List<String>) {
        prefs.setStringList(scopedKey, val);
      } else if (val is bool) {
        prefs.setBool(scopedKey, val);
      } else if (val is double) {
        prefs.setDouble(scopedKey, val);
      } else if (val is int) {
        prefs.setInt(scopedKey, val);
      } else if (val is String) {
        prefs.setString(scopedKey, val);
      }
      prefs.remove(base);
    }
  }

  static VoiceTargetRange _normalizeTarget(double minHz, double maxHz) {
    final clampedMin = minHz.clamp(80.0, 275.0).toDouble();
    final clampedMax = maxHz.clamp(clampedMin + 5.0, 280.0).toDouble();
    return VoiceTargetRange(minHz: clampedMin, maxHz: clampedMax);
  }

  static Future<VoiceTargetRange> loadTargetRange([String? uid]) async {
    final prefs = await SharedPreferences.getInstance();
    final minKey = _key(_baseTargetMinKey, uid);
    final maxKey = _key(_baseTargetMaxKey, uid);
    _migrateIfLegacy(prefs, _baseTargetMinKey, minKey);
    _migrateIfLegacy(prefs, _baseTargetMaxKey, maxKey);
    final minVal = prefs.getDouble(minKey);
    final maxVal = prefs.getDouble(maxKey);
    if (minVal == null || maxVal == null) {
      return const VoiceTargetRange();
    }
    return _normalizeTarget(minVal, maxVal);
  }

  static Future<VoiceTargetRange> saveTargetRange(
      VoiceTargetRange range, [String? uid]) async {
    final normalized = _normalizeTarget(range.minHz, range.maxHz);
    final prefs = await SharedPreferences.getInstance();
    final minKey = _key(_baseTargetMinKey, uid);
    final maxKey = _key(_baseTargetMaxKey, uid);
    await prefs.setDouble(minKey, normalized.minHz);
    await prefs.setDouble(maxKey, normalized.maxHz);
    return normalized;
  }

  static final Set<String> _locallyDeletedIds = <String>{};
  static bool _locallyClearedAll = false;

  @visibleForTesting
  static void resetSessionStateForTest() {
    _locallyDeletedIds.clear();
    _locallyClearedAll = false;
  }

  static Future<bool> isUnlocked([String? uid]) async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedKey = _key(_baseUnlockedKey, uid);
    _migrateIfLegacy(prefs, _baseUnlockedKey, unlockedKey);
    return prefs.getBool(unlockedKey) ?? false;
  }

  static Future<void> setUnlocked(bool unlocked, [String? uid]) async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedKey = _key(_baseUnlockedKey, uid);
    await prefs.setBool(unlockedKey, unlocked);
  }

  static Future<List<VoiceTestResult>> loadResults([String? uid]) async {
    final prefs = await SharedPreferences.getInstance();
    final resultsKey = _key(_baseResultsKey, uid);
    _migrateIfLegacy(prefs, _baseResultsKey, resultsKey);
    return _loadResultsFromPrefs(prefs, resultsKey);
  }

  static List<VoiceTestResult> _loadResultsFromPrefs(
      SharedPreferences prefs, String key) {
    final rawList = prefs.getStringList(key) ?? const <String>[];
    final out = <VoiceTestResult>[];
    for (final raw in rawList) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          final parsed = VoiceTestResult.fromJson(decoded);
          if (parsed != null) out.add(parsed);
        }
      } catch (_) {
        // Skip malformed entries safely.
      }
    }
    out.sort((a, b) => b.at.compareTo(a.at));
    return out;
  }

  static Future<List<VoiceTestResult>> saveResult(
      VoiceTestResult result, [String? uid]) async {
    _locallyDeletedIds.remove(result.id);
    _locallyClearedAll = false;
    final prefs = await SharedPreferences.getInstance();
    final resultsKey = _key(_baseResultsKey, uid);
    _migrateIfLegacy(prefs, _baseResultsKey, resultsKey);
    final existing = _loadResultsFromPrefs(prefs, resultsKey);
    final updated = [result, ...existing.where((r) => r.id != result.id)]
        .take(_maxSaved)
        .toList();
    await _writeResultsToPrefs(prefs, resultsKey, updated);
    return updated;
  }

  static Future<List<VoiceTestResult>> deleteResult(String id, [String? uid]) async {
    _locallyDeletedIds.add(id);
    final prefs = await SharedPreferences.getInstance();
    final resultsKey = _key(_baseResultsKey, uid);
    final syncedKey = _key(_baseSyncedIdsKey, uid);
    _migrateIfLegacy(prefs, _baseResultsKey, resultsKey);
    _migrateIfLegacy(prefs, _baseSyncedIdsKey, syncedKey);
    final existing = _loadResultsFromPrefs(prefs, resultsKey);
    final updated = existing.where((r) => r.id != id).toList();
    await _writeResultsToPrefs(prefs, resultsKey, updated);
    final synced =
        (prefs.getStringList(syncedKey) ?? const <String>[]).toSet()
          ..remove(id);
    await prefs.setStringList(syncedKey, synced.toList());
    return updated;
  }

  static Future<void> clearResults(
      {Iterable<String> knownIds = const [], String? uid}) async {
    final prefs = await SharedPreferences.getInstance();
    final resultsKey = _key(_baseResultsKey, uid);
    final syncedKey = _key(_baseSyncedIdsKey, uid);
    _migrateIfLegacy(prefs, _baseResultsKey, resultsKey);
    _migrateIfLegacy(prefs, _baseSyncedIdsKey, syncedKey);
    final existing = _loadResultsFromPrefs(prefs, resultsKey);
    for (final r in existing) {
      _locallyDeletedIds.add(r.id);
    }
    _locallyDeletedIds.addAll(knownIds);
    _locallyClearedAll = true;
    await prefs.remove(resultsKey);
    await prefs.remove(syncedKey);
  }

  static Future<void> clearLocal([String? uid]) async {
    resetSessionStateForTest();
    final prefs = await SharedPreferences.getInstance();
    final effectiveUid = uid ?? _authUid();
    final keys = <String>[
      if (effectiveUid != null && effectiveUid.isNotEmpty) ...[
        '${_baseResultsKey}_$effectiveUid',
        '${_baseSyncedIdsKey}_$effectiveUid',
        '${_baseUnlockedKey}_$effectiveUid',
        '${_baseTargetMinKey}_$effectiveUid',
        '${_baseTargetMaxKey}_$effectiveUid',
      ],
      _baseResultsKey,
      _baseSyncedIdsKey,
      _baseUnlockedKey,
      _baseTargetMinKey,
      _baseTargetMaxKey,
    ];
    for (final k in keys) {
      await prefs.remove(k);
    }
  }

  /// Merges local SharedPreferences history with Cloud Firestore snapshots.
  /// Uploads legacy local-only entries (when [uploadMissing] is supplied),
  /// propagates cross-device deletions, respects same-session local deletes,
  /// and auto-unlocks Voice Pitch Studio on new devices with synced results.
  static Future<List<VoiceTestResult>> reconcileWithRemote(
    List<VoiceTestResult> remote, {
    Future<void> Function(VoiceTestResult result)? uploadMissing,
    String? uid,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final resultsKey = _key(_baseResultsKey, uid);
    final syncedKey = _key(_baseSyncedIdsKey, uid);
    final unlockedKey = _key(_baseUnlockedKey, uid);
    _migrateIfLegacy(prefs, _baseResultsKey, resultsKey);
    _migrateIfLegacy(prefs, _baseSyncedIdsKey, syncedKey);
    _migrateIfLegacy(prefs, _baseUnlockedKey, unlockedKey);
    final local = _loadResultsFromPrefs(prefs, resultsKey);

    if (_locallyClearedAll) {
      if (remote.isEmpty) {
        _locallyClearedAll = false;
        await prefs.remove(syncedKey);
        return const [];
      }
      return local;
    }

    final previouslySynced =
        (prefs.getStringList(syncedKey) ?? const <String>[]).toSet();
    final byId = <String, VoiceTestResult>{};
    final remoteIds = <String>{};

    for (final r in remote) {
      remoteIds.add(r.id);
      if (_locallyDeletedIds.contains(r.id)) continue;
      byId[r.id] = r;
    }

    final missingOnRemote = <VoiceTestResult>[];
    for (final l in local) {
      if (_locallyDeletedIds.contains(l.id)) continue;
      if (!remoteIds.contains(l.id) && previouslySynced.contains(l.id)) {
        continue;
      }
      byId[l.id] = l;
      if (!remoteIds.contains(l.id)) {
        missingOnRemote.add(l);
      }
    }

    final merged = byId.values.toList()
      ..sort((a, b) => b.at.compareTo(a.at));
    final capped = merged.take(_maxSaved).toList();

    if (!_sameResults(local, capped)) {
      await _writeResultsToPrefs(prefs, resultsKey, capped);
    }

    final nextSynced = <String>[
      for (final r in remote)
        if (!_locallyDeletedIds.contains(r.id)) r.id,
    ];
    await prefs.setStringList(syncedKey, nextSynced);

    if (capped.isNotEmpty && !prefs.containsKey(unlockedKey)) {
      await prefs.setBool(unlockedKey, true);
    }

    if (uploadMissing != null && missingOnRemote.isNotEmpty) {
      final cappedIds = {for (final r in capped) r.id};
      for (final item in missingOnRemote) {
        if (!cappedIds.contains(item.id)) continue;
        await uploadMissing(item);
      }
    }

    return capped;
  }

  static bool _sameResults(List<VoiceTestResult> a, List<VoiceTestResult> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final x = a[i];
      final y = b[i];
      if (x.id != y.id ||
          x.at.millisecondsSinceEpoch != y.at.millisecondsSinceEpoch ||
          x.avgHz != y.avgHz ||
          x.minHz != y.minHz ||
          x.maxHz != y.maxHz ||
          x.category != y.category ||
          x.contextTag != y.contextTag) {
        return false;
      }
    }
    return true;
  }

  static Future<void> _writeResultsToPrefs(
      SharedPreferences prefs, String key, List<VoiceTestResult> results) async {
    await prefs.setStringList(
      key,
      [for (final r in results) jsonEncode(r.toJson())],
    );
  }
}
