import 'package:json_annotation/json_annotation.dart';

part 'shopping_list_update_input.g.dart';

@JsonSerializable(includeIfNull: false, createFactory: false)
class ShoppingListUpdateInput {
  const ShoppingListUpdateInput({required this.id, this.title, this.status});

  @JsonKey(includeFromJson: false, includeToJson: false)
  final String id;

  final String? title;
  final String? status;

  Map<String, dynamic> toJson() => _$ShoppingListUpdateInputToJson(this);
}
