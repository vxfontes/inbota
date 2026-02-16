class TaskOutput {
  const TaskOutput({
    required this.id,
    required this.title,
    required this.status,
    this.description,
    this.dueAt,
    this.flagName,
    this.subflagName,
    this.flagColor,
    this.subflagColor,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String status;
  final String? description;
  final DateTime? dueAt;
  final String? flagName;
  final String? subflagName;
  final String? flagColor;
  final String? subflagColor;
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
      flagName: _parseNestedString(json['flag'], 'name'),
      subflagName: _parseNestedString(json['subflag'], 'name'),
      flagColor: _parseNestedString(json['flag'], 'color'),
      subflagColor: _parseNestedString(json['subflag'], 'color'),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  TaskOutput copyWith({
    String? status,
    String? flagName,
    String? subflagName,
    String? flagColor,
    String? subflagColor,
  }) {
    return TaskOutput(
      id: id,
      title: title,
      status: status ?? this.status,
      description: description,
      dueAt: dueAt,
      flagName: flagName ?? this.flagName,
      subflagName: subflagName ?? this.subflagName,
      flagColor: flagColor ?? this.flagColor,
      subflagColor: subflagColor ?? this.subflagColor,
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

  static String? _parseNestedString(dynamic source, String key) {
    if (source is Map<String, dynamic>) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      return null;
    }
    if (source is Map) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      return null;
    }
    return null;
  }
}
