import 'package:inbota/modules/reminders/data/models/reminder_output.dart';
import 'package:inbota/modules/reminders/data/models/reminder_update_input.dart';
import 'package:inbota/modules/reminders/domain/repositories/i_reminder_repository.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/templates/ib_usecase.dart';

class UpdateReminderUsecase extends IBUsecase {
  final IReminderRepository _repository;

  UpdateReminderUsecase(this._repository);

  UsecaseResponse<Failure, ReminderOutput> call(ReminderUpdateInput input) {
    return _repository.updateReminder(input);
  }
}
