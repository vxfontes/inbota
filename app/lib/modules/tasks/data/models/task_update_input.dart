class TaskUpdateInput {
  const TaskUpdateInput({required this.id, required this.status});

  final String id;
  final String status;

  Map<String, dynamic> toJson() => {'status': status};
}
