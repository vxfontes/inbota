// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_list_output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReminderListOutput _$ReminderListOutputFromJson(Map<String, dynamic> json) =>
    ReminderListOutput(
      items: (json['items'] as List<dynamic>)
          .map((e) => ReminderOutput.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
    );

Map<String, dynamic> _$ReminderListOutputToJson(ReminderListOutput instance) =>
    <String, dynamic>{
      'items': instance.items,
      'nextCursor': instance.nextCursor,
    };
