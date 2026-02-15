import 'package:json_annotation/json_annotation.dart';

import 'shopping_list_object_output.dart';

part 'shopping_item_output.g.dart';

@JsonSerializable()
class ShoppingItemOutput {
  const ShoppingItemOutput({
    required this.id,
    this.list,
    required this.title,
    this.quantity,
    required this.checked,
    required this.sortOrder,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final ShoppingListObjectOutput? list;
  final String title;
  final String? quantity;
  final bool checked;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isDone => checked;

  factory ShoppingItemOutput.fromJson(Map<String, dynamic> json) {
    return _$ShoppingItemOutputFromJson(json);
  }

  factory ShoppingItemOutput.fromDynamic(dynamic value) {
    return ShoppingItemOutput.fromJson(_asMap(value));
  }

  Map<String, dynamic> toJson() => _$ShoppingItemOutputToJson(this);

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }
}
