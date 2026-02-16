import 'package:json_annotation/json_annotation.dart';

import 'reminder_output.dart';

part 'reminder_list_output.g.dart';

@JsonSerializable()
class ReminderListOutput {
  const ReminderListOutput({required this.items, this.nextCursor});

  final List<ReminderOutput> items;
  final String? nextCursor;

  factory ReminderListOutput.fromJson(Map<String, dynamic> json) {
    return _$ReminderListOutputFromJson(json);
  }

  factory ReminderListOutput.fromDynamic(dynamic value) {
    if (value is Map<String, dynamic>) {
      return ReminderListOutput.fromJson(value);
    }
    if (value is Map) {
      return ReminderListOutput.fromJson(
        value.map((key, val) => MapEntry(key.toString(), val)),
      );
    }
    return const ReminderListOutput(items: []);
  }

  Map<String, dynamic> toJson() => _$ReminderListOutputToJson(this);
}
