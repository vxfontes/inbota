import 'package:dartz/dartz.dart';
import 'package:organiq/modules/auth/domain/repositories/i_auth_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/services/push/push_notification_service.dart';
import 'package:organiq/shared/templates/oq_usecase.dart';

class DeleteAccountUsecase extends OQUsecase {
  final IAuthRepository _repository;

  DeleteAccountUsecase(this._repository);

  UsecaseResponse<Failure, void> call(String password) async {
    final result = await _repository.deleteAccount(password);
    if (result.isLeft()) return result;

    // The account is already gone server-side, so the local teardown must reach
    // the login screen no matter what: every failure below is dropped on
    // purpose. A token that survives is cleared by the 401 on the next request.
    try {
      await PushNotificationService.instance.unregisterDevice(
        remote: false,
        purgeStoredDeviceId: true,
      );
    } catch (_) {}

    await _repository.logout();
    return const Right(null);
  }
}
