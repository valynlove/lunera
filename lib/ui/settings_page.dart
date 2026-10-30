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
            Expanded(child: Text(context.tr('Settings'), style: display(32))),
          ]),
          gap(16),
          _card(context.tr('Appearance'), [
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
                          context.tr('Celestial Midnight & Pastel'),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.tr('Signature nocturnal sanctuary with soft pastel highlights.'),
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
            Text(context.tr('Phase accent'), style: const TextStyle(fontWeight: FontWeight.w600)),
            gap(6),
            Wrap(spacing: 8, runSpacing: 6, children: [
              for (final e in accents.entries)
                ChoiceChip(
                  label: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.circle, size: 12, color: e.value.$2),
                    Icon(Icons.circle, size: 12, color: e.value.$3),
                    const SizedBox(width: 6),
                    Text(e.value.$1),
                  ]),
                  selected: p.accent == e.key,
                  onSelected: (_) => _save(p.copy(accent: e.key)),
                ),
            ]),
            gap(8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.language_rounded),
              title: Text(context.tr('Language')),
              subtitle: Text(p.locale == 'id' ? context.tr('Bahasa Indonesia') : context.tr('English (Default)')),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                final chosen = await showDialog<String>(
                  context: context,
                  builder: (ctx) => SimpleDialog(
                    title: Text(context.tr('Language')),
                    children: [
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, 'en'),
                        child: Row(children: [
                          Icon(p.locale == 'en' ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: C.peony),
                          const SizedBox(width: 12),
                          const Text('English (Default)'),
                        ]),
                      ),
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, 'id'),
                        child: Row(children: [
                          Icon(p.locale == 'id' ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: C.peony),
                          const SizedBox(width: 12),
                          const Text('Bahasa Indonesia'),
                        ]),
                      ),
                    ],
                  ),
                );
                if (chosen != null) _save(p.copy(locale: chosen));
              },
            ),
          ]),
          _card(context.tr('Reminders'), [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('Dose reminders')),
              subtitle: Text(AppNotifier.instance.supported
                  ? context.tr('Notifications appear at scheduled times, even offline.')
                  : context.tr('Only available on Android and iOS apps.')),
              value: p.notify,
              onChanged: !AppNotifier.instance.supported
                  ? null
                  : (v) async {
                      if (v && !await AppNotifier.instance.requestPermission()) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(context.tr('Notification permission was denied. Enable it in system settings.'))),
                          );
                        }
                        return;
                      }
                      _save(p.copy(notify: v));
                    },
            ),
            if (AppNotifier.instance.supported && p.notify)
              OutlinedButton.icon(
                onPressed: () => AppNotifier.instance.test(),
                icon: const Icon(Icons.notifications_active_outlined),
                label: Text(context.tr('Send test notification')),
              ),
          ]),
          _card(context.tr('Hormone Level Units'), [
            for (final h in presets) ...[
              Text(h.name, style: Theme.of(context).textTheme.bodySmall),
              Wrap(spacing: 8, children: [
                for (final u in h.units.keys)
                  ChoiceChip(label: Text(u), selected: p.unitOf(h.id) == u, onSelected: (_) => _save(p.copy(units: {...p.units, h.id: u}))),
              ]),
              gap(6),
            ],
          ]),
          _card(context.tr('Injection & Patch Sites'), [
            Text(context.tr('Selection order determines next suggested site, alternating from top to bottom.')),
            gap(8),
            Wrap(spacing: 8, runSpacing: 4, children: [
              for (final x in [...placePresets, ...extra])
                FilterChip(
                  label: Text(x),
                  selected: p.places.contains(x),
                  onSelected: (v) => _save(p.copy(places: v ? [...p.places, x] : ([...p.places]..remove(x)))),
                ),
            ]),
            gap(10),
            Row(children: [
              Expanded(child: TextField(controller: custom, decoration: InputDecoration(labelText: context.tr('Other location')))),
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
          _card(context.tr('Days & Counters'), [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('Count HRT therapy duration')),
              subtitle: Text(context.tr('Show on History tab.')),
              value: p.hrtCounter,
              onChanged: (v) => _save(p.copy(hrtCounter: v)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('Day starts at')),
              subtitle: Text(context.tr('Doses past midnight are counted for the previous day.')),
              trailing: Text(ds.format(context), style: const TextStyle(fontWeight: FontWeight.w700)),
              onTap: () async {
                final t = await showTimePicker(context: context, initialTime: ds);
                if (t != null) _save(p.copy(dayStart: t.hour * 60 + t.minute));
              },
            ),
          ]),
          _card(context.tr('Home Screen Widgets'), [
            Text(context.tr('Long-press home screen, choose Widgets, then find Lunera: available HRT counter, schedule, and level chart widgets.')),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('Hide details on widgets')),
              subtitle: Text(context.tr('Widgets only display the app name. Useful if your home screen is seen by others.')),
              value: p.widgetHide,
              onChanged: (v) => _save(p.copy(widgetHide: v)),
            ),
          ]),
          _card(context.tr('About & Support'), [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.system_update_alt_rounded),
              title: Row(
                children: [
                  Text(context.tr('Check for Updates')),
                  if (updateInfo != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE65100),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        context.tr('NEW'),
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
                    ? 'v${UpdateCheckerService.currentVersion} ➔ v${updateInfo.latestVersion} (${context.tr('Update Available!')})'
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
                      content: Text(context.tr('Checking for updates...')),
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
              title: Text(context.tr('Version Changelog')),
              subtitle: Text(
                context.tr(
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
              title: Text(context.tr('GitHub Repository')),
              subtitle: Text(context.tr('View source code, release notes, and issue tracker.')),
              trailing: const Icon(Icons.open_in_new_rounded, size: 18),
              onTap: () => UpdateCheckerService.openUrl('https://github.com/valynlove/lunera'),
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.health_and_safety_outlined),
              title: Text(context.tr('Medical Disclaimer')),
              subtitle: Text(context.tr('Lunera is a personal tracking tool and not a substitute for professional medical advice.')),
              trailing: const Icon(Icons.info_outline_rounded, size: 18),
              onTap: () {
                showDialog<void>(
                  context: context,
                  builder: (d) => AlertDialog(
                    title: Row(children: [
                      const MoonLogoSmall(),
                      const SizedBox(width: 12),
                      Text(context.tr('Medical Disclaimer')),
                    ]),
                    content: const Text(
                      'Lunera is a personal health tracking and medication reminder tool. It is not a licensed medical software or substitute for professional clinical advice.\n\n'
                      'Estimated hormone levels are calculated using generalized population pharmacokinetic curves and may differ significantly from your individual laboratory blood tests. Always consult your healthcare provider or physician for dosage adjustments.',
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(d), child: Text(context.tr('Close'))),
                    ],
                  ),
                );
              },
            ),
          ]),
          _card(context.tr('Sample Data'), [
            Text(context.tr('Populate your account with sample therapies, logs, lab results, and stock to test the app. All marked as "(sample)" and can be safely deleted.')),
            gap(10),
            Wrap(spacing: 8, children: [
              OutlinedButton(
                onPressed: () async {
                  if (!await confirm(context, context.tr('Add sample data to your account?'), ok: context.tr('Add'))) return;
                  ref.read(repoProvider)?.addDemo();
                },
                child: Text(context.tr('Add')),
              ),
              OutlinedButton(
                onPressed: () async {
                  if (!await confirm(context, context.tr('Delete all sample data?'), ok: context.tr('Delete'))) return;
                  ref.read(repoProvider)?.clearDemo();
                },
                child: Text(context.tr('Delete')),
              ),
            ]),
          ]),
          _card(context.tr('Data & Storage'), [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.import_export_rounded),
              title: Text(context.tr('Import, export, backup')),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DataPage())),
            ),
          ]),
          _card(context.tr('Account'), [
            if (user?.displayName?.isNotEmpty ?? false) Text('@${user!.displayName}', style: const TextStyle(fontWeight: FontWeight.w700)),
            if (user?.email != null) Text(user!.email!),
            gap(8),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                signOutAll();
              },
              icon: const Icon(Icons.logout_rounded),
              label: Text(context.tr('Log out')),
            ),
          ]),
        ]),
      ),
    );
  }
}
