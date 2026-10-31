import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n_id.dart';

/// Bahasa aplikasi: English (bawaan) atau Indonesia. Disimpan per perangkat.
class L10n {
  L10n._();
  static final notifier = ValueNotifier<String>('en');
  static String get code => notifier.value;

  static Future<void> load() async {
    final c = (await SharedPreferences.getInstance()).getString('app.lang');
    notifier.value = c == 'id' ? 'id' : 'en';
  }

  static Future<void> set(String c) async {
    final code = c == 'id' ? 'id' : 'en';
    if (code == notifier.value) return;
    await (await SharedPreferences.getInstance()).setString('app.lang', code);
    notifier.value = code;
  }
}

/// Backwards compatibility for AppLocale
class AppLocale {
  static String get code => L10n.code;
  static const supported = [Locale('en'), Locale('id')];
}

final _plural = RegExp(r'\{(\d+)\?([^|}]*)\|([^}]*)\}');
final _slot = RegExp(r'\{(\d+)\}');

/// Terjemahan. Teks dasar (kunci) selalu English; Indonesia diambil dari `idStrings`.
/// `{0}`, `{1}` diisi dari [args]; `{0?day|days}` memilih kata tunggal atau jamak menurut argumen ke-0.
/// Mendukung argumen List `[a, b]` maupun Map `{'name': 'val'}` untuk fleksibilitas.
String tr(String en, [dynamic args = const []]) {
  var s = en;
  if (L10n.code == 'id') {
    final t = idStrings[en];
    if (t != null) {
      s = t;
    } else if (kDebugMode) {
      debugPrint('i18n: belum ada terjemahan Indonesia untuk "$en"');
    }
  }
  if (args is Map) {
    args.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
    return s;
  }
  final list = args is List ? args : [args];
  s = s.replaceAllMapped(_plural, (m) {
    final i = int.parse(m[1]!);
    final v = i < list.length ? list[i] : null;
    final n = v is num ? v : num.tryParse('$v');
    return n == 1 ? m[2]! : m[3]!;
  });
  return s.replaceAllMapped(_slot, (m) {
    final i = int.parse(m[1]!);
    return i < list.length ? '${list[i]}' : m[0]!;
  });
}

extension TrContext on BuildContext {
  String tr(String key, [dynamic args = const []]) => l10nTr(key, args);
}

String trG(String key, [dynamic args = const []]) => tr(key, args);
String l10nTr(String key, [dynamic args = const []]) => tr(key, args);

/// Sapaan menurut jam. English memakai tiga bagian hari, Indonesia empat.
String greeting() {
  final h = DateTime.now().hour;
  if (L10n.code == 'id') return h < 11 ? 'Selamat pagi' : (h < 15 ? 'Selamat siang' : (h < 19 ? 'Selamat sore' : 'Selamat malam'));
  return h < 12 ? 'Good morning' : (h < 17 ? 'Good afternoon' : 'Good evening');
}

/// Untuk provider yang harus dijalankan ulang saat bahasa berganti (notifikasi, widget).
final langProvider = Provider<String>((ref) {
  void listener() => ref.invalidateSelf();
  L10n.notifier.addListener(listener);
  ref.onDispose(() => L10n.notifier.removeListener(listener));
  return L10n.code;
});
