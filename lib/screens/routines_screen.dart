import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../services/workout_service.dart';
import '../widgets/transitions.dart';
import '../widgets/empty_state.dart';
import 'routine_detail_screen.dart';

class RoutinesScreen extends StatefulWidget {
  const RoutinesScreen({super.key});

  @override
  State<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends State<RoutinesScreen> {
  final _service = WorkoutService();
  late Future<List<Routine>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getRoutines();
  }

  void _refresh() => setState(() => _future = _service.getRoutines());

  Future<void> _addDialog() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New workout day'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g. Push Day, Leg Day…',
            prefixIcon: Icon(Icons.fitness_center_rounded),
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null && name.trim().isNotEmpty) {
      await _service.createRoutine(name.trim());
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Workout Days')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Day'),
      ),
      body: FutureBuilder<List<Routine>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final routines = snap.data!;
          if (routines.isEmpty) {
            return const EmptyState(
              icon: Icons.fitness_center_rounded,
              title: 'No workout days yet',
              subtitle: 'Tap "New Day" to create your first workout',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 96),
            itemCount: routines.length,
            itemBuilder: (context, i) {
              final r = routines[i];
              return Card(
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    AppPageRoute(
                      builder: (_) => RoutineDetailScreen(routine: r),
                    ),
                  ),
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
                            borderRadius: BorderRadius.circular(12),
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
                        Icon(
                          Icons.chevron_right_rounded,
                          color: cs.onSurfaceVariant,
                        ),
                      ],
                    ),
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
