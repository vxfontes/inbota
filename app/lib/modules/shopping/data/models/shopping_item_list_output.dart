import 'package:json_annotation/json_annotation.dart';

import 'shopping_item_output.dart';

part 'shopping_item_list_output.g.dart';

@JsonSerializable()
class ShoppingItemListOutput {
  const ShoppingItemListOutput({required this.items, this.nextCursor});

  final List<ShoppingItemOutput> items;
  final String? nextCursor;

  factory ShoppingItemListOutput.fromJson(Map<String, dynamic> json) {
    return _$ShoppingItemListOutputFromJson(json);
  }

  factory ShoppingItemListOutput.fromDynamic(dynamic value) {
    return ShoppingItemListOutput.fromJson(_asMap(value));
  }

  Map<String, dynamic> toJson() => _$ShoppingItemListOutputToJson(this);

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }
}
