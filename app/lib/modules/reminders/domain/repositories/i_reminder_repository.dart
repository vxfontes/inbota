import 'package:dartz/dartz.dart';

import 'package:inbota/modules/reminders/data/models/reminder_list_output.dart';
import 'package:inbota/modules/reminders/data/models/reminder_output.dart';
import 'package:inbota/modules/reminders/data/models/reminder_update_input.dart';
import 'package:inbota/shared/errors/failures.dart';

abstract class IReminderRepository {
  Future<Either<Failure, ReminderListOutput>> fetchReminders({int? limit, String? cursor});
  Future<Either<Failure, ReminderOutput>> updateReminder(ReminderUpdateInput input);
}
