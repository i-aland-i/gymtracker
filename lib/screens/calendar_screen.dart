import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../models/workout_set.dart';
import '../services/workout_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _service = WorkoutService();
  DateTime _selected = DateTime.now();
  late Future<List<_SessionView>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load(_selected);
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String _w(num w) => w % 1 == 0 ? w.toInt().toString() : w.toString();

  // Read-only aggregation of everything done on a given date.
  Future<List<_SessionView>> _load(DateTime date) async {
    final sessions = await _service.getSessionsForDate(date);
    if (sessions.isEmpty) return [];
    final routines = await _service.getRoutines();
    final nameById = {for (final r in routines) r.id: r.name};

    final views = <_SessionView>[];
    for (final s in sessions) {
      final exercises = s.routineId == null
          ? <Exercise>[]
          : await _service.getRoutineExercises(s.routineId!);
      final entries = <_ExerciseView>[];
      for (final e in exercises) {
        final sets = await _service.getSets(s.id, e.id);
        if (sets.isNotEmpty) entries.add(_ExerciseView(e.name, sets));
      }
      views.add(_SessionView(nameById[s.routineId] ?? 'Workout', entries));
    }
    return views;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selected,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selected = picked;
        _future = _load(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _fmtDate(_selected),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Pick date'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<_SessionView>>(
              future: _future,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final sessions = snap.data!;
                if (sessions.isEmpty) {
                  return Center(
                    child: Text('Nothing logged on ${_fmtDate(_selected)}'),
                  );
                }
                return ListView(
                  children: sessions.map((sv) {
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sv.routineName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (sv.exercises.isEmpty)
                              const Text('No sets logged')
                            else
                              ...sv.exercises.map(
                                (ev) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '${ev.name}:  '
                                    '${ev.sets.map((s) => '${_w(s.weight)}kg × ${s.reps}').join(',  ')}',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionView {
  final String routineName;
  final List<_ExerciseView> exercises;
  _SessionView(this.routineName, this.exercises);
}

class _ExerciseView {
  final String name;
  final List<WorkoutSet> sets;
  _ExerciseView(this.name, this.sets);
}
