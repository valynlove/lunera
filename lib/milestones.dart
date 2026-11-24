import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n.dart';

/// Optional milestone tags (key, English label).
const List<(String key, String en)> milestonePresetTags = [
  ('first_step', 'First Step'),
  ('month_3', '3 Months'),
  ('month_6', '6 Months'),
  ('year_1', '1 Year'),
  ('personal_win', 'Personal Win'),
];

String? milestoneTagLabel(String? key) {
  if (key == null) return null;
  for (final item in milestonePresetTags) {
    if (item.$1 == key) return tr(item.$2);
  }
  return null;
}

/// Private, on-device transition milestone entry (stored strictly in local
/// SharedPreferences behind Lunera's biometric/PIN LockGate, never synced unencrypted).
class TransitionMilestone {
  const TransitionMilestone({
    required this.id,
    required this.at,
    required this.title,
    this.tag,
    this.note,
    this.photoBase64,
  });

  final String id;
  final DateTime at;
  final String title;
  final String? tag;
  final String? note;
  final String? photoBase64;

  bool get hasPhoto => photoBase64 != null && photoBase64!.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'at': at.toIso8601String(),
        'title': title,
        if (tag != null && tag!.isNotEmpty) 'tag': tag,
        if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
        if (hasPhoto) 'photoBase64': photoBase64,
      };

  static TransitionMilestone? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final atRaw = json['at'];
    final title = json['title'];
    if (id is! String ||
        id.trim().isEmpty ||
        atRaw is! String ||
        title is! String ||
        title.trim().isEmpty) {
      return null;
    }
    final at = DateTime.tryParse(atRaw);
    if (at == null) return null;
    final tag = json['tag'];
    final note = json['note'];
    final photo = json['photoBase64'];
    return TransitionMilestone(
      id: id.trim(),
      at: at,
      title: title.trim(),
      tag: (tag is String && tag.trim().isNotEmpty) ? tag.trim() : null,
      note: (note is String && note.trim().isNotEmpty) ? note.trim() : null,
      photoBase64:
          (photo is String && photo.isNotEmpty) ? photo : null,
    );
  }
}

/// Local-only SharedPreferences store for private milestones & locked progress photos.
class MilestoneStore {
  static const _storageKey = 'body.private_milestones';

  static String? _authUid() {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  static String _resolveKey([String? uid]) {
    final targetUid = uid ?? _authUid();
    if (targetUid != null && targetUid.isNotEmpty) {
      return '${_storageKey}_$targetUid';
    }
    return _storageKey;
  }

  static Future<List<TransitionMilestone>> loadMilestones([String? uid]) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _resolveKey(uid);
    // Legacy migration: if scoped key is empty but legacy un-scoped key exists, migrate it
    if (key != _storageKey && !prefs.containsKey(key) && prefs.containsKey(_storageKey)) {
      final legacy = prefs.getStringList(_storageKey);
      if (legacy != null) {
        await prefs.setStringList(key, legacy);
        await prefs.remove(_storageKey);
      }
    }
    return _decodeList(prefs.getStringList(key) ?? const <String>[]);
  }

  static List<TransitionMilestone> _decodeList(List<String> rawList) {
    final out = <TransitionMilestone>[];
    for (final raw in rawList) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          final parsed = TransitionMilestone.fromJson(decoded);
          if (parsed != null) out.add(parsed);
        }
      } catch (_) {
        // Ignore malformed entries cleanly.
      }
    }
    out.sort((a, b) => b.at.compareTo(a.at));
    return out;
  }

  static Future<List<TransitionMilestone>> saveMilestone(
      TransitionMilestone item, [String? uid]) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _resolveKey(uid);
    final existing = _decodeList(
        prefs.getStringList(key) ?? const <String>[]);
    final updated = [item, ...existing.where((m) => m.id != item.id)]
      ..sort((a, b) => b.at.compareTo(a.at));
    await prefs.setStringList(
      key,
      [for (final m in updated) jsonEncode(m.toJson())],
    );
    return updated;
  }

  static Future<void> importMilestones(
    List<dynamic> rawList, {
    required bool replace,
    String? uid,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _resolveKey(uid);
    final items = <TransitionMilestone>[];
    for (final r in rawList) {
      if (r is Map) {
        final parsed = TransitionMilestone.fromJson(r.cast<String, dynamic>());
        if (parsed != null) items.add(parsed);
      }
    }
    if (replace) {
      await prefs.setStringList(
        key,
        [for (final m in items) jsonEncode(m.toJson())],
      );
    } else {
      final existing = await loadMilestones(uid);
      final existingIds = {for (final m in existing) m.id};
      final merged = [
        ...existing,
        ...items.where((m) => !existingIds.contains(m.id)),
      ]..sort((a, b) => b.at.compareTo(a.at));
      await prefs.setStringList(
        key,
        [for (final m in merged) jsonEncode(m.toJson())],
      );
    }
  }

  static Future<List<TransitionMilestone>> deleteMilestone(String id, [String? uid]) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _resolveKey(uid);
    final existing = _decodeList(
        prefs.getStringList(key) ?? const <String>[]);
    final updated = existing.where((m) => m.id != id).toList();
    await prefs.setStringList(
      key,
      [for (final m in updated) jsonEncode(m.toJson())],
    );
    return updated;
  }

  static Future<void> clearLocal([String? uid]) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _resolveKey(uid);
    await prefs.remove(key);
    await prefs.remove(_storageKey);
  }

  static Future<void> clearForTest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    final uid = _authUid();
    if (uid != null && uid.isNotEmpty) {
      await prefs.remove('${_storageKey}_$uid');
    }
  }
}
