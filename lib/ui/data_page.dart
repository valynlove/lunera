import 'dart:async';
import 'dart:convert';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../repo.dart';
import '../theme.dart';

class DataPage extends ConsumerStatefulWidget {
  const DataPage({super.key});
  @override
  ConsumerState<DataPage> createState() => _DataPageState();
}

class _DataPageState extends ConsumerState<DataPage> {
  bool busy = false;

  void _toast(String s) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  Future<void> _run(Future<void> Function() f) async {
    setState(() => busy = true);
    try {
      await f();
    } on FormatException catch (e) {
      _toast(e.message);
    } on TimeoutException {
      _toast('Belum ada koneksi. Perubahan akan terkirim saat kamu online.');
    } catch (e) {
      _toast('Gagal: $e');
    }
    if (mounted) setState(() => busy = false);
  }

  Future<String?> _ask(int n) => showDialog<String>(
        context: context,
        builder: (d) => AlertDialog(
          title: Text('Impor $n catatan'),
          content: const Text('Gabungkan: catatan dari file ditambahkan atau diperbarui, datamu sekarang tetap ada.\n\n'
              'Ganti semua: data sekarang dihapus dulu, lalu diisi dari file.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d), child: const Text('Batal')),
            TextButton(onPressed: () => Navigator.pop(d, 'merge'), child: const Text('Gabungkan')),
            FilledButton(onPressed: () => Navigator.pop(d, 'replace'), child: const Text('Ganti semua')),
          ],
        ),
      );

  Future<void> _importRaw(dynamic raw) async {
    final repo = ref.read(repoProvider);
    if (repo == null) return;
    final n = repo.validate(raw);
    final mode = await _ask(n);
    if (mode == null) return;
    await repo.importData(raw as Map, replace: mode == 'replace');
    _toast('Berhasil memulihkan $n catatan.');
  }

  Future<void> _exportFile() => _run(() async {
        final text = await ref.read(repoProvider)!.exportJson();
        final name = 'lunera_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}.json';
        final f = XFile.fromData(Uint8List.fromList(utf8.encode(text)), mimeType: 'application/json', name: name);
        if (kIsWeb) {
          await f.saveTo(name);
          _toast('File diunduh.');
        } else {
          await Share.shareXFiles([f], fileNameOverrides: [name]);
        }
      });

  Future<void> _importFile() => _run(() async {
        const group = XTypeGroup(label: 'JSON', extensions: ['json']);
        final onAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
        final f = await openFile(acceptedTypeGroups: onAndroid ? const [] : const [group]);
        if (f == null) return;
        await _importRaw(jsonDecode(utf8.decode(await f.readAsBytes())));
      });

  @override
  Widget build(BuildContext context) {
    final backups = ref.watch(backupsProvider).value ?? [];
    final fmtDate = DateFormat('d MMM y, HH:mm', 'id');
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Row(children: [
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)),
            Expanded(child: Text('Data', style: display(32))),
          ]),
          gap(12),
          _Panel(
            icon: Icons.wifi_off_rounded,
            tag: 'Offline',
            title: 'File di perangkat',
            body: 'Simpan semua datamu ke satu file JSON, atau pulihkan dari file. Tidak butuh internet.',
            actions: [
              pillButton('Ekspor', busy ? () {} : _exportFile, icon: Icons.file_upload_outlined),
              OutlinedButton.icon(onPressed: busy ? null : _importFile, icon: const Icon(Icons.file_download_outlined), label: const Text('Impor')),
            ],
          ),
          gap(14),
          _Panel(
            icon: Icons.cloud_done_rounded,
            tag: 'Online',
            title: 'Cadangan awan',
            body: 'Simpan salinan datamu di akun Firebase-mu. Berguna untuk kembali ke kondisi sebelumnya.',
            actions: [
              pillButton('Cadangkan sekarang', busy ? () {} : () => _run(() async {
                    await ref.read(repoProvider)!.saveBackup();
                    _toast('Cadangan tersimpan.');
                  }), icon: Icons.cloud_upload_rounded, color: C.lagoon),
            ],
          ),
          gap(8),
          for (final b in backups)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: Text(fmtDate.format(b.at), style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${b.count} catatan, ${(b.bytes / 1024).ceil()} KB'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  tooltip: 'Pulihkan',
                  onPressed: busy ? null : () => _run(() async => _importRaw(await ref.read(repoProvider)!.backupJson(b.id))),
                  icon: const Icon(Icons.settings_backup_restore_rounded),
                ),
                IconButton(
                  tooltip: 'Hapus',
                  onPressed: busy ? null : () => _run(() => ref.read(repoProvider)!.deleteBackup(b.id)),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ]),
            ),
        ]),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.icon, required this.tag, required this.title, required this.body, required this.actions});
  final IconData icon;
  final String tag, title, body;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(32)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(title, style: display(24))),
          Chip(avatar: Icon(icon, size: 16), label: Text(tag), side: BorderSide.none, backgroundColor: fg.withValues(alpha: .07)),
        ]),
        gap(10),
        Text(body),
        gap(16),
        Wrap(spacing: 10, runSpacing: 8, children: actions),
      ]),
    );
  }
}
