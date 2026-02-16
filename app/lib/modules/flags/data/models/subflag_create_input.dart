import 'package:json_annotation/json_annotation.dart';

part 'subflag_create_input.g.dart';

@JsonSerializable(includeIfNull: false, createFactory: false)
class SubflagCreateInput {
  const SubflagCreateInput({
    required this.flagId,
    required this.name,
    this.sortOrder,
  });

  @JsonKey(includeFromJson: false, includeToJson: false)
  final String flagId;

  final String name;
  final int? sortOrder;

  Map<String, dynamic> toJson() => _$SubflagCreateInputToJson(this);
}
