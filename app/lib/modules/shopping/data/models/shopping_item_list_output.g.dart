// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_item_list_output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShoppingItemListOutput _$ShoppingItemListOutputFromJson(
  Map<String, dynamic> json,
) => ShoppingItemListOutput(
  items: (json['items'] as List<dynamic>)
      .map((e) => ShoppingItemOutput.fromJson(e as Map<String, dynamic>))
      .toList(),
  nextCursor: json['nextCursor'] as String?,
);

Map<String, dynamic> _$ShoppingItemListOutputToJson(
  ShoppingItemListOutput instance,
) => <String, dynamic>{
  'items': instance.items,
  'nextCursor': instance.nextCursor,
};
