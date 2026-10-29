import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../profile.dart';
import '../theme.dart';
import '../update_checker.dart';
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

    Widget tile(IconData icon, String title, VoidCallback onTap, {String? sub}) => ListTile(
          leading: Icon(icon, color: C.peony),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: sub == null ? null : Text(sub),
          trailing: Icon(Icons.chevron_right_rounded, color: fg.withValues(alpha: .5)),
          onTap: onTap,
        );
    void go(Widget p) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => p));

    return ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 32), children: [
      Text('Lainnya', style: display(36)),
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
          tile(Icons.person_outline_rounded, 'Profil Akun', () => go(const ProfilePage()), sub: 'Ubah foto profil dan nama panggilan'),
          tile(Icons.tune_rounded, 'Pengaturan', () => go(const SettingsPage()), sub: 'Tampilan, satuan, lokasi suntik, pengingat'),
          tile(Icons.insights_rounded, 'Wawasan', () => go(const InsightsPage()), sub: 'Kepatuhan dan pola suasana hati'),
          tile(Icons.accessibility_new_rounded, 'Tubuh & perubahan', () => go(const BodyPage()), sub: 'Garis waktu dari jurnalmu'),
          tile(Icons.lock_outline_rounded, 'Keamanan', () => go(const SecurityPage()), sub: 'Kunci PIN dan biometrik'),
          tile(Icons.import_export_rounded, 'Impor, ekspor, cadangan', () => go(const DataPage())),
          tile(Icons.system_update_rounded, 'Periksa Pembaruan', () => UpdateCheckerService.checkAndPromptUpdate(context), sub: 'Versi ${UpdateCheckerService.currentVersion}'),
          tile(Icons.info_outline_rounded, 'Tentang $appName', () {
            showDialog<void>(
              context: context,
              builder: (d) => AlertDialog(
                title: const Row(children: [MoonLogoSmall(), SizedBox(width: 12), Text(appName)]),
                content: const Text(
                    'Versi ${UpdateCheckerService.currentVersion}\n\n$appName adalah alat pencatat dan pengingat, bukan pengganti saran medis. '
                    'Perkiraan level memakai model rata-rata dan bisa berbeda dari hasil lab. Keputusan dosis selalu bersama dokter.'),
                actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('Tutup'))],
              ),
            );
          }),
        ]),
      ),
      gap(16),
      OutlinedButton.icon(onPressed: () => signOutAll(), icon: const Icon(Icons.logout_rounded), label: const Text('Keluar')),
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

