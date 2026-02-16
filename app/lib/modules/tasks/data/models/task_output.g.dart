// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskOutput _$TaskOutputFromJson(Map<String, dynamic> json) => TaskOutput(
  id: json['id'] as String,
  title: json['title'] as String,
  status: json['status'] as String,
  description: json['description'] as String?,
  dueAt: json['dueAt'] == null ? null : DateTime.parse(json['dueAt'] as String),
  flag: json['flag'] == null
      ? null
      : TaskRefOutput.fromJson(json['flag'] as Map<String, dynamic>),
  subflag: json['subflag'] == null
      ? null
      : TaskRefOutput.fromJson(json['subflag'] as Map<String, dynamic>),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$TaskOutputToJson(TaskOutput instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'status': instance.status,
      'description': instance.description,
      'dueAt': instance.dueAt?.toIso8601String(),
      'flag': instance.flag,
      'subflag': instance.subflag,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
