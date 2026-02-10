import 'package:flutter/foundation.dart';
import 'package:inbota/modules/splash/domain/usecases/check_health_usecase.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/state/ib_state.dart';

class SplashController implements IBController {
  SplashController(this._checkHealthUsecase);

  final CheckHealthUsecase _checkHealthUsecase;

  final ValueNotifier<bool> loading = ValueNotifier(true);
  final ValueNotifier<String?> error = ValueNotifier(null);

  Future<bool> check() async {
    loading.value = true;
    error.value = null;

    final result = await _checkHealthUsecase.call();
    loading.value = false;

    return result.fold((failure) {
      error.value = _failureMessage(
        failure,
        fallback: 'Servidor indisponivel. Verifique a rede local.',
      );
      return false;
    }, (_) => true);
  }

  @override
  void dispose() {
    loading.dispose();
    error.dispose();
  }

  String _failureMessage(Failure failure, {required String fallback}) {
    return failure.message?.trim().isNotEmpty == true ? failure.message! : fallback;
  }
}
