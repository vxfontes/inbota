import 'package:json_annotation/json_annotation.dart';

part 'shopping_list_object_output.g.dart';

@JsonSerializable()
class ShoppingListObjectOutput {
  const ShoppingListObjectOutput({
    required this.id,
    required this.title,
    required this.status,
  });

  final String id;
  final String title;
  final String status;

  bool get isDone => status.toUpperCase() == 'DONE';

  factory ShoppingListObjectOutput.fromJson(Map<String, dynamic> json) {
    return _$ShoppingListObjectOutputFromJson(json);
  }

  factory ShoppingListObjectOutput.fromDynamic(dynamic value) {
    return ShoppingListObjectOutput.fromJson(_asMap(value));
  }

  Map<String, dynamic> toJson() => _$ShoppingListObjectOutputToJson(this);

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }
}
