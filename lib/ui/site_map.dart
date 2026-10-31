import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n.dart';
import '../models.dart';
import '../repo.dart';
import '../schedule.dart';
import '../theme.dart';

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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              const Icon(Icons.auto_awesome_rounded, color: Pastel.lilac, size: 18),
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

  Widget _buildFrontView(Map<String, SiteStatus> statuses) {
    return LayoutBuilder(builder: (context, constraints) {
      final totalWidth = constraints.maxWidth;
      const height = 310.0;
      final podWidth = (totalWidth - 90) / 2;

      return SizedBox(
        height: height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center Anatomical Silhouette
            Positioned(
              top: 0,
              bottom: 0,
              width: 80,
              child: CustomPaint(
                painter: _AnatomyPainter(isFront: true),
              ),
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
      final podWidth = (totalWidth - 90) / 2;

      return SizedBox(
        height: height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center Anatomical Silhouette (Back)
            Positioned(
              top: 0,
              bottom: 0,
              width: 80,
              child: CustomPaint(
                painter: _AnatomyPainter(isFront: false),
              ),
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
                    const Icon(Icons.check_circle_rounded, color: Pastel.lilac, size: 14),
                    const SizedBox(width: 4),
                  ] else if (stat.isSuggested) ...[
                    const Icon(Icons.star_rounded, color: Pastel.butter, size: 14),
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
                  Text(
                    stat.statusText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: stat.statusColor,
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

/// Menggambar siluet tubuh anatomi halus untuk panduan injeksi
class _AnatomyPainter extends CustomPainter {
  _AnatomyPainter({required this.isFront});
  final bool isFront;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    final fillPaint = Paint()
      ..color = Pastel.lilac.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Pastel.lilac.withValues(alpha: 0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    // Head
    canvas.drawCircle(Offset(cx, h * 0.08), h * 0.045, fillPaint);
    canvas.drawCircle(Offset(cx, h * 0.08), h * 0.045, strokePaint);

    // Neck
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, h * 0.13), width: w * 0.18, height: h * 0.04),
      fillPaint,
    );

    // Torso Path
    final body = Path();
    body.moveTo(cx - w * 0.45, h * 0.16); // Left shoulder
    body.lineTo(cx + w * 0.45, h * 0.16); // Right shoulder
    body.quadraticBezierTo(cx + w * 0.35, h * 0.32, cx + w * 0.30, h * 0.40); // Waist
    body.quadraticBezierTo(cx + w * 0.42, h * 0.48, cx + w * 0.38, h * 0.54); // Hip
    body.lineTo(cx - w * 0.38, h * 0.54); // Hip base
    body.quadraticBezierTo(cx - w * 0.42, h * 0.48, cx - w * 0.30, h * 0.40); // Waist
    body.quadraticBezierTo(cx - w * 0.35, h * 0.32, cx - w * 0.45, h * 0.16); // Shoulder
    body.close();

    canvas.drawPath(body, fillPaint);
    canvas.drawPath(body, strokePaint);

    // Arms
    final armStroke = Paint()
      ..color = Pastel.lilac.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.14;

    canvas.drawLine(Offset(cx - w * 0.48, h * 0.18), Offset(cx - w * 0.60, h * 0.42), armStroke);
    canvas.drawLine(Offset(cx + w * 0.48, h * 0.18), Offset(cx + w * 0.60, h * 0.42), armStroke);

    // Legs / Thighs
    final legStroke = Paint()
      ..color = Pastel.lilac.withValues(alpha: 0.26)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.22;

    canvas.drawLine(Offset(cx - w * 0.20, h * 0.56), Offset(cx - w * 0.18, h * 0.94), legStroke);
    canvas.drawLine(Offset(cx + w * 0.20, h * 0.56), Offset(cx + w * 0.18, h * 0.94), legStroke);

    // Target Injection Region Indicators
    final dotPaint = Paint()..color = Pastel.lilac;
    final ringPaint = Paint()
      ..color = Colors.white70
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    if (isFront) {
      // Deltoids (Arms)
      canvas.drawCircle(Offset(cx - w * 0.52, h * 0.25), 4, dotPaint);
      canvas.drawCircle(Offset(cx - w * 0.52, h * 0.25), 4, ringPaint);
      canvas.drawCircle(Offset(cx + w * 0.52, h * 0.25), 4, dotPaint);
      canvas.drawCircle(Offset(cx + w * 0.52, h * 0.25), 4, ringPaint);

      // Abdomen
      canvas.drawCircle(Offset(cx - w * 0.14, h * 0.42), 4, dotPaint);
      canvas.drawCircle(Offset(cx - w * 0.14, h * 0.42), 4, ringPaint);
      canvas.drawCircle(Offset(cx + w * 0.14, h * 0.42), 4, dotPaint);
      canvas.drawCircle(Offset(cx + w * 0.14, h * 0.42), 4, ringPaint);

      // Vastus Lateralis (Thighs)
      canvas.drawCircle(Offset(cx - w * 0.22, h * 0.68), 4, dotPaint);
      canvas.drawCircle(Offset(cx - w * 0.22, h * 0.68), 4, ringPaint);
      canvas.drawCircle(Offset(cx + w * 0.22, h * 0.68), 4, dotPaint);
      canvas.drawCircle(Offset(cx + w * 0.22, h * 0.68), 4, ringPaint);
    } else {
      // Gluteus / Buttocks (Dorsogluteal & Ventrogluteal)
      canvas.drawCircle(Offset(cx - w * 0.20, h * 0.48), 5, dotPaint);
      canvas.drawCircle(Offset(cx - w * 0.20, h * 0.48), 5, ringPaint);
      canvas.drawCircle(Offset(cx + w * 0.20, h * 0.48), 5, dotPaint);
      canvas.drawCircle(Offset(cx + w * 0.20, h * 0.48), 5, ringPaint);
    }
  }

  @override
  bool shouldRepaint(_AnatomyPainter oldDelegate) => oldDelegate.isFront != isFront;
}

/// Modal Sheet untuk melihat ringkasan rotasi dan kesehatan lokasi suntik
class SiteRotationSheet extends ConsumerWidget {
  const SiteRotationSheet({super.key, this.therapyId});
  final String? therapyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(prefsProvider).value ?? const Prefs();
    final logs = ref.watch(logsProvider).value ?? <DoseLog>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tr('Injection Site Rotation'), style: display(22)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
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
