import 'package:json_annotation/json_annotation.dart';
import 'task_ref_output.dart';

part 'task_output.g.dart';

@JsonSerializable()
class TaskOutput {
  const TaskOutput({
    required this.id,
    required this.title,
    required this.status,
    this.description,
    this.dueAt,
    this.flag,
    this.subflag,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String status;
  final String? description;
  final DateTime? dueAt;
  final TaskRefOutput? flag;
  final TaskRefOutput? subflag;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String? get flagName => flag?.name;
  String? get subflagName => subflag?.name;
  String? get flagColor => flag?.color;
  String? get subflagColor => subflag?.color;

  bool get isDone => status.toUpperCase() == 'DONE';

  factory TaskOutput.fromJson(Map<String, dynamic> json) {
    return _$TaskOutputFromJson(json);
  }

  factory TaskOutput.fromDynamic(dynamic value) {
    return TaskOutput.fromJson(_asMap(value));
  }

  TaskOutput copyWith({
    String? status,
    TaskRefOutput? flag,
    TaskRefOutput? subflag,
  }) {
    return TaskOutput(
      id: id,
      title: title,
      status: status ?? this.status,
      description: description,
      dueAt: dueAt,
      flag: flag ?? this.flag,
      subflag: subflag ?? this.subflag,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() => _$TaskOutputToJson(this);

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }
}
