// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_shopping_preview_output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeShoppingPreviewOutput _$HomeShoppingPreviewOutputFromJson(
  Map<String, dynamic> json,
) => HomeShoppingPreviewOutput(
  id: json['id'] as String,
  title: json['title'] as String,
  totalItems: (json['total_items'] as num).toInt(),
  pendingItems: (json['pending_items'] as num).toInt(),
  previewItems: (json['preview_items'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$HomeShoppingPreviewOutputToJson(
  HomeShoppingPreviewOutput instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'total_items': instance.totalItems,
  'pending_items': instance.pendingItems,
  'preview_items': instance.previewItems,
};
