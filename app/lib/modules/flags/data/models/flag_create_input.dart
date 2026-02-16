import 'package:json_annotation/json_annotation.dart';

part 'flag_create_input.g.dart';

@JsonSerializable(includeIfNull: false, createFactory: false)
class FlagCreateInput {
  const FlagCreateInput({required this.name, this.color, this.sortOrder});

  final String name;
  final String? color;
  final int? sortOrder;

  Map<String, dynamic> toJson() => _$FlagCreateInputToJson(this);
}
