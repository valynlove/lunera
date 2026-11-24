import 'dart:convert';

import 'package:flutter/material.dart' show IconData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n.dart';
import 'profile.dart';
import 'repo.dart';

/// Predefined category for visual milestone moments.
class MomentCategory {
  const MomentCategory({
    required this.id,
    required this.nameEn,
    required this.icon,
  });

  final String id;
  final String nameEn;
  final IconData icon;

  String get name => tr(nameEn);
}

const List<MomentCategory> momentCategories = [
  MomentCategory(
    id: 'milestone',
    nameEn: 'Milestones & Anniversaries',
    icon: LucideIcons.sparkles,
  ),
  MomentCategory(
    id: 'physical',
    nameEn: 'Physical & Body Shifts',
    icon: LucideIcons.heartPulse,
  ),
  MomentCategory(
    id: 'style',
    nameEn: 'Affirming Style & Self',
    icon: LucideIcons.shirt,
  ),
  MomentCategory(
    id: 'reflection',
    nameEn: 'Soul & Reflections',
    icon: LucideIcons.feather,
  ),
];

MomentCategory categoryOfMoment(String id) => momentCategories.firstWhere(
      (c) => c.id == id,
      orElse: () => momentCategories.first,
    );

/// A single visual keepsake entry celebrating a personal transition milestone.
class Moment {
  const Moment({
    required this.id,
    required this.at,
    required this.title,
    this.note,
    this.photoBase64,
    this.category = 'milestone',
  });

  final String id;
  final DateTime at;
  final String title;
  final String? note;
  final String? photoBase64;
  final String category;

  bool get hasPhoto => photoBase64 != null && photoBase64!.isNotEmpty;
  bool get hasNote => note != null && note!.trim().isNotEmpty;

  Moment copyWith({
    String? id,
    DateTime? at,
    String? title,
    String? note,
    String? photoBase64,
    bool clearPhoto = false,
    String? category,
  }) =>
      Moment(
        id: id ?? this.id,
        at: at ?? this.at,
        title: title ?? this.title,
        note: note ?? this.note,
        photoBase64: clearPhoto ? null : (photoBase64 ?? this.photoBase64),
        category: category ?? this.category,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'at': at.toIso8601String(),
        'title': title,
        if (note != null && note!.isNotEmpty) 'note': note,
        if (photoBase64 != null && photoBase64!.isNotEmpty)
          'photoBase64': photoBase64,
        'category': category,
      };

  factory Moment.fromMap(Map<String, dynamic> m) => Moment(
        id: m['id'] as String? ?? 'm_${DateTime.now().millisecondsSinceEpoch}',
        at: m['at'] is String
            ? DateTime.tryParse(m['at'] as String) ?? DateTime.now()
            : DateTime.now(),
        title: m['title'] as String? ?? '',
        note: m['note'] as String?,
        photoBase64: m['photoBase64'] as String?,
        category: m['category'] as String? ?? 'milestone',
      );
}

const String _kMomentsPrefsKey = 'lunera_visual_moments';

/// Riverpod controller managing visual milestone scrapbook items.
class MomentsController extends Notifier<List<Moment>> {
  SharedPreferences? _getPrefs() {
    try {
      return ref.read(sharedPreferencesProvider);
    } catch (_) {
      return null;
    }
  }

  String _storageKey() {
    String? uid;
    try {
      uid = ref.watch(userProvider).value?.uid;
    } catch (_) {}
    if (uid != null && uid.isNotEmpty) {
      return '${_kMomentsPrefsKey}_$uid';
    }
    return _kMomentsPrefsKey;
  }

  @override
  List<Moment> build() {
    final prefs = _getPrefs();
    if (prefs != null) {
      final key = _storageKey();
      // Legacy migration: if scoped key is empty but un-scoped legacy key exists, migrate it
      if (key != _kMomentsPrefsKey && !prefs.containsKey(key) && prefs.containsKey(_kMomentsPrefsKey)) {
        final legacy = prefs.getString(_kMomentsPrefsKey);
        if (legacy != null) {
          prefs.setString(key, legacy);
          prefs.remove(_kMomentsPrefsKey);
        }
      }
      final raw = prefs.getString(key);
      if (raw != null && raw.isNotEmpty) {
        try {
          final list = jsonDecode(raw) as List;
          return [
            for (final item in list)
              if (item is Map) Moment.fromMap(item.cast<String, dynamic>())
          ]..sort((a, b) => b.at.compareTo(a.at));
        } catch (_) {}
      }
    }
    return const [];
  }

  Future<void> _persist() async {
    final prefs = _getPrefs() ?? await SharedPreferences.getInstance();
    final jsonStr = jsonEncode([for (final m in state) m.toMap()]);
    await prefs.setString(_storageKey(), jsonStr);
  }

  void addMoment(Moment m) {
    state = [m, ...state]..sort((a, b) => b.at.compareTo(a.at));
    _persist();
  }

  void updateMoment(Moment m) {
    state = [
      for (final existing in state)
        if (existing.id == m.id) m else existing,
    ]..sort((a, b) => b.at.compareTo(a.at));
    _persist();
  }

  void deleteMoment(String id) {
    state = [for (final m in state) if (m.id != id) m];
    _persist();
  }

  static String _resolveStorageKey([String? uid]) {
    if (uid != null && uid.isNotEmpty) {
      return '${_kMomentsPrefsKey}_$uid';
    }
    return _kMomentsPrefsKey;
  }

  static Future<List<Moment>> loadDirect(
      [String? uid, SharedPreferences? prefs]) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    final key = _resolveStorageKey(uid);
    if (key != _kMomentsPrefsKey &&
        !p.containsKey(key) &&
        p.containsKey(_kMomentsPrefsKey)) {
      final legacy = p.getString(_kMomentsPrefsKey);
      if (legacy != null) {
        p.setString(key, legacy);
        p.remove(_kMomentsPrefsKey);
      }
    }
    final raw = p.getString(key);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List;
        return [
          for (final item in list)
            if (item is Map) Moment.fromMap(item.cast<String, dynamic>())
        ]..sort((a, b) => b.at.compareTo(a.at));
      } catch (_) {}
    }
    return const [];
  }

  static Future<void> importMoments(
    List<dynamic> rawList, {
    required bool replace,
    String? uid,
    SharedPreferences? prefs,
  }) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    final key = _resolveStorageKey(uid);
    final items = <Moment>[];
    for (final r in rawList) {
      if (r is Map) {
        items.add(Moment.fromMap(r.cast<String, dynamic>()));
      }
    }
    if (replace) {
      final jsonStr = jsonEncode([for (final m in items) m.toMap()]);
      await p.setString(key, jsonStr);
    } else {
      final existing = await loadDirect(uid, p);
      final existingIds = {for (final m in existing) m.id};
      final merged = [
        ...existing,
        ...items.where((m) => !existingIds.contains(m.id)),
      ]..sort((a, b) => b.at.compareTo(a.at));
      final jsonStr = jsonEncode([for (final m in merged) m.toMap()]);
      await p.setString(key, jsonStr);
    }
  }

  /// Purges local stored moments for [uid] on logout.
  static Future<void> clearLocal([String? uid, SharedPreferences? prefs]) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    if (uid != null && uid.isNotEmpty) {
      await p.remove('${_kMomentsPrefsKey}_$uid');
    }
    await p.remove(_kMomentsPrefsKey);
  }
}

final momentsProvider =
    NotifierProvider<MomentsController, List<Moment>>(MomentsController.new);
