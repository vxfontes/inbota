import 'package:json_annotation/json_annotation.dart';

part 'home_timeline_item_output.g.dart';

@JsonSerializable()
class HomeTimelineItemOutput {
  const HomeTimelineItemOutput({
    required this.id,
    required this.itemType,
    required this.title,
    this.subtitle,
    required this.scheduledTime,
    this.endScheduledTime,
    required this.isCompleted,
    required this.isOverdue,
  });

  final String id;
  @JsonKey(fromJson: _itemTypeFromJson)
  final String itemType;
  final String title;
  @JsonKey(fromJson: _subtitleFromJson)
  final String? subtitle;
  @JsonKey(name: 'scheduled_time')
  final DateTime scheduledTime;
  @JsonKey(name: 'end_scheduled_time')
  final DateTime? endScheduledTime;
  @JsonKey(name: 'is_completed')
  final bool isCompleted;
  @JsonKey(name: 'is_overdue')
  final bool isOverdue;

  factory HomeTimelineItemOutput.fromJson(Map<String, dynamic> json) {
    return _$HomeTimelineItemOutputFromJson(json);
  }

  factory HomeTimelineItemOutput.fromDynamic(dynamic value) {
    try {
      return HomeTimelineItemOutput.fromJson(_asMap(value));
    } catch (_) {
      return HomeTimelineItemOutput(
        id: '',
        itemType: '',
        title: '',
        scheduledTime: DateTime.fromMillisecondsSinceEpoch(0),
        isCompleted: false,
        isOverdue: false,
      );
    }
  }

  HomeTimelineItemOutput copyWith({
    bool? isCompleted,
    bool? isOverdue,
    DateTime? scheduledTime,
    DateTime? endScheduledTime,
  }) {
    return HomeTimelineItemOutput(
      id: id,
      itemType: itemType,
      title: title,
      subtitle: subtitle,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      endScheduledTime: endScheduledTime ?? this.endScheduledTime,
      isCompleted: isCompleted ?? this.isCompleted,
      isOverdue: isOverdue ?? this.isOverdue,
    );
  }

  Map<String, dynamic> toJson() => _$HomeTimelineItemOutputToJson(this);

  static String _itemTypeFromJson(dynamic value) {
    if (value == null) return '';
    return value.toString().toLowerCase();
  }

  static String? _subtitleFromJson(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return text;
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }
}
