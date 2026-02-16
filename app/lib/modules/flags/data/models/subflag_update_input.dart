import 'package:json_annotation/json_annotation.dart';

part 'subflag_update_input.g.dart';

@JsonSerializable(includeIfNull: false, createFactory: false)
class SubflagUpdateInput {
  const SubflagUpdateInput({required this.id, this.name, this.sortOrder});

  @JsonKey(includeFromJson: false, includeToJson: false)
  final String id;

  final String? name;
  final int? sortOrder;

  Map<String, dynamic> toJson() => _$SubflagUpdateInputToJson(this);
}
