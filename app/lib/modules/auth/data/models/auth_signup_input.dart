import 'package:json_annotation/json_annotation.dart';

part 'auth_signup_input.g.dart';

@JsonSerializable()
class AuthSignupInput {
  const AuthSignupInput({
    required this.email,
    required this.password,
    required this.displayName,
    required this.locale,
    required this.timezone,
  });

  final String email;
  final String password;
  final String displayName;
  final String locale;
  final String timezone;

  Map<String, dynamic> toJson() => _$AuthSignupInputToJson(this);
}
