// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_list_output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventListOutput _$EventListOutputFromJson(Map<String, dynamic> json) =>
    EventListOutput(
      items: (json['items'] as List<dynamic>)
          .map((e) => EventOutput.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
    );

Map<String, dynamic> _$EventListOutputToJson(EventListOutput instance) =>
    <String, dynamic>{
      'items': instance.items,
      'nextCursor': instance.nextCursor,
    };
