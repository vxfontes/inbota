import 'package:dartz/dartz.dart';
import 'package:inbota/modules/auth/data/models/auth_login_input.dart';
import 'package:inbota/modules/auth/data/models/auth_session_output.dart';
import 'package:inbota/modules/auth/data/models/auth_signup_input.dart';
import 'package:inbota/modules/auth/domain/repositories/i_auth_repository.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/services/http/http_client.dart';
import 'package:inbota/shared/storage/auth_token_store.dart';

class AuthRepository implements IAuthRepository {
  final IHttpClient _httpClient;
  final AuthTokenStore _tokenStore;

  final _path = '/auth';

  AuthRepository(this._httpClient, this._tokenStore);

  @override
  Future<Either<Failure, AuthSessionOutput>> login(AuthLoginInput input) async {
    try {
      final response = await _httpClient.post('$_path/login', data: input.toJson());
      final statusCode = response.statusCode ?? 0;

      if (_isSuccess(statusCode)) {
        final session = AuthSessionOutput.fromJson(_asMap(response.data));
        if (session.token.isEmpty) {
          return Left(GetFailure(message: 'Token invalido'));
        }
        await _tokenStore.saveToken(session.token);
        return Right(session);
      }

      return Left(GetFailure(message: _extractMessage(response.data)));
    } catch (err) {
      return Left(GetFailure(message: err.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthSessionOutput>> signup(AuthSignupInput input) async {
    try {
      final response = await _httpClient.post('$_path/signup', data: input.toJson());
      final statusCode = response.statusCode ?? 0;

      if (_isSuccess(statusCode)) {
        final session = AuthSessionOutput.fromJson(_asMap(response.data));
        if (session.token.isEmpty) {
          return Left(SaveFailure(message: 'Token invalido'));
        }
        await _tokenStore.saveToken(session.token);
        return Right(session);
      }

      return Left(SaveFailure(message: _extractMessage(response.data)));
    } catch (err) {
      return Left(SaveFailure(message: err.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _tokenStore.clearToken();
      return const Right(null);
    } catch (err) {
      return Left(DeleteFailure(message: err.toString()));
    }
  }

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }

  String _extractMessage(dynamic data) {
    if (data is Map) {
      final map = data.map((key, value) => MapEntry(key.toString(), value));
      final error = map['error']?.toString();
      if (error != null && error.isNotEmpty) {
        return _mapErrorCode(error);
      }
      return map['message']?.toString() ?? 'Erro inesperado';
    }
    return 'Erro inesperado';
  }

  String _mapErrorCode(String error) {
    switch (error) {
      case 'connection_refused':
        return 'Sem conexao com o servidor.';
      case 'timeout':
        return 'Tempo de conexao esgotado.';
      default:
        return error;
    }
  }
}
