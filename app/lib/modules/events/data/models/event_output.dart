import 'package:json_annotation/json_annotation.dart';

part 'event_output.g.dart';

@JsonSerializable()
class EventOutput {
  const EventOutput({
    required this.id,
    required this.title,
    this.startAt,
    this.endAt,
    this.allDay = false,
    this.location,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final DateTime? startAt;
  final DateTime? endAt;
  final bool allDay;
  final String? location;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory EventOutput.fromJson(Map<String, dynamic> json) {
    return _$EventOutputFromJson(json);
  }

  factory EventOutput.fromDynamic(dynamic value) {
    return EventOutput.fromJson(_asMap(value));
  }

  Map<String, dynamic> toJson() => _$EventOutputToJson(this);

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }
}
