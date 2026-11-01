import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n.dart';
import '../theme.dart';

/// Modal asisten pembuatan format alamat "Ambil Sendiri di Agen Ekspedisi" (Hold at Location).
/// Membantu pengguna memesan obat/perlengkapan mandiri secara aman tanpa paket terkirim ke alamat keluarga.
class PickupAssistantSheet extends StatefulWidget {
  const PickupAssistantSheet({super.key});

  @override
  State<PickupAssistantSheet> createState() => _PickupAssistantSheetState();
}

class _PickupAssistantSheetState extends State<PickupAssistantSheet> {
  String _selectedCarrier = 'J&T Express';
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _branchCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  final List<String> _carriers = [
    'J&T Express',
    'JNE Express',
    'SiCepat',
    'Pos Indonesia',
    'Other / Generic',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _branchCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  String _generateTemplate() {
    final name = _nameCtrl.text.trim().isEmpty ? tr('[Your Name / Alias]') : _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim().isEmpty ? tr('[Your Phone Number]') : _phoneCtrl.text.trim();
    final branch = _branchCtrl.text.trim().isEmpty ? tr('[Agent / Branch Name]') : _branchCtrl.text.trim();
    final address = _addressCtrl.text.trim().isEmpty ? tr('[Branch Street Address]') : _addressCtrl.text.trim();
    final city = _cityCtrl.text.trim().isEmpty ? tr('[City & Postal Code]') : _cityCtrl.text.trim();

    return '''
${tr('Recipient')}: $name
${tr('Phone')}: $phone
${tr('Shipping Address')}:
KANTOR AGEN $_selectedCarrier ($branch)
$address, $city
${tr('Note')}: MOHON DITAHAN DI KANTOR AGEN UNTUK DIAMBIL SENDIRI (HOLD AT LOCATION / PICKUP SENDIRI). JANGAN DIANTAR KE RUMAH.
'''.trim();
  }

  void _copyToClipboard() {
    final text = _generateTemplate();
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('Address template copied to clipboard!')),
        backgroundColor: C.peony,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? C.deepCard : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: dark ? Border.all(color: Colors.white.withValues(alpha: 0.12)) : null,
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        18,
        22,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            gap(14),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: C.peony.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.local_shipping_rounded, color: C.peony, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('Discreet Shipping & Pickup Assistant'), style: display(18)),
                      Text(
                        tr('Hold-at-agent delivery template for safe private pickup.'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
            gap(16),

            // Carrier Selector
            Text(
              tr('Select Courier / Expedition'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            gap(8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final c in _carriers)
                  ChoiceChip(
                    label: Text(c),
                    selected: _selectedCarrier == c,
                    onSelected: (_) => setState(() => _selectedCarrier = c),
                  ),
              ],
            ),
            gap(14),

            // Form inputs
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: tr('Recipient Name / Alias'),
                      hintText: tr('e.g. Olivia'),
                      filled: true,
                      fillColor: dark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: tr('Phone / WhatsApp'),
                      hintText: tr('08xxxxxxxxxx'),
                      filled: true,
                      fillColor: dark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ],
            ),
            gap(10),
            TextField(
              controller: _branchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: tr('Agent Office / Drop Point Name'),
                hintText: tr('e.g. Drop Point J&T Cabang Sudirman'),
                filled: true,
                fillColor: dark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            gap(10),
            TextField(
              controller: _addressCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: tr('Office Street Address'),
                hintText: tr('e.g. Jl. Jend. Sudirman No. 45'),
                filled: true,
                fillColor: dark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            gap(10),
            TextField(
              controller: _cityCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: tr('District & City'),
                hintText: tr('e.g. Kec. Menteng, Jakarta Pusat 10310'),
                filled: true,
                fillColor: dark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            gap(16),

            // Preview Box
            Text(
              tr('Generated Order Template:'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            gap(8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: dark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: C.peony.withValues(alpha: 0.25)),
              ),
              child: SelectableText(
                _generateTemplate(),
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  height: 1.4,
                ),
              ),
            ),
            gap(14),

            // Copy Action Button
            FilledButton.icon(
              onPressed: _copyToClipboard,
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: Text(
                tr('Copy Template to Clipboard'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: C.peony,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            gap(18),

            // Practical Safe Pickup Checklist
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: C.amber.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: C.amber.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: C.amber, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        tr('Safe Pickup Privacy Tips'),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ],
                  ),
                  gap(6),
                  Text(
                    tr('• Ask seller to describe package neutrally (e.g. "Health Vitamins / Supplement").\n• Track package until "Arrived at Drop Point", then go directly to pick it up with your tracking receipt & ID.'),
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
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
