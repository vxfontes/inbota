import 'package:dartz/dartz.dart';

import 'package:inbota/modules/home/data/models/home_dashboard_output.dart';
import 'package:inbota/modules/home/domain/repositories/i_home_repository.dart';
import 'package:inbota/shared/errors/api_error_mapper.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/services/http/app_path.dart';
import 'package:inbota/shared/services/http/http_client.dart';

class HomeRepository implements IHomeRepository {
  HomeRepository(this._httpClient);

  final IHttpClient _httpClient;

  @override
  Future<Either<Failure, HomeDashboardOutput>> fetchDashboard() async {
    try {
      final response = await _httpClient.get(AppPath.homeDashboard);
      final statusCode = response.statusCode ?? 0;

      if (_isSuccess(statusCode)) {
        return Right(HomeDashboardOutput.fromDynamic(response.data));
      }

      return Left(
        GetFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao carregar dashboard da Home.',
          ),
        ),
      );
    } catch (err) {
      return Left(GetFailure(message: err.toString()));
    }
  }

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;
}
