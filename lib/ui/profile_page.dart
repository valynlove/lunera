import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../profile.dart';
import '../repo.dart';
import '../theme.dart';

/// Halaman manajemen profil: Foto profil, nama panggilan (nickname), serta info akun.
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late final TextEditingController _nicknameController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(
      text: ref.read(profileProvider).nickname ?? '',
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        await ref.read(profileProvider.notifier).setPhoto(bytes);
        _toast('Foto profil berhasil diperbarui.');
        return;
      }
    } catch (_) {
      // Fallback untuk platform desktop / file selector
      try {
        const typeGroup = XTypeGroup(label: 'images', extensions: ['jpg', 'png', 'jpeg', 'webp']);
        final file = await openFile(acceptedTypeGroups: [typeGroup]);
        if (file != null) {
          final bytes = await file.readAsBytes();
          await ref.read(profileProvider.notifier).setPhoto(bytes);
          _toast('Foto profil berhasil diperbarui.');
        }
      } catch (e) {
        _toast('Gagal memilih foto: $e');
      }
    }
  }

  Future<void> _removePhoto() async {
    final confirmed = await confirm(context, 'Hapus foto profil saat ini?');
    if (!confirmed || !mounted) return;
    await ref.read(profileProvider.notifier).setPhoto(null);
    _toast('Foto profil dihapus.');
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(profileProvider.notifier).setNickname(_nicknameController.text);
      _toast('Profil berhasil disimpan.');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _toast('Gagal menyimpan profil: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider).value;
    final username = user?.displayName;
    final hasPhoto = ref.watch(profileProvider.select((s) => s.photo != null));
    final theme = Theme.of(context);
    final fg = theme.colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profil', style: display(22)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Center(
            child: Stack(
              children: [
                const UserAvatar(size: 112),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Material(
                    color: C.peony,
                    shape: const CircleBorder(),
                    elevation: 3,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _pickPhoto,
                      child: const Padding(
                        padding: EdgeInsets.all(9),
                        child: Icon(
                          Icons.photo_camera_outlined,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.image_outlined, size: 18),
                label: const Text('Ganti foto'),
              ),
              if (hasPhoto) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _removePhoto,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                  label: const Text('Hapus foto', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: cardBox(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nicknameController,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 30,
                  decoration: const InputDecoration(
                    labelText: 'Nama Panggilan (Nickname)',
                    hintText: 'Contoh: Lunaria',
                    helperText: 'Ditampilkan pada salam Beranda dan kartu profil.',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                gap(16),
                if (username != null && username.isNotEmpty)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.alternate_email_rounded, color: C.peony),
                    title: Text('@$username', style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Username akun'),
                  ),
                if (user?.email != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.mail_outline_rounded, color: C.peony),
                    title: Text(user!.email!, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Email terdaftar'),
                  ),
                gap(8),
                Text(
                  'Username dan email digunakan untuk otentikasi login dan tidak dapat diubah.',
                  style: theme.textTheme.bodySmall?.copyWith(color: fg.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          gap(24),
          pillButton(
            _saving ? 'Menyimpan...' : 'Simpan Profil',
            _saving ? () {} : _save,
            icon: Icons.check_circle_outline_rounded,
          ),
        ],
      ),
    );
  }
}
