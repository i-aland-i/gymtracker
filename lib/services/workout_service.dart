import '../supabase_client.dart';
import '../models/routine.dart';
import '../models/exercise.dart';
import '../models/session.dart';
import '../models/workout_set.dart';

class WorkoutService {
  // routines (workout days)
  Future<List<Routine>> getRoutines() async {
    final data = await supabase
        .from('routines')
        .select()
        .eq('user_id', supabase.auth.currentUser!.id)
        .order('position', ascending: true);
    return (data as List).map((e) => Routine.fromJson(e)).toList();
  }

  Future<void> updateRoutinePositions(List<String> orderedRoutineIds) async {
    final userId = supabase.auth.currentUser!.id;
    for (var i = 0; i < orderedRoutineIds.length; i++) {
      await supabase
          .from('routines')
          .update({'position': i})
          .eq('id', orderedRoutineIds[i])
          .eq('user_id', userId);
    }
  }

  Future<void> deleteRoutine(String routineId) async {
    // Fetch sessions so we can delete their sets first
    final sessionData = await supabase
        .from('sessions')
        .select('id')
        .eq('routine_id', routineId);
    for (final s in sessionData as List) {
      await supabase.from('sets').delete().eq('session_id', s['id']);
    }
    await supabase.from('sessions').delete().eq('routine_id', routineId);
    await supabase
        .from('routine_exercises')
        .delete()
        .eq('routine_id', routineId);
    await supabase.from('routines').delete().eq('id', routineId);
  }

  Future<Routine> createRoutine(String name, {required int position}) async {
    final data = await supabase
        .from('routines')
        .insert({
          'name': name,
          'user_id': supabase.auth.currentUser!.id,
          'position': position,
        })
        .select()
        .single();
    return Routine.fromJson(data);
  }

  // exercises
  Future<List<Exercise>> getExercises() async {
    final data = await supabase
        .from('exercises')
        .select()
        .eq('user_id', supabase.auth.currentUser!.id)
        .order('name');
    return (data as List).map((e) => Exercise.fromJson(e)).toList();
  }

  Future<Exercise> createExercise(String name, {String? muscleGroup}) async {
    final data = await supabase
        .from('exercises')
        .insert({
          'name': name,
          'muscle_group': muscleGroup,
          'user_id': supabase.auth.currentUser!.id,
        })
        .select()
        .single();
    return Exercise.fromJson(data);
  }

  Future<void> addExerciseToRoutine(
    String routineId,
    String exerciseId,
    int position,
  ) => supabase.from('routine_exercises').insert({
    'routine_id': routineId,
    'exercise_id': exerciseId,
    'position': position,
    'user_id': supabase.auth.currentUser!.id,
  });

  Future<void> removeExerciseFromRoutine(
          String routineId, String exerciseId) =>
      supabase
          .from('routine_exercises')
          .delete()
          .eq('routine_id', routineId)
          .eq('exercise_id', exerciseId);

  Future<void> updateExercisePositions(
      String routineId, List<String> orderedExerciseIds) async {
    final userId = supabase.auth.currentUser!.id;
    // Delete all rows for this routine, then re-insert with correct positions.
    // Single delete + single insert is atomic and can't partially fail.
    await supabase
        .from('routine_exercises')
        .delete()
        .eq('routine_id', routineId)
        .eq('user_id', userId);
    if (orderedExerciseIds.isEmpty) return;
    await supabase.from('routine_exercises').insert(
      orderedExerciseIds.asMap().entries.map((e) => {
        'routine_id': routineId,
        'exercise_id': e.value,
        'position': e.key,
        'user_id': userId,
      }).toList(),
    );
  }

  Future<List<Exercise>> getRoutineExercises(String routineId) async {
    final data = await supabase
        .from('routine_exercises')
        .select('position, exercises(*)')
        .eq('routine_id', routineId)
        .order('position', ascending: true);
    return (data as List)
        .map((e) => Exercise.fromJson(e['exercises']))
        .toList();
  }

  // sessions
  Future<void> deleteSession(String sessionId) =>
      supabase.from('sessions').delete().eq('id', sessionId);

  Future<Session> startSession(String routineId, DateTime date) async {
    final data = await supabase
        .from('sessions')
        .insert({
          'routine_id': routineId,
          'date': date.toIso8601String().substring(0, 10),
          'user_id': supabase.auth.currentUser!.id,
        })
        .select()
        .single();
    return Session.fromJson(data);
  }

  Future<List<Session>> getSessionsForDate(DateTime date) async {
    final d = date.toIso8601String().substring(0, 10);
    final data = await supabase
        .from('sessions')
        .select()
        .eq('user_id', supabase.auth.currentUser!.id)
        .eq('date', d)
        .order('created_at');
    return (data as List).map((e) => Session.fromJson(e)).toList();
  }

  // sets
  Future<void> logSet({
    required String sessionId,
    required String exerciseId,
    required int reps,
    required num weight,
    int? setNumber,
  }) => supabase.from('sets').insert({
    'session_id': sessionId,
    'exercise_id': exerciseId,
    'reps': reps,
    'weight': weight,
    'set_number': setNumber,
    'user_id': supabase.auth.currentUser!.id,
  });

  Future<void> deleteSet(String setId) =>
      supabase.from('sets').delete().eq('id', setId);

  Future<List<WorkoutSet>> getSets(String sessionId, String exerciseId) async {
    final data = await supabase
        .from('sets')
        .select()
        .eq('session_id', sessionId)
        .eq('exercise_id', exerciseId)
        .order('set_number', ascending: true, nullsFirst: false);
    final sets = (data as List).map((e) => WorkoutSet.fromJson(e)).toList();
    sets.sort((a, b) => (a.setNumber ?? 9999).compareTo(b.setNumber ?? 9999));
    return sets;
  }

  // the "last time" feature
  Future<List<WorkoutSet>> lastTime(
    String exerciseId, {
    String? excludeSessionId,
  }) async {
    final data = await supabase.rpc(
      'last_exercise_sets',
      params: {
        'p_exercise_id': exerciseId,
        'p_exclude_session_id': excludeSessionId,
      },
    );
    return (data as List).map((e) => WorkoutSet.fromJson(e)).toList();
  }
}
