import 'package:json_annotation/json_annotation.dart';

part 'inbox_ref_output.g.dart';

@JsonSerializable()
class InboxRefOutput {
  const InboxRefOutput({required this.id, required this.name, this.color});

  final String id;
  final String name;
  final String? color;

  factory InboxRefOutput.fromJson(Map<String, dynamic> json) {
    return _$InboxRefOutputFromJson(json);
  }

  factory InboxRefOutput.fromDynamic(dynamic value) {
    return InboxRefOutput.fromJson(_asMap(value));
  }

  Map<String, dynamic> toJson() => _$InboxRefOutputToJson(this);

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }
}
