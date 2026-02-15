import 'package:dartz/dartz.dart' show Unit;
import 'package:inbota/modules/reminders/domain/repositories/i_reminder_repository.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/templates/ib_usecase.dart';

class DeleteReminderUsecase extends IBUsecase {
  DeleteReminderUsecase(this._repository);

  final IReminderRepository _repository;

  UsecaseResponse<Failure, Unit> call(String id) {
    return _repository.deleteReminder(id);
  }
}
