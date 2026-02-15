import 'package:json_annotation/json_annotation.dart';

import 'event_output.dart';

part 'event_list_output.g.dart';

@JsonSerializable()
class EventListOutput {
  const EventListOutput({required this.items, this.nextCursor});

  final List<EventOutput> items;
  final String? nextCursor;

  factory EventListOutput.fromJson(Map<String, dynamic> json) {
    return _$EventListOutputFromJson(json);
  }

  factory EventListOutput.fromDynamic(dynamic value) {
    return EventListOutput.fromJson(_asMap(value));
  }

  Map<String, dynamic> toJson() => _$EventListOutputToJson(this);

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }
}
