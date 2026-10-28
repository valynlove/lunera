import 'dart:convert';
import 'dart:ui' as ui;
import 'package:file_selector/file_selector.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../notifications.dart';
import '../repo.dart';
import '../theme.dart';
import '../update_checker.dart';
import 'auth.dart';
import 'data_page.dart';
import 'pin_lock_gate.dart';
import 'supplies.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});
  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final custom = TextEditingController();

  void _save(Prefs p) => ref.read(repoProvider)?.setPrefs(p);

  Widget _card(String title, List<Widget> kids) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(28)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          gap(12),
          ...kids,
        ]),
      );

  Future<void> _editProfile(BuildContext context, Prefs p) async {
    final nickCtrl = TextEditingController(text: p.nickname);
    String selectedAvatar = p.avatarUrl;

    const presetAvatars = ['🌸', '🌙', '✨', '🦊', '💜', '🌟', '🍃', '🕊️'];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (b) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 0, 20, MediaQuery.of(b).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit Profile & Nickname', style: display(22)),
              gap(16),

              // Live Preview of Current / Selected Photo
              if (selectedAvatar.isNotEmpty) ...[
                Center(
                  child: buildAvatar(p.copy(avatarUrl: selectedAvatar),
                      radius: 42),
                ),
                gap(12),
              ],

              TextField(
                controller: nickCtrl,
                decoration: const InputDecoration(
                  labelText: 'Display Nickname',
                  hintText: 'e.g. Olivia, Hyena, etc.',
                ),
              ),
              gap(16),

              const Text('Profile Photo / Avatar',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              gap(10),

              OutlinedButton.icon(
                onPressed: () async {
                  const typeGroup = XTypeGroup(
                    label: 'images',
                    extensions: <String>['jpg', 'png', 'jpeg', 'webp'],
                  );
                  final file = await openFile(
                      acceptedTypeGroups: <XTypeGroup>[typeGroup]);
                  if (file != null && context.mounted) {
                    final rawBytes = await file.readAsBytes();
                    if (!context.mounted) return;
                    final croppedBytes =
                        await Navigator.of(context).push<Uint8List>(
                      MaterialPageRoute(
                          builder: (_) =>
                              _PhotoFittingDialog(imageBytes: rawBytes)),
                    );
                    if (croppedBytes != null) {
                      final base64Image =
                          'data:image/png;base64,${base64Encode(croppedBytes)}';
                      setModalState(() {
                        selectedAvatar = base64Image;
                      });
                    }
                  }
                },
                icon: const Icon(Icons.photo_library_rounded),
                label: const Text('Choose & Fit Photo'),
              ),
              gap(12),

              const Text('Or select an emoji avatar:',
                  style: TextStyle(fontSize: 12)),
              gap(8),
              Wrap(
                spacing: 10,
                children: [
                  for (final a in presetAvatars)
                    GestureDetector(
                      onTap: () => setModalState(() => selectedAvatar = a),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: selectedAvatar == a
                              ? C.lavender.withValues(alpha: .3)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedAvatar == a
                                ? C.lavender
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Text(a, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                  if (selectedAvatar.isNotEmpty)
                    TextButton(
                      onPressed: () => setModalState(() => selectedAvatar = ''),
                      child: const Text('Remove Photo'),
                    ),
                ],
              ),
              gap(24),

              SizedBox(
                width: double.infinity,
                child: pillButton('Save Changes', () {
                  _save(p.copy(
                    nickname: nickCtrl.text.trim(),
                    avatarUrl: selectedAvatar,
                  ));
                  Navigator.pop(b);
                }, icon: Icons.check_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(prefsProvider).value ?? const Prefs();
    final user = FirebaseAuth.instance.currentUser;
    final ds = TimeOfDay(hour: p.dayStart ~/ 60, minute: p.dayStart % 60);
    final extra = [
      for (final x in p.places)
        if (!placePresets.contains(x)) x
    ];
    return Scaffold(
      body: SafeArea(
        child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            children: [
              Row(children: [
                if (Navigator.of(context).canPop())
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded)),
                Expanded(child: Text('Profile & Settings', style: display(30))),
              ]),
              gap(16),

              // User Profile Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  children: [
                    buildAvatar(p,
                        radius: 30, onTap: () => _editProfile(context, p)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.nickname.isNotEmpty
                                ? p.nickname
                                : ((user?.displayName?.isNotEmpty ?? false)
                                    ? user!.displayName!
                                    : ((user?.email?.isNotEmpty ?? false)
                                        ? user!.email!.split('@').first
                                        : 'Lunera Friend')),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 18),
                          ),
                          gap(2),
                          Text(
                            user?.email != null
                                ? '@${user!.email!.split('@').first} · ${user.email}'
                                : 'olivia.adeline@example.com',
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: .7)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit Profile',
                      icon: const Icon(Icons.edit_rounded,
                          size: 20, color: C.lavender),
                      onPressed: () => _editProfile(context, p),
                    ),
                  ],
                ),
              ),
              gap(16),

              _card('Supplies & Tools', [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      const Icon(Icons.inventory_2_outlined, color: C.lavender),
                  title: const Text('Manage Supplies & Equipment'),
                  subtitle:
                      const Text('Syringes, needles, alcohol wipes, and vials'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => Scaffold(
                            appBar: AppBar(
                                title: Text('Supplies & Tools',
                                    style: display(22))),
                            body: const SuppliesPage(),
                          ))),
                ),
              ]),
              _card('About Lunera', [
                Row(children: [
                  const LuneraLogo(size: 64),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lunera', style: display(24, color: C.lavender)),
                        Text('Every Phase, Your Own.',
                            style: tagline(11,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: .7))),
                      ],
                    ),
                  ),
                ]),
                gap(12),
                const Text(
                  'Lunera is a personal health tracking application accompanying every step of your journey. With a gentle, secure, and personal approach, Lunera helps you understand your body, discover patterns, and care for yourself — in every phase.',
                  style: TextStyle(fontSize: 13, height: 1.45),
                ),
                gap(12),
                Text('Logo Meaning',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                gap(6),
                const Text(
                  '• Orbit: Circular ring symbolizing continuity, cycles, and long-term journey.\n• Moon & Star: Representing calmness, hope, and light in every phase.',
                  style: TextStyle(fontSize: 12.5, height: 1.4),
                ),
              ]),
              _card('Appearance', [
                Wrap(spacing: 8, children: [
                  for (final t in const [
                    ('system', 'System'),
                    ('light', 'Light'),
                    ('dark', 'Dark')
                  ])
                    ChoiceChip(
                        label: Text(t.$2),
                        selected: p.theme == t.$1,
                        onSelected: (_) => _save(p.copy(theme: t.$1))),
                ]),
                gap(12),
                const Text('Accent color'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final e in accents.entries)
                    ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 12, color: e.value.$2),
                          const SizedBox(width: 3),
                          Icon(Icons.circle, size: 12, color: e.value.$3),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              e.value.$1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      selected: p.accent == e.key,
                      onSelected: (_) => _save(p.copy(accent: e.key)),
                    ),
                ]),
              ]),
              _card('Reminders', [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Dose reminders'),
                  subtitle: Text(AppNotifier.instance.supported
                      ? 'Notifications appear at scheduled times, even offline.'
                      : 'Only available on Android and iOS devices.'),
                  value: p.notify,
                  onChanged: !AppNotifier.instance.supported
                      ? null
                      : (v) async {
                          if (v &&
                              !await AppNotifier.instance.requestPermission()) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Notification permission denied. Enable in system settings.')));
                            }
                            return;
                          }
                          _save(p.copy(notify: v));
                        },
                ),
                if (AppNotifier.instance.supported)
                  OutlinedButton.icon(
                    onPressed: () async {
                      final sent = await AppNotifier.instance.test();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(sent
                                ? 'Test notification sent! Check your notification panel.'
                                : 'Notifications not supported on this platform.'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: const Text('Send test notification'),
                  ),
              ]),
              _card('Hormone Level Units', [
                for (final h in presets) ...[
                  Text(h.name, style: Theme.of(context).textTheme.bodySmall),
                  Wrap(spacing: 8, children: [
                    for (final u in h.units.keys)
                      ChoiceChip(
                          label: Text(u),
                          selected: p.unitOf(h.id) == u,
                          onSelected: (_) =>
                              _save(p.copy(units: {...p.units, h.id: u}))),
                  ]),
                  gap(6),
                ],
              ]),
              _card('Injection and Patch Sites', [
                const Text(
                    'Selection order determines next suggested site, alternating from top to bottom.'),
                gap(8),
                Wrap(spacing: 8, runSpacing: 4, children: [
                  for (final x in [...placePresets, ...extra])
                    FilterChip(
                      label: Text(translatePlace(x)),
                      selected: p.places.contains(x),
                      onSelected: (v) => _save(p.copy(
                          places: v
                              ? [...p.places, x]
                              : ([...p.places]..remove(x)))),
                    ),
                ]),
                gap(10),
                Row(children: [
                  Expanded(
                      child: TextField(
                          controller: custom,
                          decoration:
                              const InputDecoration(labelText: 'Custom site'))),
                  IconButton.filledTonal(
                    onPressed: () {
                      final v = custom.text.trim();
                      if (v.isEmpty || p.places.contains(v)) return;
                      _save(p.copy(places: [...p.places, v]));
                      custom.clear();
                    },
                    icon: const Icon(Icons.add_rounded),
                  ),
                ]),
              ]),
              _card('Days and Counter', [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Track therapy duration'),
                  subtitle: const Text('Shown in History tab.'),
                  value: p.hrtCounter,
                  onChanged: (v) => _save(p.copy(hrtCounter: v)),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('New day starts at'),
                  subtitle: const Text(
                      'Doses past midnight are counted towards previous day.'),
                  trailing: Text(ds.format(context),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () async {
                    final t =
                        await showTimePicker(context: context, initialTime: ds);
                    if (t != null) {
                      _save(p.copy(dayStart: t.hour * 60 + t.minute));
                    }
                  },
                ),
              ]),
              _card('Sample Data', [
                const Text(
                    'Fill your account with sample therapies, notes, lab results, and supplies to test the app. Marked as "(demo)" and can be deleted anytime.'),
                gap(10),
                Wrap(spacing: 8, children: [
                  OutlinedButton(
                    onPressed: () async {
                      if (!await confirm(
                          context, 'Add sample data to your account?',
                          ok: 'Add')) {
                        return;
                      }
                      ref.read(repoProvider)?.addDemo();
                    },
                    child: const Text('Add'),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      if (!await confirm(context, 'Delete all sample data?',
                          ok: 'Delete')) {
                        return;
                      }
                      ref.read(repoProvider)?.clearDemo();
                    },
                    child: const Text('Delete'),
                  ),
                ]),
              ]),
              _card('Data & Backup', [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.import_export_rounded),
                  title: const Text('Import, export, backup'),
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DataPage())),
                ),
              ]),
              _card('Security & Privacy', [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Lock app with Biometrics'),
                  subtitle: Text(!kIsWeb &&
                          defaultTargetPlatform == TargetPlatform.windows
                      ? 'Biometric security is tailored for Android and iOS mobile devices.'
                      : 'Require fingerprint / face ID when app is opened or from background.'),
                  value: (!kIsWeb &&
                          defaultTargetPlatform == TargetPlatform.windows)
                      ? false
                      : p.appLock,
                  onChanged: (!kIsWeb &&
                          defaultTargetPlatform == TargetPlatform.windows)
                      ? null
                      : (v) async {
                          if (v && !await BiometricService.isAvailable()) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Biometrics / fingerprint not available on this device.')));
                            }
                            return;
                          }
                          await BiometricService.setAppLockEnabled(v);
                          _save(p.copy(appLock: v));
                        },
                ),
              ]),
              _card('Account', [
                if (user?.displayName?.isNotEmpty ?? false)
                  Text('@${user!.displayName}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                if (user?.email != null) Text(user!.email!),
                gap(10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.pop(context);
                        }
                        signOutAll();
                      },
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Sign Out'),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () async {
                        final ok = await confirm(context,
                            'Permanently delete account and all your data? This action cannot be undone.',
                            ok: 'Delete Account');
                        if (ok && context.mounted) {
                          try {
                            await user?.delete();
                            signOutAll();
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(
                                      'Failed to delete account: $e. Please sign out and sign in again.')));
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.delete_forever_rounded),
                      label: const Text('Delete Account'),
                    ),
                  ],
                ),
              ]),
              _card('About & Updates', [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.system_update_rounded, color: C.lavender),
                  title: const Text('Check for Updates'),
                  subtitle: const Text('Current version: v${UpdateCheckerService.currentVersion}'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => UpdateCheckerService.checkAndPromptUpdate(context, silentIfUpToDate: false),
                ),
                gap(6),
                Center(
                  child: Text(
                    'Lunera • Every Phase, Your Own.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5),
                    ),
                  ),
                ),
              ]),
            ]),
      ),
    );
  }
}

class _PhotoFittingDialog extends StatefulWidget {
  const _PhotoFittingDialog({required this.imageBytes});
  final Uint8List imageBytes;

  @override
  State<_PhotoFittingDialog> createState() => _PhotoFittingDialogState();
}

class _PhotoFittingDialogState extends State<_PhotoFittingDialog> {
  final TransformationController _transformController =
      TransformationController();
  ui.Image? _decodedImage;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final codec = await ui.instantiateImageCodec(widget.imageBytes);
    final frame = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        _decodedImage = frame.image;
        _loading = false;
      });
    }
  }

  Future<Uint8List?> _cropAndCompress() async {
    if (_decodedImage == null) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const targetSize = 250.0;
    const rect = Rect.fromLTWH(0, 0, targetSize, targetSize);

    final path = Path()..addOval(rect);
    canvas.clipPath(path);

    final matrix = _transformController.value;
    canvas.transform(matrix.storage);

    paintImage(
      canvas: canvas,
      rect: rect,
      image: _decodedImage!,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(250, 250);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.midnight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Adjust Photo', style: display(20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: C.lavender))
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: InteractiveViewer(
                          transformationController: _transformController,
                          minScale: 0.8,
                          maxScale: 4.0,
                          boundaryMargin: const EdgeInsets.all(300),
                          child: Center(
                            child: Image.memory(
                              widget.imageBytes,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      IgnorePointer(
                        child: Container(
                          width: 280,
                          height: 280,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: C.lavender, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.7),
                                spreadRadius: 500,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    child: pillButton('Use This Photo', () async {
                      final croppedBytes = await _cropAndCompress();
                      if (context.mounted && croppedBytes != null) {
                        Navigator.pop(context, croppedBytes);
                      }
                    }, icon: Icons.check_rounded),
                  ),
                ),
              ],
            ),
    );
  }
}
