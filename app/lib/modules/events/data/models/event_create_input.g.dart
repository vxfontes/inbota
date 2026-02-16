// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_create_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$EventCreateInputToJson(EventCreateInput instance) =>
    <String, dynamic>{
      'title': instance.title,
      'startAt': _dateToUtcIso(instance.startAt),
      'endAt': _dateToUtcIso(instance.endAt),
      'allDay': instance.allDay,
      'location': instance.location,
      'flagId': instance.flagId,
      'subflagId': instance.subflagId,
    };
