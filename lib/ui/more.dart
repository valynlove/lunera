import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n.dart';
import '../profile.dart';
import '../theme.dart';
import '../update_checker.dart';
import 'app_changelog.dart';
import 'auth.dart';
import 'body.dart';
import 'data_page.dart';
import 'insights.dart';
import 'profile_page.dart';
import 'security_page.dart';
import 'settings_page.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final username = (user?.displayName?.isNotEmpty ?? false) ? user!.displayName! : null;
    final displayName = ref.watch(displayNameProvider);
    final fg = Theme.of(context).colorScheme.onSurface;
    final updateInfo = ref.watch(availableUpdateProvider);

    Widget tile(
      IconData icon,
      String title,
      VoidCallback onTap, {
      String? sub,
      Widget? trailing,
      Widget? titleExtra,
    }) =>
        ListTile(
          leading: Icon(icon, color: C.peony),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (titleExtra != null) ...[
                const SizedBox(width: 8),
                titleExtra,
              ],
            ],
          ),
          subtitle: sub == null ? null : Text(sub),
          trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: fg.withValues(alpha: .5)),
          onTap: onTap,
        );
    void go(Widget p) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => p));

    return ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 32), children: [
      Text(tr('More'), style: display(36)),
      gap(18),
      InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => go(const ProfilePage()),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: cardBox(context),
          child: Row(children: [
            const UserAvatar(size: 60),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(displayName ?? appName, style: display(22)),
                if (username != null)
                  Text('@$username', style: TextStyle(color: fg.withValues(alpha: 0.7), fontWeight: FontWeight.w600)),
                if (user?.email != null) Text(user!.email!, style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
            Icon(Icons.chevron_right_rounded, color: fg.withValues(alpha: .5)),
          ]),
        ),
      ),
      gap(16),
      Container(
        decoration: cardBox(context),
        child: Column(children: [
          tile(Icons.person_outline_rounded, tr('Account Profile'), () => go(const ProfilePage()), sub: tr('Change photo and nickname')),
          tile(Icons.tune_rounded, tr('Settings'), () => go(const SettingsPage()), sub: tr('Appearance, units, injection sites, reminders')),
          tile(Icons.insights_rounded, tr('Insights'), () => go(const InsightsPage()), sub: tr('Adherence and mood patterns')),
          tile(Icons.accessibility_new_rounded, tr('Body & changes'), () => go(const BodyPage()), sub: tr('Timeline from your journal')),
          tile(Icons.lock_outline_rounded, tr('Security'), () => go(const SecurityPage()), sub: tr('PIN lock and biometrics')),
          tile(Icons.import_export_rounded, tr('Import, export, backups'), () => go(const DataPage())),
          tile(
            Icons.system_update_rounded,
            tr('Check for Updates'),
            () {
              if (updateInfo != null) {
                UpdateCheckerService.showUpdateDialog(context, updateInfo);
              } else {
                UpdateCheckerService.checkAndPromptUpdate(context, ref: ref);
              }
            },
            titleExtra: updateInfo != null
                ? Container(
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
                  )
                : null,
            sub: updateInfo != null
                ? 'v${UpdateCheckerService.currentVersion} ➔ v${updateInfo.latestVersion} (${tr('Update Available!')})'
                : 'v${UpdateCheckerService.currentVersion}',
          ),
          tile(
            Icons.history_edu_rounded,
            tr('Version Changelog'),
            () => showAppChangelogSheet(context),
            sub: tr("See what's new in v{version} and past releases", {'version': UpdateCheckerService.currentVersion}),
          ),
          tile(Icons.info_outline_rounded, tr('About {0}', [appName]), () {
            showDialog<void>(
              context: context,
              builder: (d) => AlertDialog(
                title: const Row(children: [MoonLogoSmall(), SizedBox(width: 12), Text(appName)]),
                content: Text(
                    'Version ${UpdateCheckerService.currentVersion}\n\n$appName ${tr('is a tracking and reminder tool, not a substitute for medical advice. ')}${tr('Estimated levels use an average model and can differ from lab results. Dosing decisions always stay with your doctor.')}'),
                actions: [TextButton(onPressed: () => Navigator.pop(d), child: Text(tr('Close')))],
              ),
            );
          }),
        ]),
      ),
      gap(16),
      OutlinedButton.icon(onPressed: () => signOutAll(), icon: const Icon(Icons.logout_rounded), label: Text(tr('Sign out'))),
    ]);
  }
}

class MoonLogoSmall extends StatelessWidget {
  const MoonLogoSmall({super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: C.deep, borderRadius: BorderRadius.circular(12)),
        child: const MoonLogo(size: 28),
      );
}
