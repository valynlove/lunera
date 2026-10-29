import 'package:flutter/material.dart';
import '../l10n.dart';
import '../lock.dart';
import '../theme.dart';
import 'lock_screen.dart';

class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  Future<void> _toggle(BuildContext context, bool on) async {
    if (on) {
      final pin = await createPin(context);
      if (pin != null) await Lock.instance.setPin(pin);
    } else if (await askPin(context, title: context.tr('Enter PIN to disable'))) {
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
                Expanded(child: Text(context.tr('Security'), style: display(32))),
              ]),
              gap(16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: cardBox(context),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(context.tr('App PIN Lock')),
                    subtitle: Text(context.tr('PIN protects your medical data and automatically syncs across your devices.')),
                    value: st.enabled,
                    onChanged: (v) => _toggle(context, v),
                  ),
                  if (st.enabled) ...[
                    gap(12),
                    Text(context.tr('Auto-lock timeout'), style: const TextStyle(fontWeight: FontWeight.w600)),
                    gap(8),
                    PillTabs<int>(
                      items: [
                        (0, context.tr('Immediately')),
                        (1, context.tr('1 minute')),
                        (5, context.tr('5 minutes')),
                      ],
                      value: st.delayMin,
                      onChanged: (m) => Lock.instance.setDelay(m),
                    ),
                    gap(16),
                    TextButton.icon(
                      onPressed: () async {
                        if (!await askPin(context, title: context.tr('Enter old PIN')) || !context.mounted) return;
                        final pin = await createPin(context);
                        if (pin != null) await Lock.instance.setPin(pin);
                      },
                      icon: const Icon(Icons.password_rounded),
                      label: Text(context.tr('Change PIN')),
                    ),
                  ],
                ]),
              ),
            ]),
          ),
        ),
      );
}
