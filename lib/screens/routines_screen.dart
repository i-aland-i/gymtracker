import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../services/workout_service.dart';
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
          decoration: const InputDecoration(hintText: 'e.g. Push Day'),
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
    if (name != null && name.trim().isNotEmpty) {
      await _service.createRoutine(name.trim());
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout Days')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDialog,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Routine>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final routines = snap.data!;
          if (routines.isEmpty) {
            return const Center(child: Text('No workout days yet'));
          }
          return ListView(
            children: routines
                .map(
                  (r) => ListTile(
                    title: Text(r.name),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RoutineDetailScreen(routine: r),
                      ),
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}
