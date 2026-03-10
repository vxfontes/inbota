import 'package:json_annotation/json_annotation.dart';
import 'package:inbota/modules/home/data/models/home_day_progress_output.dart';
import 'package:inbota/modules/home/data/models/home_insight_output.dart';
import 'package:inbota/modules/home/data/models/home_shopping_preview_output.dart';
import 'package:inbota/modules/home/data/models/home_timeline_item_output.dart';
import 'package:inbota/modules/tasks/data/models/task_output.dart';

part 'home_dashboard_output.g.dart';

@JsonSerializable()
class HomeDashboardOutput {
  const HomeDashboardOutput({
    required this.dayProgress,
    this.insight,
    required this.timeline,
    required this.shoppingPreview,
    required this.weekDensity,
    required this.focusTasks,
    this.eventsTodayCount,
    this.remindersTodayCount,
  });

  @JsonKey(name: 'day_progress')
  final HomeDayProgressOutput dayProgress;
  final HomeInsightOutput? insight;
  final List<HomeTimelineItemOutput> timeline;
  @JsonKey(name: 'shopping_preview')
  final List<HomeShoppingPreviewOutput> shoppingPreview;
  @JsonKey(name: 'week_density')
  final Map<String, int> weekDensity;
  @JsonKey(name: 'focus_tasks')
  final List<TaskOutput> focusTasks;
  @JsonKey(name: 'events_today_count')
  final int? eventsTodayCount;
  @JsonKey(name: 'reminders_today_count')
  final int? remindersTodayCount;

  factory HomeDashboardOutput.fromJson(Map<String, dynamic> json) {
    return _$HomeDashboardOutputFromJson(json);
  }

  factory HomeDashboardOutput.fromDynamic(dynamic value) {
    try {
      return HomeDashboardOutput.fromJson(_asMap(value));
    } catch (_) {
      return const HomeDashboardOutput(
        dayProgress: HomeDayProgressOutput(
          routinesDone: 0,
          routinesTotal: 0,
          tasksDone: 0,
          tasksTotal: 0,
          progressPercent: 0,
        ),
        timeline: [],
        shoppingPreview: [],
        weekDensity: {},
        focusTasks: [],
      );
    }
  }

  HomeDashboardOutput copyWith({
    HomeDayProgressOutput? dayProgress,
    HomeInsightOutput? insight,
    bool clearInsight = false,
    List<HomeTimelineItemOutput>? timeline,
    List<HomeShoppingPreviewOutput>? shoppingPreview,
    Map<String, int>? weekDensity,
    List<TaskOutput>? focusTasks,
    int? eventsTodayCount,
    int? remindersTodayCount,
    bool clearEventsTodayCount = false,
    bool clearRemindersTodayCount = false,
  }) {
    return HomeDashboardOutput(
      dayProgress: dayProgress ?? this.dayProgress,
      insight: clearInsight ? null : (insight ?? this.insight),
      timeline: timeline ?? this.timeline,
      shoppingPreview: shoppingPreview ?? this.shoppingPreview,
      weekDensity: weekDensity ?? this.weekDensity,
      focusTasks: focusTasks ?? this.focusTasks,
      eventsTodayCount: clearEventsTodayCount
          ? null
          : (eventsTodayCount ?? this.eventsTodayCount),
      remindersTodayCount: clearRemindersTodayCount
          ? null
          : (remindersTodayCount ?? this.remindersTodayCount),
    );
  }

  Map<String, dynamic> toJson() => _$HomeDashboardOutputToJson(this);

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }
}
