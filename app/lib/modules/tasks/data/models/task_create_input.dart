class TaskCreateInput {
  const TaskCreateInput({
    required this.title,
    this.description,
    this.dueAt,
    this.status,
  });

  final String title;
  final String? description;
  final DateTime? dueAt;
  final String? status;

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{
      'title': title,
    };

    if (description != null && description!.trim().isNotEmpty) {
      payload['description'] = description!.trim();
    }

    if (dueAt != null) {
      payload['dueAt'] = dueAt!.toIso8601String();
    }

    if (status != null && status!.trim().isNotEmpty) {
      payload['status'] = status!.trim();
    }

    return payload;
  }
}
