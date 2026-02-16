// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_list_output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskListOutput _$TaskListOutputFromJson(Map<String, dynamic> json) =>
    TaskListOutput(
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => TaskOutput.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      nextCursor: json['nextCursor'] as String?,
    );

Map<String, dynamic> _$TaskListOutputToJson(TaskListOutput instance) =>
    <String, dynamic>{
      'items': instance.items,
      'nextCursor': instance.nextCursor,
    };
