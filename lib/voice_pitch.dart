import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart' show Color;
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n.dart';
import 'theme.dart';

/// Soft, non-judgmental voice pitch range categories for self-reference only.
enum VoicePitchCategory { low, neutral, high }

extension VoicePitchCategoryMeta on VoicePitchCategory {
  String get label {
    switch (this) {
      case VoicePitchCategory.low:
        return tr('Low / Masculine Range');
      case VoicePitchCategory.neutral:
        return tr('Neutral / Overlap Range');
      case VoicePitchCategory.high:
        return tr('Bright / Feminine Range');
    }
  }

  String get rangeHint => switch (this) {
        VoicePitchCategory.low => '~85–155 Hz',
        VoicePitchCategory.neutral => '~155–185 Hz',
        VoicePitchCategory.high => '~185–265+ Hz',
      };

  Color get color => switch (this) {
        VoicePitchCategory.low => C.violet,
        VoicePitchCategory.neutral => C.lavender,
        VoicePitchCategory.high => C.rose,
      };

  String get key => name;

  static VoicePitchCategory fromKey(String? raw) {
    for (final c in VoicePitchCategory.values) {
      if (c.name == raw) return c;
    }
    return VoicePitchCategory.neutral;
  }
}

/// Maps fundamental frequency [hz] to a gentle overlapping pitch category.
VoicePitchCategory categorizePitchHz(double hz) {
  if (hz < 155.0) return VoicePitchCategory.low;
  if (hz <= 185.0) return VoicePitchCategory.neutral;
  return VoicePitchCategory.high;
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

/// Numeric-only voice pitch session summary. Never stores raw audio recordings.
class VoiceTestResult {
  const VoiceTestResult({
    required this.id,
    required this.at,
    required this.avgHz,
    required this.minHz,
    required this.maxHz,
    required this.category,
  });

  final String id;
  final DateTime at;
  final double avgHz;
  final double minHz;
  final double maxHz;
  final VoicePitchCategory category;

  Map<String, dynamic> toJson() => {
        'id': id,
        'at': at.toIso8601String(),
        'avgHz': double.parse(avgHz.toStringAsFixed(1)),
        'minHz': double.parse(minHz.toStringAsFixed(1)),
        'maxHz': double.parse(maxHz.toStringAsFixed(1)),
        'category': category.key,
      };

  static VoiceTestResult? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final atRaw = json['at'];
    final avg = (json['avgHz'] as num?)?.toDouble();
    final min = (json['minHz'] as num?)?.toDouble();
    final max = (json['maxHz'] as num?)?.toDouble();
    if (id is! String ||
        atRaw is! String ||
        avg == null ||
        min == null ||
        max == null) {
      return null;
    }
    final at = DateTime.tryParse(atRaw);
    if (at == null) return null;
    return VoiceTestResult(
      id: id,
      at: at,
      avgHz: avg,
      minHz: min,
      maxHz: max,
      category: VoicePitchCategoryMeta.fromKey(json['category'] as String?),
    );
  }
}

/// Offline SharedPreferences store for the hidden Voice Pitch Studio & numeric results.
class VoiceStore {
  static const _unlockedKey = 'sanctuary.voice_unlocked';
  static const _resultsKey = 'sanctuary.voice_results';
  static const _maxSaved = 50;

  static Future<bool> isUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_unlockedKey) ?? false;
  }

  static Future<void> setUnlocked(bool unlocked) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_unlockedKey, unlocked);
  }

  static Future<List<VoiceTestResult>> loadResults() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_resultsKey) ?? const <String>[];
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
      VoiceTestResult result) async {
    final existing = await loadResults();
    final updated = [result, ...existing.where((r) => r.id != result.id)]
        .take(_maxSaved)
        .toList();
    await _writeResults(updated);
    return updated;
  }

  static Future<List<VoiceTestResult>> deleteResult(String id) async {
    final existing = await loadResults();
    final updated = existing.where((r) => r.id != id).toList();
    await _writeResults(updated);
    return updated;
  }

  static Future<void> clearResults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_resultsKey);
  }

  static Future<void> _writeResults(List<VoiceTestResult> results) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _resultsKey,
      [for (final r in results) jsonEncode(r.toJson())],
    );
  }
}
