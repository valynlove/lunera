import 'package:flutter/material.dart';
import '../lock.dart';
import '../theme.dart';
import 'lock_screen.dart';
import '../l10n.dart';

class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  Future<void> _toggle(BuildContext context, bool on) async {
    if (on) {
      final pin = await createPin(context);
      if (pin != null) await Lock.instance.setPin(pin);
    } else if (await askPin(context, title: tr('Enter your PIN to turn it off'))) {
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
                Expanded(child: Text(tr('Security'), style: display(32))),
              ]),
              gap(16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: cardBox(context),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(tr('Lock with PIN')),
                    subtitle: Text(tr('Your PIN is stored only on this device.')),
                    value: st.enabled,
                    onChanged: (v) => _toggle(context, v),
                  ),
                  if (st.enabled) ...[
                    FutureBuilder<bool>(
                      future: Lock.instance.bioAvailable(),
                      builder: (c, snap) => SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(tr('Fingerprint or face')),
                        subtitle: Text(snap.data == true ? tr('Unlock without typing your PIN.') : tr('Not available on this device.')),
                        value: st.bio,
                        onChanged: snap.data == true
                            ? (v) async {
                                if (!v || await Lock.instance.authBio()) await Lock.instance.setBio(v);
                              }
                            : null,
                      ),
                    ),
                    const Divider(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(tr('Decoy Calculator Lock')),
                      subtitle: Text(tr('Disguise the lock screen as a functional calculator. Type your 6-digit PIN and press "=" to unlock.')),
                      value: st.decoyCalculator,
                      onChanged: (v) => Lock.instance.setDecoyCalculator(v),
                    ),
                    gap(8),
                    Text(tr('Lock again after leaving the app')),
                    gap(8),
                    PillTabs<int>(
                      items: [(0, tr('Immediately')), (1, tr('1 minute')), (5, tr('5 minutes'))],
                      value: st.delayMin,
                      onChanged: (m) => Lock.instance.setDelay(m),
                    ),
                    gap(8),
                    TextButton.icon(
                      onPressed: () async {
                        if (!await askPin(context, title: tr('Enter your current PIN')) || !context.mounted) return;
                        final pin = await createPin(context);
                        if (pin != null) await Lock.instance.setPin(pin);
                      },
                      icon: const Icon(Icons.password_rounded),
                      label: Text(tr('Change PIN')),
                    ),
                  ],
                ]),
              ),
            ]),
          ),
        ),
      );
}
