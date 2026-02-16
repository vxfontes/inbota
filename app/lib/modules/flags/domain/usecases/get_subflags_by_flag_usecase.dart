import 'package:inbota/modules/flags/data/models/subflag_list_output.dart';
import 'package:inbota/modules/flags/domain/repositories/i_flag_repository.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/templates/ib_usecase.dart';

class GetSubflagsByFlagUsecase extends IBUsecase {
  GetSubflagsByFlagUsecase(this._repository);

  final IFlagRepository _repository;

  UsecaseResponse<Failure, SubflagListOutput> call({
    required String flagId,
    int? limit,
    String? cursor,
  }) {
    return _repository.fetchSubflagsByFlag(
      flagId: flagId,
      limit: limit,
      cursor: cursor,
    );
  }
}
