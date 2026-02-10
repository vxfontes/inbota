// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_signup_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthSignupInput _$AuthSignupInputFromJson(Map<String, dynamic> json) =>
    AuthSignupInput(
      email: json['email'] as String,
      password: json['password'] as String,
      displayName: json['displayName'] as String,
      locale: json['locale'] as String,
      timezone: json['timezone'] as String,
    );

Map<String, dynamic> _$AuthSignupInputToJson(AuthSignupInput instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'displayName': instance.displayName,
      'locale': instance.locale,
      'timezone': instance.timezone,
    };
