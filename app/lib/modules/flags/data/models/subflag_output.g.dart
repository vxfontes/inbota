// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subflag_output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubflagOutput _$SubflagOutputFromJson(Map<String, dynamic> json) =>
    SubflagOutput(
      id: json['id'] as String,
      flag: json['flag'] == null
          ? null
          : FlagObjectOutput.fromJson(json['flag'] as Map<String, dynamic>),
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

Map<String, dynamic> _$SubflagOutputToJson(SubflagOutput instance) =>
    <String, dynamic>{
      'id': instance.id,
      'flag': instance.flag,
      'name': instance.name,
      'color': instance.color,
      'sortOrder': instance.sortOrder,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
