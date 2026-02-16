import 'package:json_annotation/json_annotation.dart';

part 'flag_update_input.g.dart';

@JsonSerializable(includeIfNull: false, createFactory: false)
class FlagUpdateInput {
  const FlagUpdateInput({
    required this.id,
    this.name,
    this.color,
    this.sortOrder,
  });

  @JsonKey(includeFromJson: false, includeToJson: false)
  final String id;

  final String? name;
  final String? color;
  final int? sortOrder;

  Map<String, dynamic> toJson() => _$FlagUpdateInputToJson(this);
}
