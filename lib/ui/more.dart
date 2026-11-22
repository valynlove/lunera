import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n.dart';
import '../models.dart';
import '../profile.dart';
import '../repo.dart';
import '../schedule.dart';
import '../theme.dart';
import 'body.dart';
import 'guided_injection.dart';
import 'guides_page.dart';
import 'insights.dart';
import 'pickup_assistant_sheet.dart';
import 'profile_page.dart';
import 'about_sheet.dart';
import 'sanctuary/sanctuary_page.dart';
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
      user = ref.watch(userProvider).valueOrNull ??
          FirebaseAuth.instance.currentUser;
    } catch (_) {
      user = null;
    }
    final username =
        (user?.displayName?.isNotEmpty ?? false) ? user!.displayName! : null;
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
          style: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 14.5, color: Colors.white),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
              fontSize: 12,
              color: Pastel.mist.withValues(alpha: 0.85),
              height: 1.25),
        ),
        trailing: trailing ??
            const Icon(LucideIcons.chevronRight,
                size: 18, color: C.iconDefault),
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
          SnackBar(
              content: Text(
                  tr('No injection therapies found. Add one in Home first.'))),
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
                    leading: iconBadge(LucideIcons.pill, Pastel.sky),
                    title: Text(inj.name,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
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
              TextButton(
                  onPressed: () => Navigator.pop(d), child: Text(tr('Cancel'))),
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

    void openProfile() {
      HapticFeedback.lightImpact();
      Navigator.of(context).push(
        PageRouteBuilder<void>(
          pageBuilder: (context, _, __) => const ProfilePage(enableHero: false),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }

    final takenLogs = logs.where((l) => !l.skipped).toList();
    final starts = [
      ...takenLogs.map((l) => l.at),
      ...therapies.map((t) => t.start),
    ]..sort();
    final journeyLabel = starts.isEmpty
        ? '—'
        : '${daysBetween(starts.first, DateTime.now()).clamp(0, 99999)}d';
    final since30 = DateTime.now().subtract(const Duration(days: 30));
    final scheduledIds = {
      for (final t in therapies)
        if (!t.asNeeded) t.id,
    };
    final taken30 = takenLogs
        .where(
            (l) => l.at.isAfter(since30) && scheduledIds.contains(l.therapyId))
        .length;
    final skipped30 =
        logs.where((l) => l.skipped && l.at.isAfter(since30)).length;
    final missed30 = buildSlots(therapies, logs, prefs, back: 30, ahead: 0)
        .where((s) => s.status == 'overdue')
        .length;
    final total30 = taken30 + skipped30 + missed30;
    final adherenceLabel =
        total30 == 0 ? '—' : '${(taken30 * 100 / total30).round()}%';

    Widget profileStat(String value, String label) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: C.lavender.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      children: [
        Text(tr('More'), style: display(40)),
        gap(16),

        // 1. User Profile Hero Card (Eternal Dusk Glassmorphic Membership Card)
        Container(
          margin: const EdgeInsets.only(top: 4, bottom: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: C.lavender.withValues(alpha: 0.42),
              width: 1.25,
            ),
            boxShadow: [
              BoxShadow(
                color: C.voidBg.withValues(alpha: 0.55),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: C.aurora.withValues(alpha: 0.22),
                blurRadius: 20,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(27),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/profile_banner_dusk.jpg',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            C.nebula.withValues(alpha: 0.94),
                            C.midnight.withValues(alpha: 0.98),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          C.voidBg.withValues(alpha: 0.48),
                          C.midnight.withValues(alpha: 0.72),
                          C.voidBg.withValues(alpha: 0.62),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.center,
                        colors: [
                          Colors.white.withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(27),
                    onTap: openProfile,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Top Header Row
                          LayoutBuilder(
                            builder: (context, constraints) => Row(
                              children: [
                                const Icon(
                                  LucideIcons.moonStar,
                                  size: 15,
                                  color: C.lavender,
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  appName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: C.mist,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          C.lavender.withValues(alpha: 0.38),
                                          C.lavender.withValues(alpha: 0.08),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: constraints.maxWidth * 0.58,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: C.midnight.withValues(alpha: 0.48),
                                      border: Border.all(
                                        color:
                                            C.lavender.withValues(alpha: 0.4),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          LucideIcons.pencil,
                                          size: 12,
                                          color: C.mist,
                                        ),
                                        const SizedBox(width: 5),
                                        Flexible(
                                          child: Text(
                                            tr('Edit Profile'),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Middle Horizontal Profile Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3.5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: C.lavender.withValues(alpha: 0.72),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: C.aurora.withValues(alpha: 0.42),
                                      blurRadius: 18,
                                      spreadRadius: 1,
                                    ),
                                    BoxShadow(
                                      color: C.rose.withValues(alpha: 0.24),
                                      blurRadius: 22,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const UserAvatar(size: 72),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      displayName ?? appName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          username == null &&
                                                  user?.email != null
                                              ? LucideIcons.mail
                                              : LucideIcons.user,
                                          size: 13,
                                          color:
                                              C.lavender.withValues(alpha: 0.9),
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            username != null
                                                ? '@$username'
                                                : (user?.email != null
                                                    ? user!.email!
                                                    : tr('Lunera User')),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: C.mist
                                                  .withValues(alpha: 0.88),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: C.nebula.withValues(alpha: 0.55),
                                        border: Border.all(
                                          color: C.lavender
                                              .withValues(alpha: 0.35),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            user != null
                                                ? LucideIcons.shieldCheck
                                                : LucideIcons.shield,
                                            size: 13,
                                            color: user != null
                                                ? Pastel.mint
                                                : C.lavender,
                                          ),
                                          const SizedBox(width: 5),
                                          Flexible(
                                            child: Text(
                                              user != null
                                                  ? tr('Cloud Synced')
                                                  : tr('Local Account'),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Ornamental Divider
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        C.lavender.withValues(alpha: 0.35),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Icon(
                                  LucideIcons.sparkles,
                                  size: 12,
                                  color: C.lavender.withValues(alpha: 0.85),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        C.lavender.withValues(alpha: 0.35),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Mini Stats Strip
                          Row(
                            children: [
                              profileStat(journeyLabel, tr('Journey')),
                              Container(
                                width: 1,
                                height: 22,
                                color: C.lavender.withValues(alpha: 0.22),
                              ),
                              profileStat(
                                '${therapies.length}',
                                tr('Therapies'),
                              ),
                              Container(
                                width: 1,
                                height: 22,
                                color: C.lavender.withValues(alpha: 0.22),
                              ),
                              profileStat(
                                '${takenLogs.length}',
                                tr('Doses'),
                              ),
                              Container(
                                width: 1,
                                height: 22,
                                color: C.lavender.withValues(alpha: 0.22),
                              ),
                              profileStat(adherenceLabel, tr('Adherence')),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Tagline
                          Text(
                            tr(tagline),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontStyle: FontStyle.italic,
                              color: C.mist.withValues(alpha: 0.82),
                              letterSpacing: 0.3,
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
        ),

        // 2. Health & Journey
        SectionHeader(title: tr('Health & Journey')),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              tile(
                icon: LucideIcons.activity,
                color: Pastel.lilac,
                title: tr('Insights & Patterns'),
                subtitle: tr('Adherence trends and mood patterns'),
                onTap: () => openPage(const InsightsPage()),
              ),
              const Divider(height: 1, indent: 68),
              tile(
                icon: LucideIcons.accessibility,
                color: Pastel.rose,
                title: tr('Body & Changes'),
                subtitle:
                    tr('Timeline of physical milestones from your journal'),
                onTap: () => openPage(const BodyPage()),
              ),
              const Divider(height: 1, indent: 68),
              tile(
                icon: LucideIcons.bandage,
                color: Pastel.mint,
                title: tr('Site Rotation & Health'),
                subtitle: tr(
                    'Interactive body map & injection tissue resting tracker'),
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
                icon: LucideIcons.bookOpen,
                color: C.lavender,
                title: tr('Care & HRT Guides'),
                subtitle:
                    tr('Evidence-informed articles, dosing math & safety tips'),
                onTap: () => openPage(const GuidesPage()),
              ),
              const Divider(height: 1, indent: 68),
              tile(
                icon: LucideIcons.sparkles,
                color: C.magenta,
                title: tr('Twilight Sanctuary'),
                subtitle:
                    tr('Calming ripples, safety practice & moonlight lantern'),
                onTap: () => openPage(const SanctuaryPage()),
              ),
              const Divider(height: 1, indent: 68),
              tile(
                icon: LucideIcons.heartPulse,
                color: Pastel.sky,
                title: tr('Guided Calm Injection'),
                subtitle:
                    tr('Step-by-step calming procedure with breathing timer'),
                onTap: startGuidedInjection,
              ),
              const Divider(height: 1, indent: 68),
              tile(
                icon: LucideIcons.truck,
                color: Pastel.butter,
                title: tr('Discreet Pickup Assistant'),
                subtitle: tr(
                    'Format package for pickup at courier branch (Hold at Location)'),
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
                icon: LucideIcons.slidersHorizontal,
                color: C.peony,
                title: tr('Settings'),
                subtitle: tr('Appearance, units, reminders, security & backup'),
                onTap: () => openPage(const SettingsPage()),
              ),
              const Divider(height: 1, indent: 68),
              tile(
                icon: LucideIcons.info,
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
