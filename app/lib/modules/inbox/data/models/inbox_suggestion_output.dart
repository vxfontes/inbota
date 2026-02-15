import 'package:json_annotation/json_annotation.dart';

import 'inbox_ref_output.dart';

part 'inbox_suggestion_output.g.dart';

@JsonSerializable()
class InboxSuggestionOutput {
  const InboxSuggestionOutput({
    required this.id,
    required this.type,
    required this.title,
    this.confidence,
    this.flag,
    this.subflag,
    required this.needsReview,
    this.payload,
    this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final double? confidence;
  final InboxRefOutput? flag;
  final InboxRefOutput? subflag;
  final bool needsReview;
  final dynamic payload;
  final DateTime? createdAt;

  factory InboxSuggestionOutput.fromJson(Map<String, dynamic> json) {
    return _$InboxSuggestionOutputFromJson(json);
  }

  factory InboxSuggestionOutput.fromDynamic(dynamic value) {
    return InboxSuggestionOutput.fromJson(_asMap(value));
  }

  Map<String, dynamic> toJson() => _$InboxSuggestionOutputToJson(this);

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }
}
