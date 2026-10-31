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

/// Layanan AI Asteria menggunakan Google Gemini REST API dengan deteksi offline terintegrasi.
class AsteriaService {
  static const String _model = 'gemini-1.5-flash';

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

  /// Mengirim pesan ke Gemini API dan mengembalikan balasan teks.
  static Future<String> sendMessage({
    required String apiKey,
    required List<ChatMessage> history,
    required String userMessage,
    required String languageCode,
  }) async {
    final key = apiKey.trim();
    if (key.isEmpty) {
      throw const SocketException('API Key is missing');
    }

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$key',
    );

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

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final req = await client.postUrl(uri);
      req.headers.set('Content-Type', 'application/json; charset=utf-8');
      req.add(utf8.encode(jsonEncode(payload)));

      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();

      if (res.statusCode != 200) {
        final err = jsonDecode(body);
        final msg = err['error']?['message'] ?? 'Gemini API Error (${res.statusCode})';
        throw Exception(msg);
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      final candidates = json['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          return (parts[0]['text'] as String?)?.trim() ?? '';
        }
      }
      return '';
    } finally {
      client.close();
    }
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

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$key',
    );

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

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final req = await client.postUrl(uri);
      req.headers.set('Content-Type', 'application/json; charset=utf-8');
      req.add(utf8.encode(jsonEncode(payload)));

      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();

      if (res.statusCode == 200) {
        final json = jsonDecode(body) as Map<String, dynamic>;
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
      }
    } catch (_) {
      // Fallback anggun jika JSON parsing gagal
    } finally {
      client.close();
    }

    return AsteriaSummary(
      summary: languageCode == 'id'
          ? 'Sesi refleksi dan berbagi bersama Asteria.'
          : 'Reflective heart-to-heart session with Asteria.',
      mood: 'calm',
    );
  }
}
