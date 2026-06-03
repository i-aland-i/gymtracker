import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../models/exercise.dart';
import '../services/workout_service.dart';

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

  // Add an existing catalog exercise to this routine.
  Future<void> _addExisting(Exercise exercise, int position) async {
    await _service.addExerciseToRoutine(
      widget.routine.id,
      exercise.id,
      position,
    );
    if (mounted) Navigator.pop(context);
    _refresh();
  }

  // Create a brand-new exercise, then add it to this routine.
  Future<void> _createAndAdd(
    String name,
    String? muscleGroup,
    int position,
  ) async {
    final exercise = await _service.createExercise(
      name,
      muscleGroup: muscleGroup,
    );
    await _service.addExerciseToRoutine(
      widget.routine.id,
      exercise.id,
      position,
    );
    if (mounted) Navigator.pop(context);
    _refresh();
  }

  Future<void> _openAddSheet(int nextPosition, List<Exercise> alreadyIn) async {
    final existingIds = alreadyIn.map((e) => e.id).toSet();
    final nameController = TextEditingController();
    final muscleController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create new movement',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'e.g. Bench Press'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: muscleController,
                decoration: const InputDecoration(
                  hintText: 'Muscle group (optional)',
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    final muscle = muscleController.text.trim();
                    _createAndAdd(
                      name,
                      muscle.isEmpty ? null : muscle,
                      nextPosition,
                    );
                  },
                  child: const Text('Create & add'),
                ),
              ),
              const Divider(height: 32),
              const Text(
                'Or pick from your movements',
                style: TextStyle(fontWeight: FontWeight.bold),
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
                  // Hide movements already in this routine.
                  final catalog = snap.data!
                      .where((e) => !existingIds.contains(e.id))
                      .toList();
                  if (catalog.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Nothing else in your catalog yet'),
                    );
                  }
                  return Column(
                    children: catalog
                        .map(
                          (e) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(e.name),
                            subtitle: e.muscleGroup == null
                                ? null
                                : Text(e.muscleGroup!),
                            trailing: const Icon(Icons.add),
                            onTap: () => _addExisting(e, nextPosition),
                          ),
                        )
                        .toList(),
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.routine.name)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddSheet(_movements.length, _movements),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Exercise>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          _movements = snap.data!;
          if (_movements.isEmpty) {
            return const Center(child: Text('No movements yet — tap + to add'));
          }
          return ListView.builder(
            itemCount: _movements.length,
            itemBuilder: (context, i) {
              final e = _movements[i];
              return ListTile(
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(e.name),
                subtitle: e.muscleGroup == null ? null : Text(e.muscleGroup!),
              );
            },
          );
        },
      ),
    );
  }
}
