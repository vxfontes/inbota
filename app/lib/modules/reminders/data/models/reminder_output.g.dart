// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReminderOutput _$ReminderOutputFromJson(Map<String, dynamic> json) =>
    ReminderOutput(
      id: json['id'] as String,
      title: json['title'] as String,
      status: json['status'] as String,
      remindAt: json['remindAt'] == null
          ? null
          : DateTime.parse(json['remindAt'] as String),
      flag: json['flag'] == null
          ? null
          : FlagObjectOutput.fromJson(json['flag'] as Map<String, dynamic>),
      subflag: json['subflag'] == null
          ? null
          : FlagObjectOutput.fromJson(json['subflag'] as Map<String, dynamic>),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ReminderOutputToJson(ReminderOutput instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'status': instance.status,
      'remindAt': instance.remindAt?.toIso8601String(),
      'flag': instance.flag,
      'subflag': instance.subflag,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
