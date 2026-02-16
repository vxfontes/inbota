// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subflag_list_output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubflagListOutput _$SubflagListOutputFromJson(Map<String, dynamic> json) =>
    SubflagListOutput(
      items: (json['items'] as List<dynamic>)
          .map((e) => SubflagOutput.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
    );

Map<String, dynamic> _$SubflagListOutputToJson(SubflagListOutput instance) =>
    <String, dynamic>{
      'items': instance.items,
      'nextCursor': instance.nextCursor,
    };
