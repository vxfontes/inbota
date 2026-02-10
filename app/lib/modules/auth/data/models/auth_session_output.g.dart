// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_session_output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthSessionOutput _$AuthSessionOutputFromJson(Map<String, dynamic> json) =>
    AuthSessionOutput(
      token: json['token'] as String,
      user: AuthUserModel.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AuthSessionOutputToJson(AuthSessionOutput instance) =>
    <String, dynamic>{'token': instance.token, 'user': instance.user};
