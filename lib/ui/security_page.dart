import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../lock.dart';
import '../theme.dart';
import 'lock_screen.dart';
import '../l10n.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Lock.instance.refreshBiometricSupport();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !Lock.instance.isAuthenticatingBiometric) {
      Lock.instance.refreshBiometricSupport();
    }
  }

  Future<void> _toggle(BuildContext context, bool on) async {
    if (on) {
      final pin = await createPin(context);
      if (pin != null) {
        await Lock.instance.setPin(pin);
        await Lock.instance.refreshBiometricSupport();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('PIN lock enabled.'))),
          );
        }
      }
    } else if (await askPin(context, title: tr('Enter your PIN to turn it off'))) {
      await Lock.instance.disable();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('PIN lock disabled.'))),
        );
      }
    }
  }

  Future<void> _toggleBiometric(BuildContext context, bool on) async {
    final ok = await Lock.instance.setBiometric(
      on,
      localizedReason: tr('Verify your identity to enable Biometric Unlock'),
    );
    if (!context.mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(on ? 'Biometric unlock enabled.' : 'Biometric unlock disabled.')),
        ),
      );
    } else if (on) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('Biometric verification failed or canceled.')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<AppLockState>(
        valueListenable: Lock.instance.state,
        builder: (context, st, _) {
          final bioTitle = st.isFaceOnly
              ? tr('Face Unlock')
              : st.isFingerprintOnly
                  ? tr('Fingerprint Unlock')
                  : tr('Biometric Unlock');

          final bioSubtitle = !st.biometricAvailable
              ? tr('No fingerprint or face biometrics enrolled on this device.')
              : st.isFaceOnly
                  ? tr('Unlock the app quickly using Face Unlock alongside your PIN.')
                  : st.isFingerprintOnly
                      ? tr('Unlock the app quickly using your fingerprint alongside your PIN.')
                      : tr('Unlock without typing your PIN.');

          return Scaffold(
            body: SafeArea(
              child: ListView(padding: const EdgeInsets.all(20), children: [
                Row(children: [
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.arrowLeft)),
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
                      subtitle: Text(tr('PIN protects your medical data and automatically syncs across your devices.')),
                      value: st.enabled,
                      onChanged: (v) => _toggle(context, v),
                    ),
                    if (st.enabled) ...[
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(bioTitle),
                        subtitle: Text(bioSubtitle),
                        value: st.biometricEnabled,
                        onChanged: st.biometricAvailable
                            ? (v) => _toggleBiometric(context, v)
                            : null,
                      ),
                      const Divider(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(tr('Decoy Calculator Lock')),
                        subtitle: Text(tr('Disguise the lock screen as a functional calculator. Type your 6-digit PIN and press "=" to unlock.')),
                        value: st.decoyCalculator,
                        onChanged: (v) => Lock.instance.setDecoyCalculator(v),
                      ),
                      const Divider(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(tr('Privacy Shield')),
                        subtitle: Text(tr('Hides app preview in Recent Apps and blocks screenshots to protect medical privacy.')),
                        value: st.privacyShield,
                        onChanged: (v) => Lock.instance.setPrivacyShield(v),
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
                        icon: const Icon(LucideIcons.keyRound),
                        label: Text(tr('Change PIN')),
                      ),
                    ],
                  ]),
                ),
              ]),
            ),
          );
        },
      );
}
