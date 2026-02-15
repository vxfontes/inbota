import 'package:json_annotation/json_annotation.dart';

part 'shopping_list_output.g.dart';

@JsonSerializable()
class ShoppingListOutput {
  const ShoppingListOutput({
    required this.id,
    required this.title,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isDone => status.toUpperCase() == 'DONE';
  bool get isArchived => status.toUpperCase() == 'ARCHIVED';

  factory ShoppingListOutput.fromJson(Map<String, dynamic> json) {
    return _$ShoppingListOutputFromJson(json);
  }

  factory ShoppingListOutput.fromDynamic(dynamic value) {
    return ShoppingListOutput.fromJson(_asMap(value));
  }

  Map<String, dynamic> toJson() => _$ShoppingListOutputToJson(this);

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }
}
