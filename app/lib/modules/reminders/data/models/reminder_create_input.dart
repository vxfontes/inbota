import 'package:json_annotation/json_annotation.dart';

part 'reminder_create_input.g.dart';

String? _dateToUtcIso(DateTime? value) => value?.toUtc().toIso8601String();

@JsonSerializable(createFactory: false)
class ReminderCreateInput {
  const ReminderCreateInput({
    required this.title,
    this.status,
    this.remindAt,
    this.flagId,
    this.subflagId,
  });

  final String title;
  final String? status;
  @JsonKey(toJson: _dateToUtcIso)
  final DateTime? remindAt;
  final String? flagId;
  final String? subflagId;

  Map<String, dynamic> toJson() => _$ReminderCreateInputToJson(this);
}
