import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../models/exercise.dart';
import '../models/session.dart';
import '../models/workout_set.dart';
import '../services/workout_service.dart';
import '../widgets/empty_state.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  final _service = WorkoutService();
  Session? _session;
  Routine? _routine;
  bool _starting = false;

  static String _todayRaw() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  static String _todayLabel() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final d = DateTime.now();
    return '${days[d.weekday - 1]} · ${months[d.month - 1]} ${d.day}';
  }

  Future<void> _start(Routine routine) async {
    setState(() => _starting = true);
    final today = DateTime.now();
    final existing = (await _service.getSessionsForDate(today))
        .where((s) => s.routineId == routine.id)
        .toList();
    final session = existing.isNotEmpty
        ? existing.first
        : await _service.startSession(routine.id, today);
    if (!mounted) return;
    setState(() {
      _session = session;
      _routine = routine;
      _starting = false;
    });
  }

  void _finish() => setState(() {
        _session = null;
        _routine = null;
      });

  @override
  Widget build(BuildContext context) {
    if (_session == null) return _buildPicker();
    return _buildLogger();
  }

  // ── Routine picker ──────────────────────────────────────────────────────

  Widget _buildPicker() {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Log workout'),
            Text(
              _todayRaw(),
              style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
      body: _starting
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Routine>>(
              future: _service.getRoutines(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final routines = snap.data!;
                if (routines.isEmpty) {
                  return const EmptyState(
                    icon: Icons.fitness_center_rounded,
                    title: 'No workout days yet',
                    subtitle: 'Create a workout day in the Days tab first',
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                      child: Text(
                        'Pick a workout to start',
                        style: t.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 4, bottom: 20),
                        itemCount: routines.length,
                        itemBuilder: (context, i) {
                          final r = routines[i];
                          return Card(
                            child: InkWell(
                              onTap: () => _start(r),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: cs.primaryContainer,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.fitness_center_rounded,
                                        color: cs.onPrimaryContainer,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(r.name, style: t.titleMedium),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: cs.primary,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'Start',
                                        style: t.labelMedium?.copyWith(
                                          color: cs.onPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  // ── Active session logger ───────────────────────────────────────────────

  Widget _buildLogger() {
    final session = _session!;
    final routine = _routine!;
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _finish,
        ),
        title: Text(routine.name),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.tonal(
              onPressed: _finish,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
              child: const Text('Finish'),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Exercise>>(
        future: _service.getRoutineExercises(routine.id),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final movements = snap.data!;
          if (movements.isEmpty) {
            return EmptyState(
              icon: Icons.bolt_rounded,
              title: 'No movements',
              subtitle:
                  'Add movements to "${routine.name}" in the Days tab first',
            );
          }
          return ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 32),
            children: movements
                .map((e) => _MovementLogTile(
                      key: ValueKey(e.id),
                      service: _service,
                      session: session,
                      exercise: e,
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}

// ── Movement tile ─────────────────────────────────────────────────────────────

class _MovementLogTile extends StatefulWidget {
  final WorkoutService service;
  final Session session;
  final Exercise exercise;

  const _MovementLogTile({
    super.key,
    required this.service,
    required this.session,
    required this.exercise,
  });

  @override
  State<_MovementLogTile> createState() => _MovementLogTileState();
}

class _MovementLogTileState extends State<_MovementLogTile> {
  late Future<List<WorkoutSet>> _setsFuture;
  late Future<List<WorkoutSet>> _lastFuture;
  final _repsCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  List<WorkoutSet> _sets = [];
  int? _selectedReps;

  @override
  void initState() {
    super.initState();
    _setsFuture =
        widget.service.getSets(widget.session.id, widget.exercise.id);
    _lastFuture = widget.service.lastTime(
      widget.exercise.id,
      excludeSessionId: widget.session.id,
    );
  }

  @override
  void dispose() {
    _repsCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  void _reloadSets() => setState(
      () => _setsFuture =
          widget.service.getSets(widget.session.id, widget.exercise.id));

  Future<void> _addSet() async {
    final reps = int.tryParse(_repsCtrl.text.trim());
    final weight = num.tryParse(_weightCtrl.text.trim());
    if (reps == null || reps <= 0 || weight == null || weight < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid reps and weight')),
      );
      return;
    }
    await widget.service.logSet(
      sessionId: widget.session.id,
      exerciseId: widget.exercise.id,
      reps: reps,
      weight: weight,
      setNumber: _sets.length + 1,
    );
    setState(() => _selectedReps = null);
    _repsCtrl.clear();
    _weightCtrl.clear();
    _reloadSets();
  }

  String _w(num w) => w % 1 == 0 ? w.toInt().toString() : w.toString();

  String _formatSets(List<WorkoutSet> sets) =>
      sets.map((s) => '${_w(s.weight)} kg × ${s.reps}').join('  ·  ');

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: name + muscle badge ────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(widget.exercise.name, style: t.titleMedium),
                ),
                if (widget.exercise.muscleGroup != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.exercise.muscleGroup!,
                      style: t.labelSmall
                          ?.copyWith(color: cs.onSecondaryContainer),
                    ),
                  ),
                ],
              ],
            ),

            // ── Last session ───────────────────────────────────────────
            FutureBuilder<List<WorkoutSet>>(
              future: _lastFuture,
              builder: (context, snap) {
                if (!snap.hasData || snap.data!.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.history_rounded,
                            size: 14, color: cs.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Last: ${_formatSets(snap.data!)}',
                            style: t.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // ── Sets logged this session ───────────────────────────────
            FutureBuilder<List<WorkoutSet>>(
              future: _setsFuture,
              builder: (context, snap) {
                if (!snap.hasData) return const SizedBox.shrink();
                _sets = snap.data!;
                if (_sets.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    children: _sets.asMap().entries.map((e) {
                      final i = e.key;
                      final s = e.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color:
                                    cs.primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${s.setNumber ?? i + 1}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: cs.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${_w(s.weight)} kg  ×  ${s.reps} reps',
                              style: t.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),

            // ── Divider ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, color: cs.outlineVariant),
            ),

            // ── Quick reps ─────────────────────────────────────────────
            Row(
              children: [
                Text(
                  'Reps',
                  style: t.labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(width: 10),
                Wrap(
                  spacing: 5,
                  children: List.generate(6, (i) {
                    final n = i + 1;
                    return ChoiceChip(
                      label: Text('$n'),
                      selected: _selectedReps == n,
                      onSelected: (_) => setState(() {
                        _selectedReps = n;
                        _repsCtrl.text = '$n';
                      }),
                      visualDensity: VisualDensity.compact,
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Input row ──────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _repsCtrl,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: 'Reps',
                      prefixIcon: Icon(Icons.repeat_rounded, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _weightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addSet(),
                    decoration: const InputDecoration(
                      hintText: 'Weight (kg)',
                      prefixIcon:
                          Icon(Icons.monitor_weight_outlined, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _addSet,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
