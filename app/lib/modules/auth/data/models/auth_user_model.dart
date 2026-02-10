import 'package:json_annotation/json_annotation.dart';

part 'auth_user_model.g.dart';

@JsonSerializable()
class AuthUserModel {
  const AuthUserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.locale,
    required this.timezone,
  });

  final String id;
  final String email;
  final String displayName;
  final String locale;
  final String timezone;

  factory AuthUserModel.fromJson(Map<String, dynamic> json) =>
      _$AuthUserModelFromJson(json);

  Map<String, dynamic> toJson() => _$AuthUserModelToJson(this);
}
