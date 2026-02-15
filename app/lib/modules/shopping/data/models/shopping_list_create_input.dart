import 'package:json_annotation/json_annotation.dart';

part 'shopping_list_create_input.g.dart';

@JsonSerializable(includeIfNull: false, createFactory: false)
class ShoppingListCreateInput {
  const ShoppingListCreateInput({required this.title, this.status});

  final String title;
  final String? status;

  Map<String, dynamic> toJson() => _$ShoppingListCreateInputToJson(this);
}
