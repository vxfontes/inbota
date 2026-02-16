import 'package:json_annotation/json_annotation.dart';

part 'task_ref_output.g.dart';

@JsonSerializable()
class TaskRefOutput {
  const TaskRefOutput({required this.id, required this.name, this.color});

  final String id;
  final String name;
  final String? color;

  factory TaskRefOutput.fromJson(Map<String, dynamic> json) {
    return _$TaskRefOutputFromJson(json);
  }

  factory TaskRefOutput.fromDynamic(dynamic value) {
    return TaskRefOutput.fromJson(_asMap(value));
  }

  Map<String, dynamic> toJson() => _$TaskRefOutputToJson(this);

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }
}
