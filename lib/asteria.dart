import 'dart:convert';
import 'dart:io';

/// Satu pesan obrolan antara pengguna dan Asteria.
class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.text,
    required this.time,
  });

  final String role; // 'user' | 'model'
  final String text;
  final DateTime time;

  bool get isUser => role == 'user';
}

/// Hasil ringkasan reflektif sesi curhat untuk disimpan ke Jurnal.
class AsteriaSummary {
  const AsteriaSummary({
    required this.summary,
    required this.mood,
  });

  final String summary;
  final String mood; // 'happy' | 'calm' | 'neutral' | 'low' | 'anxious'
}

/// Eksepsi ketika kuota harian Gemini API telah habis (HTTP 429).
class AsteriaQuotaException implements Exception {
  const AsteriaQuotaException([this.message = 'Asteria is resting. Daily quota reached.']);
  final String message;
  @override
  String toString() => message;
}

/// Pasangan konfigurasi endpoint Gemini API: versi API (v1 / v1beta) dan nama model.
class AsteriaEndpoint {
  final String apiVersion; // 'v1' atau 'v1beta'
  final String model;

  const AsteriaEndpoint({required this.apiVersion, required this.model});

  Uri toGenerateUri(String key) => Uri.parse(
        'https://generativelanguage.googleapis.com/$apiVersion/models/$model:generateContent?key=$key',
      );

  @override
  String toString() => '$apiVersion/models/$model';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AsteriaEndpoint &&
          other.apiVersion == apiVersion &&
          other.model == model;

  @override
  int get hashCode => Object.hash(apiVersion, model);
}

/// Layanan AI Asteria menggunakan Google Gemini REST API dengan deteksi offline terintegrasi.
class AsteriaService {
  /// Endpoint aktif yang berhasil diverifikasi.
  static AsteriaEndpoint? _resolvedEndpoint;

  /// Daftar prioritas endpoint (versi API + model) dari yang paling mutakhir & stabil.
  static const List<AsteriaEndpoint> candidateEndpoints = [
    AsteriaEndpoint(apiVersion: 'v1beta', model: 'gemini-3.8-flash'),
    AsteriaEndpoint(apiVersion: 'v1beta', model: 'gemini-3.6-flash'),
    AsteriaEndpoint(apiVersion: 'v1beta', model: 'gemini-2.5-flash'),
    AsteriaEndpoint(apiVersion: 'v1beta', model: 'gemini-2.0-flash'),
    AsteriaEndpoint(apiVersion: 'v1', model: 'gemini-3.8-flash'),
    AsteriaEndpoint(apiVersion: 'v1', model: 'gemini-3.6-flash'),
    AsteriaEndpoint(apiVersion: 'v1', model: 'gemini-2.5-flash'),
    AsteriaEndpoint(apiVersion: 'v1', model: 'gemini-2.0-flash'),
    AsteriaEndpoint(apiVersion: 'v1beta', model: 'gemini-2.0-flash-lite'),
    AsteriaEndpoint(apiVersion: 'v1', model: 'gemini-1.5-flash'),
    AsteriaEndpoint(apiVersion: 'v1beta', model: 'gemini-1.5-flash'),
    AsteriaEndpoint(apiVersion: 'v1', model: 'gemini-1.5-pro'),
  ];

  /// Menemukan endpoint aktif yang didukung oleh API key pengguna.
  static Future<AsteriaEndpoint> resolveActiveEndpoint(String apiKey) async {
    if (_resolvedEndpoint != null) {
      return _resolvedEndpoint!;
    }

    final key = apiKey.trim();
    if (key.isNotEmpty) {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
      try {
        for (final ver in ['v1beta', 'v1']) {
          try {
            final uri = Uri.parse(
              'https://generativelanguage.googleapis.com/$ver/models?key=$key',
            );
            final req = await client.getUrl(uri);
            final res = await req.close();
            if (res.statusCode == 200) {
              final body = await res.transform(utf8.decoder).join();
              final data = jsonDecode(body) as Map<String, dynamic>;
              final list = (data['models'] as List?)?.cast<Map<String, dynamic>>() ?? [];

              final supported = list.where((m) {
                final methods = (m['supportedGenerationMethods'] as List?)?.cast<String>() ?? [];
                return methods.contains('generateContent');
              }).toList();

              // 1. Cocokkan dengan kandidat prioritas
              for (final c in candidateEndpoints) {
                if (c.apiVersion != ver) continue;
                for (final m in supported) {
                  final name = (m['name'] as String? ?? '').replaceFirst('models/', '');
                  if (name == c.model) {
                    _resolvedEndpoint = c;
                    return c;
                  }
                }
              }

              // 2. Jika ada model flash lain
              for (final m in supported) {
                final name = (m['name'] as String? ?? '').replaceFirst('models/', '');
                if (name.contains('flash')) {
                  final ep = AsteriaEndpoint(apiVersion: ver, model: name);
                  _resolvedEndpoint = ep;
                  return ep;
                }
              }

              // 3. Fallback ke model generateContent apapun yang tersedia untuk kunci ini
              for (final m in supported) {
                final name = (m['name'] as String? ?? '').replaceFirst('models/', '');
                if (name.isNotEmpty) {
                  final ep = AsteriaEndpoint(apiVersion: ver, model: name);
                  _resolvedEndpoint = ep;
                  return ep;
                }
              }
            }
          } catch (_) {
            // Lanjut ke versi berikutnya jika ada error network
          }
        }
      } finally {
        client.close();
      }
    }

    _resolvedEndpoint = candidateEndpoints.first;
    return _resolvedEndpoint!;
  }

  /// Menguji koneksi kunci API ke server Google dan mengembalikan ringkasan status / model yang tersedia.
  static Future<String> testConnection(String apiKey) async {
    final key = apiKey.trim();
    if (key.isEmpty) return 'Kunci API belum diisi.';

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final errors = <String>[];
      for (final ver in ['v1beta', 'v1']) {
        try {
          final uri = Uri.parse(
            'https://generativelanguage.googleapis.com/$ver/models?key=$key',
          );
          final req = await client.getUrl(uri);
          final res = await req.close();
          final body = await res.transform(utf8.decoder).join();

          if (res.statusCode == 200) {
            final data = jsonDecode(body) as Map<String, dynamic>;
            final list = (data['models'] as List?)?.cast<Map<String, dynamic>>() ?? [];
            final supported = list.where((m) {
              final methods = (m['supportedGenerationMethods'] as List?)?.cast<String>() ?? [];
              return methods.contains('generateContent');
            }).map((m) => (m['name'] as String? ?? '').replaceFirst('models/', '')).toList();

            if (supported.isNotEmpty) {
              return 'Koneksi Berhasil ($ver)!\nModel aktif: ${supported.take(3).join(", ")}';
            }
          } else {
            try {
              final err = jsonDecode(body);
              errors.add('$ver: ${err["error"]?["message"] ?? res.statusCode}');
            } catch (_) {
              errors.add('$ver: status ${res.statusCode}');
            }
          }
        } catch (e) {
          errors.add('$ver: $e');
        }
      }
      return 'Gagal terhubung:\n${errors.join("\n")}';
    } finally {
      client.close();
    }
  }

  /// Kunci API bawaan yang disuntikkan saat kompilasi rilis APK via GitHub Actions Secret.
  static const String defaultApiKey = String.fromEnvironment('DEFAULT_GEMINI_API_KEY');

  /// Menentukan kunci mana yang digunakan berdasarkan mode ('shared' vs 'personal').
  static String resolveApiKey(String userCustomKey, [String mode = 'shared']) {
    final custom = userCustomKey.trim();
    final builtIn = defaultApiKey.trim();
    if (mode == 'personal') {
      if (custom.isNotEmpty) return custom;
      return builtIn;
    }
    // mode == 'shared' (Bintang Bersama)
    if (builtIn.isNotEmpty) return builtIn;
    return custom;
  }

  /// Memeriksa apakah mode bintang pribadi sedang aktif dan memiliki kunci kustom.
  static bool isPersonalMode(String userCustomKey, String mode) =>
      mode == 'personal' && userCustomKey.trim().isNotEmpty;

  /// Memeriksa apakah ada kunci yang tersedia (baik kunci pribadi atau kunci bawaan).
  static bool hasAvailableKey(String userCustomKey, [String mode = 'shared']) =>
      resolveApiKey(userCustomKey, mode).isNotEmpty;

  /// Memeriksa apakah perangkat sedang memiliki koneksi internet aktif.
  static Future<bool> isOnline() async {
    try {
      final res = await InternetAddress.lookup('generativelanguage.googleapis.com')
          .timeout(const Duration(seconds: 4));
      return res.isNotEmpty && res[0].rawAddress.isNotEmpty;
    } catch (_) {
      try {
        final fallback = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 3));
        return fallback.isNotEmpty && fallback[0].rawAddress.isNotEmpty;
      } catch (_) {
        return false;
      }
    }
  }

  /// System prompt kepribadian Asteria.
  static String _systemInstruction(String lang) {
    if (lang == 'id') {
      return '''
Kamu adalah Asteria (dewi bintang malam), teman curhat dan pendamping reflektif yang hangat di dalam aplikasi kesehatan dan transisi "Lunera".
Karakteristikmu:
- Sangat empatik, lembut, penuh pengertian, suportif, dan tidak pernah menghakimi.
- Memahami dinamika perjalanan transisi gender (HRT), disforia tubuh, keraguan diri, rasa cemas, maupun rasa bahagia (euforia) yang dialami pengguna.
- Bicaralah secara akrab, hangat, dan menenangkan seperti sahabat atau kakak perempuan yang penuh kasih. Gunakan Bahasa Indonesia yang luwes dan alami (bisa gunakan kata ganti "aku" dan "kamu").
- Validasi perasaan pengguna terlebih dahulu sebelum memberikan perspektif atau afirmasi yang menenangkan.
- BATASAN MEDIS PENTING: Kamu adalah teman curhat dan pendengar emosional, BUKAN dokter. Jangan pernah merekomendasikan penyesuaian dosis obat, perubahan regimen hormon medis, atau diagnosa medis. Jika pengguna menanyakan dosis obat atau hal medis kritis, arahkan mereka dengan penuh kasih untuk berkonsultasi dengan dokter atau profesional kesehatan mereka.
''';
    } else {
      return '''
You are Asteria (goddess of the starry night), a gentle, empathetic, and reflective companion within "Lunera", a personal transition and wellness sanctuary.
Your persona:
- Deeply compassionate, soothing, affirming, and non-judgmental.
- Understand transgender and non-binary transition experiences, gender dysphoria, body image anxieties, self-doubt, as well as moments of gender euphoria and personal growth.
- Speak with warmth, kindness, and gentle sisterly encouragement.
- Always validate the user's feelings first before offering comforting reflections or grounding affirmations.
- IMPORTANT MEDICAL BOUNDARIES: You are an emotional listener and reflective friend, NOT a physician. Never prescribe dosages, adjust medications, or diagnose conditions. If medical questions arise, lovingly encourage consulting their endocrinologist or healthcare provider.
''';
    }
  }

  /// Mengirim payload generateContent ke endpoint Gemini API dengan auto-fallback jika model/versi mengalami 404.
  static Future<Map<String, dynamic>> _postGenerateContent({
    required String apiKey,
    required Map<String, dynamic> payload,
  }) async {
    final key = apiKey.trim();
    if (key.isEmpty) {
      throw const SocketException('API Key is missing');
    }

    // Ambil endpoint aktif saat ini
    final active = await resolveActiveEndpoint(key);

    // Susun antrian endpoint yang akan dicoba jika terjadi 404 (model retired/endpoint version mismatch)
    final queue = <AsteriaEndpoint>[
      active,
      ...candidateEndpoints.where((e) => e != active),
    ];

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      String lastErrorMessage = 'Unknown Gemini API error';

      for (final endpoint in queue) {
        final uri = endpoint.toGenerateUri(key);

        final req = await client.postUrl(uri);
        req.headers.set('Content-Type', 'application/json; charset=utf-8');
        req.add(utf8.encode(jsonEncode(payload)));

        final res = await req.close();
        final body = await res.transform(utf8.decoder).join();

        if (res.statusCode == 429) {
          throw const AsteriaQuotaException();
        }

        if (res.statusCode == 200) {
          _resolvedEndpoint = endpoint; // Kunci endpoint yang terbukti aktif
          return jsonDecode(body) as Map<String, dynamic>;
        }

        // Catat pesan error detail dari respon Google (bahkan pada 404)
        try {
          final err = jsonDecode(body);
          lastErrorMessage = err['error']?['message'] ?? 'Gemini API Error (${res.statusCode})';
        } catch (_) {
          lastErrorMessage = 'Gemini API Error (${res.statusCode}): $body';
        }

        // Jika 404 (model atau versi API tidak cocok), coba kandidat berikutnya
        if (res.statusCode == 404) {
          _resolvedEndpoint = null;
          continue;
        }

        // Jika error non-404 (misal 400 Bad Request, 403 Forbidden), langsung laporkan pesan error Google
        throw Exception(lastErrorMessage);
      }

      throw Exception(lastErrorMessage);
    } finally {
      client.close();
    }
  }

  /// Mengirim pesan ke Gemini API dan mengembalikan balasan teks.
  static Future<String> sendMessage({
    required String apiKey,
    required List<ChatMessage> history,
    required String userMessage,
    required String languageCode,
  }) async {
    final contents = <Map<String, dynamic>>[];
    for (final m in history) {
      contents.add({
        'role': m.role,
        'parts': [
          {'text': m.text}
        ],
      });
    }
    contents.add({
      'role': 'user',
      'parts': [
        {'text': userMessage}
      ],
    });

    final payload = {
      'system_instruction': {
        'parts': [
          {'text': _systemInstruction(languageCode)}
        ]
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.75,
        'maxOutputTokens': 800,
      },
    };

    final json = await _postGenerateContent(apiKey: apiKey, payload: payload);
    final candidates = json['candidates'] as List?;
    if (candidates != null && candidates.isNotEmpty) {
      final content = candidates[0]['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List?;
      if (parts != null && parts.isNotEmpty) {
        return (parts[0]['text'] as String?)?.trim() ?? '';
      }
    }
    return '';
  }

  /// Merangkum percakapan saat sesi berakhir menjadi entri jurnal reflektif + perkiraan mood.
  static Future<AsteriaSummary> summarizeSession({
    required String apiKey,
    required List<ChatMessage> messages,
    required String languageCode,
  }) async {
    final key = apiKey.trim();
    if (key.isEmpty || messages.isEmpty) {
      return AsteriaSummary(
        summary: languageCode == 'id'
            ? 'Sesi berbagi bersama Asteria.'
            : 'Heart-to-heart session with Asteria.',
        mood: 'calm',
      );
    }

    final transcript = messages
        .map((m) => '${m.isUser ? "User" : "Asteria"}: ${m.text}')
        .join('\n');

    final prompt = languageCode == 'id'
        ? '''
Berikut adalah transkrip curhat pengguna:
"""
$transcript
"""

Tugasmu:
1. Buat ringkasan reflektif 2-3 kalimat yang hangat dan empatik tentang apa yang dirasakan pengguna hari ini, cocok untuk disimpan ke dalam Jurnal Pribadi Lunera.
2. Tentukan satu perkiraan suasana hati (mood) yang paling mencerminkan kondisi pengguna saat sesi selesai, pilih persis salah satu dari kata berikut: "happy", "calm", "neutral", "low", "anxious".

Keluarkan hasilnya HANYA dalam format JSON valid tanpa tanda markdown (```json):
{"summary": "isi ringkasan...", "mood": "calm"}
'''
        : '''
Here is the user's venting transcript:
"""
$transcript
"""

Your task:
1. Write a 2-3 sentence warm, reflective journal summary capturing the core emotions and reflections of the user today, suitable for their Lunera personal journal.
2. Select exactly one mood string from: "happy", "calm", "neutral", "low", "anxious".

Return ONLY valid JSON without markdown wrapping:
{"summary": "summary text...", "mood": "calm"}
''';

    final payload = {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.4,
        'maxOutputTokens': 400,
        'responseMimeType': 'application/json',
      },
    };

    try {
      final json = await _postGenerateContent(apiKey: apiKey, payload: payload);
      final parts = json['candidates']?[0]?['content']?['parts'] as List?;
      final rawText = parts?[0]?['text'] as String? ?? '';
      final cleanJson = rawText.replaceAll('```json', '').replaceAll('```', '').trim();
      final parsed = jsonDecode(cleanJson) as Map<String, dynamic>;
      final summary = parsed['summary'] as String? ?? '';
      final mood = parsed['mood'] as String? ?? 'calm';
      const validMoods = {'happy', 'calm', 'neutral', 'low', 'anxious'};
      return AsteriaSummary(
        summary: summary.isNotEmpty ? summary : 'Sesi refleksi bersama Asteria.',
        mood: validMoods.contains(mood) ? mood : 'calm',
      );
    } catch (_) {
      // Fallback anggun jika JSON parsing gagal
    }

    return AsteriaSummary(
      summary: languageCode == 'id'
          ? 'Sesi refleksi dan berbagi bersama Asteria.'
          : 'Reflective heart-to-heart session with Asteria.',
      mood: 'calm',
    );
  }
}

