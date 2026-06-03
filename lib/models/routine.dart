class Routine {
  final String id;
  final String name;
  Routine({required this.id, required this.name});
  factory Routine.fromJson(Map<String, dynamic> j) =>
      Routine(id: j['id'], name: j['name']);
}
