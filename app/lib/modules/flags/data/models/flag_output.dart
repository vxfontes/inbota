import 'package:json_annotation/json_annotation.dart';

part 'flag_output.g.dart';

@JsonSerializable()
class FlagOutput {
  const FlagOutput({
    required this.id,
    required this.name,
    this.color,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? color;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory FlagOutput.fromJson(Map<String, dynamic> json) {
    return _$FlagOutputFromJson(json);
  }

  factory FlagOutput.fromDynamic(dynamic value) {
    return FlagOutput.fromJson(_asMap(value));
  }

  Map<String, dynamic> toJson() => _$FlagOutputToJson(this);

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }
}
