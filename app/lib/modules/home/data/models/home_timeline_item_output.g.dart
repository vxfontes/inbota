// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_timeline_item_output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeTimelineItemOutput _$HomeTimelineItemOutputFromJson(
  Map<String, dynamic> json,
) => HomeTimelineItemOutput(
  id: json['id'] as String,
  itemType: HomeTimelineItemOutput._itemTypeFromJson(json['itemType']),
  title: json['title'] as String,
  subtitle: HomeTimelineItemOutput._subtitleFromJson(json['subtitle']),
  scheduledTime: DateTime.parse(json['scheduled_time'] as String),
  endScheduledTime: json['end_scheduled_time'] == null
      ? null
      : DateTime.parse(json['end_scheduled_time'] as String),
  isCompleted: json['is_completed'] as bool,
  isOverdue: json['is_overdue'] as bool,
);

Map<String, dynamic> _$HomeTimelineItemOutputToJson(
  HomeTimelineItemOutput instance,
) => <String, dynamic>{
  'id': instance.id,
  'itemType': instance.itemType,
  'title': instance.title,
  'subtitle': instance.subtitle,
  'scheduled_time': instance.scheduledTime.toIso8601String(),
  'end_scheduled_time': instance.endScheduledTime?.toIso8601String(),
  'is_completed': instance.isCompleted,
  'is_overdue': instance.isOverdue,
};
