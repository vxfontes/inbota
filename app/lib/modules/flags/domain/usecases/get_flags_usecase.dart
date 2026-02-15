import 'package:inbota/modules/flags/data/models/flag_list_output.dart';
import 'package:inbota/modules/flags/domain/repositories/i_flag_repository.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/templates/ib_usecase.dart';

class GetFlagsUsecase extends IBUsecase {
  final IFlagRepository _repository;

  GetFlagsUsecase(this._repository);

  UsecaseResponse<Failure, FlagListOutput> call({int? limit, String? cursor}) {
    return _repository.fetchFlags(limit: limit, cursor: cursor);
  }
}
