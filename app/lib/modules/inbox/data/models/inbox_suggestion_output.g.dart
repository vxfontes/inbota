// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inbox_suggestion_output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InboxSuggestionOutput _$InboxSuggestionOutputFromJson(
  Map<String, dynamic> json,
) => InboxSuggestionOutput(
  id: json['id'] as String,
  type: json['type'] as String,
  title: json['title'] as String,
  confidence: (json['confidence'] as num?)?.toDouble(),
  flag: json['flag'] == null
      ? null
      : InboxRefOutput.fromJson(json['flag'] as Map<String, dynamic>),
  subflag: json['subflag'] == null
      ? null
      : InboxRefOutput.fromJson(json['subflag'] as Map<String, dynamic>),
  needsReview: json['needsReview'] as bool,
  payload: json['payload'],
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$InboxSuggestionOutputToJson(
  InboxSuggestionOutput instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'title': instance.title,
  'confidence': instance.confidence,
  'flag': instance.flag,
  'subflag': instance.subflag,
  'needsReview': instance.needsReview,
  'payload': instance.payload,
  'createdAt': instance.createdAt?.toIso8601String(),
};
