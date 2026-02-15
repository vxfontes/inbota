class TaskOutput {
  const TaskOutput({
    required this.id,
    required this.title,
    required this.status,
    this.description,
    this.dueAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String status;
  final String? description;
  final DateTime? dueAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isDone => status.toUpperCase() == 'DONE';

  factory TaskOutput.fromJson(Map<String, dynamic> json) {
    return TaskOutput(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      status: json['status']?.toString() ?? 'OPEN',
      description: json['description']?.toString(),
      dueAt: _parseDate(json['dueAt']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  TaskOutput copyWith({String? status}) {
    return TaskOutput(
      id: id,
      title: title,
      status: status ?? this.status,
      description: description,
      dueAt: dueAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
