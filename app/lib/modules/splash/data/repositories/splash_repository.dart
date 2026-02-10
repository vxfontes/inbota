import 'package:dartz/dartz.dart';
import 'package:inbota/modules/splash/data/models/health_status_output.dart';
import 'package:inbota/modules/splash/domain/repositories/i_splash_repository.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/services/http/http_client.dart';

class SplashRepository implements ISplashRepository {
  SplashRepository(this._httpClient);

  final IHttpClient _httpClient;

  @override
  Future<Either<Failure, HealthStatusOutput>> checkHealth() async {
    try {
      final response = await _httpClient.get(
        '/healthz',
        extra: const {'auth': false},
      );
      final statusCode = response.statusCode ?? 0;

      if (_isSuccess(statusCode)) {
        return Right(HealthStatusOutput.fromJson(_asMap(response.data)));
      }

      return Left(GetFailure(message: _extractMessage(response.data)));
    } catch (err) {
      return Left(GetFailure(message: err.toString()));
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
      return map['message']?.toString() ?? 'Servidor indisponivel.';
    }
    return 'Servidor indisponivel.';
  }

  String _mapErrorCode(String error) {
    switch (error) {
      case 'connection_refused':
        return 'Servidor indisponivel. Verifique a rede local.';
      case 'timeout':
        return 'Tempo de conexao esgotado.';
      default:
        return error;
    }
  }
}
