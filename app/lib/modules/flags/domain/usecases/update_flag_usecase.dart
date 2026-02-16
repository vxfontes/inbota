import 'package:inbota/modules/flags/data/models/flag_output.dart';
import 'package:inbota/modules/flags/data/models/flag_update_input.dart';
import 'package:inbota/modules/flags/domain/repositories/i_flag_repository.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/templates/ib_usecase.dart';

class UpdateFlagUsecase extends IBUsecase {
  UpdateFlagUsecase(this._repository);

  final IFlagRepository _repository;

  UsecaseResponse<Failure, FlagOutput> call(FlagUpdateInput input) {
    return _repository.updateFlag(input);
  }
}
