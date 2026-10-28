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

    const channel = AndroidNotificationChannel(
      'doses',
      'Dose Reminders',
      description: 'Medication and injection schedule reminders',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    await _android?.createNotificationChannel(channel);

    _ready = true;
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          'doses',
          'Dose Reminders',
          channelDescription: 'Medication and injection schedule reminders',
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
        'inj' => 'Time for injection',
        'oral' || 'sublingual' || 'supp' => 'Time to take medication',
        'patch' => 'Time to change patch',
        _ => 'Time to take medication',
      };

  Future<bool> test() async {
    if (!supported) return false;
    await init();
    await requestPermission();
    await _plugin.show(
      id: 1,
      title: 'Lunera',
      body: 'Notification reminders are working properly. ✨',
      notificationDetails: _details,
    );
    return true;
  }

  Future<void> cancelAll() async {
    if (!supported) return;
    await init();
    await _plugin.cancelAll();
  }

  /// Jadwalkan ulang semua pengingat (diserialkan agar tidak saling menimpa).
  Future<void> sync(List<Therapy> ths, List<DoseLog> logs, Prefs prefs) {
    _chain = _chain.then((_) => _sync(ths, logs, prefs)).catchError((Object e) {
      debugPrint('Failed to schedule notifications: $e');
    });
    return _chain;
  }

  Future<void> _sync(List<Therapy> ths, List<DoseLog> logs, Prefs prefs) async {
    if (!supported) return;
    await init();
    await _plugin.cancelAll();
    if (!prefs.notify) return;
    final now = DateTime.now();
    final mode = await _canExact() ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle;
    final desc = [...logs]..sort((a, b) => b.at.compareTo(a.at));
    final slots = [
      for (final s in buildSlots(ths, logs, prefs, back: 0, ahead: 21))
        if (!s.taken && s.at.isAfter(now)) s,
    ];
    for (final s in slots.take(60)) {
      final t = s.t;
      final place = t.adm.places ? suggestPlace(prefs, desc, t.id) : '';
      final scheduledDate = tz.TZDateTime.from(s.at, tz.local);
      if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
        continue;
      }
      await _plugin.zonedSchedule(
        id: _id(t, s.at),
        title: '${_verb(t)}: ${t.name}',
        body: '${fmt(t.dose)} ${t.doseUnit}${place.isEmpty ? '' : ', site: $place'}',
        scheduledDate: scheduledDate,
        notificationDetails: _details,
        androidScheduleMode: mode,
      );
    }
  }

  Future<void> checkStockAlerts(List<Supply> supplies) async {
    if (!supported) return;
    await init();
    for (final s in supplies) {
      if (s.doses > 0 && s.doses <= 3) {
        await _plugin.show(
          id: ('stock|${s.id}').hashCode & 0x7fffffff,
          title: 'Low Stock Alert: ${s.name}',
          body: 'Only ${s.doses} doses remaining. Please restock soon.',
          notificationDetails: _details,
        );
      }
      if (s.expiry != null) {
        final leftDays = s.expiry!.difference(DateTime.now()).inDays;
        if (leftDays <= 7 && leftDays >= 0) {
          await _plugin.show(
            id: ('expiry|${s.id}').hashCode & 0x7fffffff,
            title: 'Expiry Warning: ${s.name}',
            body: 'Stock ${s.name} will expire in $leftDays days.',
            notificationDetails: _details,
          );
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
  if (ths == null || logs == null || prefs == null) return;
  AppNotifier.instance.sync(ths, logs, prefs);
  if (supplies != null) {
    AppNotifier.instance.checkStockAlerts(supplies);
  }
});
