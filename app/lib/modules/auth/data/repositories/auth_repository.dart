import 'package:dartz/dartz.dart';
import 'package:organiq/modules/auth/data/models/auth_login_input.dart';
import 'package:organiq/modules/auth/data/models/auth_session_output.dart';
import 'package:organiq/modules/auth/data/models/auth_signup_input.dart';
import 'package:organiq/modules/auth/data/models/auth_user_model.dart';
import 'package:organiq/modules/auth/domain/repositories/i_auth_repository.dart';
import 'package:organiq/shared/errors/api_error_mapper.dart';
import 'package:organiq/shared/errors/exception_mapper.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/extensions/response_model_extensions.dart';
import 'package:organiq/shared/services/analytics/app_session_service.dart';
import 'package:organiq/shared/services/cache/cache_service.dart';
import 'package:organiq/shared/services/http/app_path.dart';
import 'package:organiq/shared/services/http/http_client.dart';
import 'package:organiq/shared/storage/auth_token_store.dart';

const String _wrongPasswordMessage = 'Senha incorreta. Tente de novo.';
const String _tooManyAttemptsMessage =
    'Muitas tentativas. Aguarde um minuto e tente de novo.';
const String _deleteAccountFailureMessage =
    'Não foi possível excluir sua conta agora. Tente novamente.';

class AuthRepository implements IAuthRepository {
  final IHttpClient _httpClient;
  final AuthTokenStore _tokenStore;
  final AppSessionService _sessionService;
  final ICacheService _cache;

  AuthRepository(this._httpClient, this._tokenStore, this._sessionService, this._cache);

  @override
  Future<Either<Failure, AuthSessionOutput>> login(AuthLoginInput input) async {
    try {
      final response = await _httpClient.post(
        AppPath.authLogin,
        data: input.toJson(),
        extra: const {'auth': false},
      );

      if (response.isSuccess) {
        final session = AuthSessionOutput.fromJson(response.asMap());
        if (session.token.isEmpty) {
          return Left(GetFailure(message: 'Token inválido'));
        }
        await _sessionService.refreshSession();
        await _tokenStore.saveToken(session.token);
        return Right(session);
      }

      return Left(
        GetFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro inesperado',
          ),
        ),
      );
    } catch (err) {
      return Left(
        ExceptionMapper.toFailure(
          err,
          fallbackMessage: 'Erro ao fazer login. Tente novamente.',
          failureFactory: (msg) => GetFailure(message: msg),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, AuthSessionOutput>> signup(
    AuthSignupInput input,
  ) async {
    try {
      final response = await _httpClient.post(
        AppPath.authSignup,
        data: input.toJson(),
        extra: const {'auth': false},
      );

      if (response.isSuccess) {
        final session = AuthSessionOutput.fromJson(response.asMap());
        if (session.token.isEmpty) {
          return Left(SaveFailure(message: 'Token inválido'));
        }
        await _sessionService.refreshSession();
        await _tokenStore.saveToken(session.token);
        return Right(session);
      }

      return Left(
        SaveFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro inesperado',
          ),
        ),
      );
    } catch (err) {
      return Left(
        ExceptionMapper.toFailure(
          err,
          fallbackMessage: 'Erro ao criar conta. Tente novamente.',
          failureFactory: (msg) => SaveFailure(message: msg),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, AuthUserModel>> me() async {
    try {
      final response = await _httpClient.get(AppPath.me);

      if (response.isSuccess) {
        final session = AuthSessionOutput.fromJson(response.asMap());
        return Right(session.user);
      }

      return Left(
        GetFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro inesperado',
          ),
        ),
      );
    } catch (err) {
      return Left(
        ExceptionMapper.toFailure(
          err,
          fallbackMessage: 'Erro ao carregar perfil. Tente novamente.',
          failureFactory: (msg) => GetFailure(message: msg),
        ),
      );
    }
  }

  // The whole DELETE /v1/me contract lives here — verb, path, body key and
  // status mapping. A backend change touches this method and nothing else.
  @override
  Future<Either<Failure, void>> deleteAccount(String password) async {
    try {
      final response = await _httpClient.delete(
        AppPath.me,
        data: {'password': password},
      );

      if (response.isSuccess) return const Right(null);

      // Every branch below is keyed on the status and answers with a constant.
      // The body is deliberately never read here: ApiErrorMapper falls back to
      // the raw code for anything it does not know, so an unmapped error would
      // print a machine string inside the password field.

      // 403 is the only failure the user can fix without leaving the sheet, and
      // on this route it means exactly one thing — the password is wrong.
      if (response.statusCode == 403) {
        return Left(InvalidParameterFailure(message: _wrongPasswordMessage));
      }

      // The route is rate limited at 5/min per IP. A reviewer trying a wrong
      // password a few times behind a shared NAT reaches this, so it is a
      // normal state of the flow and not an edge case.
      if (response.statusCode == 429) {
        return Left(DeleteFailure(message: _tooManyAttemptsMessage));
      }

      return Left(DeleteFailure(message: _deleteAccountFailureMessage));
    } catch (err) {
      return Left(
        ExceptionMapper.toFailure(
          err,
          fallbackMessage: 'Erro ao excluir a conta. Tente novamente.',
          failureFactory: (msg) => DeleteFailure(message: msg),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await Future.wait([
        _tokenStore.clearToken(),
        _cache.clear(),
      ]);
      await _sessionService.refreshSession();
      return const Right(null);
    } catch (err) {
      return Left(
        ExceptionMapper.toFailure(
          err,
          fallbackMessage: 'Erro ao sair. Tente novamente.',
          failureFactory: (msg) => DeleteFailure(message: msg),
        ),
      );
    }
  }
}
