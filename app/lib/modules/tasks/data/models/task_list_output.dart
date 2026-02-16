import 'task_output.dart';
import 'package:json_annotation/json_annotation.dart';

part 'task_list_output.g.dart';

@JsonSerializable()
class TaskListOutput {
  const TaskListOutput({required this.items, this.nextCursor});

  @JsonKey(defaultValue: <TaskOutput>[])
  final List<TaskOutput> items;
  final String? nextCursor;

  factory TaskListOutput.fromJson(Map<String, dynamic> json) {
    return _$TaskListOutputFromJson(json);
  }

  factory TaskListOutput.fromDynamic(dynamic value) {
    return TaskListOutput.fromJson(_asMap(value));
  }

  Map<String, dynamic> toJson() => _$TaskListOutputToJson(this);

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }
}
