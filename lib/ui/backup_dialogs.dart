import 'package:flutter/material.dart';
import '../l10n.dart';
import '../theme.dart';

/// Memilih mode ekspor (JSON biasa atau terenkripsi dengan kata sandi).
Future<({bool encrypt, String passphrase})?> askExportMode(
    BuildContext context) {
  return showDialog<({bool encrypt, String passphrase})>(
    context: context,
    builder: (_) => const _ExportModeDialog(),
  );
}

/// Meminta kata sandi untuk mendekripsi berkas cadangan terenkripsi.
Future<String?> askImportPassphrase(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (_) => const _ImportPassphraseDialog(),
  );
}

class _ExportModeDialog extends StatefulWidget {
  const _ExportModeDialog();

  @override
  State<_ExportModeDialog> createState() => _ExportModeDialogState();
}

class _ExportModeDialogState extends State<_ExportModeDialog> {
  bool _encrypt = false;
  String? _error;
  final _pass1 = TextEditingController();
  final _pass2 = TextEditingController();

  @override
  void dispose() {
    _pass1.dispose();
    _pass2.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_encrypt) {
      Navigator.pop(context, (encrypt: false, passphrase: ''));
      return;
    }
    final p1 = _pass1.text;
    final p2 = _pass2.text;
    if (p1.length < 8) {
      setState(() => _error = tr('Use at least 8 characters.'));
      return;
    }
    if (p1 != p2) {
      setState(() => _error = tr('Passphrases do not match.'));
      return;
    }
    Navigator.pop(context, (encrypt: true, passphrase: p1));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(tr('Export backup')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ChoiceChip(
                  label: Text(tr('Plain JSON')),
                  selected: !_encrypt,
                  onSelected: (_) => setState(() {
                    _encrypt = false;
                    _error = null;
                  }),
                ),
                ChoiceChip(
                  label: Text(tr('Encrypted with passphrase')),
                  selected: _encrypt,
                  onSelected: (_) => setState(() {
                    _encrypt = true;
                    _error = null;
                  }),
                ),
              ],
            ),
            if (_encrypt) ...[
              gap(12),
              TextField(
                controller: _pass1,
                obscureText: true,
                decoration: InputDecoration(labelText: tr('Passphrase')),
              ),
              gap(8),
              TextField(
                controller: _pass2,
                obscureText: true,
                decoration: InputDecoration(labelText: tr('Confirm passphrase')),
              ),
              gap(8),
              Text(
                tr('If you forget this passphrase, the backup cannot be recovered.'),
                style: TextStyle(
                  fontSize: 12,
                  color: Pastel.mist.withValues(alpha: 0.85),
                ),
              ),
              if (_error != null) ...[
                gap(6),
                Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Pastel.rose,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr('Cancel')),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(tr('Export')),
        ),
      ],
    );
  }
}

class _ImportPassphraseDialog extends StatefulWidget {
  const _ImportPassphraseDialog();

  @override
  State<_ImportPassphraseDialog> createState() =>
      _ImportPassphraseDialogState();
}

class _ImportPassphraseDialogState extends State<_ImportPassphraseDialog> {
  final _pass = TextEditingController();

  @override
  void dispose() {
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(tr('Encrypted backup')),
      content: TextField(
        controller: _pass,
        obscureText: true,
        autofocus: true,
        decoration: InputDecoration(labelText: tr('Passphrase')),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr('Cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _pass.text),
          child: Text(tr('Unlock')),
        ),
      ],
    );
  }
}
