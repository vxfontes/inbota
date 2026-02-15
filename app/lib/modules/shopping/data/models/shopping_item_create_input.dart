import 'package:json_annotation/json_annotation.dart';

part 'shopping_item_create_input.g.dart';

@JsonSerializable(includeIfNull: false, createFactory: false)
class ShoppingItemCreateInput {
  const ShoppingItemCreateInput({
    required this.listId,
    required this.title,
    this.quantity,
    this.checked,
    this.sortOrder,
  });

  @JsonKey(includeFromJson: false, includeToJson: false)
  final String listId;

  final String title;
  final String? quantity;
  final bool? checked;
  final int? sortOrder;

  Map<String, dynamic> toJson() => _$ShoppingItemCreateInputToJson(this);
}
