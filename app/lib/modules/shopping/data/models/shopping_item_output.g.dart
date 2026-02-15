// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_item_output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShoppingItemOutput _$ShoppingItemOutputFromJson(Map<String, dynamic> json) =>
    ShoppingItemOutput(
      id: json['id'] as String,
      list: json['list'] == null
          ? null
          : ShoppingListObjectOutput.fromJson(
              json['list'] as Map<String, dynamic>,
            ),
      title: json['title'] as String,
      quantity: json['quantity'] as String?,
      checked: json['checked'] as bool,
      sortOrder: (json['sortOrder'] as num).toInt(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ShoppingItemOutputToJson(ShoppingItemOutput instance) =>
    <String, dynamic>{
      'id': instance.id,
      'list': instance.list,
      'title': instance.title,
      'quantity': instance.quantity,
      'checked': instance.checked,
      'sortOrder': instance.sortOrder,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
