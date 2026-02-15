import 'package:flutter_modular/flutter_modular.dart';
import 'package:inbota/modules/flags/data/repositories/flag_repository.dart';
import 'package:inbota/modules/flags/domain/repositories/i_flag_repository.dart';
import 'package:inbota/modules/flags/domain/usecases/get_flags_usecase.dart';

class FlagsModule {
  static void binds(Injector i) {
    // repository
    i.addLazySingleton<IFlagRepository>(FlagRepository.new);

    // usecases
    i.addLazySingleton<GetFlagsUsecase>(GetFlagsUsecase.new);
  }
}
