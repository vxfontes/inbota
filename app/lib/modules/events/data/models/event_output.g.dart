// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventOutput _$EventOutputFromJson(Map<String, dynamic> json) => EventOutput(
  id: json['id'] as String,
  title: json['title'] as String,
  startAt: json['startAt'] == null
      ? null
      : DateTime.parse(json['startAt'] as String),
  endAt: json['endAt'] == null ? null : DateTime.parse(json['endAt'] as String),
  allDay: json['allDay'] as bool? ?? false,
  location: json['location'] as String?,
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

Map<String, dynamic> _$EventOutputToJson(EventOutput instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'startAt': instance.startAt?.toIso8601String(),
      'endAt': instance.endAt?.toIso8601String(),
      'allDay': instance.allDay,
      'location': instance.location,
      'flag': instance.flag,
      'subflag': instance.subflag,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
