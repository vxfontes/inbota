import 'flag_output.dart';
import 'package:json_annotation/json_annotation.dart';

part 'flag_list_output.g.dart';

@JsonSerializable()
class FlagListOutput {
  const FlagListOutput({required this.items, this.nextCursor});

  final List<FlagOutput> items;
  final String? nextCursor;

  factory FlagListOutput.fromJson(Map<String, dynamic> json) {
    return _$FlagListOutputFromJson(json);
  }

  factory FlagListOutput.fromDynamic(dynamic value) {
    return FlagListOutput.fromJson(_asMap(value));
  }

  Map<String, dynamic> toJson() => _$FlagListOutputToJson(this);

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }
}
