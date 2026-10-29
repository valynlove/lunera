import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'models.dart';
import 'repo.dart';
import 'schedule.dart';

/// Pengingat dosis lewat notifikasi lokal (Android dan iOS). Dijadwalkan ulang
/// setiap terapi, catatan, atau pengaturan berubah, jadi tetap muncul saat offline.
class AppNotifier {
  AppNotifier._();
  static final instance = AppNotifier._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  Future<void> _chain = Future.value();

  bool get supported => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  IOSFlutterLocalNotificationsPlugin? get _ios =>
      _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

  Future<void> init() async {
    if (_ready || !supported) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      try {
        tz.setLocalLocation(tz.getLocation(info.identifier));
      } catch (_) {
        final offset = DateTime.now().timeZoneOffset;
        final matching = tz.timeZoneDatabase.locations.values.firstWhere(
          (l) => l.currentTimeZone.offset == offset,
          orElse: () => tz.getLocation('UTC'),
        );
        tz.setLocalLocation(matching);
      }
    } catch (e) {
      debugPrint('Gagal set timezone lokal, fallback ke UTC: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false),
      ),
    );

    // Daftarkan channel Android secara eksplisit dengan sound & vibration
    const dosesChannel = AndroidNotificationChannel(
      'doses',
      'Pengingat dosis',
      description: 'Pengingat jadwal obat dan suntikan',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    await _android?.createNotificationChannel(dosesChannel);

    _ready = true;
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          'doses',
          'Pengingat dosis',
          channelDescription: 'Pengingat jadwal obat dan suntikan',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(interruptionLevel: InterruptionLevel.timeSensitive, presentAlert: true, presentBadge: true, presentSound: true),
      );

  Future<bool> requestPermission() async {
    if (!supported) return false;
    await init();
    final a = _android;
    if (a != null) {
      final ok = await a.requestNotificationsPermission();
      await a.requestExactAlarmsPermission();
      return ok ?? false;
    }
    return await _ios?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
  }

  Future<bool> _canExact() async => (await _android?.canScheduleExactNotifications()) ?? false;

  int _id(Therapy t, DateTime at) => '${t.id}|${slotKey(at)}'.hashCode & 0x7fffffff;

  String _verb(Therapy t) => switch (t.route) {
        'inj' => 'Waktunya suntik',
        'oral' || 'sublingual' || 'supp' => 'Waktunya minum obat',
        'patch' => 'Waktunya ganti patch',
        _ => 'Waktunya pakai obat',
      };

  Future<void> test() async {
    if (!supported) return;
    await init();
    await _plugin.show(id: 1, title: 'Lunera', body: 'Notifikasi pengingat berfungsi.', notificationDetails: _details);
  }

  Future<void> cancelAll() async {
    if (!supported) return;
    await init();
    await _plugin.cancelAll();
  }

  /// Jadwalkan ulang semua pengingat (diserialkan agar tidak saling menimpa).
  Future<void> sync(List<Therapy> ths, List<DoseLog> logs, List<Supply> supplies, Prefs prefs) {
    _chain = _chain.then((_) => _sync(ths, logs, supplies, prefs)).catchError((Object e) {
      debugPrint('Gagal menjadwalkan notifikasi: $e');
    });
    return _chain;
  }

  Future<void> _sync(List<Therapy> ths, List<DoseLog> logs, List<Supply> supplies, Prefs prefs) async {
    if (!supported) return;
    await init();
    await _plugin.cancelAll();
    if (!prefs.notify) return;
    final now = DateTime.now();
    final mode = await _canExact() ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle;
    final desc = [...logs]..sort((a, b) => b.at.compareTo(a.at));
    final slots = [
      for (final s in buildSlots(ths, logs, prefs, back: 0, ahead: 21))
        if (s.pending && s.at.isAfter(now)) s,
    ];
    for (final s in slots.take(60)) {
      final t = s.t;
      final place = t.adm.places ? suggestPlace(prefs, desc, t.id) : '';
      await _plugin.zonedSchedule(
        id: _id(t, s.at),
        title: '${_verb(t)}: ${t.name}',
        body: '${fmt(t.dose)} ${t.doseUnit}${place.isEmpty ? '' : ', lokasi: $place'}',
        scheduledDate: tz.TZDateTime.from(s.at, tz.local),
        notificationDetails: _details,
        androidScheduleMode: mode,
      );
    }

    // Stok hampir habis: pagi pukul 09:00, tiga hari berturut-turut selama masih menipis.
    Future<void> at9(DateTime at, String key, String title, String body) => _plugin.zonedSchedule(
          id: key.hashCode & 0x7fffffff,
          title: title,
          body: body,
          scheduledDate: tz.TZDateTime(tz.local, at.year, at.month, at.day, at.hour, at.minute),
          notificationDetails: _details,
          androidScheduleMode: mode,
        );
    final firstMorning = now.hour < 9 ? DateTime(now.year, now.month, now.day, 9) : DateTime(now.year, now.month, now.day + 1, 9);
    for (final s in supplies) {
      if (s.low && !s.expired) {
        for (var d = 0; d < 3; d++) {
          await at9(DateTime(firstMorning.year, firstMorning.month, firstMorning.day + d, 9), 'low|${s.id}|$d', 'Stok hampir habis',
              s.generic ? '${s.name}: tinggal ${fmt(s.qty)}' : '${s.name}: ${s.doses} dosis tersisa');
        }
      }
      final e = s.expiry;
      if (e != null) {
        for (final lead in const [14, 3, 0]) {
          final at = DateTime(e.year, e.month, e.day - lead, 9);
          if (!at.isAfter(now)) continue;
          await at9(at, 'exp|${s.id}|$lead', lead == 0 ? 'Obat kedaluwarsa hari ini' : 'Obat segera kedaluwarsa', lead == 0 ? s.name : '${s.name}: $lead hari lagi');
        }
      }
    }
  }
}

/// Dipantau dari Shell: menjadwalkan ulang notifikasi saat data berubah.
final notifySyncProvider = Provider<void>((ref) {
  final ths = ref.watch(therapiesProvider).value;
  final logs = ref.watch(logsProvider).value;
  final supplies = ref.watch(suppliesProvider).value;
  final prefs = ref.watch(prefsProvider).value;
  if (ths == null || logs == null || supplies == null || prefs == null) return;
  AppNotifier.instance.sync(ths, logs, supplies, prefs);
});
