import 'package:dartz/dartz.dart';

import 'package:inbota/modules/flags/data/models/flag_list_output.dart';
import 'package:inbota/shared/errors/failures.dart';

abstract class IFlagRepository {
  Future<Either<Failure, FlagListOutput>> fetchFlags({ int? limit, String? cursor });
}
