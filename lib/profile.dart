import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'repo.dart';
import 'theme.dart';

/// Keadaan profil pengguna: nama panggilan dan foto profil.
class ProfileState {
  const ProfileState({this.nickname, this.photo});

  final String? nickname;
  final Uint8List? photo;
}

/// Di-override di ProviderScope pada main.dart dengan instance SharedPreferences.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden in ProviderScope'),
);

/// Pengontrol profil (nickname & foto profil) yang disimpan secara lokal
/// dengan SharedPreferences dan disinkronkan secara aman ke Cloud Firestore.
class ProfileController extends Notifier<ProfileState> {
  static const _timeout = Duration(seconds: 15);

  String _nickKey(String uid) => 'nickname_$uid';
  String _photoKey(String uid) => 'photo_$uid';
  String _updatedKey(String uid) => 'profile_updated_$uid';

  @override
  ProfileState build() {
    final user = ref.watch(userProvider).value;
    if (user == null) return const ProfileState();

    final p = ref.watch(sharedPreferencesProvider);
    final b64 = p.getString(_photoKey(user.uid));

    // Sinkronkan dari awan di latar belakang jika ada data yang lebih baru
    Future.microtask(() => restoreFromCloud(user.uid));

    return ProfileState(
      nickname: p.getString(_nickKey(user.uid)),
      photo: b64 == null ? null : base64Decode(b64),
    );
  }

  String? get _uid => ref.read(userProvider).value?.uid;

  /// Perbarui nama panggilan (nickname)
  Future<void> setNickname(String value) async {
    final uid = _uid;
    if (uid == null) return;
    final p = ref.read(sharedPreferencesProvider);
    final nick = value.trim();
    if (nick.isEmpty) {
      await p.remove(_nickKey(uid));
    } else {
      await p.setString(_nickKey(uid), nick);
    }
    await p.setInt(_updatedKey(uid), DateTime.now().millisecondsSinceEpoch);
    state = ProfileState(nickname: nick.isEmpty ? null : nick, photo: state.photo);
    await uploadToCloud(uid);
  }

  /// Perbarui foto profil (null untuk menghapus)
  Future<void> setPhoto(Uint8List? bytes) async {
    final uid = _uid;
    if (uid == null) return;
    final p = ref.read(sharedPreferencesProvider);
    if (bytes == null) {
      await p.remove(_photoKey(uid));
    } else {
      await p.setString(_photoKey(uid), base64Encode(bytes));
    }
    await p.setInt(_updatedKey(uid), DateTime.now().millisecondsSinceEpoch);
    state = ProfileState(nickname: state.nickname, photo: bytes);
    await uploadToCloud(uid);
  }

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('meta').doc('profile');

  /// Unggah profil ke cloud Firestore
  Future<void> uploadToCloud(String uid) async {
    try {
      final p = ref.read(sharedPreferencesProvider);
      await _doc(uid).set({
        'nickname': p.getString(_nickKey(uid)),
        'photo': p.getString(_photoKey(uid)),
        'updatedAt': p.getInt(_updatedKey(uid)) ?? 0,
      }).timeout(_timeout);
    } catch (_) {}
  }

  /// Pulihkan profil dari cloud jika ada versi yang lebih baru
  Future<void> restoreFromCloud(String uid) async {
    try {
      final snap = await _doc(uid).get().timeout(_timeout);
      final data = snap.data();
      if (data == null) return;
      final p = ref.read(sharedPreferencesProvider);
      final remoteAt = (data['updatedAt'] as num?)?.toInt() ?? 0;
      final localAt = p.getInt(_updatedKey(uid)) ?? 0;
      if (remoteAt <= localAt) return;

      final nick = data['nickname'] as String?;
      final photo = data['photo'] as String?;
      if (nick == null) {
        await p.remove(_nickKey(uid));
      } else {
        await p.setString(_nickKey(uid), nick);
      }
      if (photo == null) {
        await p.remove(_photoKey(uid));
      } else {
        await p.setString(_photoKey(uid), photo);
      }
      await p.setInt(_updatedKey(uid), remoteAt);
      state = ProfileState(
        nickname: nick,
        photo: photo == null ? null : base64Decode(photo),
      );
    } catch (_) {}
  }
}

final profileProvider = NotifierProvider<ProfileController, ProfileState>(ProfileController.new);

/// Nama tampilan utama: Nickname jika ada, lalu Username, lalu awalan email.
final displayNameProvider = Provider<String?>((ref) {
  final nick = ref.watch(profileProvider).nickname?.trim();
  if (nick != null && nick.isNotEmpty) return nick;
  final user = ref.watch(userProvider).value;
  final name = user?.displayName?.trim();
  if (name != null && name.isNotEmpty) return name;
  final email = user?.email ?? '';
  final local = email.split('@').first;
  if (local.isEmpty) return null;
  return local[0].toUpperCase() + local.substring(1);
});

/// Widget avatar pengguna dengan dukungan foto dan inisial teks.
class UserAvatar extends ConsumerWidget {
  const UserAvatar({super.key, this.size = 48, this.onTap});

  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photo = ref.watch(profileProvider.select((s) => s.photo));
    final name = ref.watch(displayNameProvider) ?? appName;
    final initial = (name.isEmpty ? appName.substring(0, 1) : String.fromCharCode(name.runes.first)).toUpperCase();

    final avatar = CircleAvatar(
      radius: size / 2,
      backgroundColor: C.peony,
      backgroundImage: photo == null ? null : MemoryImage(photo),
      child: photo == null
          ? Text(
              initial,
              style: display(size * 0.42, color: Colors.white, weight: FontWeight.w800),
            )
          : null,
    );

    if (onTap == null) return avatar;
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: avatar,
    );
  }
}
