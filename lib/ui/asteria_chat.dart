import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../asteria.dart';
import '../l10n.dart';
import '../models.dart';
import '../repo.dart';
import '../theme.dart';

/// Halaman percakapan empatik bersama Asteria AI Companion.
class AsteriaChatPage extends ConsumerStatefulWidget {
  const AsteriaChatPage({super.key});

  @override
  ConsumerState<AsteriaChatPage> createState() => _AsteriaChatPageState();
}

class _AsteriaChatPageState extends ConsumerState<AsteriaChatPage> {
  final _messages = <ChatMessage>[];
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _apiKeyCtrl = TextEditingController();

  bool _isOnline = true;
  bool _isGenerating = false;
  bool _isSummarizing = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final online = await AsteriaService.isOnline();
    if (!mounted) return;
    setState(() {
      _isOnline = online;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? quickText]) async {
    final text = quickText ?? _textCtrl.text.trim();
    if (text.isEmpty || _isGenerating) return;

    final prefs = ref.read(prefsProvider).value ?? const Prefs();
    if (prefs.geminiApiKey.isEmpty) {
      _showApiKeyDialog();
      return;
    }

    if (!_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Asteria is currently offline. Connect to internet.'))),
      );
      return;
    }

    if (quickText == null) {
      _textCtrl.clear();
    }

    setState(() {
      _messages.add(ChatMessage(role: 'user', text: text, time: DateTime.now()));
      _isGenerating = true;
    });
    _scrollToBottom();

    try {
      final reply = await AsteriaService.sendMessage(
        apiKey: prefs.geminiApiKey,
        history: _messages.sublist(0, _messages.length - 1),
        userMessage: text,
        languageCode: L10n.code,
      );

      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(role: 'model', text: reply, time: DateTime.now()));
        _isGenerating = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tr("Error communicating with Asteria")}: $e')),
      );
    }
  }

  Future<void> _finishSession() async {
    if (_messages.isEmpty || _isSummarizing) return;

    final prefs = ref.read(prefsProvider).value ?? const Prefs();
    setState(() => _isSummarizing = true);

    try {
      final summary = await AsteriaService.summarizeSession(
        apiKey: prefs.geminiApiKey,
        messages: _messages,
        languageCode: L10n.code,
      );

      if (!mounted) return;
      setState(() => _isSummarizing = false);
      _showSaveToJournalSheet(summary);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSummarizing = false);
      _showSaveToJournalSheet(
        AsteriaSummary(
          summary: _messages.where((m) => m.isUser).map((m) => m.text).join('\n'),
          mood: 'calm',
        ),
      );
    }
  }

  void _showSaveToJournalSheet(AsteriaSummary initial) {
    String selectedMood = initial.mood;
    final noteCtrl = TextEditingController(text: initial.summary);
    final dark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheetState) {
        return Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          decoration: BoxDecoration(
            color: dark ? C.deepCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: dark ? Border.all(color: Colors.white.withValues(alpha: 0.12)) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              gap(16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: C.peony.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.auto_awesome_rounded, color: C.peony, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('Reflective Journal Summary'), style: display(18)),
                        Text(
                          tr('Asteria has crafted a gentle summary for your Journal.'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              gap(16),
              Text(tr('Estimated Mood'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              gap(8),
              Wrap(
                spacing: 8,
                children: [
                  for (final m in [
                    ('happy', '😊', tr('Happy')),
                    ('calm', '😌', tr('Calm')),
                    ('neutral', '😐', tr('Neutral')),
                    ('low', '😔', tr('Low')),
                    ('anxious', '😰', tr('Anxious')),
                  ])
                    ChoiceChip(
                      selected: selectedMood == m.$1,
                      onSelected: (_) => setSheetState(() => selectedMood = m.$1),
                      label: Text('${m.$2} ${m.$3}'),
                      selectedColor: C.peony.withValues(alpha: 0.25),
                    ),
                ],
              ),
              gap(14),
              Text(tr('Journal Note'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              gap(6),
              TextField(
                controller: noteCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: dark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              gap(18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(tr('Cancel')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () {
                        final note = noteCtrl.text.trim();
                        final entry = JournalEntry(
                          id: '',
                          at: DateTime.now(),
                          mood: selectedMood,
                          text: note.isNotEmpty ? note : null,
                        );
                        ref.read(repoProvider)?.addJournal(entry);
                        Navigator.pop(ctx);

                        setState(() => _messages.clear());
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(tr('Reflection saved to your Journal!'))),
                        );
                      },
                      icon: const Icon(Icons.bookmark_added_rounded, size: 18),
                      label: Text(tr('Save to Journal'), style: const TextStyle(fontWeight: FontWeight.w700)),
                      style: FilledButton.styleFrom(
                        backgroundColor: C.peony,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  void _showApiKeyDialog() {
    final prefs = ref.read(prefsProvider).value ?? const Prefs();
    _apiKeyCtrl.text = prefs.geminiApiKey;
    final dark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dark ? C.deepCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.key_rounded, color: C.peony),
            const SizedBox(width: 8),
            Text(tr('Asteria API Key'), style: display(18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('Enter your Google Gemini API key to activate Asteria. Your key is stored securely in your private account preferences.'),
              style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75)),
            ),
            gap(14),
            TextField(
              controller: _apiKeyCtrl,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'AIzaSy...',
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.content_paste_rounded),
                  tooltip: tr('Paste from clipboard'),
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data?.text != null) {
                      _apiKeyCtrl.text = data!.text!.trim();
                    }
                  },
                ),
              ),
            ),
            gap(8),
            Text(
              tr('Get a free key at aistudio.google.com'),
              style: TextStyle(fontSize: 12, color: C.peony, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('Cancel')),
          ),
          FilledButton(
            onPressed: () {
              final newKey = _apiKeyCtrl.text.trim();
              ref.read(repoProvider)?.setPrefs(prefs.copy(geminiApiKey: newKey));
              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(tr('Asteria API Key updated.'))),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: C.peony, foregroundColor: Colors.white),
            child: Text(tr('Save Key')),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: C.peony.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cloud_off_rounded, size: 54, color: C.peony.withValues(alpha: 0.8)),
            ),
            gap(20),
            Text(
              tr('Asteria is resting'),
              style: display(22),
              textAlign: TextAlign.center,
            ),
            gap(8),
            Text(
              tr('Asteria is resting beneath the night clouds. Connect your device to the internet to chat with her.'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
            gap(24),
            pillButton(
              tr('Retry connection'),
              _checkConnectivity,
              icon: Icons.refresh_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final starters = [
      tr('I feel anxious about my body and progress today...'),
      tr('Can you remind me that adaptation takes time?'),
      tr('I tried new feminine clothes, but I feel uncertain...'),
      tr('I just want to vent about how I feel right now.'),
    ];

    return Center(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [C.peony.withValues(alpha: 0.25), C.lavender.withValues(alpha: 0.15)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome_rounded, size: 48, color: C.peony),
            ),
          ),
          gap(16),
          Text(
            tr('Hello, I am Asteria ✦'),
            textAlign: TextAlign.center,
            style: display(22),
          ),
          gap(8),
          Text(
            tr('Your safe, non-judgmental space to share your journey, feelings, dysphoria, or small victories. How are you holding up today?'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
              height: 1.4,
            ),
          ),
          gap(24),
          for (final s in starters)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _sendMessage(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: C.peony.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: C.peony.withValues(alpha: 0.20)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 16, color: C.peony),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(prefsProvider).value ?? const Prefs();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final timeFmt = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: C.peony.withValues(alpha: 0.20),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome_rounded, color: C.peony, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Asteria', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isOnline ? Colors.greenAccent : Colors.amber,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                Text(
                  _isOnline ? tr('Always here to listen') : tr('Offline mode'),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_messages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _isSummarizing ? null : _finishSession,
                icon: _isSummarizing
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check_circle_outline_rounded, size: 16),
                label: Text(tr('Finish Curhat'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                style: TextButton.styleFrom(
                  foregroundColor: C.peony,
                  backgroundColor: C.peony.withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          IconButton(
            tooltip: tr('Asteria Settings / API Key'),
            icon: const Icon(Icons.key_rounded, size: 20),
            onPressed: _showApiKeyDialog,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!_isOnline)
              Expanded(child: _buildOfflineView())
            else if (prefs.geminiApiKey.isEmpty)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.key_rounded, size: 50, color: C.peony),
                        gap(16),
                        Text(tr('Connect to Asteria'), style: display(20)),
                        gap(8),
                        Text(
                          tr('Please configure your free Gemini API key to start chatting with Asteria.'),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                        ),
                        gap(20),
                        pillButton(tr('Enter API Key'), _showApiKeyDialog, icon: Icons.vpn_key_rounded),
                      ],
                    ),
                  ),
                ),
              )
            else if (_messages.isEmpty)
              Expanded(child: _buildEmptyState())
            else
              Expanded(
                child: ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _messages.length + (_isGenerating ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i == _messages.length && _isGenerating) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: dark ? C.deepCard : Colors.grey.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: C.peony),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                tr('Asteria is reflecting...'),
                                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final m = _messages[i];
                    return Align(
                      alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: m.isUser
                              ? C.peony
                              : (dark ? C.deepCard : Colors.grey.withValues(alpha: 0.12)),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: Radius.circular(m.isUser ? 20 : 4),
                            bottomRight: Radius.circular(m.isUser ? 4 : 20),
                          ),
                          border: m.isUser
                              ? null
                              : Border.all(color: dark ? Colors.white10 : Colors.black12),
                        ),
                        child: Column(
                          crossAxisAlignment: m.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.text,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: m.isUser ? Colors.white : (dark ? Colors.white : C.midnight),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeFmt.format(m.time),
                              style: TextStyle(
                                fontSize: 10,
                                color: m.isUser
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Composer area
            if (_isOnline && prefs.geminiApiKey.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(top: BorderSide(color: dark ? Colors.white10 : Colors.black12)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textCtrl,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: tr('Talk to Asteria...'),
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          filled: true,
                          fillColor: dark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _isGenerating ? null : () => _sendMessage(),
                      icon: const Icon(Icons.arrow_upward_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: C.peony,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
