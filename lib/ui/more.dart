import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n.dart';
import '../models.dart';
import '../profile.dart';
import '../repo.dart';
import '../schedule.dart';
import '../theme.dart';
import 'body.dart';
import 'guided_injection.dart';
import 'insights.dart';
import 'pickup_assistant_sheet.dart';
import 'profile_page.dart';
import 'about_sheet.dart';
import 'settings_page.dart';
import 'site_map.dart';

/// Halaman pusat fitur (Feature Hub) Lunera: perjalanan tubuh, analitik kepatuhan,
/// peta rotasi jaringan suntik, panduan suntik mandiri, dan asisten ekspedisi privat.
class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    User? user;
    try {
      user = ref.watch(userProvider).valueOrNull ?? FirebaseAuth.instance.currentUser;
    } catch (_) {
      user = null;
    }
    final username = (user?.displayName?.isNotEmpty ?? false) ? user!.displayName! : null;
    final displayName = ref.watch(displayNameProvider);

    final therapies = ref.watch(therapiesProvider).valueOrNull ?? <Therapy>[];
    final supplies = ref.watch(suppliesProvider).valueOrNull ?? <Supply>[];
    final prefs = ref.watch(prefsProvider).valueOrNull ?? const Prefs();
    final logs = ref.watch(logsProvider).valueOrNull ?? <DoseLog>[];

    void openPage(Widget page) {
      HapticFeedback.selectionClick();
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
    }

    Widget tile({
      required IconData icon,
      required Color color,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
      Widget? trailing,
    }) {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: iconBadge(icon, color),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: Colors.white),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Pastel.mist.withValues(alpha: 0.85), height: 1.25),
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded, size: 20, color: Pastel.lilac),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
      );
    }

    void startGuidedInjection() {
      final injections = therapies.where((t) => t.route == 'inj').toList();
      if (injections.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('No injection therapies found. Add one in Home first.'))),
        );
        return;
      }

      if (injections.length == 1) {
        HapticFeedback.lightImpact();
        final t = injections.first;
        final suggested = suggestPlace(prefs, logs, t.id);
        showSheet(
          context,
          CalmInjectionSheet(
            t: t,
            supplies: supplies,
            prefs: prefs,
            suggestedPlace: suggested,
          ),
        );
      } else {
        HapticFeedback.selectionClick();
        showDialog<void>(
          context: context,
          builder: (d) => AlertDialog(
            title: Text(tr('Select Injection Therapy')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(tr('Choose which therapy you would like guidance for:')),
                const SizedBox(height: 12),
                for (final inj in injections)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: iconBadge(Icons.medication_rounded, Pastel.sky),
                    title: Text(inj.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${fmt(inj.dose)} ${inj.doseUnit}'),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(d);
                      final suggested = suggestPlace(prefs, logs, inj.id);
                      showSheet(
                        context,
                        CalmInjectionSheet(
                          t: inj,
                          supplies: supplies,
                          prefs: prefs,
                          suggestedPlace: suggested,
                        ),
                      );
                    },
                  ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(d), child: Text(tr('Cancel'))),
            ],
          ),
        );
      }
    }

    void openPickupAssistant() {
      HapticFeedback.lightImpact();
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const PickupAssistantSheet(),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      children: [
        Text(tr('More'), style: display(40)),
        gap(16),

        // 1. Header Profil Pengguna (Arcane Astral Hero Card)
        Container(
          margin: const EdgeInsets.only(top: 4, bottom: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF28205A),
                Color(0xFF1B1544),
              ],
            ),
            border: Border.all(
              color: const Color(0xFFD6B277).withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF070516).withValues(alpha: 0.55),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: C.peony.withValues(alpha: 0.15),
                blurRadius: 18,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.settings_outlined, size: 22),
                  color: Pastel.cream.withValues(alpha: 0.85),
                  tooltip: tr('Settings'),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    openPage(const SettingsPage());
                  },
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () {
                  HapticFeedback.lightImpact();
                  openPage(const ProfilePage());
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Avatar dengan glowing celestial frame halo
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: C.amber.withValues(alpha: 0.35),
                                blurRadius: 18,
                                spreadRadius: 2,
                              ),
                              BoxShadow(
                                color: C.peony.withValues(alpha: 0.25),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const UserAvatar(size: 80),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          displayName ?? appName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          username != null
                              ? '@$username'
                              : (user?.email != null ? user!.email! : tr('Lunera User')),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Pastel.lilac.withValues(alpha: 0.95),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 2. Health & Journey
        SectionHeader(title: tr('Health & Journey')),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              tile(
                icon: Icons.insights_rounded,
                color: Pastel.lilac,
                title: tr('Insights & Patterns'),
                subtitle: tr('Adherence trends and mood patterns'),
                onTap: () => openPage(const InsightsPage()),
              ),
              const Divider(height: 1, indent: 68),
              tile(
                icon: Icons.accessibility_new_rounded,
                color: Pastel.rose,
                title: tr('Body & Changes'),
                subtitle: tr('Timeline of physical milestones from your journal'),
                onTap: () => openPage(const BodyPage()),
              ),
              const Divider(height: 1, indent: 68),
              tile(
                icon: Icons.healing_rounded,
                color: Pastel.mint,
                title: tr('Site Rotation & Health'),
                subtitle: tr('Interactive body map & injection tissue resting tracker'),
                onTap: () => showSheet(context, const SiteRotationSheet()),
              ),
            ],
          ),
        ),

        // 3. Care & Assistant Tools
        SectionHeader(title: tr('Care & Assistant Tools')),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              tile(
                icon: Icons.self_improvement_rounded,
                color: Pastel.sky,
                title: tr('Guided Calm Injection'),
                subtitle: tr('Step-by-step calming procedure with breathing timer'),
                onTap: startGuidedInjection,
              ),
              const Divider(height: 1, indent: 68),
              tile(
                icon: Icons.local_shipping_outlined,
                color: Pastel.butter,
                title: tr('Discreet Pickup Assistant'),
                subtitle: tr('Format package for pickup at courier branch (Hold at Location)'),
                onTap: openPickupAssistant,
              ),
            ],
          ),
        ),

        // 4. System & Settings
        SectionHeader(title: tr('System')),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              tile(
                icon: Icons.tune_rounded,
                color: C.peony,
                title: tr('Settings'),
                subtitle: tr('Appearance, units, reminders, security & backup'),
                onTap: () => openPage(const SettingsPage()),
              ),
              const Divider(height: 1, indent: 68),
              tile(
                icon: Icons.info_outline_rounded,
                color: Pastel.lilac,
                title: tr('About {0}', [appName]),
                subtitle: tr('Version, mission, and medical disclaimer'),
                onTap: () => showAboutLuneraSheet(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
