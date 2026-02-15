import 'package:json_annotation/json_annotation.dart';

import 'shopping_list_output.dart';

part 'shopping_list_list_output.g.dart';

@JsonSerializable()
class ShoppingListListOutput {
  const ShoppingListListOutput({required this.items, this.nextCursor});

  final List<ShoppingListOutput> items;
  final String? nextCursor;

  factory ShoppingListListOutput.fromJson(Map<String, dynamic> json) {
    return _$ShoppingListListOutputFromJson(json);
  }

  factory ShoppingListListOutput.fromDynamic(dynamic value) {
    return ShoppingListListOutput.fromJson(_asMap(value));
  }

  Map<String, dynamic> toJson() => _$ShoppingListListOutputToJson(this);

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }
}
