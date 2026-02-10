// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_status_output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HealthStatusOutput _$HealthStatusOutputFromJson(Map<String, dynamic> json) =>
    HealthStatusOutput(
      status: json['status'] as String,
      time: json['time'] == null
          ? null
          : DateTime.parse(json['time'] as String),
    );

Map<String, dynamic> _$HealthStatusOutputToJson(HealthStatusOutput instance) =>
    <String, dynamic>{
      'status': instance.status,
      'time': instance.time?.toIso8601String(),
    };
