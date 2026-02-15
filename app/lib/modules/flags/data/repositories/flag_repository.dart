import 'package:dartz/dartz.dart';

import 'package:inbota/modules/flags/data/models/flag_list_output.dart';
import 'package:inbota/modules/flags/domain/repositories/i_flag_repository.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/services/http/http_client.dart';

class FlagRepository implements IFlagRepository {
  FlagRepository(this._httpClient);

  final IHttpClient _httpClient;
  final String _path = '/flags';

  @override
  Future<Either<Failure, FlagListOutput>> fetchFlags({
    int? limit,
    String? cursor,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (limit != null) query['limit'] = limit;
      if (cursor != null) query['cursor'] = cursor;

      final response = await _httpClient.get(
        _path,
        queryParameters: query.isEmpty ? null : query,
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        return Right(FlagListOutput.fromDynamic(response.data));
      }

      return Left(GetListFailure(message: _extractMessage(response.data)));
    } catch (err) {
      return Left(GetListFailure(message: err.toString()));
    }
  }

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

  String _extractMessage(dynamic data) {
    if (data is Map) {
      final map = data.map((key, value) => MapEntry(key.toString(), value));
      final error = map['error']?.toString();
      if (error != null && error.isNotEmpty) {
        return _mapErrorCode(error);
      }
      return map['message']?.toString() ?? 'Erro ao carregar flags.';
    }
    return 'Erro ao carregar flags.';
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
