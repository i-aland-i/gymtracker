import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../models/exercise.dart';
import '../services/workout_service.dart';
import '../widgets/transitions.dart';
import '../widgets/empty_state.dart';
import '../app_settings.dart';
import 'routine_detail_screen.dart';

class RoutinesScreen extends StatefulWidget {
  const RoutinesScreen({super.key});

  @override
  State<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends State<RoutinesScreen> {
  final _service = WorkoutService();
  List<Routine> _routines = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _service.getRoutines();
    if (mounted) setState(() { _routines = data; _loading = false; });
  }

  void _reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final list = List<Routine>.from(_routines);
    list.insert(newIndex, list.removeAt(oldIndex));
    setState(() => _routines = list);
    _service.updateRoutinePositions(list.map((r) => r.id).toList());
    notifyRoutinesChanged();
  }

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
      final routine = await _service.createRoutine(
        name.trim(),
        position: _routines.length,
      );
      if (mounted) setState(() => _routines = [..._routines, routine]);
      notifyRoutinesChanged();
    }
  }

  Future<void> _deleteRoutine(Routine r) async {
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete workout day?'),
        content: Text(
            '"${r.name}" and all its logged sessions will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.deleteRoutine(r.id);
      if (mounted) {
        final updated = _routines.where((x) => x.id != r.id).toList();
        setState(() => _routines = updated);
        _service.updateRoutinePositions(updated.map((r) => r.id).toList());
        notifyRoutinesChanged();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout Days')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Day'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _routines.isEmpty
              ? const EmptyState(
                  icon: Icons.fitness_center_rounded,
                  title: 'No workout days yet',
                  subtitle: 'Tap "New Day" to create your first workout',
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 96),
                  buildDefaultDragHandles: false,
                  // ignore: deprecated_member_use
                  onReorder: _reorder,
                  itemCount: _routines.length,
                  itemBuilder: (context, i) {
                    final r = _routines[i];
                    return _RoutineCard(
                      key: ValueKey(r.id),
                      routine: r,
                      service: _service,
                      index: i,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          AppPageRoute(
                            builder: (_) => RoutineDetailScreen(routine: r),
                          ),
                        );
                        _load();
                      },
                      onDelete: () => _deleteRoutine(r),
                    );
                  },
                ),
    );
  }
}

// ── Routine card ──────────────────────────────────────────────────────────────

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({
    super.key,
    required this.routine,
    required this.service,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  final Routine routine;
  final WorkoutService service;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            children: [
              // Icon box
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.fitness_center_rounded,
                    color: cs.onPrimaryContainer, size: 22),
              ),
              const SizedBox(width: 14),
              // Name + exercise preview
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(routine.name, style: t.titleMedium),
                    const SizedBox(height: 4),
                    FutureBuilder<List<Exercise>>(
                      future: service.getRoutineExercises(routine.id),
                      builder: (context, snap) {
                        if (!snap.hasData || snap.data!.isEmpty) {
                          return Text(
                            'No movements yet',
                            style: t.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          );
                        }
                        final names =
                            snap.data!.map((e) => e.name).toList();
                        final preview = names.length > 3
                            ? '${names.take(3).join(' · ')}  +${names.length - 3}'
                            : names.join(' · ');
                        return Text(
                          preview,
                          style: t.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Delete
              IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    size: 20, color: cs.error),
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
              ),
              // Drag handle
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.drag_handle_rounded,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
