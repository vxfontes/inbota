import 'package:flutter/material.dart';
import 'package:organiq/modules/auth/domain/usecases/delete_account_usecase.dart';
import 'package:organiq/modules/auth/domain/usecases/logout_usecase.dart';
import 'package:organiq/presentation/routes/app_navigation.dart';
import 'package:organiq/presentation/routes/app_routes.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/services/analytics/app_monitoring_service.dart';
import 'package:organiq/shared/services/timezone/user_timezone_service.dart';
import 'package:organiq/shared/state/oq_state.dart';

class SettingsController implements OQController {
  SettingsController(
    this._logoutUsecase,
    this._deleteAccountUsecase,
    this._monitoringService,
  );

  final LogoutUsecase _logoutUsecase;
  final DeleteAccountUsecase _deleteAccountUsecase;
  final AppMonitoringService _monitoringService;

  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);

  Future<bool> fetchLogout() async {
    if (loading.value) return false;
    loading.value = true;
    error.value = null;

    final result = await _logoutUsecase.call();
    loading.value = false;

    return result.fold((failure) {
      error.value = _failureMessage(
        failure,
        fallback: 'Não foi possível sair agora.',
      );
      return false;
    }, (_) => true);
  }

  Future<void> logout() async {
    final success = await fetchLogout();
    if (!success) return;
    UserTimezoneService.instance.clear();
    await _monitoringService.logEvent('auth_logout');
    await _monitoringService.clearUser();
    AppNavigation.clearAndPush(AppRoutes.auth);
  }

  /// Returns a message for the confirmation sheet to show inline, or null when
  /// the account is gone. Navigation is left to [finishAccountDeletion] so the
  /// sheet closes before the stack is cleared.
  Future<String?> deleteAccount(String password) async {
    final result = await _deleteAccountUsecase.call(password);

    final failure = result.fold<Failure?>((failure) => failure, (_) => null);
    if (failure != null) {
      return _failureMessage(
        failure,
        fallback: 'Não foi possível excluir sua conta agora.',
      );
    }

    return null;
  }

  Future<void> finishAccountDeletion() async {
    UserTimezoneService.instance.clear();
    await _monitoringService.logEvent('account_deleted');
    await _monitoringService.clearUser();
    AppNavigation.clearAndPush(AppRoutes.auth);
  }

  @override
  void dispose() {
    loading.dispose();
    error.dispose();
  }

  String _failureMessage(Failure failure, {required String fallback}) {
    return failure.message?.trim().isNotEmpty == true
        ? failure.message!
        : fallback;
  }
}
