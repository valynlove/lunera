import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n.dart';
import '../models.dart';
import '../notifications.dart';
import '../repo.dart';
import '../theme.dart';
import '../update_checker.dart';
import 'app_changelog.dart';
import 'auth.dart';
import 'data_page.dart';
import 'site_map.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final custom = TextEditingController();

  @override
  void dispose() {
    custom.dispose();
    super.dispose();
  }

  void _save(Prefs p) => ref.read(repoProvider)?.setPrefs(p);

  Widget _card(String title, List<Widget> kids) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(20),
        decoration: cardBox(context),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          gap(12),
          ...kids,
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(prefsProvider).value ?? const Prefs();
    final user = FirebaseAuth.instance.currentUser;
    final ds = TimeOfDay(hour: p.dayStart ~/ 60, minute: p.dayStart % 60);
    final extra = [for (final x in p.places) if (!placePresets.contains(x)) x];
    final updateInfo = ref.watch(availableUpdateProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Row(children: [
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)),
            Expanded(child: Text(tr('Settings'), style: display(32))),
          ]),
          gap(16),
          _card(tr('Language'), [
            PillTabs<String>(
              items: const [('en', 'English'), ('id', 'Bahasa Indonesia')],
              value: L10n.code,
              onChanged: (c) {
                L10n.set(c);
                _save(p.copy(locale: c));
              },
            ),
          ]),
          _card(tr('Appearance'), [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: C.midnight.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Pastel.lilac.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Pastel.lilac.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: Pastel.lilac, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('Celestial Midnight & Pastel'),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tr('Signature nocturnal sanctuary with soft pastel highlights.'),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Pastel.mist.withValues(alpha: 0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            gap(14),
            Text(tr('Phase accent'), style: const TextStyle(fontWeight: FontWeight.w600)),
            gap(6),
            Wrap(spacing: 8, runSpacing: 6, children: [
              for (final e in accents.entries)
                ChoiceChip(
                  label: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.circle, size: 12, color: e.value.$2),
                    Icon(Icons.circle, size: 12, color: e.value.$3),
                    const SizedBox(width: 6),
                    Text(tr(e.value.$1)),
                  ]),
                  selected: p.accent == e.key,
                  onSelected: (_) => _save(p.copy(accent: e.key)),
                ),
            ]),
          ]),
          _card(tr('Reminders'), [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(tr('Dose reminders')),
              subtitle: Text(AppNotifier.instance.supported
                  ? tr('Notifications appear at scheduled times, even offline.')
                  : tr('Only available on Android and iOS apps.')),
              value: p.notify,
              onChanged: !AppNotifier.instance.supported
                  ? null
                  : (v) async {
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
              const Divider(height: 20),
              Text(tr('Notification Privacy (Lockscreen Masking)'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              gap(4),
              Text(
                tr('Disguise notification text to protect your privacy when received in public or around family.'),
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
              gap(10),
              PillTabs<String>(
                items: [
                  ('off', tr('Standard')),
                  ('wellness', tr('Wellness & Routine')),
                  ('minimal', tr('Minimal')),
                ],
                value: p.discreetNotify,
                onChanged: (mode) => _save(p.copy(discreetNotify: mode)),
              ),
              gap(12),
              OutlinedButton.icon(
                onPressed: () => AppNotifier.instance.test(p),
                icon: const Icon(Icons.notifications_active_outlined),
                label: Text(tr('Send test notification')),
              ),
            ],
          ]),
          _card(tr('Hormone Level Units'), [
            for (final h in presets) ...[
              Text(h.name, style: Theme.of(context).textTheme.bodySmall),
              Wrap(spacing: 8, children: [
                for (final u in h.units.keys)
                  ChoiceChip(label: Text(u), selected: p.unitOf(h.id) == u, onSelected: (_) => _save(p.copy(units: {...p.units, h.id: u}))),
              ]),
              gap(6),
            ],
          ]),
          _card(tr('Injection & Patch Sites'), [
            Text(tr('Selection order determines next suggested site, alternating from top to bottom.')),
            gap(10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                side: BorderSide(color: Pastel.lilac.withValues(alpha: 0.3)),
              ),
              onPressed: () => showSheet(context, const SiteRotationSheet()),
              icon: const Icon(Icons.accessibility_new_rounded, size: 18, color: Pastel.lilac),
              label: Text(tr('View Site Rotation & Health'), style: const TextStyle(color: Pastel.lilac, fontWeight: FontWeight.w600)),
            ),
            gap(10),
            Wrap(spacing: 8, runSpacing: 4, children: [
              for (final x in [...placePresets, ...extra])
                FilterChip(
                  label: Text(tr(x)),
                  selected: p.places.contains(x),
                  onSelected: (v) => _save(p.copy(places: v ? [...p.places, x] : ([...p.places]..remove(x)))),
                ),
            ]),
            gap(10),
            Row(children: [
              Expanded(child: TextField(controller: custom, decoration: InputDecoration(labelText: tr('Other location')))),
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
          _card(tr('Days & Counters'), [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(tr('Count HRT therapy duration')),
              subtitle: Text(tr('Show on History tab.')),
              value: p.hrtCounter,
              onChanged: (v) => _save(p.copy(hrtCounter: v)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(tr('Day starts at')),
              subtitle: Text(tr('Doses past midnight are counted toward yesterday.')),
              trailing: Text(ds.format(context), style: const TextStyle(fontWeight: FontWeight.w700)),
              onTap: () async {
                final t = await showTimePicker(context: context, initialTime: ds);
                if (t != null) _save(p.copy(dayStart: t.hour * 60 + t.minute));
              },
            ),
          ]),
          _card(tr('Home Screen Widgets'), [
            Text(tr('Long-press home screen, choose Widgets, then find Lunera: available HRT counter, schedule, and level chart widgets.')),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(tr('Hide details on widgets')),
              subtitle: Text(tr('Widgets only display the app name. Useful if your home screen is seen by others.')),
              value: p.widgetHide,
              onChanged: (v) => _save(p.copy(widgetHide: v)),
            ),
          ]),
          _card(tr('About & Support'), [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.system_update_alt_rounded),
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
                    : 'Lunera v${UpdateCheckerService.currentVersion} • Latest Release',
                style: TextStyle(
                  color: updateInfo != null ? const Color(0xFFE65100) : null,
                  fontWeight: updateInfo != null ? FontWeight.w700 : null,
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
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
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history_edu_rounded),
              title: Text(tr('Version Changelog')),
              subtitle: Text(
                tr(
                  "See what's new in v{version} and past releases",
                  {'version': UpdateCheckerService.currentVersion},
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => showAppChangelogSheet(context),
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.code_rounded),
              title: Text(tr('GitHub Repository')),
              subtitle: Text(tr('View source code, release notes, and issue tracker.')),
              trailing: const Icon(Icons.open_in_new_rounded, size: 18),
              onTap: () => UpdateCheckerService.openUrl('https://github.com/valynlove/lunera'),
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.health_and_safety_outlined),
              title: Text(tr('Medical Disclaimer')),
              subtitle: Text(tr('Lunera is a personal tracking tool and not a substitute for professional medical advice.')),
              trailing: const Icon(Icons.info_outline_rounded, size: 18),
              onTap: () {
                showDialog<void>(
                  context: context,
                  builder: (d) => AlertDialog(
                    title: Row(children: [
                      const MoonLogoSmall(),
                      const SizedBox(width: 12),
                      Text(tr('Medical Disclaimer')),
                    ]),
                    content: Text(
                      '$appName ${tr('is a tracking and reminder tool, not a substitute for medical advice. ')}${tr('Estimated levels use an average model and can differ from lab results. Dosing decisions always stay with your doctor.')}',
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(d), child: Text(tr('Close'))),
                    ],
                  ),
                );
              },
            ),
          ]),
          _card(tr('Sample Data'), [
            Text(tr('Populate your account with sample therapies, logs, lab results, and stock to test the app. All marked as "(sample)" and can be safely deleted.')),
            gap(10),
            Wrap(spacing: 8, children: [
              OutlinedButton(
                onPressed: () async {
                  if (!await confirm(context, tr('Add sample data to your account?'), ok: tr('Add'))) return;
                  ref.read(repoProvider)?.addDemo();
                },
                child: Text(tr('Add')),
              ),
              OutlinedButton(
                onPressed: () async {
                  if (!await confirm(context, tr('Delete all sample data?'), ok: tr('Delete'))) return;
                  ref.read(repoProvider)?.clearDemo();
                },
                child: Text(tr('Delete')),
              ),
            ]),
          ]),
          _card(tr('Data & Storage'), [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.import_export_rounded),
              title: Text(tr('Import, export, backups')),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DataPage())),
            ),
          ]),
          _card(tr('Account'), [
            if (user?.displayName?.isNotEmpty ?? false) Text('@${user!.displayName}', style: const TextStyle(fontWeight: FontWeight.w700)),
            if (user?.email != null) Text(user!.email!),
            gap(8),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                signOutAll();
              },
              icon: const Icon(Icons.logout_rounded),
              label: Text(tr('Sign out')),
            ),
          ]),
        ]),
      ),
    );
  }
}
