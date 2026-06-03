class Exercise {
  final String id;
  final String name;
  final String? muscleGroup;
  Exercise({required this.id, required this.name, this.muscleGroup});
  factory Exercise.fromJson(Map<String, dynamic> j) =>
      Exercise(id: j['id'], name: j['name'], muscleGroup: j['muscle_group']);
}
