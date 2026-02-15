import 'package:json_annotation/json_annotation.dart';

part 'shopping_item_update_input.g.dart';

@JsonSerializable(includeIfNull: false, createFactory: false)
class ShoppingItemUpdateInput {
  const ShoppingItemUpdateInput({
    required this.id,
    this.title,
    this.quantity,
    this.checked,
    this.sortOrder,
  });

  @JsonKey(includeFromJson: false, includeToJson: false)
  final String id;

  final String? title;
  final String? quantity;
  final bool? checked;
  final int? sortOrder;

  Map<String, dynamic> toJson() => _$ShoppingItemUpdateInputToJson(this);
}
