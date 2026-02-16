import 'package:json_annotation/json_annotation.dart';

part 'event_create_input.g.dart';

String? _dateToUtcIso(DateTime? value) => value?.toUtc().toIso8601String();

@JsonSerializable(createFactory: false)
class EventCreateInput {
  const EventCreateInput({
    required this.title,
    this.startAt,
    this.endAt,
    this.allDay,
    this.location,
    this.flagId,
    this.subflagId,
  });

  final String title;
  @JsonKey(toJson: _dateToUtcIso)
  final DateTime? startAt;
  @JsonKey(toJson: _dateToUtcIso)
  final DateTime? endAt;
  final bool? allDay;
  final String? location;
  final String? flagId;
  final String? subflagId;

  Map<String, dynamic> toJson() => _$EventCreateInputToJson(this);
}
