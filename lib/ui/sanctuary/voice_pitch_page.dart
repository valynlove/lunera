import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:record/record.dart';

import '../../l10n.dart';
import '../../theme.dart';
import '../../voice_pitch.dart';

/// Optional, easter-egg Voice Pitch Studio with gentle dysphoria awareness,
/// quiet no-mic warm-up mode, reading prompts, live on-device Hz estimation,
/// and numeric-only local result history (never saves audio recordings).
class VoicePitchPage extends StatefulWidget {
  const VoicePitchPage({super.key, this.streamBuilder});

  /// Optional synthetic PCM16 stream factory for testing without mic hardware.
  final Stream<Uint8List> Function()? streamBuilder;

  @override
  State<VoicePitchPage> createState() => _VoicePitchPageState();
}

class _VoicePitchPageState extends State<VoicePitchPage> {
  int _mode = 0; // 0: Live Voice Test, 1: Quiet Warm-up
  int _promptIndex = 0;
  String? _customPrompt;

  // Live pitch detection state (RAM only)
  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _streamSub;
  final List<int> _pcmBuffer = [];
  final List<double> _samples = [];
  bool _listening = false;
  double? _liveHz;
  String? _statusNote;

  // Quiet warm-up timer state (no microphone)
  Timer? _warmupTimer;
  int _warmupSecondsLeft = 60;
  bool _warmupRunning = false;

  // Saved numeric history
  List<VoiceTestResult> _results = const [];
  bool _savedCurrentSession = false;

  @override
  void initState() {
    super.initState();
    _promptIndex = math.Random().nextInt(voiceReadingPrompts.length);
    _loadResults();
  }

  @override
  void dispose() {
    _warmupTimer?.cancel();
    _stopListeningSync();
    _recorder?.dispose();
    super.dispose();
  }

  Future<void> _loadResults() async {
    try {
      final list = await VoiceStore.loadResults();
      if (!mounted) return;
      setState(() => _results = list);
    } catch (_) {
      // Ignore storage read errors gracefully.
    }
  }

  void _stopListeningSync() {
    _streamSub?.cancel();
    _streamSub = null;
    _pcmBuffer.clear();
  }

  Future<void> _toggleListening() async {
    if (_listening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    HapticFeedback.lightImpact();
    setState(() {
      _statusNote = null;
      _samples.clear();
      _liveHz = null;
      _savedCurrentSession = false;
      _pcmBuffer.clear();
    });

    try {
      Stream<Uint8List> stream;
      if (widget.streamBuilder != null) {
        stream = widget.streamBuilder!();
      } else {
        _recorder ??= AudioRecorder();
        final allowed = await _recorder!.hasPermission();
        if (!allowed) {
          if (!mounted) return;
          setState(() {
            _statusNote = tr(
                'Microphone permission is needed for live pitch checks. You can still use Quiet Warm-up anytime.');
          });
          return;
        }
        stream = await _recorder!.startStream(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: 16000,
            numChannels: 1,
          ),
        );
      }

      if (!mounted) return;
      setState(() => _listening = true);

      _streamSub = stream.listen(
        _onAudioChunk,
        onError: (_) {
          if (!mounted) return;
          setState(() {
            _listening = false;
            _statusNote = tr(
                'Microphone input could not be started on this device. Quiet Warm-up remains available.');
          });
        },
        onDone: () {
          if (mounted && _listening) {
            _stopListening();
          }
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _listening = false;
        _statusNote = tr(
            'Microphone input could not be started on this device. Quiet Warm-up remains available.');
      });
    }
  }

  void _onAudioChunk(Uint8List chunk) {
    _pcmBuffer.addAll(chunk);
    const frameBytes = 2560; // 1280 samples @ 16kHz = 80ms
    const hopBytes = 1280; // 50% overlap

    double? latestHz;
    while (_pcmBuffer.length >= frameBytes) {
      final frame = Uint8List.fromList(_pcmBuffer.sublist(0, frameBytes));
      _pcmBuffer.removeRange(0, hopBytes);
      final hz = detectPitchFromPcm16(frame, sampleRate: 16000);
      if (hz != null) {
        latestHz = hz;
        _samples.add(hz);
      }
    }

    if (latestHz != null && mounted) {
      setState(() => _liveHz = latestHz);
    }
  }

  Future<void> _stopListening() async {
    HapticFeedback.selectionClick();
    _stopListeningSync();
    try {
      await _recorder?.stop();
    } catch (_) {
      // Ignore recorder stop exceptions on unsupported platforms/tests.
    }
    if (!mounted) return;
    setState(() => _listening = false);
  }

  void _shufflePrompt() {
    HapticFeedback.selectionClick();
    setState(() {
      _customPrompt = null;
      _promptIndex = (_promptIndex + 1 + math.Random().nextInt(3)) %
          voiceReadingPrompts.length;
    });
  }

  Future<void> _editCustomPrompt() async {
    final ctrl = TextEditingController(
      text: _customPrompt ?? pickVoicePrompt(index: _promptIndex),
    );
    final updated = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(tr('Custom reading prompt')),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: tr('Type a comfortable sentence to read aloud...'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: Text(tr('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(d, ctrl.text.trim()),
            child: Text(tr('Save')),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (updated != null && updated.isNotEmpty && mounted) {
      setState(() => _customPrompt = updated);
    }
  }

  Future<void> _saveSessionResult() async {
    if (_samples.isEmpty || _savedCurrentSession) return;
    HapticFeedback.lightImpact();
    final avg = _samples.reduce((a, b) => a + b) / _samples.length;
    final minVal = _samples.reduce(math.min);
    final maxVal = _samples.reduce(math.max);
    final res = VoiceTestResult(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      at: DateTime.now(),
      avgHz: avg,
      minHz: minVal,
      maxHz: maxVal,
      category: categorizePitchHz(avg),
    );
    final updated = await VoiceStore.saveResult(res);
    if (!mounted) return;
    setState(() {
      _results = updated;
      _savedCurrentSession = true;
    });
  }

  Future<void> _deleteResult(String id) async {
    HapticFeedback.selectionClick();
    final updated = await VoiceStore.deleteResult(id);
    if (!mounted) return;
    setState(() => _results = updated);
  }

  Future<void> _clearAllResults() async {
    HapticFeedback.selectionClick();
    await VoiceStore.clearResults();
    if (!mounted) return;
    setState(() => _results = const []);
  }

  Future<void> _hideStudio() async {
    HapticFeedback.selectionClick();
    await _stopListening();
    await VoiceStore.setUnlocked(false);
    if (!mounted) return;
    Navigator.pop(context);
  }

  void _toggleWarmupTimer() {
    HapticFeedback.selectionClick();
    if (_warmupRunning) {
      _warmupTimer?.cancel();
      setState(() => _warmupRunning = false);
      return;
    }
    if (_warmupSecondsLeft <= 0) {
      _warmupSecondsLeft = 60;
    }
    setState(() => _warmupRunning = true);
    _warmupTimer?.cancel();
    _warmupTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_warmupSecondsLeft > 1) {
        setState(() => _warmupSecondsLeft--);
      } else {
        t.cancel();
        HapticFeedback.lightImpact();
        setState(() {
          _warmupSecondsLeft = 0;
          _warmupRunning = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final promptText = _customPrompt ?? pickVoicePrompt(index: _promptIndex);
    final avgHz = _samples.isEmpty
        ? null
        : _samples.reduce((a, b) => a + b) / _samples.length;
    final minHz = _samples.isEmpty ? null : _samples.reduce(math.min);
    final maxHz = _samples.isEmpty ? null : _samples.reduce(math.max);
    final displayHz = _liveHz ?? avgHz;
    final category = displayHz == null ? null : categorizePitchHz(displayHz);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.arrowLeft),
                  tooltip: tr('Back'),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    tr('Voice Pitch Studio'),
                    style: display(30),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            gap(10),

            // Gentle dysphoria warning & privacy reassurance
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: C.coral.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: C.coral.withValues(alpha: 0.34)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.heartHandshake,
                      size: 18, color: C.coral),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tr('Voice practice can sometimes feel heavy. Live mic checks are 100% optional, run in memory without saving recordings, and you can switch to Quiet Warm-up or hide this studio anytime.'),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Pastel.mist.withValues(alpha: 0.90),
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            gap(16),

            PillTabs<int>(
              items: [
                (0, tr('Live Voice Test')),
                (1, tr('Quiet Warm-up')),
              ],
              value: _mode,
              onChanged: (v) async {
                if (v != 0 && _listening) {
                  await _stopListening();
                }
                if (mounted) setState(() => _mode = v);
              },
            ),
            gap(16),

            if (_mode == 0) ...[
              // Reading prompt card
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.messageSquareQuote,
                            size: 16, color: C.lavender),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tr('Reading prompt'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: C.lavender,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _shufflePrompt,
                          icon: const Icon(LucideIcons.refreshCw, size: 17),
                          color: C.iconDefault,
                          tooltip: tr('Shuffle prompt'),
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          onPressed: _editCustomPrompt,
                          icon: const Icon(LucideIcons.pencil, size: 17),
                          color: C.iconDefault,
                          tooltip: tr('Edit custom text'),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    gap(8),
                    Text(
                      '"$promptText"',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              gap(14),

              // Live pitch meter card
              AppCard(
                highlight: true,
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Text(
                      displayHz != null ? '${displayHz.round()} Hz' : '— Hz',
                      style: display(44, color: Colors.white),
                    ),
                    gap(8),
                    if (category != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: category.color.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: category.color.withValues(alpha: 0.45)),
                        ),
                        child: Text(
                          '${category.label} (${category.rangeHint})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: category.color,
                          ),
                        ),
                      )
                    else
                      Text(
                        _listening
                            ? tr('Speak comfortably at your own pace...')
                            : tr('Press Start when you feel ready'),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Pastel.mist.withValues(alpha: 0.78),
                        ),
                      ),
                    gap(16),
                    _PitchGaugeBar(hz: displayHz),
                    gap(10),
                    Text(
                      tr('Pitch is only one piece alongside resonance & comfort.'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Pastel.mist.withValues(alpha: 0.72),
                      ),
                    ),
                    if (_statusNote != null) ...[
                      gap(10),
                      Text(
                        _statusNote!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: C.coral,
                          height: 1.4,
                        ),
                      ),
                    ],
                    gap(16),
                    SizedBox(
                      width: double.infinity,
                      child: pillButton(
                        _listening
                            ? tr('Stop voice check')
                            : tr('Start live voice check'),
                        _toggleListening,
                        icon: _listening
                            ? LucideIcons.square
                            : LucideIcons.mic,
                        color: _listening ? C.coral : C.aurora,
                      ),
                    ),
                    if (!_listening &&
                        avgHz != null &&
                        minHz != null &&
                        maxHz != null) ...[
                      gap(14),
                      const Divider(height: 1),
                      gap(12),
                      Text(
                        tr('Session average: {0} Hz ({1}–{2} Hz)', [
                          avgHz.round(),
                          minHz.round(),
                          maxHz.round(),
                        ]),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      gap(10),
                      if (_savedCurrentSession)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.check,
                                size: 16, color: Pastel.mint),
                            const SizedBox(width: 6),
                            Text(
                              tr('Result saved (numbers only)'),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Pastel.mint,
                              ),
                            ),
                          ],
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: _saveSessionResult,
                          icon: const Icon(LucideIcons.bookmarkCheck, size: 17),
                          label: Text(tr('Save result (numbers only)')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: C.lavender,
                            side: BorderSide(
                                color: C.lavender.withValues(alpha: 0.4)),
                            shape: const StadiumBorder(),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              gap(18),

              // Saved numeric history
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr('Saved results'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (_results.isNotEmpty)
                    TextButton(
                      onPressed: _clearAllResults,
                      child: Text(tr('Clear all')),
                    ),
                ],
              ),
              Text(
                tr('Numbers and category only — zero audio is ever stored.'),
                style: TextStyle(
                  fontSize: 11.5,
                  color: Pastel.mist.withValues(alpha: 0.72),
                ),
              ),
              gap(10),
              if (_results.isEmpty)
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    tr('No saved pitch results yet.'),
                    style: TextStyle(
                      fontSize: 13,
                      color: Pastel.mist.withValues(alpha: 0.78),
                    ),
                  ),
                )
              else
                for (final r in _results) ...[
                  _SavedResultTile(
                    result: r,
                    onDelete: () => _deleteResult(r.id),
                  ),
                  gap(8),
                ],
            ] else ...[
              // Quiet Warm-up (No-Mic)
              AppCard(
                highlight: true,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    iconBadge(LucideIcons.wind, Pastel.mint,
                        size: 52, iconSize: 26),
                    gap(12),
                    Text(
                      '${_warmupSecondsLeft}s',
                      style: display(42, color: Colors.white),
                    ),
                    gap(8),
                    Text(
                      tr('Relax your jaw and shoulders. Hum gently on a comfortable note without pushing volume.'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Pastel.mist.withValues(alpha: 0.88),
                        height: 1.45,
                      ),
                    ),
                    gap(16),
                    pillButton(
                      _warmupRunning
                          ? tr('Pause warm-up')
                          : tr('Start 60s warm-up'),
                      _toggleWarmupTimer,
                      icon: _warmupRunning
                          ? LucideIcons.pause
                          : LucideIcons.play,
                      color: C.aurora,
                    ),
                  ],
                ),
              ),
            ],

            gap(24),
            OutlinedButton.icon(
              onPressed: _hideStudio,
              icon: const Icon(LucideIcons.eyeOff, size: 17),
              label: Text(tr('Hide Voice Pitch Studio')),
              style: OutlinedButton.styleFrom(
                foregroundColor: C.iconDefault,
                side: BorderSide(color: C.lavender.withValues(alpha: 0.22)),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PitchGaugeBar extends StatelessWidget {
  const _PitchGaugeBar({required this.hz});

  final double? hz;

  @override
  Widget build(BuildContext context) {
    const minScale = 85.0;
    const maxScale = 280.0;
    final norm = hz == null
        ? null
        : ((hz! - minScale) / (maxScale - minScale)).clamp(0.0, 1.0);

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            return SizedBox(
              height: 18,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: const LinearGradient(
                        colors: [C.violet, C.lavender, C.rose],
                        stops: [0.25, 0.50, 0.85],
                      ),
                    ),
                  ),
                  if (norm != null)
                    Positioned(
                      left: (w - 14) * norm,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: C.aurora, width: 2.5),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        gap(4),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('85 Hz', style: TextStyle(fontSize: 10.5, color: C.iconDefault)),
            Text('155–185 Hz',
                style: TextStyle(fontSize: 10.5, color: C.iconDefault)),
            Text('280 Hz',
                style: TextStyle(fontSize: 10.5, color: C.iconDefault)),
          ],
        ),
      ],
    );
  }
}

class _SavedResultTile extends StatelessWidget {
  const _SavedResultTile({required this.result, required this.onDelete});

  final VoiceTestResult result;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final stamp = DateFormat('d MMM y • HH:mm', L10n.code).format(result.at);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          iconBadge(LucideIcons.mic, result.category.color,
              size: 38, iconSize: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${result.avgHz.round()} Hz  •  ${result.category.label}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                gap(2),
                Text(
                  '$stamp  (${result.minHz.round()}–${result.maxHz.round()} Hz)',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Pastel.mist.withValues(alpha: 0.76),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(LucideIcons.trash2, size: 17),
            color: C.iconDefault,
            tooltip: tr('Delete'),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
