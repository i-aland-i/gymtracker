class WorkoutSet {
  final String? id; // null when it comes from the "last time" rpc
  final int? setNumber;
  final int reps;
  final num weight;
  WorkoutSet({
    this.id,
    this.setNumber,
    required this.reps,
    required this.weight,
  });
  factory WorkoutSet.fromJson(Map<String, dynamic> j) => WorkoutSet(
    id: j['id'],
    setNumber: j['set_number'],
    reps: j['reps'],
    weight: j['weight'],
  );
}
