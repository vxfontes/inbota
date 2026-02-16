import 'package:json_annotation/json_annotation.dart';

part 'flag_object_output.g.dart';

@JsonSerializable()
class FlagObjectOutput {
  const FlagObjectOutput({required this.id, required this.name, this.color});

  final String id;
  final String name;
  final String? color;

  factory FlagObjectOutput.fromJson(Map<String, dynamic> json) {
    return _$FlagObjectOutputFromJson(json);
  }

  factory FlagObjectOutput.fromDynamic(dynamic value) {
    return FlagObjectOutput.fromJson(_asMap(value));
  }

  Map<String, dynamic> toJson() => _$FlagObjectOutputToJson(this);

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }
}
