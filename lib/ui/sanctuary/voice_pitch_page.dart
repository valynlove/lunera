import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:record/record.dart';

import '../../l10n.dart';
import '../../repo.dart';
import '../../theme.dart';
import '../../voice_pitch.dart';
import '../companion_avatar.dart';

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
  static const int _maxContourPoints = 48;

  int _mode = 0; // 0: Live Voice Test, 1: Quiet Warm-up
  int _readingMode = 0; // 0: Short prompt, 1: Article passage
  int _promptIndex = 0;
  int _passageIndex = 0;
  String? _customPrompt;

  // Live pitch & spectral tone state (RAM only)
  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _streamSub;
  final List<int> _pcmBuffer = [];
  final List<double> _samples = [];
  final List<double> _contourPoints = [];
  final List<double> _brightnessSamples = [];
  final List<double> _weightSamples = [];
  bool _listening = false;
  double? _liveHz;
  VoiceToneAnalysis? _latestTone;
  String? _statusNote;
  String? _selectedContextTag;

  // Gentle reference tone highlight timer
  double? _playingToneHz;
  Timer? _toneHighlightTimer;

  // Customizable target comfort zone
  VoiceTargetRange _targetRange = const VoiceTargetRange();
  bool _showTargetEditor = false;

  // Guided 4-step quiet warm-up state (no microphone)
  Timer? _warmupTimer;
  int _warmupStepIndex = 0;
  int _warmupSecondsLeft = voiceWarmupSteps.first.durationSeconds;
  bool _warmupRunning = false;
  bool _warmupCompleted = false;

  // Saved numeric history
  List<VoiceTestResult> _results = const [];
  bool _savedCurrentSession = false;
  Repo? _repo;
  StreamSubscription<List<VoiceTestResult>>? _voiceSub;

  @override
  void initState() {
    super.initState();
    final rng = math.Random();
    _promptIndex = rng.nextInt(voiceReadingPrompts.length);
    _passageIndex = rng.nextInt(voiceReadingPassages.length);
    _loadResults();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repo = maybeRepoFrom(context);
    if (identical(repo, _repo)) return;
    _repo = repo;
    _voiceSub?.cancel();
    _voiceSub = repo?.voiceResults().listen(_onRemoteResults);
  }

  @override
  void dispose() {
    _voiceSub?.cancel();
    _warmupTimer?.cancel();
    _toneHighlightTimer?.cancel();
    _stopListeningSync();
    _recorder?.dispose();
    super.dispose();
  }

  Future<void> _onRemoteResults(List<VoiceTestResult> remote) async {
    try {
      final repo = _repo;
      final merged = await VoiceStore.reconcileWithRemote(
        remote,
        uploadMissing: repo?.saveVoiceResult,
      );
      if (!mounted) return;
      setState(() => _results = merged);
    } catch (_) {
      // Offline/auth transient error: keep current local history.
    }
  }

  Future<void> _loadResults() async {
    try {
      final list = await VoiceStore.loadResults();
      final target = await VoiceStore.loadTargetRange();
      if (!mounted) return;
      setState(() {
        _results = list;
        _targetRange = target;
      });
    } catch (_) {
      // Ignore storage read errors gracefully.
    }
  }

  Future<void> _setTargetRange(VoiceTargetRange range,
      {bool persist = true}) async {
    setState(() => _targetRange = range);
    if (!persist) return;
    try {
      final saved = await VoiceStore.saveTargetRange(range);
      if (mounted) setState(() => _targetRange = saved);
    } catch (_) {
      // Keep in-memory selection on transient storage errors.
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
      _contourPoints.clear();
      _brightnessSamples.clear();
      _weightSamples.clear();
      _liveHz = null;
      _latestTone = null;
      _selectedContextTag = null;
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
        _contourPoints.add(hz);
        final tone = analyzeVoiceToneFromPcm16(frame, sampleRate: 16000, f0Hz: hz);
        if (tone != null) {
          _brightnessSamples.add(tone.brightnessScore);
          _weightSamples.add(tone.weightScore);
        }
      }
    }
    if (_contourPoints.length > _maxContourPoints) {
      _contourPoints.removeRange(0, _contourPoints.length - _maxContourPoints);
    }

    if (latestHz != null && mounted) {
      VoiceToneAnalysis? smoothedTone;
      if (_brightnessSamples.isNotEmpty) {
        final windowCount = math.min(4, _brightnessSamples.length);
        var bSum = 0.0;
        var wSum = 0.0;
        for (var i = _brightnessSamples.length - windowCount;
            i < _brightnessSamples.length;
            i++) {
          bSum += _brightnessSamples[i];
          wSum += _weightSamples[i];
        }
        smoothedTone = VoiceToneAnalysis(
          brightnessScore: bSum / windowCount,
          weightScore: wSum / windowCount,
        );
      }
      setState(() {
        _liveHz = latestHz;
        _latestTone = smoothedTone ?? _latestTone;
      });
    }
  }

  Future<void> _playReferenceTone(double hz) async {
    HapticFeedback.selectionClick();
    if (_listening) {
      await _stopListening();
    }
    _toneHighlightTimer?.cancel();
    if (mounted) {
      setState(() => _playingToneHz = hz);
    }
    _toneHighlightTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted && _playingToneHz == hz) {
        setState(() => _playingToneHz = null);
      }
    });
    unawaited(playVoiceReferenceTone(hz));
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
      if (_readingMode == 1) {
        _passageIndex = (_passageIndex + 1 + math.Random().nextInt(2)) %
            voiceReadingPassages.length;
      } else {
        _promptIndex = (_promptIndex + 1 + math.Random().nextInt(3)) %
            voiceReadingPrompts.length;
      }
    });
  }

  Future<void> _editCustomPrompt() async {
    final fallback = _readingMode == 1
        ? pickVoicePassage(index: _passageIndex).body
        : pickVoicePrompt(index: _promptIndex);
    final ctrl = TextEditingController(text: _customPrompt ?? fallback);
    final updated = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(tr('Custom reading prompt')),
        content: TextField(
          controller: ctrl,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: tr(
                'Type or paste any comfortable sentence or short paragraph to read aloud...'),
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
      contextTag: _selectedContextTag,
    );
    final updated = await VoiceStore.saveResult(res);
    final syncFuture = _repo?.saveVoiceResult(res);
    if (syncFuture != null) unawaited(syncFuture);
    if (!mounted) return;
    setState(() {
      _results = updated;
      _savedCurrentSession = true;
    });
  }

  Future<void> _deleteResult(String id) async {
    HapticFeedback.selectionClick();
    final updated = await VoiceStore.deleteResult(id);
    final syncFuture = _repo?.deleteVoiceResult(id);
    if (syncFuture != null) unawaited(syncFuture);
    if (!mounted) return;
    setState(() => _results = updated);
  }

  Future<void> _clearAllResults() async {
    HapticFeedback.selectionClick();
    final knownIds = [for (final r in _results) r.id];
    await VoiceStore.clearResults(knownIds: knownIds);
    final syncFuture = _repo?.clearVoiceResults(knownIds: knownIds);
    if (syncFuture != null) unawaited(syncFuture);
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

  void _selectWarmupStep(int index, {bool autoStart = false}) {
    HapticFeedback.selectionClick();
    _warmupTimer?.cancel();
    final clamped = index.clamp(0, voiceWarmupSteps.length - 1);
    setState(() {
      _warmupStepIndex = clamped;
      _warmupSecondsLeft = voiceWarmupSteps[clamped].durationSeconds;
      _warmupCompleted = false;
      _warmupRunning = autoStart;
    });
    if (autoStart) {
      _startWarmupTick();
    }
  }

  void _startWarmupTick() {
    _warmupTimer?.cancel();
    _warmupTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_warmupSecondsLeft > 1) {
        setState(() => _warmupSecondsLeft--);
      } else {
        HapticFeedback.lightImpact();
        if (_warmupStepIndex < voiceWarmupSteps.length - 1) {
          setState(() {
            _warmupStepIndex++;
            _warmupSecondsLeft =
                voiceWarmupSteps[_warmupStepIndex].durationSeconds;
          });
        } else {
          t.cancel();
          setState(() {
            _warmupSecondsLeft = 0;
            _warmupRunning = false;
            _warmupCompleted = true;
          });
        }
      }
    });
  }

  void _toggleWarmupTimer() {
    HapticFeedback.selectionClick();
    if (_warmupCompleted) {
      _selectWarmupStep(0, autoStart: true);
      return;
    }
    if (_warmupRunning) {
      _warmupTimer?.cancel();
      setState(() => _warmupRunning = false);
      return;
    }
    if (_warmupSecondsLeft <= 0) {
      _warmupSecondsLeft = voiceWarmupSteps[_warmupStepIndex].durationSeconds;
    }
    setState(() => _warmupRunning = true);
    _startWarmupTick();
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
    final metrics = computeVoiceSessionMetrics(_samples, _targetRange);
    final passage = pickVoicePassage(index: _passageIndex);
    VoiceToneAnalysis? displayTone;
    if (_listening && _latestTone != null) {
      displayTone = _latestTone;
    } else if (_brightnessSamples.isNotEmpty) {
      final bAvg = _brightnessSamples.reduce((a, b) => a + b) /
          _brightnessSamples.length;
      final wAvg =
          _weightSamples.reduce((a, b) => a + b) / _weightSamples.length;
      displayTone =
          VoiceToneAnalysis(brightnessScore: bAvg, weightScore: wAvg);
    }

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
              // Reading prompt / article passage card
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
                          tooltip: _readingMode == 1
                              ? tr('Shuffle passage')
                              : tr('Shuffle prompt'),
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _SelectableChip(
                          label: tr('Short prompt'),
                          selected: _readingMode == 0,
                          onTap: () => setState(() {
                            _readingMode = 0;
                            _customPrompt = null;
                          }),
                        ),
                        _SelectableChip(
                          label: tr('Article passage'),
                          selected: _readingMode == 1,
                          onTap: () => setState(() {
                            _readingMode = 1;
                            _customPrompt = null;
                          }),
                        ),
                      ],
                    ),
                    gap(10),
                    if (_customPrompt != null)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 155),
                        child: SingleChildScrollView(
                          child: Text(
                            '"$_customPrompt"',
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              height: 1.5,
                            ),
                          ),
                        ),
                      )
                    else if (_readingMode == 1) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _MetaBadge(
                            text: passage.topic,
                            color: C.violet,
                          ),
                          _MetaBadge(
                            text: tr('~{0}s read', [passage.estSeconds]),
                            color: Pastel.mint,
                          ),
                        ],
                      ),
                      gap(8),
                      Text(
                        passage.title,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      gap(6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 165),
                        child: SingleChildScrollView(
                          child: Text(
                            passage.body,
                            style: TextStyle(
                              fontSize: 13.8,
                              color: Pastel.mist.withValues(alpha: 0.92),
                              height: 1.55,
                            ),
                          ),
                        ),
                      ),
                    ] else
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

              // Live pitch meter & contour card
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
                    if (category != null) ...[
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
                      ),
                      gap(4),
                      Text(
                        category.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Pastel.mist.withValues(alpha: 0.85),
                        ),
                      ),
                    ] else
                      Text(
                        _listening
                            ? tr('Speak comfortably at your own pace...')
                            : tr('Press Start when you feel ready'),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Pastel.mist.withValues(alpha: 0.78),
                        ),
                      ),
                    gap(12),
                    _LivePitchContourChart(
                      points: _contourPoints,
                      target: _targetRange,
                    ),
                    gap(10),
                    _PitchGaugeBar(hz: displayHz, target: _targetRange),
                    gap(10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            tr('Target: {0}–{1} Hz', [
                              _targetRange.minHz.round(),
                              _targetRange.maxHz.round(),
                            ]),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Pastel.mint.withValues(alpha: 0.92),
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => setState(
                              () => _showTargetEditor = !_showTargetEditor),
                          icon: Icon(
                            _showTargetEditor
                                ? LucideIcons.chevronUp
                                : LucideIcons.slidersHorizontal,
                            size: 14,
                          ),
                          label: Text(
                            tr('Adjust target'),
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                          ),
                        ),
                      ],
                    ),
                    if (_showTargetEditor) ...[
                      gap(6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: C.midnight.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: C.lavender.withValues(alpha: 0.16)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('Target zone'),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Pastel.mist.withValues(alpha: 0.8),
                              ),
                            ),
                            gap(6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _SelectableChip(
                                  label: tr('Masculine'),
                                  selected: _targetRange ==
                                      VoiceTargetRange.masculine,
                                  color: C.violet,
                                  onTap: () => _setTargetRange(
                                      VoiceTargetRange.masculine),
                                ),
                                _SelectableChip(
                                  label: tr('Neutral pitch'),
                                  selected:
                                      _targetRange == VoiceTargetRange.neutral,
                                  color: Pastel.mint,
                                  onTap: () =>
                                      _setTargetRange(VoiceTargetRange.neutral),
                                ),
                                _SelectableChip(
                                  label: tr('Feminine'),
                                  selected:
                                      _targetRange == VoiceTargetRange.feminine,
                                  color: C.rose,
                                  onTap: () => _setTargetRange(
                                      VoiceTargetRange.feminine),
                                ),
                              ],
                            ),
                            RangeSlider(
                              values: RangeValues(
                                _targetRange.minHz.clamp(80.0, 275.0),
                                _targetRange.maxHz.clamp(85.0, 280.0),
                              ),
                              min: 80,
                              max: 280,
                              divisions: 40,
                              activeColor: Pastel.mint,
                              inactiveColor:
                                  C.lavender.withValues(alpha: 0.22),
                              labels: RangeLabels(
                                '${_targetRange.minHz.round()} Hz',
                                '${_targetRange.maxHz.round()} Hz',
                              ),
                              onChanged: (v) {
                                final minV = v.start;
                                final maxV = math.max(minV + 5.0, v.end);
                                _setTargetRange(
                                  VoiceTargetRange(minHz: minV, maxHz: maxV),
                                  persist: false,
                                );
                              },
                              onChangeEnd: (v) {
                                final minV = v.start;
                                final maxV = math.max(minV + 5.0, v.end);
                                _setTargetRange(
                                  VoiceTargetRange(minHz: minV, maxHz: maxV),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (metrics != null) ...[
                      gap(8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: [
                          _MetaBadge(
                            text: tr('In target: {0}%',
                                [metrics.inTargetPercent.round()]),
                            color: Pastel.mint,
                          ),
                          _MetaBadge(
                            text: tr('Intonation: {0} Hz • {1}', [
                              metrics.spreadHz.round(),
                              metrics.intonationLabel,
                            ]),
                            color: C.lavender,
                          ),
                        ],
                      ),
                    ],
                    gap(12),
                    _ToneBalanceCard(tone: displayTone),
                    gap(12),
                    _ReferenceToneStrip(
                      playingHz: _playingToneHz,
                      onPlay: _playReferenceTone,
                    ),
                    gap(8),
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
                    gap(14),
                    SizedBox(
                      width: double.infinity,
                      child: pillButton(
                        _listening
                            ? tr('Stop voice check')
                            : tr('Start live voice check'),
                        _toggleListening,
                        icon: _listening ? LucideIcons.square : LucideIcons.mic,
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
                      else ...[
                        Text(
                          tr('Session tag (optional)'),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Pastel.mist.withValues(alpha: 0.72),
                          ),
                        ),
                        gap(6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: [
                            for (final tag in voiceContextTags)
                              _SelectableChip(
                                label: tr(tag.$2),
                                selected: _selectedContextTag == tag.$1,
                                color: C.lavender,
                                onTap: () => setState(() =>
                                    _selectedContextTag =
                                        _selectedContextTag == tag.$1
                                            ? null
                                            : tag.$1),
                              ),
                          ],
                        ),
                        gap(12),
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
              if (_results.length >= 2) ...[
                _VoiceTrendChartCard(results: _results, target: _targetRange),
                gap(12),
              ],
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
              // Guided 4-Step SOVTE & Resonance Quiet Warm-up (No-Mic)
              Builder(builder: (_) {
                final step = voiceWarmupSteps[_warmupStepIndex];
                final progress = _warmupCompleted
                    ? 1.0
                    : (_warmupStepIndex + 1) / voiceWarmupSteps.length;
                return AppCard(
                  highlight: true,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _MetaBadge(
                            text: tr('Step {0} of {1}', [
                              _warmupStepIndex + 1,
                              voiceWarmupSteps.length,
                            ]),
                            color: C.lavender,
                          ),
                          Text(
                            '${(progress * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: C.iconDefault,
                            ),
                          ),
                        ],
                      ),
                      gap(10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 5,
                          backgroundColor: C.midnight.withValues(alpha: 0.7),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Pastel.mint),
                        ),
                      ),
                      gap(18),
                      if (_warmupCompleted) ...[
                        const CompanionAvatar(
                          mood: CompanionMood.laugh,
                          size: 78,
                          glowColor: Pastel.mint,
                        ),
                        gap(12),
                        Text(
                          tr('Warm-up complete!'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        gap(8),
                        Text(
                          tr('Your voice is gently warmed up. Switch to Live Voice Test anytime you feel ready.'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Pastel.mist.withValues(alpha: 0.88),
                            height: 1.45,
                          ),
                        ),
                        gap(16),
                        pillButton(
                          tr('Restart routine'),
                          _toggleWarmupTimer,
                          icon: LucideIcons.rotateCcw,
                          color: Pastel.mint,
                        ),
                      ] else ...[
                        iconBadge(LucideIcons.wind, Pastel.mint,
                            size: 50, iconSize: 24),
                        gap(10),
                        Text(
                          '${_warmupSecondsLeft}s',
                          style: display(42, color: Colors.white),
                        ),
                        gap(8),
                        Text(
                          step.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        gap(6),
                        Text(
                          step.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Pastel.mist.withValues(alpha: 0.88),
                            height: 1.45,
                          ),
                        ),
                        gap(12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: C.midnight.withValues(alpha: 0.62),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: C.lavender.withValues(alpha: 0.16)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(LucideIcons.sparkles,
                                  size: 16, color: Pastel.mint),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  step.tip,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Pastel.mist.withValues(alpha: 0.85),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        gap(16),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _warmupStepIndex > 0
                                  ? () => _selectWarmupStep(_warmupStepIndex - 1)
                                  : null,
                              icon: const Icon(LucideIcons.chevronLeft),
                              tooltip: tr('Previous step'),
                            ),
                            Expanded(
                              child: pillButton(
                                _warmupRunning
                                    ? tr('Pause warm-up')
                                    : tr('Start step'),
                                _toggleWarmupTimer,
                                icon: _warmupRunning
                                    ? LucideIcons.pause
                                    : LucideIcons.play,
                                color: C.aurora,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                if (_warmupStepIndex <
                                    voiceWarmupSteps.length - 1) {
                                  _selectWarmupStep(_warmupStepIndex + 1);
                                } else {
                                  HapticFeedback.selectionClick();
                                  _warmupTimer?.cancel();
                                  setState(() {
                                    _warmupRunning = false;
                                    _warmupSecondsLeft = 0;
                                    _warmupCompleted = true;
                                  });
                                }
                              },
                              icon: const Icon(LucideIcons.chevronRight),
                              tooltip: tr('Next step'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              }),
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

class _SelectableChip extends StatelessWidget {
  const _SelectableChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = C.aurora,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.22)
                : C.midnight.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.85)
                  : C.lavender.withValues(alpha: 0.18),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : Pastel.mist.withValues(alpha: 0.78),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _LivePitchContourChart extends StatelessWidget {
  const _LivePitchContourChart({
    required this.points,
    required this.target,
  });

  final List<double> points;
  final VoiceTargetRange target;

  @override
  Widget build(BuildContext context) {
    final snapshot = List<double>.of(points);
    return Container(
      height: 76,
      width: double.infinity,
      decoration: BoxDecoration(
        color: C.midnight.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.lavender.withValues(alpha: 0.16)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _PitchContourPainter(
              points: snapshot,
              target: target,
            ),
          ),
          if (snapshot.isEmpty)
            Center(
              child: Text(
                tr('Live pitch contour'),
                style: TextStyle(
                  fontSize: 11.5,
                  color: Pastel.mist.withValues(alpha: 0.45),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PitchContourPainter extends CustomPainter {
  _PitchContourPainter({
    required this.points,
    required this.target,
  })  : _count = points.length,
        _last = points.isEmpty ? null : points.last;

  final List<double> points;
  final VoiceTargetRange target;
  final int _count;
  final double? _last;

  static const double _minHz = 65.0;
  static const double _maxHz = 290.0;

  double _yFor(double hz, double h) {
    final norm = ((hz - _minHz) / (_maxHz - _minHz)).clamp(0.0, 1.0);
    return (h - 8) - norm * (h - 16);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Target comfort band fill
    final topY = _yFor(target.maxHz, h);
    final bottomY = _yFor(target.minHz, h);
    canvas.drawRect(
      Rect.fromLTRB(0, topY, w, bottomY),
      Paint()..color = Pastel.mint.withValues(alpha: 0.12),
    );
    final targetEdgePaint = Paint()
      ..color = Pastel.mint.withValues(alpha: 0.28)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, topY), Offset(w, topY), targetEdgePaint);
    canvas.drawLine(Offset(0, bottomY), Offset(w, bottomY), targetEdgePaint);

    // Subtle reference lines (100, 180, 240 Hz)
    final guidePaint = Paint()
      ..color = C.lavender.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (final hz in const [100.0, 180.0, 240.0]) {
      final y = _yFor(hz, h);
      canvas.drawLine(Offset(0, y), Offset(w, y), guidePaint);
    }

    if (points.isEmpty) return;

    if (points.length == 1) {
      final pt = Offset(w * 0.5, _yFor(points.first, h));
      canvas.drawCircle(
        pt,
        6,
        Paint()..color = C.aurora.withValues(alpha: 0.35),
      );
      canvas.drawCircle(pt, 3.5, Paint()..color = Colors.white);
      return;
    }

    final offsets = <Offset>[];
    final stepX = (w - 16) / (points.length - 1);
    for (var i = 0; i < points.length; i++) {
      offsets.add(Offset(8 + i * stepX, _yFor(points[i], h)));
    }

    final linePath = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (var i = 0; i < offsets.length - 1; i++) {
      final curr = offsets[i];
      final next = offsets[i + 1];
      final mid = Offset((curr.dx + next.dx) * 0.5, (curr.dy + next.dy) * 0.5);
      linePath.quadraticBezierTo(curr.dx, curr.dy, mid.dx, mid.dy);
    }
    linePath.lineTo(offsets.last.dx, offsets.last.dy);

    final fillPath = Path.from(linePath)
      ..lineTo(offsets.last.dx, h)
      ..lineTo(offsets.first.dx, h)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            C.aurora.withValues(alpha: 0.28),
            C.aurora.withValues(alpha: 0.01),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = C.lavender
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );

    final latest = offsets.last;
    canvas.drawCircle(
      latest,
      6,
      Paint()..color = C.rose.withValues(alpha: 0.36),
    );
    canvas.drawCircle(latest, 3.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _PitchContourPainter old) =>
      old.target != target || old._count != _count || old._last != _last;
}

class _PitchGaugeBar extends StatelessWidget {
  const _PitchGaugeBar({required this.hz, required this.target});

  final double? hz;
  final VoiceTargetRange target;

  @override
  Widget build(BuildContext context) {
    const minScale = 65.0;
    const maxScale = 280.0;
    final norm = hz == null
        ? null
        : ((hz! - minScale) / (maxScale - minScale)).clamp(0.0, 1.0);
    final tMinNorm =
        ((target.minHz - minScale) / (maxScale - minScale)).clamp(0.0, 1.0);
    final tMaxNorm =
        ((target.maxHz - minScale) / (maxScale - minScale)).clamp(0.0, 1.0);

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final bracketLeft = w * tMinNorm;
            final bracketWidth = math.max(4.0, w * (tMaxNorm - tMinNorm));
            return SizedBox(
              height: 20,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: const LinearGradient(
                        colors: [C.aurora, C.violet, Pastel.mint, C.rose, C.coral],
                        stops: [0.10, 0.32, 0.54, 0.78, 0.96],
                      ),
                    ),
                  ),
                  Positioned(
                    left: bracketLeft,
                    width: bracketWidth,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: Pastel.mint.withValues(alpha: 0.16),
                        border: Border.all(
                          color: Pastel.mint.withValues(alpha: 0.72),
                          width: 1.2,
                        ),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('65 Hz',
                style: TextStyle(fontSize: 10.5, color: C.iconDefault)),
            Text(
              '${target.minHz.round()}–${target.maxHz.round()} Hz',
              style: const TextStyle(fontSize: 10.5, color: Pastel.mint),
            ),
            const Text('280 Hz',
                style: TextStyle(fontSize: 10.5, color: C.iconDefault)),
          ],
        ),
      ],
    );
  }
}

class _VoiceTrendChartCard extends StatelessWidget {
  const _VoiceTrendChartCard({required this.results, required this.target});

  final List<VoiceTestResult> results;
  final VoiceTargetRange target;

  @override
  Widget build(BuildContext context) {
    final ordered = results.take(20).toList().reversed.toList();
    if (ordered.length < 2) return const SizedBox.shrink();

    final overallAvg =
        ordered.fold<double>(0, (s, r) => s + r.avgHz) / ordered.length;
    var minSample = ordered.first.minHz;
    var maxSample = ordered.first.maxHz;
    for (final r in ordered) {
      if (r.minHz < minSample) minSample = r.minHz;
      if (r.maxHz > maxSample) maxSample = r.maxHz;
    }
    final minY = math.min(60.0, (minSample - 15.0).clamp(40.0, 200.0));
    final maxY = math.max(290.0, (maxSample + 15.0).clamp(150.0, 380.0));

    final avgSpots = [
      for (var i = 0; i < ordered.length; i++) FlSpot(i.toDouble(), ordered[i].avgHz),
    ];
    final maxSpots = [
      for (var i = 0; i < ordered.length; i++) FlSpot(i.toDouble(), ordered[i].maxHz),
    ];
    final minSpots = [
      for (var i = 0; i < ordered.length; i++) FlSpot(i.toDouble(), ordered[i].minHz),
    ];
    final totalX = (ordered.length - 1).toDouble();

    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.trendingUp, size: 16, color: C.lavender),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr('Progress trend'),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              _MetaBadge(
                text: tr('{0} sessions', [ordered.length]),
                color: C.lavender,
              ),
            ],
          ),
          gap(4),
          Text(
            tr('Overall avg: {0} Hz', [overallAvg.round()]),
            style: TextStyle(
              fontSize: 11.5,
              color: Pastel.mist.withValues(alpha: 0.78),
            ),
          ),
          gap(12),
          SizedBox(
            height: 168,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: totalX,
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: 50,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: C.lavender.withValues(alpha: 0.08),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: 50,
                      getTitlesWidget: (v, _) => Text(
                        '${v.round()}',
                        style: const TextStyle(
                            fontSize: 10.5, color: C.iconDefault),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: math.max(totalX / 3, 1),
                      getTitlesWidget: (v, _) {
                        final idx = v.round().clamp(0, ordered.length - 1);
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat('d MMM', L10n.code)
                                .format(ordered[idx].at),
                            style: const TextStyle(
                                fontSize: 10, color: C.iconDefault),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                rangeAnnotations: RangeAnnotations(
                  horizontalRangeAnnotations: [
                    HorizontalRangeAnnotation(
                      y1: target.minHz,
                      y2: target.maxHz,
                      color: Pastel.mint.withValues(alpha: 0.12),
                    ),
                  ],
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touched) => [
                      for (final s in touched)
                        LineTooltipItem(
                          '${s.y.round()} Hz',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: maxSpots,
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: C.rose.withValues(alpha: 0.40),
                    barWidth: 1.3,
                    dashArray: [4, 4],
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: minSpots,
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: C.violet.withValues(alpha: 0.40),
                    barWidth: 1.3,
                    dashArray: [4, 4],
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: avgSpots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    preventCurveOverShooting: true,
                    color: C.lavender,
                    barWidth: 2.8,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      getDotPainter: (spot, _, __, ___) {
                        final inTarget = target.contains(spot.y);
                        return FlDotCirclePainter(
                          radius: 3.6,
                          color: inTarget ? Pastel.mint : C.lavender,
                          strokeWidth: 1.5,
                          strokeColor: C.midnight,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          C.aurora.withValues(alpha: 0.22),
                          C.aurora.withValues(alpha: 0.01),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          gap(6),
          Text(
            tr('Target zone shaded • Solid line shows session average'),
            style: TextStyle(
              fontSize: 10.5,
              color: Pastel.mist.withValues(alpha: 0.62),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToneBalanceCard extends StatelessWidget {
  const _ToneBalanceCard({required this.tone});

  final VoiceToneAnalysis? tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: C.midnight.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.lavender.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BalanceGaugeBar(
            title: tr('Voice Size / Resonance'),
            valueLabel: tone?.brightnessLabel,
            score: tone?.brightnessScore,
            leftLabel: tr('Warm tone'),
            rightLabel: tr('Bright tone'),
            gradientColors: const [C.violet, Pastel.mint, C.rose],
          ),
          gap(10),
          _BalanceGaugeBar(
            title: tr('Vocal Weight'),
            valueLabel: tone?.weightLabel,
            score: tone?.weightScore,
            leftLabel: tr('Light weight'),
            rightLabel: tr('Heavy weight'),
            gradientColors: const [Pastel.mint, C.lavender, C.coral],
          ),
          gap(8),
          Text(
            tr('Approximate visual guide from your phone mic — resonance & comfort matter most.'),
            style: TextStyle(
              fontSize: 10.8,
              color: Pastel.mist.withValues(alpha: 0.65),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceGaugeBar extends StatelessWidget {
  const _BalanceGaugeBar({
    required this.title,
    required this.valueLabel,
    required this.score,
    required this.leftLabel,
    required this.rightLabel,
    required this.gradientColors,
  });

  final String title;
  final String? valueLabel;
  final double? score;
  final String leftLabel;
  final String rightLabel;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    final norm = score?.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              valueLabel ?? '—',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: valueLabel != null
                    ? C.lavender
                    : Pastel.mist.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        gap(5),
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            return SizedBox(
              height: 14,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(colors: gradientColors),
                    ),
                  ),
                  if (norm != null)
                    Positioned(
                      left: (w - 12) * norm,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: C.aurora, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        gap(2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(leftLabel,
                style: const TextStyle(fontSize: 10, color: C.iconDefault)),
            Text(rightLabel,
                style: const TextStyle(fontSize: 10, color: C.iconDefault)),
          ],
        ),
      ],
    );
  }
}

class _ReferenceToneStrip extends StatelessWidget {
  const _ReferenceToneStrip({
    required this.playingHz,
    required this.onPlay,
  });

  final double? playingHz;
  final ValueChanged<double> onPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: C.midnight.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: C.lavender.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.volume2, size: 15, color: C.lavender),
              const SizedBox(width: 6),
              Text(
                tr('Reference tone'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: C.lavender,
                ),
              ),
            ],
          ),
          gap(3),
          Text(
            tr('Tap a gentle tone as a starting anchor before speaking.'),
            style: TextStyle(
              fontSize: 11,
              color: Pastel.mist.withValues(alpha: 0.68),
            ),
          ),
          gap(8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final tone in voiceReferenceTones)
                _SelectableChip(
                  label: '${tone.hz.round()} Hz • ${tone.label}',
                  selected:
                      playingHz != null && (playingHz! - tone.hz).abs() < 0.5,
                  color: tone.color,
                  onTap: () => onPlay(tone.hz),
                ),
            ],
          ),
        ],
      ),
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
    final tagLabel = voiceContextTagLabel(result.contextTag);
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
                if (tagLabel != null) ...[
                  gap(5),
                  _MetaBadge(text: tagLabel, color: C.lavender),
                ],
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
