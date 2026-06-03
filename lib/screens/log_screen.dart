import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../models/exercise.dart';
import '../models/session.dart';
import '../models/workout_set.dart';
import '../services/workout_service.dart';

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

  String get _today {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  // Reuse today's session for this routine if one exists, else start a new one.
  Future<void> _start(Routine routine) async {
    setState(() => _starting = true);
    final today = DateTime.now();
    final existing = (await _service.getSessionsForDate(
      today,
    )).where((s) => s.routineId == routine.id).toList();
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

  Widget _buildPicker() {
    return Scaffold(
      appBar: AppBar(title: Text('Log — $_today')),
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
                  return const Center(
                    child: Text('Create a workout day first (Days tab)'),
                  );
                }
                return ListView(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Pick a workout day to log'),
                    ),
                    ...routines.map(
                      (r) => ListTile(
                        title: Text(r.name),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _start(r),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildLogger() {
    final session = _session!;
    final routine = _routine!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _finish,
        ),
        title: Text(routine.name),
      ),
      body: FutureBuilder<List<Exercise>>(
        future: _service.getRoutineExercises(routine.id),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final movements = snap.data!;
          if (movements.isEmpty) {
            return const Center(
              child: Text(
                'No movements in this day — add some in the Days tab',
              ),
            );
          }
          return ListView(
            children: movements
                .map(
                  (e) => _MovementLogTile(
                    key: ValueKey(e.id),
                    service: _service,
                    session: session,
                    exercise: e,
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

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
  final _repsController = TextEditingController();
  final _weightController = TextEditingController();
  List<WorkoutSet> _sets = [];

  @override
  void initState() {
    super.initState();
    _setsFuture = widget.service.getSets(widget.session.id, widget.exercise.id);
    _lastFuture = widget.service.lastTime(
      widget.exercise.id,
      excludeSessionId: widget.session.id,
    );
  }

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _reloadSets() => setState(() {
    _setsFuture = widget.service.getSets(widget.session.id, widget.exercise.id);
  });

  Future<void> _addSet() async {
    final reps = int.tryParse(_repsController.text.trim());
    final weight = num.tryParse(_weightController.text.trim());
    if (reps == null || reps <= 0 || weight == null || weight < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter reps and weight')));
      return;
    }
    await widget.service.logSet(
      sessionId: widget.session.id,
      exerciseId: widget.exercise.id,
      reps: reps,
      weight: weight,
      setNumber: _sets.length + 1,
    );
    _reloadSets();
  }

  // Drop a trailing ".0" so 60.0 shows as 60 but 62.5 stays 62.5.
  String _w(num w) => w % 1 == 0 ? w.toInt().toString() : w.toString();

  String _format(List<WorkoutSet> sets) =>
      sets.map((s) => '${_w(s.weight)}kg × ${s.reps}').join(',  ');

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.exercise.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            // Last time line — the defining feature.
            FutureBuilder<List<WorkoutSet>>(
              future: _lastFuture,
              builder: (context, snap) {
                if (!snap.hasData) return const SizedBox(height: 16);
                final last = snap.data!;
                final text = last.isEmpty
                    ? 'Last time: no previous data'
                    : 'Last time: ${_format(last)}';
                return Text(
                  text,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            // Sets logged this session.
            FutureBuilder<List<WorkoutSet>>(
              future: _setsFuture,
              builder: (context, snap) {
                if (!snap.hasData) return const SizedBox.shrink();
                _sets = snap.data!;
                if (_sets.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _sets
                      .asMap()
                      .entries
                      .map(
                        (entry) => Text(
                          'Set ${entry.value.setNumber ?? entry.key + 1}:  '
                          '${_w(entry.value.weight)}kg × ${entry.value.reps} reps',
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 8),
            // Reps quick-pick 1-6.
            Wrap(
              spacing: 6,
              children: List.generate(6, (i) {
                final n = i + 1;
                return ActionChip(
                  label: Text('$n'),
                  onPressed: () => _repsController.text = '$n',
                );
              }),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _repsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Reps',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Weight (kg)',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _addSet, child: const Text('Add')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
