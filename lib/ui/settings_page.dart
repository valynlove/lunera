import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n.dart';
import '../lock.dart';
import '../models.dart';
import '../notifications.dart';
import '../repo.dart';
import '../theme.dart';
import '../update_checker.dart';
import 'app_changelog.dart';
import 'about_sheet.dart';
import 'auth.dart';
import 'data_page.dart';
import 'security_page.dart';
import 'site_map.dart';

/// Halaman Pengaturan lengkap (Settings Center) Lunera yang mengadopsi struktur terorganisir
/// ala Wall o' Pay: Preferensi, Tampilan, Notifikasi, Terapi, Keamanan PIN/Biometrik,
/// Sinkronisasi Cloud Firestore, Backup JSON, Data Sampel, dan Informasi Aplikasi.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final custom = TextEditingController();
  bool _busyCloud = false;

  @override
  void dispose() {
    custom.dispose();
    super.dispose();
  }

  void _save(Prefs p) => ref.read(repoProvider)?.setPrefs(p);

  Future<void> _exportFile() async {
    final repo = ref.read(repoProvider);
    if (repo == null) return;
    try {
      final text = await repo.exportJson();
      final name = 'lunera_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}.json';
      final f = XFile.fromData(Uint8List.fromList(utf8.encode(text)), mimeType: 'application/json', name: name);
      if (kIsWeb) {
        await f.saveTo(name);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('File downloaded.'))));
      } else {
        await Share.shareXFiles([f], fileNameOverrides: [name]);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Failed: {0}', [e]))));
    }
  }

  Future<void> _importFile() async {
    const group = XTypeGroup(label: 'JSON', extensions: ['json']);
    final onAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final f = await openFile(acceptedTypeGroups: onAndroid ? const [] : const [group]);
    if (f == null) return;
    try {
      final raw = jsonDecode(utf8.decode(await f.readAsBytes()));
      final repo = ref.read(repoProvider);
      if (repo == null) return;
      final n = repo.validate(raw);
      if (!mounted) return;
      final mode = await showDialog<String>(
        context: context,
        builder: (d) => AlertDialog(
          title: Text(tr('Import {0} {0?record|records}', [n])),
          content: Text(
            tr('Merge: records from the file are added or updated, and your current data stays.\n\n') +
                tr('Replace all: your current data is deleted first, then filled from the file.'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d), child: Text(tr('Cancel'))),
            TextButton(onPressed: () => Navigator.pop(d, 'merge'), child: Text(tr('Merge'))),
            FilledButton(onPressed: () => Navigator.pop(d, 'replace'), child: Text(tr('Replace all'))),
          ],
        ),
      );
      if (mode == null) return;
      await repo.importData(raw as Map, replace: mode == 'replace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Restored {0} {0?record|records}.', [n]))));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Failed: {0}', [e]))));
    }
  }

  Future<void> _saveCloudBackup() async {
    final repo = ref.read(repoProvider);
    if (repo == null) return;
    HapticFeedback.lightImpact();
    setState(() => _busyCloud = true);
    try {
      await repo.saveBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Backup saved to cloud.'))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Failed: {0}', [e]))));
      }
    } finally {
      if (mounted) setState(() => _busyCloud = false);
    }
  }

  void _showAboutDialog(BuildContext context) {
    showAboutLuneraSheet(context);
  }

  void _showDisclaimerDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (d) => AlertDialog(
        title: Row(children: [
          const MoonLogoSmall(),
          const SizedBox(width: 12),
          Text(tr('Medical Disclaimer')),
        ]),
        content: Text(
          '$appName ${tr('is a tracking and reminder tool, not a substitute for medical advice. ')}'
          '${tr('Estimated levels use an average model and can differ from lab results. Dosing decisions always stay with your doctor.')}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: Text(tr('Close'))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(prefsProvider).value ?? const Prefs();
    User? user;
    try {
      user = ref.watch(userProvider).valueOrNull ?? FirebaseAuth.instance.currentUser;
    } catch (_) {
      user = null;
    }
    final ds = TimeOfDay(hour: p.dayStart ~/ 60, minute: p.dayStart % 60);
    final extra = [for (final x in p.places) if (!placePresets.contains(x)) x];
    final updateInfo = ref.watch(availableUpdateProvider);
    final syncState = ref.watch(syncStateProvider);

    final theme = Theme.of(context);
    final muted = Pastel.mist.withValues(alpha: 0.85);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Settings')),
        centerTitle: false,
        leading: IconButton(
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 48),
          children: [
            // 1. Preferences (Language)
            SectionHeader(title: tr('Preferences')),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('Language'), style: theme.textTheme.labelLarge),
                  const SizedBox(height: 10),
                  PillTabs<String>(
                    items: const [('en', 'English'), ('id', 'Bahasa Indonesia')],
                    value: L10n.code,
                    onChanged: (c) {
                      HapticFeedback.selectionClick();
                      L10n.set(c);
                      _save(p.copy(locale: c));
                    },
                  ),
                ],
              ),
            ),

            // 2. Appearance
            SectionHeader(title: tr('Appearance')),
            AppCard(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: C.midnight.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Pastel.lilac.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: C.peony.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: C.peony.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, color: Pastel.lilac, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('Arcane Astral'),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tr('Signature Arcane Astral sanctuary with mystical amethyst and honey gold highlights.'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Pastel.mist.withValues(alpha: 0.75),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              for (final col in [
                                const Color(0xFF120E2E),
                                const Color(0xFF201A4B),
                                const Color(0xFF9E7CC6),
                                const Color(0xFFF1BA79),
                                const Color(0xFFFCE3BD),
                              ])
                                Container(
                                  width: 16,
                                  height: 16,
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: col,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      width: 1,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Reminders & Privacy
            SectionHeader(title: tr('Reminders & Privacy')),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: iconBadge(Icons.alarm_rounded, Pastel.butter),
                    title: Text(
                      tr('Dose reminders'),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      AppNotifier.instance.supported
                          ? tr('Notifications appear at scheduled times, even offline.')
                          : tr('Only available on Android and iOS apps.'),
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                    value: p.notify,
                    onChanged: !AppNotifier.instance.supported
                        ? null
                        : (v) async {
                            HapticFeedback.selectionClick();
                            if (v && !await AppNotifier.instance.requestPermission()) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(tr('Notification permission was denied. Enable it in system settings.'))),
                                );
                              }
                              return;
                            }
                            _save(p.copy(notify: v));
                          },
                  ),
                  if (AppNotifier.instance.supported && p.notify) ...[
                    const Divider(height: 1, indent: 68),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('Notification Privacy (Lockscreen Masking)'),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          gap(4),
                          Text(
                            tr('Disguise notification text to protect your privacy when received in public or around family.'),
                            style: TextStyle(fontSize: 12, color: muted),
                          ),
                          gap(10),
                          PillTabs<String>(
                            items: [
                              ('off', tr('Standard')),
                              ('wellness', tr('Wellness & Routine')),
                              ('minimal', tr('Minimal')),
                            ],
                            value: p.discreetNotify,
                            onChanged: (mode) {
                              HapticFeedback.selectionClick();
                              _save(p.copy(discreetNotify: mode));
                            },
                          ),
                          gap(12),
                          OutlinedButton.icon(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              AppNotifier.instance.test(p);
                            },
                            icon: const Icon(Icons.notifications_active_outlined, size: 18),
                            label: Text(tr('Send test notification')),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 4. Therapy & Clinical
            SectionHeader(title: tr('Therapy & Clinical')),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('Hormone Level Units'), style: theme.textTheme.labelLarge),
                  gap(8),
                  for (final h in presets) ...[
                    Text(h.name, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final u in h.units.keys)
                          ChoiceChip(
                            label: Text(u),
                            selected: p.unitOf(h.id) == u,
                            onSelected: (_) {
                              HapticFeedback.selectionClick();
                              _save(p.copy(units: {...p.units, h.id: u}));
                            },
                          ),
                      ],
                    ),
                    gap(6),
                  ],
                  const Divider(height: 24),
                  Text(tr('Injection & Patch Sites'), style: theme.textTheme.labelLarge),
                  gap(4),
                  Text(
                    tr('Selection order determines next suggested site, alternating from top to bottom.'),
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                  gap(10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(color: Pastel.lilac.withValues(alpha: 0.3)),
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      showSheet(context, const SiteRotationSheet());
                    },
                    icon: const Icon(Icons.accessibility_new_rounded, size: 18, color: Pastel.lilac),
                    label: Text(tr('View Site Rotation & Health'), style: const TextStyle(color: Pastel.lilac, fontWeight: FontWeight.w600)),
                  ),
                  gap(10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final x in [...placePresets, ...extra])
                        FilterChip(
                          label: Text(tr(x)),
                          selected: p.places.contains(x),
                          onSelected: (v) {
                            HapticFeedback.selectionClick();
                            _save(p.copy(places: v ? [...p.places, x] : ([...p.places]..remove(x))));
                          },
                        ),
                    ],
                  ),
                  gap(10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: custom,
                          decoration: InputDecoration(labelText: tr('Other location')),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: () {
                          final v = custom.text.trim();
                          if (v.isEmpty || p.places.contains(v)) return;
                          HapticFeedback.lightImpact();
                          _save(p.copy(places: [...p.places, v]));
                          custom.clear();
                        },
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(tr('Count HRT therapy duration')),
                    subtitle: Text(tr('Show on History tab.')),
                    value: p.hrtCounter,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      _save(p.copy(hrtCounter: v));
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(tr('Day starts at')),
                    subtitle: Text(tr('Doses past midnight are counted toward yesterday.')),
                    trailing: Text(ds.format(context), style: const TextStyle(fontWeight: FontWeight.w700)),
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      final t = await showTimePicker(context: context, initialTime: ds);
                      if (t != null) _save(p.copy(dayStart: t.hour * 60 + t.minute));
                    },
                  ),
                ],
              ),
            ),

            // 5. Home Screen Widgets
            SectionHeader(title: tr('Home Screen Widgets')),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('Long-press home screen, choose Widgets, then find Lunera: available HRT counter, schedule, and level chart widgets.'),
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(tr('Hide details on widgets')),
                    subtitle: Text(tr('Widgets only display the app name. Useful if your home screen is seen by others.')),
                    value: p.widgetHide,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      _save(p.copy(widgetHide: v));
                    },
                  ),
                ],
              ),
            ),

            // 6. Security & Privacy
            SectionHeader(title: tr('Security & Privacy')),
            ValueListenableBuilder<AppLockState>(
              valueListenable: Lock.instance.state,
              builder: (context, lockState, _) {
                final timeoutLabel = switch (lockState.delayMin) {
                  0 => tr('Immediately'),
                  5 => tr('5 minutes'),
                  _ => tr('1 minute'),
                };
                return AppCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: iconBadge(
                      Icons.lock_outline_rounded,
                      lockState.enabled ? Pastel.mint : Pastel.lilac,
                    ),
                    title: Text(
                      tr('App PIN & Biometrics'),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      lockState.enabled
                          ? (lockState.bio
                              ? tr('Active (PIN + Biometrics) • Timeout: {0}', [timeoutLabel])
                              : tr('Active (PIN) • Timeout: {0}', [timeoutLabel]))
                          : tr('Protect your therapy logs with a 6-digit PIN and biometrics.'),
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(builder: (_) => const SecurityPage()),
                      );
                    },
                  ),
                );
              },
            ),

            // 7. Cloud Sync & Storage
            SectionHeader(title: tr('Cloud Sync & Storage')),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (user == null) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Pastel.lilac.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cloud_off_outlined,
                            color: Pastel.lilac,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr('Guest Mode (Offline)'),
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tr('Your records are stored locally on this device. Sign in to back up and sync across devices.'),
                                style: theme.textTheme.bodySmall?.copyWith(color: muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.login_rounded, size: 18),
                        label: Text(tr('Sign In / Create Account')),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(builder: (_) => const WelcomePage()),
                        ),
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Pastel.mint.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            syncState.status == SyncStatus.syncing
                                ? Icons.sync_rounded
                                : Icons.cloud_done_rounded,
                            color: Pastel.mint,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    tr('Real-Time Cloud Sync'),
                                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Pastel.mint.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      syncState.status == SyncStatus.syncing
                                          ? tr('Syncing in progress...')
                                          : tr('Active'),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Pastel.mint,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tr('Automatic background sync keeps your data safe across devices.'),
                                style: theme.textTheme.bodySmall?.copyWith(color: muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: _busyCloud
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.cloud_upload_outlined, size: 16),
                            label: Text(tr('Save Cloud Backup Now')),
                            onPressed: _busyCloud ? null : _saveCloudBackup,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.history_toggle_off_rounded, size: 16),
                            label: Text(tr('Manage Cloud Backups')),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(builder: (_) => const DataPage()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // 8. Manual Backup & Export
            SectionHeader(title: tr('Manual Backup & Export')),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: iconBadge(Icons.file_upload_outlined, Pastel.mint),
                    title: Text(
                      tr('Export backup file (JSON)'),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      tr('Save or share a copy of all your therapy data.'),
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _exportFile();
                    },
                  ),
                  const Divider(height: 1, indent: 68),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: iconBadge(Icons.file_download_outlined, Pastel.sky),
                    title: Text(
                      tr('Import backup file (JSON)'),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      tr('Merges or restores a backup file into this device.'),
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _importFile();
                    },
                  ),
                  const Divider(height: 1, indent: 68),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: iconBadge(Icons.history_toggle_off_rounded, Pastel.lilac),
                    title: Text(
                      tr('Manage cloud backups & history'),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      tr('View and restore past cloud snapshots'),
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(builder: (_) => const DataPage()),
                      );
                    },
                  ),
                ],
              ),
            ),

            // 9. Sample Data
            SectionHeader(title: tr('Sample Data')),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('Populate your account with sample therapies, logs, lab results, and stock to test the app. All marked as "(sample)" and can be safely deleted.'),
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                  gap(10),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () async {
                          HapticFeedback.selectionClick();
                          if (!await confirm(context, tr('Add sample data to your account?'), ok: tr('Add'))) return;
                          HapticFeedback.lightImpact();
                          ref.read(repoProvider)?.addDemo();
                        },
                        child: Text(tr('Add')),
                      ),
                      OutlinedButton(
                        onPressed: () async {
                          HapticFeedback.selectionClick();
                          if (!await confirm(context, tr('Delete all sample data?'), ok: tr('Delete'))) return;
                          HapticFeedback.mediumImpact();
                          ref.read(repoProvider)?.clearDemo();
                        },
                        child: Text(tr('Delete')),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 10. Account
            SectionHeader(title: tr('Account')),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: iconBadge(Icons.logout_rounded, C.amber),
                    title: Text(
                      tr('Sign out'),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      user?.email ?? user?.displayName ?? tr('Guest'),
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.pop(context);
                      signOutAll();
                    },
                  ),
                ],
              ),
            ),

            // 11. About & Support
            SectionHeader(title: tr('About & Support')),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: iconBadge(Icons.info_outline_rounded, Pastel.lilac),
                    title: Text(
                      tr('About {0}', [appName]),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      tr('Personal health & therapy tracking application'),
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _showAboutDialog(context);
                    },
                  ),
                  const Divider(height: 1, indent: 68),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: iconBadge(
                      Icons.system_update_alt_rounded,
                      updateInfo != null ? const Color(0xFFE65100) : Pastel.sky,
                    ),
                    title: Row(
                      children: [
                        Text(tr('Check for Updates')),
                        if (updateInfo != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE65100),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tr('NEW'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      updateInfo != null
                          ? 'v${UpdateCheckerService.currentVersion} ➔ v${updateInfo.latestVersion} (${tr('Update Available!')})'
                          : 'Lunera v${UpdateCheckerService.currentVersion}${kDebugMode ? ' (Dev)' : ''} • ${kDebugMode ? 'Debug Build' : 'Latest Release'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: updateInfo != null ? const Color(0xFFE65100) : muted,
                        fontWeight: updateInfo != null ? FontWeight.w700 : null,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      if (updateInfo != null) {
                        UpdateCheckerService.showUpdateDialog(context, updateInfo);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(tr('Checking for updates...')),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                        UpdateCheckerService.checkAndPromptUpdate(context, ref: ref, silentIfUpToDate: false);
                      }
                    },
                  ),
                  const Divider(height: 1, indent: 68),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: iconBadge(Icons.history_edu_rounded, Pastel.rose),
                    title: Text(
                      tr('Version Changelog'),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      tr(
                        "See what's new in v{version} and past releases",
                        {'version': UpdateCheckerService.currentVersion},
                      ),
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      showAppChangelogSheet(context);
                    },
                  ),
                  const Divider(height: 1, indent: 68),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: iconBadge(Icons.code_rounded, Pastel.mint),
                    title: Text(
                      tr('GitHub Repository'),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      tr('View source code, release notes, and issue tracker.'),
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                    trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      UpdateCheckerService.openUrl('https://github.com/valynlove/lunera');
                    },
                  ),
                  const Divider(height: 1, indent: 68),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: iconBadge(Icons.health_and_safety_outlined, C.amber),
                    title: Text(
                      tr('Medical Disclaimer'),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      tr('Lunera is a personal tracking tool and not a substitute for professional medical advice.'),
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                    trailing: const Icon(Icons.info_outline_rounded, size: 18),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _showDisclaimerDialog(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
