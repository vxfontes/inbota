// Locks the DELETE /v1/me contract from the app side.
//
// The rule these tests exist to protect: no machine string ever reaches the
// UI of this flow. ApiErrorMapper.mapCode falls back to the raw code for
// anything it does not know, so parsing the body here would print things like
// `rate_limited` inside the password field of an App Store reviewer.

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiq/modules/auth/data/repositories/auth_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/services/analytics/app_session_service.dart';
import 'package:organiq/shared/services/cache/cache_service.dart';
import 'package:organiq/shared/services/http/http_client.dart';
import 'package:organiq/shared/storage/auth_token_store.dart';
import 'package:organiq/shared/storage/token_storage.dart';

const String _wrongPassword = 'Senha incorreta. Tente de novo.';
const String _tooManyAttempts = 'Muitas tentativas. Aguarde um minuto e tente de novo.';
const String _genericFailure = 'Não foi possível excluir sua conta agora. Tente novamente.';

void main() {
  group('AuthRepository.deleteAccount', () {
    test('204 sem body devolve sucesso e envia a senha em /me', () async {
      final http = _FakeHttpClient(ResponseModel(statusCode: 204));

      final result = await _repositoryWith(http).deleteAccount('senha-certa');

      expect(result.isRight(), isTrue);
      expect(http.capturedPath, '/me');
      expect(http.capturedData, {'password': 'senha-certa'});
    });

    test('403 vira mensagem de senha errada, corrigível sem sair do sheet', () async {
      final http = _FakeHttpClient(
        ResponseModel(statusCode: 403, data: const {'error': 'incorrect_password'}),
      );

      final result = await _repositoryWith(http).deleteAccount('senha-errada');

      expect(result.isLeft(), isTrue);
      expect(_failureOf(result), isA<InvalidParameterFailure>());
      expect(_messageOf(result), _wrongPassword);
    });

    // O caso que a enumeração anterior não cobria: listar os códigos conhecidos
    // é denylist, e um valor novo vazava cru. Aqui o body é ignorado de vez.
    test('403 com código desconhecido continua humano, sem vazar o body', () async {
      final http = _FakeHttpClient(
        ResponseModel(statusCode: 403, data: const {'error': 'codigo_que_ninguem_mapeou'}),
      );

      final result = await _repositoryWith(http).deleteAccount('senha-errada');

      expect(_messageOf(result), _wrongPassword);
      expect(_messageOf(result), isNot(contains('codigo_que_ninguem_mapeou')));
    });

    // RateLimitByIP(5, time.Minute) na rota. Revisor da Apple erra a senha de
    // propósito e sai por NAT compartilhado: 429 é estado normal aqui.
    test('429 vira mensagem humana e nunca a string rate_limited', () async {
      final http = _FakeHttpClient(
        ResponseModel(statusCode: 429, data: const {'error': 'rate_limited'}),
      );

      final result = await _repositoryWith(http).deleteAccount('senha-certa');

      expect(_messageOf(result), _tooManyAttempts);
      expect(_messageOf(result), isNot(contains('rate_limited')));
    });

    test('500 não vaza internal_error', () async {
      final http = _FakeHttpClient(
        ResponseModel(statusCode: 500, data: const {'error': 'internal_error'}),
      );

      expect(_messageOf(await _repositoryWith(http).deleteAccount('x')), _genericFailure);
    });

    // Estado real de hoje: a rota ainda não está publicada no Render.
    test('404 de rota não publicada não vaza not_found', () async {
      final http = _FakeHttpClient(
        ResponseModel(statusCode: 404, data: const {'error': 'not_found'}),
      );

      final result = await _repositoryWith(http).deleteAccount('x');

      expect(_messageOf(result), _genericFailure);
      expect(_messageOf(result), isNot(contains('not_found')));
    });
  });
}

AuthRepository _repositoryWith(_FakeHttpClient http) => AuthRepository(
  http,
  AuthTokenStore(const TokenStorage()),
  AppSessionService(),
  _FakeCacheService(),
);

Failure? _failureOf(Either<Failure, void> result) =>
    result.fold((failure) => failure, (_) => null);

String? _messageOf(Either<Failure, void> result) =>
    result.fold((failure) => failure.message, (_) => null);

class _FakeHttpClient implements IHttpClient {
  _FakeHttpClient(this._response);

  final ResponseModel _response;

  String? capturedPath;
  dynamic capturedData;

  @override
  Future<ResponseModel> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? extra,
  }) async {
    capturedPath = path;
    capturedData = data;
    return _response;
  }

  @override
  Future<ResponseModel> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? extra,
    ResponseType responseType = ResponseType.json,
  }) => throw UnimplementedError();

  @override
  Future<ResponseModel> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? extra,
  }) => throw UnimplementedError();

  @override
  Future<ResponseModel> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? extra,
  }) => throw UnimplementedError();

  @override
  Future<ResponseModel> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? extra,
  }) => throw UnimplementedError();
}

class _FakeCacheService implements ICacheService {
  @override
  Future<Map<String, dynamic>?> get(String key) async => null;

  @override
  Future<void> set(
    String key,
    Map<String, dynamic> data, {
    Duration ttl = CacheService.defaultTtl,
  }) async {}

  @override
  Future<void> invalidate(String key) async {}

  @override
  Future<void> clear() async {}
}
