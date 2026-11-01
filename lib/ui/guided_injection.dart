import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n.dart';
import '../models.dart';
import '../repo.dart';
import '../schedule.dart';
import '../theme.dart';

/// Modal interaktif "Guided Calm Injection" yang memandu proses penyuntikan mandiri
/// langkah demi langkah dengan teknik pernapasan, timer desinfeksi, dan afirmasi yang menenangkan.
class CalmInjectionSheet extends ConsumerStatefulWidget {
  const CalmInjectionSheet({
    super.key,
    required this.t,
    this.slot,
    required this.supplies,
    required this.prefs,
    required this.suggestedPlace,
  });

  final Therapy t;
  final Slot? slot;
  final List<Supply> supplies;
  final Prefs prefs;
  final String suggestedPlace;

  @override
  ConsumerState<CalmInjectionSheet> createState() => _CalmInjectionSheetState();
}

class _CalmInjectionSheetState extends ConsumerState<CalmInjectionSheet>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0; // 0: Breath, 1: Desinfeksi (Timer 30s), 2: Suntik, 3: Selesai

  // Timer untuk jeda pengeringan alkohol (30 detik)
  int _secondsLeft = 30;
  Timer? _dryingTimer;
  bool _timerRunning = false;

  // Animasi napas terpandu
  late AnimationController _breatheController;
  late Animation<double> _breatheAnimation;

  late String _selectedPlace;
  late String _injType;

  @override
  void initState() {
    super.initState();
    _selectedPlace = widget.suggestedPlace.isNotEmpty
        ? widget.suggestedPlace
        : (widget.prefs.places.isNotEmpty ? widget.prefs.places.first : 'Right thigh');
    _injType = widget.t.route == 'inj' ? 'im' : 'sc';

    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _breatheAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _dryingTimer?.cancel();
    _breatheController.dispose();
    super.dispose();
  }

  void _startDryingTimer() {
    _dryingTimer?.cancel();
    setState(() {
      _secondsLeft = 30;
      _timerRunning = true;
    });

    _dryingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft > 1) {
        setState(() => _secondsLeft--);
      } else {
        timer.cancel();
        setState(() {
          _secondsLeft = 0;
          _timerRunning = false;
        });
        HapticFeedback.mediumImpact();
      }
    });
  }

  void _completeAndLog() {
    final t = widget.t;
    final now = DateTime.now();

    // Potong 1 unit dari perlengkapan terkait
    final usage = <String, double>{};
    for (final s in widget.supplies) {
      if (!s.generic && s.id == t.supplyId) {
        usage[s.id] = s.perDose;
      } else if (s.generic && (s.gtype == 'syringe' || s.gtype == 'needle' || s.gtype == 'wipe')) {
        usage[s.id] = 1.0;
      }
    }

    final log = DoseLog(
      id: '',
      therapyId: t.id,
      at: now,
      dose: t.dose,
      places: [_selectedPlace],
      injType: _injType,
      slot: widget.slot == null ? null : slotKey(widget.slot!.at),
      used: usage,
    );

    ref.read(repoProvider)?.logDose(log);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr('Injection complete! Logged to history and site rotation updated.'),
        ),
        backgroundColor: C.peony,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? C.deepCard : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: dark ? Border.all(color: Colors.white.withValues(alpha: 0.12)) : null,
      ),
      padding: EdgeInsets.fromLTRB(
        22,
        18,
        22,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag indicator
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          gap(14),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: C.peony.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.self_improvement_rounded, color: C.peony, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('Guided Calm Injection'), style: display(18)),
                    Text(
                      tr('Step {0} of 4 • {1}', [_currentStep + 1, widget.t.name]),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
          ),
          gap(14),

          // Step Progress Bar
          Row(
            children: [
              for (int i = 0; i < 4; i++)
                Expanded(
                  child: Container(
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i <= _currentStep
                          ? C.peony
                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
            ],
          ),
          gap(20),

          // Active Step Content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _buildStepContent(),
          ),
          gap(22),

          // Navigation buttons
          Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: () => setState(() => _currentStep--),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(tr('Back')),
                  ),
                ),
              if (_currentStep > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: () {
                    if (_currentStep < 3) {
                      setState(() => _currentStep++);
                      if (_currentStep == 1 && !_timerRunning && _secondsLeft == 30) {
                        _startDryingTimer();
                      }
                    } else {
                      _completeAndLog();
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: C.peony,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    _currentStep == 3 ? tr('Complete & Log Dose') : tr('Continue'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Breathing();
      case 1:
        return _buildStep2Drying();
      case 2:
        return _buildStep3Technique();
      case 3:
      default:
        return _buildStep4Complete();
    }
  }

  Widget _buildStep1Breathing() {
    return Column(
      key: const ValueKey(0),
      children: [
        Center(
          child: ScaleTransition(
            scale: _breatheAnimation,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    C.peony.withValues(alpha: 0.35),
                    C.peony.withValues(alpha: 0.08),
                  ],
                ),
              ),
              child: Center(
                child: Icon(Icons.spa_rounded, color: C.peony, size: 44),
              ),
            ),
          ),
        ),
        gap(18),
        Text(
          tr('Breathe In & Ground Yourself'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        gap(6),
        Text(
          tr('You are in a safe, unhurried space. Relax your shoulders, unclamp your jaw, and take a slow breath. You are in total control of your pace.'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
          ),
        ),
        gap(16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: C.peony.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.place_rounded, color: C.peony, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('Suggested Injection Site'),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                    Text(
                      tr(_selectedPlace),
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep2Drying() {
    return Column(
      key: const ValueKey(1),
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _secondsLeft == 0
                ? C.lagoon.withValues(alpha: 0.22)
                : C.amber.withValues(alpha: 0.15),
          ),
          child: Center(
            child: _secondsLeft == 0
                ? Icon(Icons.check_circle_rounded, color: C.lagoon, size: 52)
                : Text(
                    '$_secondsLeft',
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: C.amber,
                    ),
                  ),
          ),
        ),
        gap(16),
        Text(
          _secondsLeft == 0 ? tr('Alcohol is Dry!') : tr('Wait for Alcohol to Dry'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        gap(6),
        Text(
          tr('Swab the skin with an alcohol wipe in a firm, circular motion. Waiting 30 seconds for it to air-dry completely prevents stinging and irritation!'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
          ),
        ),
        gap(14),
        if (!_timerRunning && _secondsLeft > 0)
          OutlinedButton.icon(
            onPressed: _startDryingTimer,
            icon: const Icon(Icons.timer_outlined, size: 18),
            label: Text(tr('Start 30s Timer')),
          )
        else if (_timerRunning)
          Text(
            tr('Letting it air-dry naturally...'),
            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
          ),
      ],
    );
  }

  Widget _buildStep3Technique() {
    return Column(
      key: const ValueKey(2),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChoiceChip(
              label: Text(tr('Intramuscular (90°)')),
              selected: _injType == 'im',
              onSelected: (_) => setState(() => _injType = 'im'),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text(tr('Subcutaneous (45°)')),
              selected: _injType == 'sc',
              onSelected: (_) => setState(() => _injType = 'sc'),
            ),
          ],
        ),
        gap(14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.tips_and_updates_rounded, color: C.amber, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _injType == 'im'
                          ? tr('Relax the Target Muscle')
                          : tr('Gently Pinch the Skin Fold'),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ],
              ),
              gap(8),
              Text(
                _injType == 'im'
                    ? tr('Do not put weight on the leg you are injecting. Insert needle smoothly at a 90° angle. Push the plunger slowly (about 10 seconds per mL) for minimal pressure.')
                    : tr('Pinch a 2-3 cm fold of fatty tissue. Insert needle at a 45° to 90° angle smoothly. Inject slowly, then release the skin fold.'),
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep4Complete() {
    return Column(
      key: const ValueKey(3),
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: C.peony.withValues(alpha: 0.16),
          ),
          child: Icon(Icons.favorite_rounded, color: C.peony, size: 46),
        ),
        gap(16),
        Text(
          tr('You Did It! ✦'),
          textAlign: TextAlign.center,
          style: display(20),
        ),
        gap(6),
        Text(
          tr('Withdraw needle gently, apply light pressure with cotton or a bandage. Safely place the used needle into your sharps container.'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
          ),
        ),
        gap(14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: C.peony.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${fmt(widget.t.dose)} ${widget.t.doseUnit} • ${tr(_selectedPlace)}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
