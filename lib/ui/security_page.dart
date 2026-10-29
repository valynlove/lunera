import 'package:flutter/material.dart';
import '../lock.dart';
import '../theme.dart';
import 'lock_screen.dart';

class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  Future<void> _toggle(BuildContext context, bool on) async {
    if (on) {
      final pin = await createPin(context);
      if (pin != null) await Lock.instance.setPin(pin);
    } else if (await askPin(context, title: 'Masukkan PIN untuk mematikan')) {
      await Lock.instance.disable();
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<AppLockState>(
        valueListenable: Lock.instance.state,
        builder: (context, st, _) => Scaffold(
          body: SafeArea(
            child: ListView(padding: const EdgeInsets.all(20), children: [
              Row(children: [
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded)),
                Expanded(child: Text('Keamanan', style: display(32))),
              ]),
              gap(16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: cardBox(context),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Kunci dengan PIN'),
                    subtitle: const Text('PIN tersimpan hanya di perangkat ini.'),
                    value: st.enabled,
                    onChanged: (v) => _toggle(context, v),
                  ),
                  if (st.enabled) ...[
                    FutureBuilder<bool>(
                      future: Lock.instance.bioAvailable(),
                      builder: (c, snap) => SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Sidik jari atau wajah'),
                        subtitle: Text(snap.data == true ? 'Buka tanpa mengetik PIN.' : 'Tidak tersedia di perangkat ini.'),
                        value: st.bio,
                        onChanged: snap.data == true
                            ? (v) async {
                                if (!v || await Lock.instance.authBio()) await Lock.instance.setBio(v);
                              }
                            : null,
                      ),
                    ),
                    gap(8),
                    const Text('Kunci lagi setelah ditinggalkan'),
                    gap(8),
                    PillTabs<int>(
                      items: const [(0, 'Segera'), (1, '1 menit'), (5, '5 menit')],
                      value: st.delayMin,
                      onChanged: (m) => Lock.instance.setDelay(m),
                    ),
                    gap(8),
                    TextButton.icon(
                      onPressed: () async {
                        if (!await askPin(context, title: 'Masukkan PIN lama') || !context.mounted) return;
                        final pin = await createPin(context);
                        if (pin != null) await Lock.instance.setPin(pin);
                      },
                      icon: const Icon(Icons.password_rounded),
                      label: const Text('Ubah PIN'),
                    ),
                  ],
                ]),
              ),
            ]),
          ),
        ),
      );
}

