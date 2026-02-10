import 'package:json_annotation/json_annotation.dart';

part 'auth_login_input.g.dart';

@JsonSerializable()
class AuthLoginInput {
  const AuthLoginInput({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => _$AuthLoginInputToJson(this);
}
