import 'dart:convert';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n.dart';
import '../lock.dart';
import '../moments.dart';
import '../repo.dart';
import '../schedule.dart';
import '../theme.dart';

/// Halaman album visual kenangan dan tonggak transisi (Lunera Moments).
/// Menyimpan foto kenangan dan catatan refleksi secara privat dan aman di perangkat lokal.
class MomentsPage extends ConsumerStatefulWidget {
  const MomentsPage({super.key});

  @override
  ConsumerState<MomentsPage> createState() => _MomentsPageState();
}

class _MomentsPageState extends ConsumerState<MomentsPage> {
  String _selectedCategory = 'all';

  void _openEditor([Moment? existing]) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MomentEditorSheet(existing: existing),
    );
  }

  void _viewFullscreen(Moment m) {
    HapticFeedback.selectionClick();
    showDialog<void>(
      context: context,
      builder: (d) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: C.midnight,
            border: Border.all(color: C.lavender.withValues(alpha: 0.35)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (m.hasPhoto)
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(23)),
                  child: Image.memory(
                    base64Decode(m.photoBase64!),
                    fit: BoxFit.contain,
                    cacheWidth: 1080,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.title,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, d MMMM y', L10n.code).format(m.at),
                      style: TextStyle(
                        fontSize: 12,
                        color: Pastel.mist.withValues(alpha: 0.85),
                      ),
                    ),
                    if (m.hasNote) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: C.surface,
                        ),
                        child: Text(
                          m.note!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.95),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(d),
                        child: Text(tr('Close')),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(Moment m) {
    HapticFeedback.selectionClick();
    showDialog<void>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(tr('Delete Moment?')),
        content: Text(tr('Are you sure you want to remove "{0}" from your scrapbook?', [m.title])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: Text(tr('Cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: C.coral),
            onPressed: () {
              Navigator.pop(d);
              ref.read(momentsProvider.notifier).deleteMoment(m.id);
            },
            child: Text(tr('Delete')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final moments = ref.watch(momentsProvider);
    final therapies = ref.watch(therapiesProvider).valueOrNull ?? const [];
    final logs = ref.watch(logsProvider).valueOrNull ?? const [];

    final starts = [
      ...logs.where((l) => !l.skipped).map((l) => l.at),
      ...therapies.map((t) => t.start),
    ]..sort();
    final journeyStart = starts.isEmpty ? null : starts.first;

    final filtered = _selectedCategory == 'all'
        ? moments
        : moments.where((m) => m.category == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr('Lunera Moments'),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        actions: [
          IconButton(
            tooltip: tr('New Moment'),
            icon: const Icon(LucideIcons.plus, size: 20),
            onPressed: () => _openEditor(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
        children: [
          // Subtitle card
          Text(
            tr('A private visual scrapbook celebrating milestones and cherished memories on your path.'),
            style: TextStyle(
              fontSize: 12.5,
              color: Pastel.mist.withValues(alpha: 0.85),
              height: 1.35,
            ),
          ),
          gap(14),

          // Category filter bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  selected: _selectedCategory == 'all',
                  label: Text(tr('All Moments')),
                  onSelected: (_) => setState(() => _selectedCategory = 'all'),
                ),
                const SizedBox(width: 8),
                for (final cat in momentCategories) ...[
                  FilterChip(
                    selected: _selectedCategory == cat.id,
                    avatar: Icon(cat.icon, size: 14),
                    label: Text(cat.name),
                    onSelected: (_) =>
                        setState(() => _selectedCategory = cat.id),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          gap(16),

          // Moments list or empty state
          if (filtered.isEmpty)
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
              child: Column(
                children: [
                  iconBadge(LucideIcons.camera, Pastel.rose),
                  gap(14),
                  Text(
                    tr('No visual moments yet'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  gap(6),
                  Text(
                    tr('Capture transition milestones, affirming outfits, self-love reflections, or anniversary smiles. All photos remain 100% private on your device.'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Pastel.mist.withValues(alpha: 0.8),
                      height: 1.35,
                    ),
                  ),
                  gap(18),
                  pillButton(
                    tr('Create First Moment'),
                    () => _openEditor(),
                    icon: LucideIcons.plus,
                    color: C.peony,
                  ),
                ],
              ),
            )
          else
            for (final m in filtered) ...[
              _MomentCard(
                moment: m,
                journeyStart: journeyStart,
                onTap: () => _viewFullscreen(m),
                onEdit: () => _openEditor(m),
                onDelete: () => _confirmDelete(m),
              ),
              gap(14),
            ],
        ],
      ),
    );
  }
}

class _MomentCard extends StatelessWidget {
  const _MomentCard({
    required this.moment,
    this.journeyStart,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Moment moment;
  final DateTime? journeyStart;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cat = categoryOfMoment(moment.category);
    final dayOffset = journeyStart == null
        ? null
        : daysBetween(journeyStart!, moment.at).clamp(0, 99999);

    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (moment.hasPhoto)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Image.memory(
                    base64Decode(moment.photoBase64!),
                    fit: BoxFit.cover,
                    cacheWidth: 600,
                    errorBuilder: (_, __, ___) => Container(
                      color: C.surface,
                      child: const Center(
                        child: Icon(LucideIcons.imageOff, color: C.mist),
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 72,
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  gradient: LinearGradient(
                    colors: [
                      C.peony.withValues(alpha: 0.25),
                      C.lavender.withValues(alpha: 0.15),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(cat.icon, size: 28, color: C.lavender),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: C.midnight.withValues(alpha: 0.6),
                          border: Border.all(
                            color: C.lavender.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(cat.icon, size: 12, color: Pastel.rose),
                            const SizedBox(width: 5),
                            Text(
                              cat.name,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      PopupMenuButton<String>(
                        icon: const Icon(LucideIcons.moreHorizontal,
                            size: 16, color: C.iconDefault),
                        onSelected: (action) {
                          if (action == 'edit') onEdit();
                          if (action == 'delete') onDelete();
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(LucideIcons.pencil, size: 16),
                                const SizedBox(width: 8),
                                Text(tr('Edit')),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(LucideIcons.trash2,
                                    size: 16, color: C.coral),
                                const SizedBox(width: 8),
                                Text(tr('Delete'),
                                    style: const TextStyle(color: C.coral)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    moment.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    dayOffset != null
                        ? '${DateFormat('d MMM y', L10n.code).format(moment.at)} • ${tr('Day {0}', [dayOffset])}'
                        : DateFormat('d MMM y', L10n.code).format(moment.at),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: Pastel.mist.withValues(alpha: 0.8),
                    ),
                  ),
                  if (moment.hasNote) ...[
                    const SizedBox(height: 10),
                    Text(
                      moment.note!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MomentEditorSheet extends ConsumerStatefulWidget {
  const _MomentEditorSheet({this.existing});
  final Moment? existing;

  @override
  ConsumerState<_MomentEditorSheet> createState() => _MomentEditorSheetState();
}

class _MomentEditorSheetState extends ConsumerState<_MomentEditorSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _noteCtrl;
  late DateTime _date;
  late String _category;
  String? _photoBase64;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.existing?.title ?? '');
    _noteCtrl = TextEditingController(text: widget.existing?.note ?? '');
    _date = widget.existing?.at ?? DateTime.now();
    _category = widget.existing?.category ?? 'milestone';
    _photoBase64 = widget.existing?.photoBase64;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<Uint8List> _downscaleImageIfNeeded(Uint8List rawBytes) async {
    if (rawBytes.lengthInBytes <= 400 * 1024) return rawBytes;
    try {
      final codec = await ui.instantiateImageCodec(
        rawBytes,
        targetWidth: 1080,
      );
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      if (data != null) {
        final processed = data.buffer.asUint8List();
        if (processed.lengthInBytes < rawBytes.lengthInBytes) {
          return processed;
        }
      }
    } catch (_) {}
    return rawBytes;
  }

  Future<void> _pickPhoto() async {
    await Lock.instance.suppressLockDuring(() async {
      Uint8List? bytes;
      try {
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1080,
          maxHeight: 1080,
          imageQuality: 75,
        );
        if (picked != null) bytes = await picked.readAsBytes();
      } catch (_) {
        try {
          const group = XTypeGroup(
              label: 'images', extensions: ['jpg', 'png', 'jpeg', 'webp']);
          final f = await openFile(acceptedTypeGroups: const [group]);
          if (f != null) {
            final raw = await f.readAsBytes();
            bytes = await _downscaleImageIfNeeded(raw);
          }
        } catch (_) {}
      }
      if (bytes != null && mounted) {
        setState(() => _photoBase64 = base64Encode(bytes!));
      }
    });
  }

  Future<void> _pickDate() async {
    HapticFeedback.selectionClick();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _date = picked);
    }
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    HapticFeedback.lightImpact();
    if (widget.existing != null) {
      final updated = widget.existing!.copyWith(
        title: title,
        note: _noteCtrl.text.trim(),
        at: _date,
        category: _category,
        photoBase64: _photoBase64,
        clearPhoto: _photoBase64 == null,
      );
      ref.read(momentsProvider.notifier).updateMoment(updated);
    } else {
      final created = Moment(
        id: 'moment_${DateTime.now().millisecondsSinceEpoch}',
        at: _date,
        title: title,
        note: _noteCtrl.text.trim(),
        photoBase64: _photoBase64,
        category: _category,
      );
      ref.read(momentsProvider.notifier).addMoment(created);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: C.midnight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: C.lavender.withValues(alpha: 0.35),
                ),
              ),
            ),
            gap(14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.existing != null
                        ? tr('Edit Moment')
                        : tr('Add Visual Moment'),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            gap(14),

            // Photo preview / selector
            if (_photoBase64 != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.memory(
                        base64Decode(_photoBase64!),
                        fit: BoxFit.cover,
                        cacheWidth: 600,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withValues(alpha: 0.65),
                      child: IconButton(
                        icon: const Icon(LucideIcons.trash2,
                            size: 16, color: C.coral),
                        onPressed: () => setState(() => _photoBase64 = null),
                      ),
                    ),
                  ),
                ],
              )
            else
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _pickPhoto,
                child: Container(
                  height: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: C.surface,
                    border: Border.all(
                      color: C.lavender.withValues(alpha: 0.3),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.camera,
                            color: Pastel.rose, size: 26),
                        const SizedBox(height: 6),
                        Text(
                          tr('Tap to add photo (optional)'),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Pastel.mist.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            gap(14),

            // Title input
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: tr('Moment Title'),
                hintText: tr('e.g. 6 Months on HRT, First New Dress, etc.'),
                prefixIcon: const Icon(LucideIcons.sparkles,
                    size: 18, color: C.iconDefault),
              ),
            ),
            gap(12),

            // Category picker
            Text(
              tr('Category:'),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: C.mist,
              ),
            ),
            gap(6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final cat in momentCategories)
                  ChoiceChip(
                    selected: _category == cat.id,
                    avatar: Icon(cat.icon, size: 13),
                    label: Text(cat.name, style: const TextStyle(fontSize: 11)),
                    onSelected: (val) {
                      if (val) setState(() => _category = cat.id);
                    },
                  ),
              ],
            ),
            gap(12),

            // Date picker row
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _pickDate,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: C.surface,
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.calendar,
                        size: 18, color: Pastel.sky),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        DateFormat('EEEE, d MMMM y', L10n.code).format(_date),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Icon(LucideIcons.chevronRight,
                        size: 16, color: C.iconDefault),
                  ],
                ),
              ),
            ),
            gap(12),

            // Reflection notes
            TextField(
              controller: _noteCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: tr('Reflection Note (optional)'),
                hintText: tr('How did you feel in this moment?'),
                alignLabelWithHint: true,
              ),
            ),
            gap(20),

            // Save button
            pillButton(
              widget.existing != null ? tr('Save Changes') : tr('Save Moment'),
              _save,
              icon: LucideIcons.check,
              color: C.peony,
            ),
          ],
        ),
      ),
    );
  }
}
