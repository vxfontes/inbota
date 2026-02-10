import 'package:flutter/material.dart';
import 'package:inbota/modules/auth/data/models/auth_login_input.dart';
import 'package:inbota/modules/auth/domain/usecases/login_usecase.dart';
import 'package:inbota/shared/errors/failures.dart';

class LoginController {
  LoginController(this._loginUsecase);

  final LoginUsecase _loginUsecase;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);

  Future<bool> submit() async {
    if (loading.value) return false;
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      error.value = 'Preencha email e senha.';
      return false;
    }

    loading.value = true;
    error.value = null;

    final result = await _loginUsecase(AuthLoginInput(email: email, password: password));
    loading.value = false;

    return result.fold((failure) {
      error.value = _failureMessage(failure, fallback: 'Nao foi possivel entrar agora.');
      return false;
    }, (_) => true);
  }

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    loading.dispose();
    error.dispose();
  }

  String _failureMessage(Failure failure, {required String fallback}) {
    return failure.message?.trim().isNotEmpty == true ? failure.message! : fallback;
  }
}
