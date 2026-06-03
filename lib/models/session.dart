class Session {
  final String id;
  final String? routineId;
  final DateTime date;
  Session({required this.id, this.routineId, required this.date});
  factory Session.fromJson(Map<String, dynamic> j) => Session(
    id: j['id'],
    routineId: j['routine_id'],
    date: DateTime.parse(j['date']),
  );
}
