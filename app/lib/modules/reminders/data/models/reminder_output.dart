class ReminderOutput {
  const ReminderOutput({
    required this.id,
    required this.title,
    required this.status,
    this.remindAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String status;
  final DateTime? remindAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isDone => status.toUpperCase() == 'DONE';

  factory ReminderOutput.fromJson(Map<String, dynamic> json) {
    return ReminderOutput(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      status: json['status']?.toString() ?? 'OPEN',
      remindAt: _parseDate(json['remindAt']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  ReminderOutput copyWith({
    String? status,
  }) {
    return ReminderOutput(
      id: id,
      title: title,
      status: status ?? this.status,
      remindAt: remindAt,
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
