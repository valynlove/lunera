import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'models.dart';
import 'repo.dart';
import 'schedule.dart';
import 'l10n.dart';

String _verb(Therapy t) => switch (t.route) {
      'inj' => tr('Time for your injection'),
      'oral' || 'sublingual' || 'supp' => tr('Time to take your medication'),
      'patch' => tr('Time to change your patch'),
      _ => tr('Time for your medication'),
    };

/// Format judul & isi pengingat dosis sesuai mode privasi layar kunci.
(String, String) doseNotificationText(Therapy t, Prefs prefs,
    {String place = ''}) {
  if (prefs.discreetNotify == 'wellness') {
    return (
      tr('Routine Reminder ✦'),
      tr('Time for your daily hydration and wellness routine.')
    );
  }
  if (prefs.discreetNotify == 'minimal') {
    return ('Lunera ✦', tr('Gentle reminder.'));
  }
  return (
    '${_verb(t)}: ${t.name}',
    '${fmt(t.dose)} ${t.doseUnit}${place.isEmpty ? '' : ', ${tr('site: {0}', [
            tr(place)
          ])}'}',
  );
}

/// Format judul & isi pengingat stok menipis sesuai mode privasi layar kunci.
(String, String) lowSupplyNotificationText(Supply s, Prefs prefs) {
  if (prefs.discreetNotify == 'wellness') {
    return (
      tr('Routine Supplies ✦'),
      tr('One of your daily wellness essentials is running low.')
    );
  }
  if (prefs.discreetNotify == 'minimal') {
    return ('Lunera ✦', tr('Gentle reminder.'));
  }
  return (
    tr('Running low'),
    s.generic
        ? tr('{0}: {1} left', [s.name, fmt(s.qty)])
        : tr('{0}: {1} {1?dose|doses} left', [s.name, s.doses]),
  );
}

/// Format judul & isi pengingat masa simpan / kedaluwarsa sesuai mode privasi layar kunci.
(String, String) expiryNotificationText(Supply s, int leadDays, Prefs prefs) {
  if (prefs.discreetNotify == 'wellness') {
    return (
      tr('Routine Supplies ✦'),
      tr('Check the shelf-life of your daily wellness essentials.')
    );
  }
  if (prefs.discreetNotify == 'minimal') {
    return ('Lunera ✦', tr('Gentle reminder.'));
  }
  return (
    leadDays == 0
        ? tr('Medication expires today')
        : tr('Medication expiring soon'),
    leadDays == 0
        ? s.name
        : tr('{0}: {1} {1?day|days} left', [s.name, leadDays]),
  );
}

/// Format judul & isi pengingat cek lab trough sesuai mode privasi layar kunci.
(String, String) troughLabNotificationText(Slot slot, Prefs prefs) {
  if (prefs.discreetNotify == 'wellness') {
    return (
      tr('Health & Lab Timing ✦'),
      tr('Upcoming schedule check-in reminder.')
    );
  }
  if (prefs.discreetNotify == 'minimal') {
    return ('Lunera ✦', tr('Gentle reminder.'));
  }
  final hhmm =
      '${slot.at.hour.toString().padLeft(2, '0')}:${slot.at.minute.toString().padLeft(2, '0')}';
  return (
    tr('Trough bloodwork window'),
    tr('Consider bloodwork before taking {0} at {1}.', [slot.t.name, hhmm]),
  );
}

/// Format gentle, guilt-free workout reminder copy respecting lockscreen privacy mode.
(String, String) workoutNotificationText(WorkoutProfile profile, Prefs prefs) {
  if (prefs.discreetNotify == 'minimal') {
    return ('Lunera ✦', tr('Gentle reminder.'));
  }
  if (prefs.discreetNotify == 'wellness') {
    return (
      tr('Movement Window ✦'),
      tr('Got 15 minutes? Your gentle session is ready whenever you are.'),
    );
  }
  return (
    tr('Lunera Personal Coach ✦'),
    tr(
      'Got 15 minutes around {0}? Your gentle HRT-friendly session is ready.',
      [profile.reminderTime],
    ),
  );
}

/// Format gentle hydration reminder copy respecting lockscreen privacy mode.
(String, String) hydrationNotificationText(Prefs prefs) {
  if (prefs.discreetNotify == 'minimal') {
    return ('Lunera ✦', tr('Gentle reminder.'));
  }
  return ('Lunera 💧', tr('Time for a gentle sip of water. Stay hydrated!'));
}

const _luneraSound = RawResourceAndroidNotificationSound('lunera_chime');
const _snoozeTag = 'snz';
const markTakenActionId = 'mark_taken';
const dismissDoseActionId = 'dismiss_dose';
const _snooze15Action = 'snooze_15';
const _snooze30Action = 'snooze_30';
const _doseCategory = 'dose_actions';

String snoozePayload({
  required String therapyId,
  required String slot,
  required String title,
  required String body,
  bool isInjection = false,
}) =>
    jsonEncode({
      'k': _snoozeTag,
      'tid': therapyId,
      'slot': slot,
      'title': title,
      'body': body,
      if (isInjection) 'inj': true,
    });

Map<String, dynamic>? parseSnoozePayload(String? payload) {
  if (payload == null || payload.isEmpty) return null;
  try {
    final m = jsonDecode(payload);
    if (m is! Map<String, dynamic> || m['k'] != _snoozeTag) return null;
    if (m['tid'] is! String ||
        m['slot'] is! String ||
        m['title'] is! String ||
        m['body'] is! String) {
      return null;
    }
    return m;
  } catch (_) {
    return null;
  }
}

int? snoozeMinutes(String? actionId) => switch (actionId) {
      _snooze15Action => 15,
      _snooze30Action => 30,
      _ => null,
    };

bool isQuickLogResponse(String? actionId) =>
    actionId == markTakenActionId || actionId == null || actionId.isEmpty;

bool keepSnooze(String? payload, Set<String> pendingKeys) {
  final p = parseSnoozePayload(payload);
  return p != null && pendingKeys.contains('${p['tid']}|${p['slot']}');
}

NotificationDetails buildDoseNotificationDetails({
  bool withActions = true,
  bool ongoing = false,
}) =>
    NotificationDetails(
      android: AndroidNotificationDetails(
        'doses',
        tr('Dose reminders'),
        channelDescription: tr('Medication and injection schedule reminders'),
        importance: Importance.max,
        priority: Priority.max,
        sound: _luneraSound,
        playSound: true,
        ongoing: ongoing,
        autoCancel: !ongoing,
        actions: withActions
            ? [
                AndroidNotificationAction(
                  markTakenActionId,
                  tr('Mark taken'),
                  showsUserInterface: true,
                  cancelNotification: true,
                ),
                AndroidNotificationAction(
                  _snooze15Action,
                  tr('Snooze 15 min'),
                  showsUserInterface: false,
                  cancelNotification: true,
                ),
                if (ongoing)
                  AndroidNotificationAction(
                    dismissDoseActionId,
                    '✕ ${tr('Dismiss')}',
                    showsUserInterface: false,
                    cancelNotification: true,
                  )
                else
                  AndroidNotificationAction(
                    _snooze30Action,
                    tr('Snooze 30 min'),
                    showsUserInterface: false,
                    cancelNotification: true,
                  ),
              ]
            : null,
      ),
      iOS: DarwinNotificationDetails(
        categoryIdentifier: withActions ? _doseCategory : null,
        interruptionLevel: InterruptionLevel.timeSensitive,
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  if (response.actionId == dismissDoseActionId) {
    final id = response.id;
    if (id != null) {
      FlutterLocalNotificationsPlugin().cancel(id: id);
    }
    return;
  }
  AppNotifier.snoozeFromResponse(response);
}

/// Pengingat dosis lewat notifikasi lokal (Android dan iOS). Dijadwalkan ulang
/// setiap terapi, catatan, atau pengaturan berubah, jadi tetap muncul saat offline.
class AppNotifier {
  AppNotifier._();
  static final instance = AppNotifier._();

  /// Holds a pending `(therapyId, slotKey)` triggered by tapping a dose
  /// notification or its "Mark taken" action so the foreground shell opens
  /// the confirmation sheet safely behind LockGate.
  static final pendingQuickDose = ValueNotifier<(String, String)?>(null);

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  Future<void> _chain = Future.value();

  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  IOSFlutterLocalNotificationsPlugin? get _ios =>
      _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

  /// Handles foreground notification responses (dismiss, snooze, and Mark taken).
  static Future<void> handleNotificationResponse(NotificationResponse r) async {
    if (r.actionId == dismissDoseActionId) {
      final id = r.id;
      if (id != null) {
        try {
          await FlutterLocalNotificationsPlugin().cancel(id: id);
        } catch (_) {}
      }
      return;
    }
    if (snoozeMinutes(r.actionId) != null) {
      await snoozeFromResponse(r);
      return;
    }
    if (isQuickLogResponse(r.actionId)) {
      final p = parseSnoozePayload(r.payload);
      if (p != null) {
        pendingQuickDose.value = (p['tid'] as String, p['slot'] as String);
      }
    }
  }

  static Future<void> snoozeFromResponse(NotificationResponse r) async {
    final m = snoozeMinutes(r.actionId);
    final p = parseSnoozePayload(r.payload);
    if (m == null || p == null) return;
    try {
      tzdata.initializeTimeZones();
      try {
        final info = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(info.identifier));
      } catch (_) {}
      final plugin = FlutterLocalNotificationsPlugin();
      final exact = (await plugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.canScheduleExactNotifications()) ??
          false;
      final mode = exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
      final id = ('${p['tid']}|${p['slot']}|$_snoozeTag').hashCode & 0x7fffffff;
      await plugin.zonedSchedule(
        id: id,
        title: p['title'] as String,
        body: p['body'] as String,
        scheduledDate: tz.TZDateTime.now(tz.local).add(Duration(minutes: m)),
        notificationDetails: buildDoseNotificationDetails(
          withActions: true,
          ongoing: p['inj'] == true,
        ),
        androidScheduleMode: mode,
        payload: r.payload,
      );
    } catch (e) {
      debugPrint('Snooze failed: $e');
    }
  }

  Future<void> init() async {
    if (_ready || !supported) return;
    tzdata.initializeTimeZones();
    final info = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(info.identifier));
    await _plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          notificationCategories: [
            DarwinNotificationCategory(
              _doseCategory,
              actions: [
                DarwinNotificationAction.plain(
                  markTakenActionId,
                  tr('Mark taken'),
                  options: {DarwinNotificationActionOption.foreground},
                ),
                DarwinNotificationAction.plain(
                  _snooze15Action,
                  tr('Snooze 15 min'),
                ),
                DarwinNotificationAction.plain(
                  _snooze30Action,
                  tr('Snooze 30 min'),
                ),
              ],
            ),
          ],
        ),
      ),
      onDidReceiveNotificationResponse: handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    _ready = true;
  }

  NotificationDetails get _details => buildDoseNotificationDetails(withActions: false);

  Future<bool> requestPermission() async {
    if (!supported) return false;
    await init();
    final a = _android;
    if (a != null) {
      final ok = await a.requestNotificationsPermission();
      await a.requestExactAlarmsPermission();
      return ok ?? false;
    }
    return await _ios?.requestPermissions(
            alert: true, badge: true, sound: true) ??
        false;
  }

  Future<bool> _canExact() async =>
      (await _android?.canScheduleExactNotifications()) ?? false;

  int _id(Therapy t, DateTime at) =>
      '${t.id}|${slotKey(at)}'.hashCode & 0x7fffffff;

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
    await _plugin.show(
        id: 1, title: title, body: body, notificationDetails: _details);
  }

  static const _troughReminderPrefKey = 'labs.trough_reminder_at';
  static const _troughPayload = 'trough_lab';
  static const _workoutPayload = 'workout_reminder';
  static const _hydrationPrefKey = 'hydration_notify_enabled';
  static const _hydrationPayload = 'hydration_reminder';
  static int get _troughReminderId =>
      'trough_lab_reminder'.hashCode & 0x7fffffff;

  NotificationDetails get _workoutDetails => NotificationDetails(
        android: AndroidNotificationDetails(
          'workout_coach',
          tr('Movement Coach reminders'),
          channelDescription:
              tr('Gentle optional movement reminders in your comfort window'),
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          sound: _luneraSound,
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          interruptionLevel: InterruptionLevel.active,
          presentAlert: true,
          presentBadge: false,
          presentSound: true,
        ),
      );

  NotificationDetails get hydrationDetails => NotificationDetails(
        android: AndroidNotificationDetails(
          'hydration',
          tr('Hydration reminders'),
          channelDescription: tr('Gentle daily water check-in reminders'),
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          sound: _luneraSound,
          playSound: true,
          ongoing: false,
          autoCancel: true,
        ),
        iOS: const DarwinNotificationDetails(
          interruptionLevel: InterruptionLevel.active,
          presentAlert: true,
          presentBadge: false,
          presentSound: true,
        ),
      );

  Future<bool> isHydrationReminderEnabled() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_hydrationPrefKey) ?? false;
  }

  Future<void> setHydrationReminderEnabled(bool enabled, Prefs prefs) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_hydrationPrefKey, enabled);
    await syncHydrationReminders(prefs);
  }

  Future<void> syncHydrationReminders(Prefs prefs, {DateTime? now}) async {
    if (!supported) return;
    await init();
    for (final req in await _plugin.pendingNotificationRequests()) {
      if (req.payload == _hydrationPayload) {
        await _plugin.cancel(id: req.id);
      }
    }
    final enabled = await isHydrationReminderEnabled();
    if (!enabled) return;

    final refNow = now ?? DateTime.now();
    final mode = await _canExact()
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    final (title, body) = hydrationNotificationText(prefs);
    const hours = [10, 14, 18, 21];

    for (var d = 0; d < 7; d++) {
      for (final h in hours) {
        final at = DateTime(refNow.year, refNow.month, refNow.day + d, h, 0);
        if (!at.isAfter(refNow)) continue;
        final dateIso =
            '${at.year.toString().padLeft(4, '0')}-${at.month.toString().padLeft(2, '0')}-${at.day.toString().padLeft(2, '0')}';
        final id = 'hydration|$dateIso|$h'.hashCode & 0x7fffffff;
        await _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate:
              tz.TZDateTime(tz.local, at.year, at.month, at.day, at.hour, 0),
          notificationDetails: hydrationDetails,
          androidScheduleMode: mode,
          payload: _hydrationPayload,
        );
      }
    }
  }

  /// Schedules or cancels optional guilt-free workout reminders independently
  /// from the critical medication `doses` channel.
  Future<void> syncWorkoutReminders(
    WorkoutProfile profile,
    Prefs prefs, {
    DateTime? now,
  }) async {
    if (!supported) return;
    await init();
    for (final req in await _plugin.pendingNotificationRequests()) {
      if (req.payload == _workoutPayload) {
        await _plugin.cancel(id: req.id);
      }
    }
    if (!profile.notifyWorkout || profile.weekdays.isEmpty) return;

    final refNow = now ?? DateTime.now();
    final parts = profile.reminderTime.split(':');
    final hour = parts.length == 2 ? (int.tryParse(parts[0]) ?? 18).clamp(0, 23) : 18;
    final minute = parts.length == 2 ? (int.tryParse(parts[1]) ?? 0).clamp(0, 59) : 0;
    final mode = await _canExact()
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    final (title, body) = workoutNotificationText(profile, prefs);

    for (var d = 0; d < 14; d++) {
      final candidate =
          DateTime(refNow.year, refNow.month, refNow.day + d, hour, minute);
      if (!candidate.isAfter(refNow)) continue;
      if (!profile.weekdays.contains(candidate.weekday)) continue;
      final candidateIso =
          '${candidate.year.toString().padLeft(4, '0')}-${candidate.month.toString().padLeft(2, '0')}-${candidate.day.toString().padLeft(2, '0')}';
      if (profile.skippedDateIso == candidateIso) continue;
      final id = 'workout|$candidateIso'.hashCode & 0x7fffffff;
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime(tz.local, candidate.year, candidate.month,
            candidate.day, candidate.hour, candidate.minute),
        notificationDetails: _workoutDetails,
        androidScheduleMode: mode,
        payload: _workoutPayload,
      );
    }
  }

  /// Returns the currently scheduled future trough bloodwork reminder time, if any.
  Future<DateTime?> getScheduledTroughReminder({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_troughReminderPrefKey);
    if (raw == null || raw.isEmpty) return null;
    final at = DateTime.tryParse(raw);
    final refNow = now ?? DateTime.now();
    if (at == null || !at.isAfter(refNow)) {
      await prefs.remove(_troughReminderPrefKey);
      return null;
    }
    return at;
  }

  /// Schedules a one-shot trough bloodwork reminder 2 hours before [slot] (or 15 min
  /// prior if <2h remain while [slot] is still in the future). Returns null if past.
  Future<DateTime?> scheduleTroughLabReminder({
    required Slot slot,
    required Prefs prefs,
    DateTime? now,
  }) async {
    final refNow = now ?? DateTime.now();
    var alertAt = slot.at.subtract(const Duration(hours: 2));
    if (!alertAt.isAfter(refNow)) {
      alertAt = slot.at.subtract(const Duration(minutes: 15));
      if (!alertAt.isAfter(refNow)) return null;
    }
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_troughReminderPrefKey, alertAt.toIso8601String());

    if (supported) {
      try {
        await init();
        final mode = await _canExact()
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle;
        final (title, body) = troughLabNotificationText(slot, prefs);
        await _plugin.zonedSchedule(
          id: _troughReminderId,
          title: title,
          body: body,
          scheduledDate: tz.TZDateTime(tz.local, alertAt.year, alertAt.month,
              alertAt.day, alertAt.hour, alertAt.minute),
          notificationDetails: _details,
          androidScheduleMode: mode,
          payload: _troughPayload,
        );
      } catch (e) {
        debugPrint('Failed to schedule trough lab reminder: $e');
      }
    }
    return alertAt;
  }

  /// Cancels any active or stored trough bloodwork reminder.
  Future<void> cancelTroughLabReminder() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_troughReminderPrefKey);
    if (!supported) return;
    try {
      await init();
      await _plugin.cancel(id: _troughReminderId);
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    if (!supported) return;
    await init();
    await _plugin.cancelAll();
  }

  /// Jadwalkan ulang semua pengingat (diserialkan agar tidak saling menimpa).
  Future<void> sync(List<Therapy> ths, List<DoseLog> logs,
      List<Supply> supplies, Prefs prefs) {
    _chain = _chain
        .then((_) => _sync(ths, logs, supplies, prefs))
        .catchError((Object e) {
      debugPrint(tr('Failed to schedule notifications: {0}', [e]));
    });
    return _chain;
  }

  Future<void> _sync(List<Therapy> ths, List<DoseLog> logs,
      List<Supply> supplies, Prefs prefs) async {
    if (!supported) return;
    await init();
    if (!prefs.notify) {
      for (final req in await _plugin.pendingNotificationRequests()) {
        if (req.payload != _troughPayload &&
            req.payload != _workoutPayload &&
            req.payload != _hydrationPayload) {
          await _plugin.cancel(id: req.id);
        }
      }
      return;
    }
    final pendingKeys = {
      for (final s in buildSlots(ths, logs, prefs, back: 2, ahead: 1))
        if (s.pending) '${s.t.id}|${slotKey(s.at)}',
    };
    try {
      for (final n in await _plugin.getActiveNotifications()) {
        final id = n.id;
        if (id != null) await _plugin.cancel(id: id, tag: n.tag);
      }
    } catch (_) {}
    for (final req in await _plugin.pendingNotificationRequests()) {
      if (!keepSnooze(req.payload, pendingKeys) &&
          req.payload != _troughPayload &&
          req.payload != _workoutPayload &&
          req.payload != _hydrationPayload) {
        await _plugin.cancel(id: req.id);
      }
    }
    final now = DateTime.now();
    final mode = await _canExact()
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    final desc = [...logs]..sort((a, b) => b.at.compareTo(a.at));
    final slots = [
      for (final s in buildSlots(ths, logs, prefs, back: 0, ahead: 21))
        if (s.pending && s.at.isAfter(now)) s,
    ];
    for (final s in slots.take(60)) {
      final t = s.t;
      final place = t.adm.places ? suggestPlace(prefs, desc, t.id) : '';
      final (title, body) = doseNotificationText(t, prefs, place: place);
      final slot = slotKey(s.at);
      final isInj = t.route == 'inj';

      await _plugin.zonedSchedule(
        id: _id(t, s.at),
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime(
            tz.local, s.at.year, s.at.month, s.at.day, s.at.hour, s.at.minute),
        notificationDetails:
            buildDoseNotificationDetails(withActions: true, ongoing: isInj),
        androidScheduleMode: mode,
        payload: snoozePayload(
          therapyId: t.id,
          slot: slot,
          title: title,
          body: body,
          isInjection: isInj,
        ),
      );
    }

    // Stok hampir habis: pagi pukul 09:00, tiga hari berturut-turut selama masih menipis.
    Future<void> at9(DateTime at, String key, String title, String body) =>
        _plugin.zonedSchedule(
          id: key.hashCode & 0x7fffffff,
          title: title,
          body: body,
          scheduledDate: tz.TZDateTime(
              tz.local, at.year, at.month, at.day, at.hour, at.minute),
          notificationDetails: _details,
          androidScheduleMode: mode,
        );
    final firstMorning = now.hour < 9
        ? DateTime(now.year, now.month, now.day, 9)
        : DateTime(now.year, now.month, now.day + 1, 9);
    for (final s in supplies) {
      if (s.low && !s.expired) {
        final (title, body) = lowSupplyNotificationText(s, prefs);
        for (var d = 0; d < 3; d++) {
          await at9(
              DateTime(firstMorning.year, firstMorning.month,
                  firstMorning.day + d, 9),
              'low|${s.id}|$d',
              title,
              body);
        }
      }
      final e = s.effectiveExpiry;
      if (e != null) {
        for (final lead in const [14, 3, 0]) {
          final at = DateTime(e.year, e.month, e.day - lead, 9);
          if (!at.isAfter(now)) continue;
          final (title, body) = expiryNotificationText(s, lead, prefs);
          await at9(at, 'exp|${s.id}|$lead', title, body);
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
