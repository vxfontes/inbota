// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_list_list_output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShoppingListListOutput _$ShoppingListListOutputFromJson(
  Map<String, dynamic> json,
) => ShoppingListListOutput(
  items: (json['items'] as List<dynamic>)
      .map((e) => ShoppingListOutput.fromJson(e as Map<String, dynamic>))
      .toList(),
  nextCursor: json['nextCursor'] as String?,
);

Map<String, dynamic> _$ShoppingListListOutputToJson(
  ShoppingListListOutput instance,
) => <String, dynamic>{
  'items': instance.items,
  'nextCursor': instance.nextCursor,
};
