import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n.dart';
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
        if (!mounted) return;
        _toast(context.tr('Profile photo updated.'));
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
          if (!mounted) return;
          _toast(context.tr('Profile photo updated.'));
        }
      } catch (e) {
        if (mounted) _toast('Failed to pick photo: $e');
      }
    }
  }

  Future<void> _removePhoto() async {
    final confirmed = await confirm(context, context.tr('Remove profile photo?'));
    if (!confirmed || !mounted) return;
    await ref.read(profileProvider.notifier).setPhoto(null);
    if (!mounted) return;
    _toast(context.tr('Profile photo removed.'));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(profileProvider.notifier).setNickname(_nicknameController.text);
      if (!mounted) return;
      _toast(context.tr('Profile saved.'));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) _toast('Failed to save profile: $e');
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
        title: Text(context.tr('Profile'), style: display(22)),
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
                label: Text(context.tr('Change photo')),
              ),
              if (hasPhoto) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _removePhoto,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                  label: Text(context.tr('Remove photo'), style: const TextStyle(color: Colors.redAccent)),
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
                  decoration: InputDecoration(
                    labelText: context.tr('Nickname'),
                    hintText: 'e.g. Lunaria',
                    helperText: context.tr('Shown in greetings on the Home screen and profile card.'),
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                ),
                gap(16),
                if (username != null && username.isNotEmpty)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.alternate_email_rounded, color: C.peony),
                    title: Text('@$username', style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(context.tr('Account username')),
                  ),
                if (user?.email != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.mail_outline_rounded, color: C.peony),
                    title: Text(user!.email!, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(context.tr('Registered email')),
                  ),
                gap(8),
                Text(
                  context.tr('Username and email are used for login authentication and cannot be changed.'),
                  style: theme.textTheme.bodySmall?.copyWith(color: fg.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          gap(24),
          pillButton(
            _saving ? '...' : context.tr('Save Profile'),
            _saving ? () {} : _save,
            icon: Icons.check_circle_outline_rounded,
          ),
        ],
      ),
    );
  }
}
