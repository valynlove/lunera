import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../guides_data.dart';
import '../l10n.dart';
import '../models.dart';
import '../repo.dart';
import '../schedule.dart';
import '../theme.dart';
import 'article_page.dart';

/// Status kesiapan jaringan dan riwayat suntik untuk satu lokasi.
class SiteStatus {
  const SiteStatus({
    required this.site,
    this.lastUsed,
    this.daysSince,
    required this.isSuggested,
    required this.isResting,
  });

  final String site;
  final DateTime? lastUsed;
  final int? daysSince;
  final bool isSuggested;
  final bool isResting; // Disuntik <= 3 hari yang lalu

  Color get statusColor {
    if (isResting) return C.amber;
    return Pastel.mint;
  }

  String get statusText {
    if (daysSince == null) return tr('Ready • Never used');
    if (daysSince == 0) return tr('Resting • Injected today');
    if (daysSince == 1) return tr('Resting • Injected yesterday');
    if (isResting) return tr('Resting • {0} {0?day|days} ago', [daysSince!]);
    return tr('Ready • {0} {0?day|days} ago', [daysSince!]);
  }
}

/// Menghitung status untuk daftar lokasi suntik.
Map<String, SiteStatus> getSiteStatuses({
  required List<String> sites,
  required List<DoseLog> logsDesc,
  required Prefs prefs,
  String? therapyId,
  int restingThresholdDays = 4,
}) {
  final out = <String, SiteStatus>{};
  final suggested = therapyId != null ? suggestPlace(prefs, logsDesc, therapyId) : '';

  for (final site in sites) {
    // Cari log terakhir yang menggunakan lokasi ini
    final log = logsDesc.where((l) => !l.skipped && l.places.contains(site)).firstOrNull;
    final days = log == null ? null : daysBetween(log.at, DateTime.now());
    final isResting = days != null && days < restingThresholdDays;

    out[site] = SiteStatus(
      site: site,
      lastUsed: log?.at,
      daysSince: days,
      isSuggested: site == suggested,
      isResting: isResting,
    );
  }
  return out;
}

/// Peta Anatomi Lokasi Suntik & Visualisasi Rotasi Jaringan
class InjectionSiteMap extends StatefulWidget {
  const InjectionSiteMap({
    super.key,
    required this.selectedSites,
    this.onSiteToggled,
    this.therapyId,
    required this.logs,
    required this.prefs,
    this.readOnly = false,
  });

  final List<String> selectedSites;
  final ValueChanged<String>? onSiteToggled;
  final String? therapyId;
  final List<DoseLog> logs;
  final Prefs prefs;
  final bool readOnly;

  @override
  State<InjectionSiteMap> createState() => _InjectionSiteMapState();
}

class _InjectionSiteMapState extends State<InjectionSiteMap> {
  // 0: Front View (Arms, Abdomen, Thighs), 1: Back View (Buttocks / Glutes)
  int _view = 0;

  static const _frontSitesRight = ['Right arm', 'Right abdomen', 'Right thigh'];
  static const _frontSitesLeft = ['Left arm', 'Left abdomen', 'Left thigh'];

  @override
  Widget build(BuildContext context) {
    final allSites = [...placePresets, ...widget.prefs.places.where((p) => !placePresets.contains(p))];
    final statuses = getSiteStatuses(
      sites: allSites,
      logsDesc: widget.logs,
      prefs: widget.prefs,
      therapyId: widget.therapyId,
    );

    final restingCount = statuses.values.where((s) => s.isResting).length;
    final readyCount = statuses.values.where((s) => !s.isResting).length;
    final suggestedSite = statuses.values.where((s) => s.isSuggested).firstOrNull?.site;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // View Selector & Health Summary
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            PillTabs<int>(
              items: [
                (0, tr('Front')),
                (1, tr('Back (Glutes)')),
              ],
              value: _view,
              onChanged: (v) => setState(() => _view = v),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: C.deepCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Pastel.mint, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text('$readyCount ${tr('Ready')}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: C.amber, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text('$restingCount ${tr('Resting')}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
        gap(12),

        // Body Silhouette with Interactive Pods
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            color: C.midnight.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Pastel.lilac.withValues(alpha: 0.15)),
          ),
          child: _view == 0
              ? _buildFrontView(statuses)
              : _buildBackView(statuses),
        ),

        // Advice Banner
        gap(10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Pastel.lilac.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Pastel.lilac.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.sparkles, color: Pastel.lilac, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  suggestedSite != null
                      ? tr('Next suggested: {0}. Rotating sites prevents scar tissue and discomfort.', [tr(suggestedSite)])
                      : tr('Rotate your injection sites regularly to allow muscle and subcutaneous tissue to heal.'),
                  style: const TextStyle(fontSize: 12, color: Pastel.mist),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarView({required bool isFront}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Pastel.lilac.withValues(alpha: 0.14),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Image.asset(
          isFront ? 'assets/images/body_front.png' : 'assets/images/body_back.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) => const Icon(
            LucideIcons.user,
            color: Pastel.lilac,
            size: 42,
          ),
        ),
      ],
    );
  }

  Widget _buildFrontView(Map<String, SiteStatus> statuses) {
    return LayoutBuilder(builder: (context, constraints) {
      final totalWidth = constraints.maxWidth;
      const height = 310.0;
      final avatarWidth = (totalWidth * 0.34).clamp(96.0, 148.0);
      final podWidth = (totalWidth - avatarWidth - 8) / 2;

      return SizedBox(
        height: height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center Chibi Avatar (Front)
            Positioned(
              top: 0,
              bottom: 0,
              width: avatarWidth,
              child: _buildAvatarView(isFront: true),
            ),

            // Right-side Body Sites (Viewer's Left)
            Positioned(
              left: 0,
              top: 10,
              bottom: 10,
              width: podWidth,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final s in _frontSitesRight)
                    _SiteCard(
                      site: s,
                      status: statuses[s],
                      isSelected: widget.selectedSites.contains(s),
                      onTap: widget.readOnly ? null : () => widget.onSiteToggled?.call(s),
                      alignLeft: true,
                    ),
                ],
              ),
            ),

            // Left-side Body Sites (Viewer's Right)
            Positioned(
              right: 0,
              top: 10,
              bottom: 10,
              width: podWidth,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final s in _frontSitesLeft)
                    _SiteCard(
                      site: s,
                      status: statuses[s],
                      isSelected: widget.selectedSites.contains(s),
                      onTap: widget.readOnly ? null : () => widget.onSiteToggled?.call(s),
                      alignLeft: false,
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildBackView(Map<String, SiteStatus> statuses) {
    return LayoutBuilder(builder: (context, constraints) {
      final totalWidth = constraints.maxWidth;
      const height = 280.0;
      final avatarWidth = (totalWidth * 0.34).clamp(96.0, 148.0);
      final podWidth = (totalWidth - avatarWidth - 8) / 2;

      return SizedBox(
        height: height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center Chibi Avatar (Back)
            Positioned(
              top: 0,
              bottom: 0,
              width: avatarWidth,
              child: _buildAvatarView(isFront: false),
            ),

            // Right Buttock (Viewer's Left)
            Positioned(
              left: 0,
              top: 90,
              width: podWidth,
              child: _SiteCard(
                site: 'Right buttock',
                status: statuses['Right buttock'],
                isSelected: widget.selectedSites.contains('Right buttock'),
                onTap: widget.readOnly ? null : () => widget.onSiteToggled?.call('Right buttock'),
                alignLeft: true,
              ),
            ),

            // Left Buttock (Viewer's Right)
            Positioned(
              right: 0,
              top: 90,
              width: podWidth,
              child: _SiteCard(
                site: 'Left buttock',
                status: statuses['Left buttock'],
                isSelected: widget.selectedSites.contains('Left buttock'),
                onTap: widget.readOnly ? null : () => widget.onSiteToggled?.call('Left buttock'),
                alignLeft: false,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _SiteCard extends StatelessWidget {
  const _SiteCard({
    required this.site,
    this.status,
    required this.isSelected,
    this.onTap,
    required this.alignLeft,
  });

  final String site;
  final SiteStatus? status;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool alignLeft;

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;
    final stat = status ?? SiteStatus(site: site, isSuggested: false, isResting: false);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Pastel.lilac.withValues(alpha: 0.22)
                : (stat.isSuggested ? C.peony.withValues(alpha: 0.12) : C.deepCard.withValues(alpha: 0.9)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? Pastel.lilac
                  : (stat.isSuggested ? Pastel.lilac.withValues(alpha: 0.5) : Colors.white12),
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Pastel.lilac.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    const Icon(LucideIcons.circleCheckBig, color: Pastel.lilac, size: 14),
                    const SizedBox(width: 4),
                  ] else if (stat.isSuggested) ...[
                    const Icon(LucideIcons.star, color: Pastel.butter, size: 14),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      tr(site),
                      style: TextStyle(
                        fontWeight: isSelected || stat.isSuggested ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 12,
                        color: isSelected ? Colors.white : fg,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: stat.statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      stat.statusText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: stat.statusColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modal Sheet untuk melihat ringkasan rotasi dan kesehatan lokasi suntik
class SiteRotationSheet extends ConsumerWidget {
  const SiteRotationSheet({super.key, this.therapyId});
  final String? therapyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(prefsProvider).valueOrNull ?? const Prefs();
    final logs = ref.watch(logsProvider).valueOrNull ?? <DoseLog>[];

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  tr('Injection Site Rotation'),
                  style: display(22),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (guideById('site_rotation') case final guide?)
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ArticlePage(article: guide),
                      ),
                    );
                  },
                  icon: const Icon(LucideIcons.bookOpen, size: 20),
                  color: C.iconDefault,
                  tooltip: tr('Site Rotation Guide'),
                ),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x)),
            ],
          ),
          gap(14),
          InjectionSiteMap(
            selectedSites: const [],
            logs: logs,
            prefs: prefs,
            therapyId: therapyId,
            readOnly: true,
          ),
          gap(16),
          pillButton(tr('Done'), () => Navigator.pop(context)),
        ],
      ),
    );
  }
}
