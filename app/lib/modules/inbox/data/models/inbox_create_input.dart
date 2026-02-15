import 'package:json_annotation/json_annotation.dart';

part 'inbox_create_input.g.dart';

@JsonSerializable(includeIfNull: false, createFactory: false)
class InboxCreateInput {
  const InboxCreateInput({
    required this.rawText,
    this.source,
    this.rawMediaUrl,
  });

  final String rawText;
  final String? source;
  final String? rawMediaUrl;

  Map<String, dynamic> toJson() => _$InboxCreateInputToJson(this);
}
