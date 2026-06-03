import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../models/exercise.dart';
import '../services/workout_service.dart';
import '../widgets/empty_state.dart';

class RoutineDetailScreen extends StatefulWidget {
  final Routine routine;
  const RoutineDetailScreen({super.key, required this.routine});

  @override
  State<RoutineDetailScreen> createState() => _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends State<RoutineDetailScreen> {
  final _service = WorkoutService();
  late Future<List<Exercise>> _future;
  List<Exercise> _movements = [];

  @override
  void initState() {
    super.initState();
    _future = _service.getRoutineExercises(widget.routine.id);
  }

  void _refresh() =>
      setState(() => _future = _service.getRoutineExercises(widget.routine.id));

  Future<void> _addExisting(Exercise exercise, int position) async {
    await _service.addExerciseToRoutine(
        widget.routine.id, exercise.id, position);
    if (mounted) Navigator.pop(context);
    _refresh();
  }

  Future<void> _createAndAdd(
      String name, String? muscleGroup, int position) async {
    final exercise = await _service.createExercise(name, muscleGroup: muscleGroup);
    await _service.addExerciseToRoutine(
        widget.routine.id, exercise.id, position);
    if (mounted) Navigator.pop(context);
    _refresh();
  }

  Future<void> _openAddSheet(int nextPosition, List<Exercise> alreadyIn) async {
    final existingIds = alreadyIn.map((e) => e.id).toSet();
    final nameCtrl = TextEditingController();
    final muscleCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create new movement',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'e.g. Bench Press',
                  prefixIcon: Icon(Icons.fitness_center_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofocus: true,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: muscleCtrl,
                decoration: const InputDecoration(
                  hintText: 'Muscle group (optional)',
                  prefixIcon: Icon(Icons.label_outline_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create & add'),
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    final muscle = muscleCtrl.text.trim();
                    _createAndAdd(name, muscle.isEmpty ? null : muscle,
                        nextPosition);
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or pick existing',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<Exercise>>(
                future: _service.getExercises(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final catalog = snap.data!
                      .where((e) => !existingIds.contains(e.id))
                      .toList();
                  if (catalog.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Nothing else in your catalog yet.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: catalog.map((e) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(e.name),
                        subtitle: e.muscleGroup != null
                            ? Text(e.muscleGroup!)
                            : null,
                        trailing: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            size: 18,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                        onTap: () => _addExisting(e, nextPosition),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.routine.name)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSheet(_movements.length, _movements),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add movement'),
      ),
      body: FutureBuilder<List<Exercise>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          _movements = snap.data!;
          if (_movements.isEmpty) {
            return const EmptyState(
              icon: Icons.bolt_rounded,
              title: 'No movements yet',
              subtitle: 'Tap "Add movement" to build this workout',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 96),
            itemCount: _movements.length,
            itemBuilder: (context, i) {
              final e = _movements[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: t.labelLarge?.copyWith(
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.name, style: t.titleSmall),
                            if (e.muscleGroup != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                e.muscleGroup!,
                                style: t.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
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
            },
          );
        },
      ),
    );
  }
}
