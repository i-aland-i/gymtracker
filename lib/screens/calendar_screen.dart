import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../models/workout_set.dart';
import '../services/workout_service.dart';
import '../widgets/empty_state.dart';

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

  void _selectDate(DateTime d) {
    final next = _load(d);
    setState(() { _selected = d; _future = next; });
  }

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
        if (sets.isNotEmpty) entries.add(_ExerciseView(e.name, e.muscleGroup, sets));
      }
      views.add(_SessionView(
        sessionId: s.id,
        routineName: nameById[s.routineId] ?? 'Workout',
        exercises: entries,
      ));
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
    if (picked != null) _selectDate(picked);
  }

  Future<void> _deleteSession(_SessionView sv) async {
    final ctrl = TextEditingController();
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Delete this session?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'All sets logged for "${sv.routineName}" on this day will be permanently deleted.',
                style: t.bodyMedium,
              ),
              const SizedBox(height: 20),
              Text('Type DELETE to confirm',
                  style: t.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 8),
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'DELETE'),
                onChanged: (_) => setDlg(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: cs.error, foregroundColor: cs.onError),
              onPressed: ctrl.text == 'DELETE'
                  ? () => Navigator.pop(ctx, true)
                  : null,
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );

    ctrl.dispose();
    if (confirmed == true) {
      await _service.deleteSession(sv.sessionId);
      _selectDate(_selected);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String get _dateLabel {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
    ];
    final d = _selected;
    if (_isSameDay(d, DateTime.now())) return 'Today';
    if (_isSameDay(d, DateTime.now().subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  String get _dateSubLabel {
    final d = _selected;
    return '${d.day.toString().padLeft(2, '0')} / '
        '${d.month.toString().padLeft(2, '0')} / ${d.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool get _canGoForward =>
      !_isSameDay(_selected, DateTime.now()) &&
      _selected.isBefore(DateTime.now());

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Date navigation ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: () => _selectDate(
                        _selected.subtract(const Duration(days: 1))),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(_dateLabel,
                            style: t.titleLarge,
                            textAlign: TextAlign.center),
                        Text(_dateSubLabel,
                            style: t.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: _canGoForward
                        ? () => _selectDate(
                            _selected.add(const Duration(days: 1)))
                        : null,
                  ),
                ],
              ),
            ),

            // ── Date picker ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month_rounded, size: 18),
                label: const Text('Pick a date'),
              ),
            ),

            const Divider(height: 20),

            // ── Content ────────────────────────────────────────────────
            Expanded(
              child: FutureBuilder<List<_SessionView>>(
                future: _future,
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final sessions = snap.data!;
                  if (sessions.isEmpty) {
                    return EmptyState(
                      icon: Icons.event_busy_rounded,
                      title: 'Rest day',
                      subtitle: 'No workout logged for $_dateLabel',
                    );
                  }
                  // One session per day
                  final sv = sessions.first;
                  return _SessionDetail(
                    sv: sv,
                    onDelete: () => _deleteSession(sv),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Session detail ────────────────────────────────────────────────────────────

class _SessionDetail extends StatelessWidget {
  const _SessionDetail({required this.sv, required this.onDelete});

  final _SessionView sv;
  final VoidCallback onDelete;

  static String _fmt(num w) =>
      w % 1 == 0 ? w.toInt().toString() : w.toStringAsFixed(1);

  static String _fmtVolume(num v) {
    if (v >= 1000) {
      final k = v / 1000;
      return '${k % 1 == 0 ? k.toInt() : k.toStringAsFixed(1)}k kg';
    }
    return '${_fmt(v)} kg';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final totalSets = sv.exercises.fold(0, (s, e) => s + e.sets.length);
    final totalVolume =
        sv.exercises.fold<num>(0, (s, e) => s + e.totalVolume);

    return CustomScrollView(
      slivers: [
        // ── Session banner ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.fitness_center_rounded,
                          color: cs.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(sv.routineName,
                          style: t.headlineSmall?.copyWith(
                              color: cs.onPrimaryContainer)),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded,
                          color: cs.onPrimaryContainer.withValues(alpha: 0.6),
                          size: 20),
                      onPressed: onDelete,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                if (sv.exercises.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.list_alt_rounded,
                        label: '${sv.exercises.length} exercises',
                        cs: cs,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        icon: Icons.repeat_rounded,
                        label: '$totalSets sets',
                        cs: cs,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        icon: Icons.monitor_weight_outlined,
                        label: _fmtVolume(totalVolume),
                        cs: cs,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),

        // ── Exercise sections ──────────────────────────────────────────
        if (sv.exercises.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('No sets were logged.',
                  style: t.bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant)),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) =>
                  _ExerciseSection(ev: sv.exercises[i], fmt: _fmt),
              childCount: sv.exercises.length,
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

// ── Stat chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip(
      {required this.icon, required this.label, required this.cs});

  final IconData icon;
  final String label;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: cs.primary),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.primary,
              )),
        ],
      ),
    );
  }
}

// ── Exercise section ──────────────────────────────────────────────────────────

class _ExerciseSection extends StatelessWidget {
  const _ExerciseSection({required this.ev, required this.fmt});

  final _ExerciseView ev;
  final String Function(num) fmt;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final totalReps = ev.sets.fold(0, (s, e) => s + e.reps);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(ev.name,
                      style: t.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                if (ev.muscleGroup != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(ev.muscleGroup!,
                        style: t.labelSmall?.copyWith(
                            color: cs.onSecondaryContainer)),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 10),

            // ── Column headers ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const SizedBox(width: 28),
                  Expanded(
                    child: Text('REPS',
                        style: t.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            letterSpacing: 0.8)),
                  ),
                  Expanded(
                    child: Text('WEIGHT',
                        style: t.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            letterSpacing: 0.8)),
                  ),
                  Expanded(
                    child: Text('VOLUME',
                        style: t.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            letterSpacing: 0.8)),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: cs.outlineVariant),
            const SizedBox(height: 6),

            // ── Set rows ─────────────────────────────────────────────
            ...ev.sets.asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value;
              final rowVolume = s.reps * s.weight;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    // Set number
                    Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${s.setNumber ?? i + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: cs.primary,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text('${s.reps} reps',
                          style:
                              t.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                    ),
                    Expanded(
                      child: Text('${fmt(s.weight)} kg',
                          style: t.bodySmall),
                    ),
                    Expanded(
                      child: Text('${fmt(rowVolume)} kg',
                          style: t.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant)),
                    ),
                  ],
                ),
              );
            }),

            // ── Totals ───────────────────────────────────────────────
            const SizedBox(height: 6),
            Divider(height: 1, color: cs.outlineVariant),
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 28),
                Expanded(
                  child: Text(
                    '$totalReps reps total',
                    style: t.labelSmall?.copyWith(
                        color: cs.primary, fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${fmt(ev.totalVolume)} kg total',
                    style: t.labelSmall?.copyWith(
                        color: cs.primary, fontWeight: FontWeight.w600),
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

// ── Data models ───────────────────────────────────────────────────────────────

class _SessionView {
  final String sessionId;
  final String routineName;
  final List<_ExerciseView> exercises;
  const _SessionView({
    required this.sessionId,
    required this.routineName,
    required this.exercises,
  });
}

class _ExerciseView {
  final String name;
  final String? muscleGroup;
  final List<WorkoutSet> sets;
  const _ExerciseView(this.name, this.muscleGroup, this.sets);

  num get totalVolume =>
      sets.fold<num>(0, (sum, s) => sum + s.reps * s.weight);
}
