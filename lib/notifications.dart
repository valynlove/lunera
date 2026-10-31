import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'models.dart';
import 'repo.dart';
import 'schedule.dart';
import 'l10n.dart';

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
    final info = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(info.identifier));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false),
      ),
    );
    _ready = true;
  }

  NotificationDetails get _details => NotificationDetails(
        android: AndroidNotificationDetails(
          'doses',
          tr('Dose reminders'),
          channelDescription: tr('Medication and injection schedule reminders'),
          importance: Importance.max,
          priority: Priority.max,
        ),
        iOS: const DarwinNotificationDetails(interruptionLevel: InterruptionLevel.timeSensitive, presentAlert: true, presentBadge: true, presentSound: true),
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
        'inj' => tr('Time for your injection'),
        'oral' || 'sublingual' || 'supp' => tr('Time to take your medication'),
        'patch' => tr('Time to change your patch'),
        _ => tr('Time for your medication'),
      };

  Future<void> test([Prefs? prefs]) async {
    if (!supported) return;
    await init();
    String title = 'Lunera';
    String body = tr('Reminder notifications are working.');
    if (prefs?.discreetNotify == 'wellness') {
      title = tr('Routine Reminder ✦');
      body = tr('Time for your daily hydration and wellness routine.');
    } else if (prefs?.discreetNotify == 'minimal') {
      title = 'Lunera ✦';
      body = tr('Gentle reminder.');
    }
    await _plugin.show(id: 1, title: title, body: body, notificationDetails: _details);
  }

  Future<void> cancelAll() async {
    if (!supported) return;
    await init();
    await _plugin.cancelAll();
  }

  /// Jadwalkan ulang semua pengingat (diserialkan agar tidak saling menimpa).
  Future<void> sync(List<Therapy> ths, List<DoseLog> logs, List<Supply> supplies, Prefs prefs) {
    _chain = _chain.then((_) => _sync(ths, logs, supplies, prefs)).catchError((Object e) {
      debugPrint(tr('Failed to schedule notifications: {0}', [e]));
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

      String title;
      String body;
      if (prefs.discreetNotify == 'wellness') {
        title = tr('Routine Reminder ✦');
        body = tr('Time for your daily hydration and wellness routine.');
      } else if (prefs.discreetNotify == 'minimal') {
        title = 'Lunera ✦';
        body = tr('Gentle reminder.');
      } else {
        title = '${_verb(t)}: ${t.name}';
        body = '${fmt(t.dose)} ${t.doseUnit}${place.isEmpty ? '' : ', ${tr('site: {0}', [tr(place)])}'}';
      }

      await _plugin.zonedSchedule(
        id: _id(t, s.at),
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime(tz.local, s.at.year, s.at.month, s.at.day, s.at.hour, s.at.minute),
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
          await at9(DateTime(firstMorning.year, firstMorning.month, firstMorning.day + d, 9), 'low|${s.id}|$d', tr('Running low'),
              s.generic ? tr('{0}: {1} left', [s.name, fmt(s.qty)]) : tr('{0}: {1} {1?dose|doses} left', [s.name, s.doses]));
        }
      }
      final e = s.expiry;
      if (e != null) {
        for (final lead in const [14, 3, 0]) {
          final at = DateTime(e.year, e.month, e.day - lead, 9);
          if (!at.isAfter(now)) continue;
          await at9(at, 'exp|${s.id}|$lead', lead == 0 ? tr('Medication expires today') : tr('Medication expiring soon'), lead == 0 ? s.name : tr('{0}: {1} {1?day|days} left', [s.name, lead]));
        }
      }
    }
  }
}

/// Dipantau dari Shell: menjadwalkan ulang notifikasi saat data berubah.
final notifySyncProvider = Provider<void>((ref) {
  ref.watch(langProvider); // teks notifikasi ikut bahasa
  final ths = ref.watch(therapiesProvider).value;
  final logs = ref.watch(logsProvider).value;
  final supplies = ref.watch(suppliesProvider).value;
  final prefs = ref.watch(prefsProvider).value;
  if (ths == null || logs == null || supplies == null || prefs == null) return;
  AppNotifier.instance.sync(ths, logs, supplies, prefs);
});
