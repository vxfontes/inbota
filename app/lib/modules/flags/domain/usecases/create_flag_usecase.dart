import 'package:inbota/modules/flags/data/models/flag_create_input.dart';
import 'package:inbota/modules/flags/data/models/flag_output.dart';
import 'package:inbota/modules/flags/domain/repositories/i_flag_repository.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/templates/ib_usecase.dart';

class CreateFlagUsecase extends IBUsecase {
  CreateFlagUsecase(this._repository);

  final IFlagRepository _repository;

  UsecaseResponse<Failure, FlagOutput> call(FlagCreateInput input) {
    return _repository.createFlag(input);
  }
}
