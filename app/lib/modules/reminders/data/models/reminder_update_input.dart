class ReminderUpdateInput {
  const ReminderUpdateInput({required this.id, required this.status});

  final String id;
  final String status;

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status,
      };
}
