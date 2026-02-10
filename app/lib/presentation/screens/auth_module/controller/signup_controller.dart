import 'package:flutter/material.dart';
import 'package:inbota/modules/auth/data/models/auth_signup_input.dart';
import 'package:inbota/modules/auth/domain/usecases/signup_usecase.dart';
import 'package:inbota/shared/errors/failures.dart';

class SignupController {
  final SignupUsecase _signupUsecase;

  SignupController(this._signupUsecase);

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);

  Future<bool> submit({required String locale, required String timezone}) async {
    if (loading.value) return false;
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      error.value = 'Preencha todos os campos.';
      return false;
    }

    loading.value = true;
    error.value = null;

    final result = await _signupUsecase.call(AuthSignupInput(
      email: email,
      password: password,
      displayName: name,
      locale: locale,
      timezone: timezone,
    ));

    loading.value = false;

    return result.fold((failure) {
      error.value = _failureMessage(failure, fallback: 'Nao foi possivel criar a conta agora.');
      return false;
    }, (_) => true);
  }

  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    loading.dispose();
    error.dispose();
  }

  String _failureMessage(Failure failure, {required String fallback}) {
    return failure.message?.trim().isNotEmpty == true ? failure.message! : fallback;
  }
}
