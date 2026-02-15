// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flag_output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FlagOutput _$FlagOutputFromJson(Map<String, dynamic> json) => FlagOutput(
  id: json['id'] as String,
  name: json['name'] as String,
  color: json['color'] as String?,
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$FlagOutputToJson(FlagOutput instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'color': instance.color,
      'sortOrder': instance.sortOrder,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
