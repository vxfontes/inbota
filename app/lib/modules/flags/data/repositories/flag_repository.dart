import 'package:dartz/dartz.dart';

import 'package:inbota/modules/flags/data/models/flag_list_output.dart';
import 'package:inbota/modules/flags/domain/repositories/i_flag_repository.dart';
import 'package:inbota/shared/errors/api_error_mapper.dart';
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

      return Left(
        GetListFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao carregar flags.',
          ),
        ),
      );
    } catch (err) {
      return Left(GetListFailure(message: err.toString()));
    }
  }

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;
}
