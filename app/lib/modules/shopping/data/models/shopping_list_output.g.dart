// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_list_output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShoppingListOutput _$ShoppingListOutputFromJson(Map<String, dynamic> json) =>
    ShoppingListOutput(
      id: json['id'] as String,
      title: json['title'] as String,
      status: json['status'] as String,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ShoppingListOutputToJson(ShoppingListOutput instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'status': instance.status,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
