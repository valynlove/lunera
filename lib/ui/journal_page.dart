import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../repo.dart';
import '../theme.dart';

class JournalPage extends ConsumerStatefulWidget {
  const JournalPage({super.key});
  @override
  ConsumerState<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends ConsumerState<JournalPage> {
  String _filter = 'All';

  final _typeOptions = const [
    ('All', 'All'),
    ('mood', 'Mood'),
    ('body', 'Body'),
    ('notes', 'Notes'),
  ];

  @override
  Widget build(BuildContext context) {
    final journals = <JournalEntry>[...(ref.watch(journalsProvider).value ?? <JournalEntry>[])]
      ..sort((a, b) => b.at.compareTo(a.at));

    final filtered = _filter == 'All' ? journals : journals.where((j) => j.type == _filter).toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: [
            Row(
              children: [
                Expanded(child: Text('Journal', style: display(32))),
                IconButton.filledTonal(
                  onPressed: () => _openAddSheet(context),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            gap(14),

            // Filter Chips
            Wrap(
              spacing: 8,
              children: [
                for (final t in _typeOptions)
                  ChoiceChip(
                    label: Text(t.$2),
                    selected: _filter == t.$1,
                    onSelected: (_) => setState(() => _filter = t.$1),
                  ),
              ],
            ),
            gap(18),

            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Column(
                  children: [
                    const Icon(Icons.auto_stories_rounded, size: 56, color: C.lavender),
                    gap(12),
                    Text('No journal entries yet', style: display(20)),
                    gap(6),
                    const Text('Share your mood or physical observations today.'),
                    gap(20),
                    pillButton('Write Journal', () => _openAddSheet(context), icon: Icons.edit_note_rounded),
                  ],
                ),
              )
            else
              for (final j in filtered) ...[
                _JournalCard(
                  j: j,
                  onDelete: () => ref.read(repoProvider)?.deleteJournal(j.id),
                ),
              ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddSheet(context),
        backgroundColor: C.lavender,
        foregroundColor: C.midnight,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  void _openAddSheet(BuildContext context) {
    showSheet(context, const _AddJournalSheet());
  }
}

class _JournalCard extends StatelessWidget {
  const _JournalCard({required this.j, required this.onDelete});
  final JournalEntry j;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMMM yyyy, HH:mm', 'en').format(j.at);

    final typeLabel = switch (j.type) {
      'mood' => 'Mood & State',
      'body' => 'Body Changes',
      _ => 'Daily Notes',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: C.lavender.withValues(alpha: .18),
                  shape: BoxShape.circle,
                ),
                child: Text(j.moodEmoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(j.title.isEmpty ? typeLabel : j.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    Text(dateStr, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .6))),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, size: 20, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .5)),
                onPressed: () async {
                  if (await confirm(context, 'Delete this journal entry?')) {
                    onDelete();
                  }
                },
              ),
            ],
          ),
          if (j.note.isNotEmpty) ...[
            gap(10),
            Text(j.note, style: const TextStyle(fontSize: 14, height: 1.4)),
          ],
        ],
      ),
    );
  }
}

class _AddJournalSheet extends ConsumerStatefulWidget {
  const _AddJournalSheet();
  @override
  ConsumerState<_AddJournalSheet> createState() => _AddJournalSheetState();
}

class _AddJournalSheetState extends ConsumerState<_AddJournalSheet> {
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _selectedEmoji = '😊';
  String _selectedType = 'mood';

  final _emojis = const [
    ('😊', 'Calm'),
    ('😄', 'Happy'),
    ('😐', 'Neutral'),
    ('✨', 'Energetic'),
    ('😴', 'Tired'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Write New Journal Entry', style: display(24)),
        gap(16),

        // Mood Picker
        const Text('Current Mood', style: TextStyle(fontWeight: FontWeight.w600)),
        gap(8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (final e in _emojis)
              GestureDetector(
                onTap: () => setState(() => _selectedEmoji = e.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _selectedEmoji == e.$1 ? C.lavender.withValues(alpha: .3) : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedEmoji == e.$1 ? C.lavender : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Text(e.$1, style: const TextStyle(fontSize: 28)),
                ),
              ),
          ],
        ),
        gap(16),

        // Type Selector
        Wrap(
          spacing: 8,
          children: [
            for (final t in const [('mood', 'Mood'), ('body', 'Body Changes'), ('notes', 'Daily Notes')])
              ChoiceChip(
                label: Text(t.$2),
                selected: _selectedType == t.$1,
                onSelected: (_) => setState(() => _selectedType = t.$1),
              ),
          ],
        ),
        gap(14),

        TextField(
          controller: _titleCtrl,
          decoration: const InputDecoration(labelText: 'Short Title (optional)'),
        ),
        gap(12),

        TextField(
          controller: _noteCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'How are you feeling today?',
            alignLabelWithHint: true,
          ),
        ),
        gap(20),

        SizedBox(
          width: double.infinity,
          child: pillButton('Save Entry', () {
            final repo = ref.read(repoProvider);
            if (repo == null) return;
            repo.addJournal(JournalEntry(
              id: '',
              at: DateTime.now(),
              type: _selectedType,
              title: _titleCtrl.text.trim(),
              note: _noteCtrl.text.trim(),
              moodEmoji: _selectedEmoji,
            ));
            Navigator.pop(context);
          }, icon: Icons.check_rounded),
        ),
      ],
    );
  }
}
