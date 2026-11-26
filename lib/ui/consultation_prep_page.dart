import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../consultation_prep.dart';
import '../doctor_report.dart';
import '../l10n.dart';
import '../lock.dart';
import '../models.dart';
import '../repo.dart';
import '../theme.dart';
import 'care_card_sheet.dart';
import 'responsive.dart';

/// Halaman persiapan konsultasi dokter pintar (Smart Consultation Prep).
/// Mengelompokkan gejala jurnal berulang, mengkorelasikan dengan ritme dosis,
/// dan menyediakan lembar persiapan kunjungan medis terpadu dengan ekspor laporan klinis.
class ConsultationPrepPage extends ConsumerStatefulWidget {
  const ConsultationPrepPage({super.key});

  @override
  ConsumerState<ConsultationPrepPage> createState() =>
      _ConsultationPrepPageState();
}

class _ConsultationPrepPageState extends ConsumerState<ConsultationPrepPage> {
  final _doctorController = TextEditingController();
  final _questionController = TextEditingController();
  final _notesController = TextEditingController();
  final _customChecklistController = TextEditingController();

  bool _isInit = false;

  @override
  void dispose() {
    _doctorController.dispose();
    _questionController.dispose();
    _notesController.dispose();
    _customChecklistController.dispose();
    super.dispose();
  }

  void _syncControllers(ConsultationSession session) {
    if (!_isInit) {
      _doctorController.text = session.doctorOrClinic;
      _notesController.text = session.postVisitNotes;
      _isInit = true;
    }
  }

  Future<void> _pickDate(ConsultationSession session) async {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    final initial = session.scheduledAt ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: C.lavender,
            onPrimary: C.midnight,
            surface: C.deepCard,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      ref.read(consultationProvider.notifier).updateScheduledAt(picked);
    }
  }

  Future<void> _exportReport(ConsultationSession session) async {
    HapticFeedback.lightImpact();
    final format = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(tr('Export Doctor Report')),
        content: Text(tr(
            'Export clinical summary and include your prepared consultation questions.')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d), child: Text(tr('Cancel'))),
          TextButton(
              onPressed: () => Navigator.pop(d, 'md'),
              child: Text(tr('Text / Markdown'))),
          FilledButton(
              onPressed: () => Navigator.pop(d, 'pdf'),
              child: Text(tr('PDF Document'))),
        ],
      ),
    );
    if (format == null || !mounted) return;

    final ths = ref.read(therapiesProvider).valueOrNull ?? const [];
    final logs = ref.read(logsProvider).valueOrNull ?? const [];
    final labs = ref.read(labsProvider).valueOrNull ?? const [];
    final targets = ref.read(targetsProvider).valueOrNull ?? const {};
    final prefs = ref.read(prefsProvider).valueOrNull ?? const Prefs();
    final journal = ref.read(journalProvider).valueOrNull ?? const [];
    final now = DateTime.now();

    final questionsText = session.questions.map((q) => q.text).toList();

    try {
      if (format == 'pdf') {
        final bytes = await buildDoctorReportPdf(
          therapies: ths,
          logs: logs,
          labs: labs,
          targets: targets,
          prefs: prefs,
          now: now,
          journal: journal,
          consultationQuestions: questionsText,
        );
        final stamp = DateFormat('yyyy-MM-dd_HH-mm').format(now);
        final name = 'lunera_consultation_summary_$stamp.pdf';
        final f = XFile.fromData(bytes, mimeType: 'application/pdf', name: name);
        if (kIsWeb) {
          await f.saveTo(name);
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(tr('File downloaded.'))));
          }
        } else {
          await Lock.instance.suppressLockDuring(
            () => Share.shareXFiles(
              [f],
              fileNameOverrides: [name],
              subject: tr('Lunera Consultation & Clinical Summary'),
            ),
          );
        }
        return;
      }

      final text = buildDoctorReport(
        therapies: ths,
        logs: logs,
        labs: labs,
        targets: targets,
        prefs: prefs,
        now: now,
        journal: journal,
        consultationQuestions: questionsText,
      );
      final stamp = DateFormat('yyyy-MM-dd_HH-mm').format(now);
      final name = 'lunera_consultation_summary_$stamp.md';
      final f = XFile.fromData(Uint8List.fromList(text.codeUnits),
          mimeType: 'text/markdown', name: name);
      if (kIsWeb) {
        await f.saveTo(name);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(tr('File downloaded.'))));
        }
      } else {
        await Lock.instance.suppressLockDuring(
          () => Share.shareXFiles(
            [f],
            fileNameOverrides: [name],
            subject: tr('Lunera Consultation & Clinical Summary'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Failed to export: {0}', [e.toString()]))),
        );
      }
    }
  }

  void _copyQuestions(ConsultationSession session) {
    if (session.questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('No questions prepared yet.'))),
      );
      return;
    }
    HapticFeedback.lightImpact();
    final buf = StringBuffer();
    if (session.doctorOrClinic.isNotEmpty) {
      buf.writeln('Consultation: ${session.doctorOrClinic}');
    }
    if (session.scheduledAt != null) {
      buf.writeln(
          'Date: ${DateFormat('d MMMM y', L10n.code).format(session.scheduledAt!)}');
    }
    buf.writeln('\nQuestions & Discussion Points:');
    for (var i = 0; i < session.questions.length; i++) {
      final q = session.questions[i];
      final mark = q.isAsked ? '[x]' : '[ ]';
      buf.writeln('$mark ${i + 1}. ${q.text}');
    }
    Clipboard.setData(ClipboardData(text: buf.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('Questions copied to clipboard.'))),
    );
  }

  void _confirmReset() {
    HapticFeedback.selectionClick();
    showDialog<void>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(tr('Reset Consultation Prep?')),
        content: Text(tr(
            'This will clear current questions and notes for a fresh consultation appointment.')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d), child: Text(tr('Cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: C.coral),
            onPressed: () {
              Navigator.pop(d);
              ref.read(consultationProvider.notifier).resetSession();
              _doctorController.clear();
              _notesController.clear();
              _isInit = false;
            },
            child: Text(tr('Reset')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(consultationProvider);
    _syncControllers(session);

    final journal = ref.watch(journalProvider).valueOrNull ?? const [];
    final logs = ref.watch(logsProvider).valueOrNull ?? const [];
    final ths = ref.watch(therapiesProvider).valueOrNull ?? const [];
    final clusters = clusterJournalSymptoms(
      journal: journal,
      logs: logs,
      therapies: ths,
    );

    final df = DateFormat('EEE, d MMM y', L10n.code);
    final checkedCount = session.checklist.where((c) => c.isChecked).length;
    final totalChecklist = session.checklist.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Smart Consultation Prep'),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        actions: [
          IconButton(
            tooltip: tr('Quick Clinic Care Card'),
            icon: const Icon(LucideIcons.heartPulse, size: 20),
            onPressed: () {
              HapticFeedback.selectionClick();
              showSheet(context, const CareCardSheet());
            },
          ),
          IconButton(
            tooltip: tr('Copy Questions'),
            icon: const Icon(LucideIcons.copy, size: 20),
            onPressed: () => _copyQuestions(session),
          ),
          IconButton(
            tooltip: tr('Reset Session'),
            icon: const Icon(LucideIcons.rotateCcw, size: 20),
            onPressed: _confirmReset,
          ),
        ],
      ),
      body: AdaptivePageFrame(
        maxWidth: 960,
        child: ListView(
          padding: context.pagePadding(top: 8, bottom: 48),
          children: [
          // 1. Appointment Overview Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    iconBadge(LucideIcons.stethoscope, Pastel.sky),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('Clinical Appointment'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            tr('Prepare topics, check-ins, and questions'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Pastel.mist.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilterChip(
                      selected: session.isCompleted,
                      label: Text(
                        session.isCompleted
                            ? tr('Completed')
                            : tr('Upcoming'),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: session.isCompleted
                              ? Pastel.mint
                              : C.lavender,
                        ),
                      ),
                      backgroundColor: C.surface,
                      selectedColor: Pastel.mint.withValues(alpha: 0.2),
                      side: BorderSide(
                        color: session.isCompleted
                            ? Pastel.mint.withValues(alpha: 0.5)
                            : C.lavender.withValues(alpha: 0.4),
                      ),
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        ref
                            .read(consultationProvider.notifier)
                            .toggleCompleted();
                      },
                    ),
                  ],
                ),
                gap(16),
                TextField(
                  controller: _doctorController,
                  decoration: InputDecoration(
                    labelText: tr('Doctor or Clinic Name'),
                    hintText: tr('e.g. Dr. Emily Thorne (Endocrinology)'),
                    prefixIcon: const Icon(LucideIcons.userCheck,
                        size: 18, color: C.iconDefault),
                    isDense: true,
                  ),
                  onChanged: (val) => ref
                      .read(consultationProvider.notifier)
                      .updateDoctorOrClinic(val),
                ),
                gap(12),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _pickDate(session),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: C.surface,
                      border: Border.all(
                        color: C.lavender.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.calendarDays,
                            size: 18, color: Pastel.sky),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            session.scheduledAt != null
                                ? df.format(session.scheduledAt!)
                                : tr('Tap to set consultation date'),
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: session.scheduledAt != null
                                  ? Colors.white
                                  : C.mist,
                            ),
                          ),
                        ),
                        if (session.scheduledAt != null)
                          IconButton(
                            icon: const Icon(LucideIcons.x, size: 16),
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              ref
                                  .read(consultationProvider.notifier)
                                  .updateScheduledAt(null);
                            },
                          )
                        else
                          const Icon(LucideIcons.chevronRight,
                              size: 16, color: C.iconDefault),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          gap(20),

          // 2. Symptom Clustering Card (from Journal)
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr('Observed Symptom Patterns'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: C.lavender,
                      ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Pastel.sky.withValues(alpha: 0.16),
                    border: Border.all(
                        color: Pastel.sky.withValues(alpha: 0.35), width: 1),
                  ),
                  child: Text(
                    tr('{0} patterns', [clusters.length]),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Pastel.sky,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (clusters.isEmpty)
            AppCard(
              child: Row(
                children: [
                  iconBadge(LucideIcons.info, Pastel.lilac),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tr('No recurring symptoms found in recent journal logs. Continue logging symptoms in your daily journal to detect cycle correlations.'),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Pastel.mist.withValues(alpha: 0.9),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...clusters.map((cluster) {
              final isAlreadyAdded = session.questions.any(
                (q) => q.symptomKey == cluster.symptomKey,
              );
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: C.surface,
                  border: Border.all(
                    color: C.lavender.withValues(alpha: 0.22),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        iconBadge(cluster.icon, Pastel.sky),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cluster.symptomName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                cluster.cycleCorrelation != null
                                    ? '${cluster.count}x • ${cluster.cycleCorrelation}'
                                    : tr('{0} entries in last 90 days',
                                        [cluster.count]),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: cluster.cycleCorrelation != null
                                      ? Pastel.mint
                                      : Pastel.mist.withValues(alpha: 0.85),
                                  fontWeight: cluster.cycleCorrelation != null
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor:
                                isAlreadyAdded ? Pastel.mint : Pastel.sky,
                          ),
                          icon: Icon(
                            isAlreadyAdded
                                ? LucideIcons.check
                                : LucideIcons.plus,
                            size: 15,
                          ),
                          label: Text(
                            isAlreadyAdded
                                ? tr('Added')
                                : tr('Add to Questions'),
                            style: const TextStyle(fontSize: 11.5),
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            if (!isAlreadyAdded) {
                              ref
                                  .read(consultationProvider.notifier)
                                  .addQuestion(
                                    cluster.suggestedQuestion,
                                    symptomKey: cluster.symptomKey,
                                  );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: C.midnight.withValues(alpha: 0.45),
                      ),
                      child: Text(
                        '"${cluster.suggestedQuestion}"',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          color: Pastel.mist.withValues(alpha: 0.95),
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          gap(16),

          // 3. Questions & Discussion Topics
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr('Questions & Discussion Points'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: C.lavender,
                      ),
                ),
                Text(
                  '${session.questions.where((q) => q.isAsked).length}/${session.questions.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: C.lavender.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (session.questions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      tr('No questions prepared yet. Use suggested topics below or write your own.'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Pastel.mist.withValues(alpha: 0.8),
                      ),
                    ),
                  )
                else
                  for (final q in session.questions)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: q.isAsked,
                            activeColor: Pastel.mint,
                            visualDensity: VisualDensity.compact,
                            onChanged: (_) {
                              HapticFeedback.selectionClick();
                              ref
                                  .read(consultationProvider.notifier)
                                  .toggleQuestion(q.id);
                            },
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                q.text,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  decoration: q.isAsked
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: q.isAsked
                                      ? C.mist.withValues(alpha: 0.6)
                                      : Colors.white,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.trash2,
                                size: 16, color: C.iconDefault),
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              ref
                                  .read(consultationProvider.notifier)
                                  .removeQuestion(q.id);
                            },
                          ),
                        ],
                      ),
                    ),
                gap(10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _questionController,
                        decoration: InputDecoration(
                          hintText: tr('Add question for clinician...'),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty) {
                            HapticFeedback.lightImpact();
                            ref
                                .read(consultationProvider.notifier)
                                .addQuestion(val);
                            _questionController.clear();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: C.lavender,
                        foregroundColor: C.midnight,
                      ),
                      icon: const Icon(LucideIcons.plus, size: 18),
                      onPressed: () {
                        final text = _questionController.text;
                        if (text.trim().isNotEmpty) {
                          HapticFeedback.lightImpact();
                          ref
                              .read(consultationProvider.notifier)
                              .addQuestion(text);
                          _questionController.clear();
                        }
                      },
                    ),
                  ],
                ),
                gap(12),
                Text(
                  tr('Quick Suggested Topics:'),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: C.mist,
                  ),
                ),
                gap(8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final topic in defaultSuggestedTopics())
                      ActionChip(
                        label: Text(
                          topic,
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: C.surface,
                        side: BorderSide(
                          color: C.lavender.withValues(alpha: 0.3),
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          ref
                              .read(consultationProvider.notifier)
                              .addQuestion(topic);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          gap(20),

          // 4. Checklist & Documents
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr('Documents & Visit Checklist'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: C.lavender,
                      ),
                ),
                Text(
                  '$checkedCount/$totalChecklist',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: checkedCount == totalChecklist && totalChecklist > 0
                        ? Pastel.mint
                        : C.lavender,
                  ),
                ),
              ],
            ),
          ),
          AppCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                for (final item in session.checklist)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: item.isChecked,
                        activeColor: Pastel.mint,
                        visualDensity: VisualDensity.compact,
                        onChanged: (_) {
                          HapticFeedback.selectionClick();
                          ref
                              .read(consultationProvider.notifier)
                              .toggleChecklistItem(item.id);
                        },
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              decoration: item.isChecked
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: item.isChecked
                                  ? C.mist.withValues(alpha: 0.6)
                                  : Colors.white,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ),
                      if (!item.isDefault)
                        IconButton(
                          icon: const Icon(LucideIcons.x,
                              size: 15, color: C.iconDefault),
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ref
                                .read(consultationProvider.notifier)
                                .removeChecklistItem(item.id);
                          },
                        ),
                    ],
                  ),
                gap(8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customChecklistController,
                        decoration: InputDecoration(
                          hintText: tr('Add checklist item...'),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty) {
                            HapticFeedback.lightImpact();
                            ref
                                .read(consultationProvider.notifier)
                                .addChecklistItem(val);
                            _customChecklistController.clear();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(LucideIcons.plus, size: 18),
                      onPressed: () {
                        final val = _customChecklistController.text;
                        if (val.trim().isNotEmpty) {
                          HapticFeedback.lightImpact();
                          ref
                              .read(consultationProvider.notifier)
                              .addChecklistItem(val);
                          _customChecklistController.clear();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          gap(20),

          // 5. Post-Visit Notes
          SectionHeader(title: tr('Post-Visit Clinical Notes')),
          AppCard(
            child: TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: tr(
                    'Record doctor adjustments, lab test orders, or follow-up instructions...'),
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (val) => ref
                  .read(consultationProvider.notifier)
                  .updatePostVisitNotes(val),
            ),
          ),
          gap(24),

          // 6. Action Button: Export Doctor Report
          pillButton(
            tr('Export Doctor Summary Report (PDF / Text)'),
            () => _exportReport(session),
            icon: LucideIcons.fileSpreadsheet,
            color: C.lavender,
          ),
          gap(10),
          Center(
            child: Text(
              tr('Includes therapies, adherence, lab trends, and your prepared questions.'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Pastel.mist.withValues(alpha: 0.75),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
