import 'package:json_annotation/json_annotation.dart';

part 'home_shopping_preview_output.g.dart';

@JsonSerializable()
class HomeShoppingPreviewOutput {
  const HomeShoppingPreviewOutput({
    required this.id,
    required this.title,
    required this.totalItems,
    required this.pendingItems,
    required this.previewItems,
  });

  final String id;
  final String title;
  @JsonKey(name: 'total_items')
  final int totalItems;
  @JsonKey(name: 'pending_items')
  final int pendingItems;
  @JsonKey(name: 'preview_items')
  final List<String> previewItems;

  factory HomeShoppingPreviewOutput.fromJson(Map<String, dynamic> json) {
    return _$HomeShoppingPreviewOutputFromJson(json);
  }

  factory HomeShoppingPreviewOutput.fromDynamic(dynamic value) {
    try {
      return HomeShoppingPreviewOutput.fromJson(_asMap(value));
    } catch (_) {
      return const HomeShoppingPreviewOutput(
        id: '',
        title: '',
        totalItems: 0,
        pendingItems: 0,
        previewItems: [],
      );
    }
  }

  Map<String, dynamic> toJson() => _$HomeShoppingPreviewOutputToJson(this);

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }
}
