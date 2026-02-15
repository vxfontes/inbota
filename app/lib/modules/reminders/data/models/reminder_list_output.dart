import 'reminder_output.dart';

class ReminderListOutput {
  const ReminderListOutput({required this.items, this.nextCursor});

  final List<ReminderOutput> items;
  final String? nextCursor;

  factory ReminderListOutput.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = <ReminderOutput>[];

    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) {
          items.add(ReminderOutput.fromJson(item));
        } else if (item is Map) {
          items.add(
            ReminderOutput.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          );
        }
      }
    }

    return ReminderListOutput(
      items: items,
      nextCursor: json['nextCursor']?.toString(),
    );
  }
}
