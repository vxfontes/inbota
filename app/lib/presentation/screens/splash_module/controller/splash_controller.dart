import 'package:flutter/foundation.dart';
import 'package:inbota/modules/auth/domain/usecases/get_me_usecase.dart';
import 'package:inbota/modules/splash/domain/usecases/check_health_usecase.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/state/ib_state.dart';
import 'package:inbota/shared/storage/auth_token_store.dart';

class SplashController implements IBController {
  SplashController(
    this._checkHealthUsecase,
    this._tokenStore,
    this._getMeUsecase,
  );

  final CheckHealthUsecase _checkHealthUsecase;
  final AuthTokenStore _tokenStore;
  final GetMeUsecase _getMeUsecase;

  final ValueNotifier<bool> loading = ValueNotifier(true);
  final ValueNotifier<String?> error = ValueNotifier(null);

  Future<bool?> check() async {
    loading.value = true;
    error.value = null;

    try {
      final result = await _checkHealthUsecase.call();
      final healthy = result.fold((failure) {
        error.value = _failureMessage(
          failure,
          fallback: 'Servidor indisponivel. Verifique a rede local.',
        );
        return false;
      }, (_) => true);

      if (!healthy) return null;

      final token = await _tokenStore.readToken();
      if (token == null || token.isEmpty) {
        return false;
      }

      final meResult = await _getMeUsecase.call();
      final hasSession = meResult.fold((_) => false, (_) => true);
      if (!hasSession) {
        await _tokenStore.clearToken();
      }
      return hasSession;
    } finally {
      loading.value = false;
    }
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
