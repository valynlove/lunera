import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../notifications.dart';
import '../repo.dart';
import '../theme.dart';
import '../update_checker.dart';
import 'auth.dart';
import 'data_page.dart';

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
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Row(children: [
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)),
            Expanded(child: Text('Pengaturan', style: display(32))),
          ]),
          gap(16),
          _card('Tampilan', [
            Wrap(spacing: 8, children: [
              for (final t in const [('system', 'Ikuti sistem'), ('light', 'Terang'), ('dark', 'Gelap')])
                ChoiceChip(label: Text(t.$2), selected: p.theme == t.$1, onSelected: (_) => _save(p.copy(theme: t.$1))),
            ]),
            gap(12),
            const Text('Warna aksen'),
            Wrap(spacing: 8, runSpacing: 4, children: [
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
          ]),
          _card('Pengingat', [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pengingat dosis'),
              subtitle: Text(AppNotifier.instance.supported
                  ? 'Notifikasi muncul pada jam jadwal, juga saat offline.'
                  : 'Hanya tersedia di aplikasi Android dan iOS.'),
              value: p.notify,
              onChanged: !AppNotifier.instance.supported
                  ? null
                  : (v) async {
                      if (v && !await AppNotifier.instance.requestPermission()) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Izin notifikasi ditolak. Aktifkan lewat pengaturan sistem.')));
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
                label: const Text('Kirim notifikasi uji'),
              ),
          ]),
          _card('Satuan level hormon', [
            for (final h in presets) ...[
              Text(h.name, style: Theme.of(context).textTheme.bodySmall),
              Wrap(spacing: 8, children: [
                for (final u in h.units.keys)
                  ChoiceChip(label: Text(u), selected: p.unitOf(h.id) == u, onSelected: (_) => _save(p.copy(units: {...p.units, h.id: u}))),
              ]),
              gap(6),
            ],
          ]),
          _card('Lokasi suntik dan patch', [
            const Text('Urutan pemilihan menentukan saran lokasi berikutnya, bergantian dari atas ke bawah.'),
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
              Expanded(child: TextField(controller: custom, decoration: const InputDecoration(labelText: 'Lokasi lain'))),
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
          _card('Hari dan penghitung', [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Hitung lama menjalani terapi'),
              subtitle: const Text('Tampil di tab Riwayat.'),
              value: p.hrtCounter,
              onChanged: (v) => _save(p.copy(hrtCounter: v)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Hari baru dimulai pukul'),
              subtitle: const Text('Dosis lewat tengah malam masih dihitung hari sebelumnya.'),
              trailing: Text(ds.format(context), style: const TextStyle(fontWeight: FontWeight.w700)),
              onTap: () async {
                final t = await showTimePicker(context: context, initialTime: ds);
                if (t != null) _save(p.copy(dayStart: t.hour * 60 + t.minute));
              },
            ),
          ]),
          _card('Pembaruan Aplikasi', [
            const Text('Versi ${UpdateCheckerService.currentVersion}'),
            gap(8),
            OutlinedButton.icon(
              onPressed: () => UpdateCheckerService.checkAndPromptUpdate(context),
              icon: const Icon(Icons.system_update_rounded),
              label: const Text('Periksa Pembaruan'),
            ),
          ]),
          _card('Data contoh', [
            const Text('Isi akunmu dengan terapi, catatan, hasil lab, dan stok contoh untuk mencoba aplikasi. Semuanya diberi tanda "(contoh)" dan bisa dihapus tanpa menyentuh datamu.'),
            gap(10),
            Wrap(spacing: 8, children: [
              OutlinedButton(
                onPressed: () async {
                  if (!await confirm(context, 'Tambahkan data contoh ke akunmu?', ok: 'Tambahkan')) return;
                  ref.read(repoProvider)?.addDemo();
                },
                child: const Text('Tambah'),
              ),
              OutlinedButton(
                onPressed: () async {
                  if (!await confirm(context, 'Hapus semua data contoh?')) return;
                  ref.read(repoProvider)?.clearDemo();
                },
                child: const Text('Hapus'),
              ),
            ]),
          ]),
          _card('Data', [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.import_export_rounded),
              title: const Text('Impor, ekspor, cadangan'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DataPage())),
            ),
          ]),
          _card('Akun', [
            if (user?.displayName?.isNotEmpty ?? false) Text('@${user!.displayName}', style: const TextStyle(fontWeight: FontWeight.w700)),
            if (user?.email != null) Text(user!.email!),
            gap(8),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                signOutAll();
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Keluar'),
            ),
          ]),
        ]),
      ),
    );
  }
}
