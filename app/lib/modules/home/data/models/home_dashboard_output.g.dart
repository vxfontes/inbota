// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_dashboard_output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeDashboardOutput _$HomeDashboardOutputFromJson(
  Map<String, dynamic> json,
) => HomeDashboardOutput(
  dayProgress: HomeDayProgressOutput.fromJson(
    json['day_progress'] as Map<String, dynamic>,
  ),
  insight: json['insight'] == null
      ? null
      : HomeInsightOutput.fromJson(json['insight'] as Map<String, dynamic>),
  timeline: (json['timeline'] as List<dynamic>)
      .map((e) => HomeTimelineItemOutput.fromJson(e as Map<String, dynamic>))
      .toList(),
  shoppingPreview: (json['shopping_preview'] as List<dynamic>)
      .map((e) => HomeShoppingPreviewOutput.fromJson(e as Map<String, dynamic>))
      .toList(),
  weekDensity: Map<String, int>.from(json['week_density'] as Map),
  focusTasks: (json['focus_tasks'] as List<dynamic>)
      .map((e) => TaskOutput.fromJson(e as Map<String, dynamic>))
      .toList(),
  eventsTodayCount: (json['events_today_count'] as num?)?.toInt(),
  remindersTodayCount: (json['reminders_today_count'] as num?)?.toInt(),
);

Map<String, dynamic> _$HomeDashboardOutputToJson(
  HomeDashboardOutput instance,
) => <String, dynamic>{
  'day_progress': instance.dayProgress,
  'insight': instance.insight,
  'timeline': instance.timeline,
  'shopping_preview': instance.shoppingPreview,
  'week_density': instance.weekDensity,
  'focus_tasks': instance.focusTasks,
  'events_today_count': instance.eventsTodayCount,
  'reminders_today_count': instance.remindersTodayCount,
};
