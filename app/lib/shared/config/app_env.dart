class AppEnv {
  AppEnv._();

  static const String _apiHost = String.fromEnvironment('API_HOST');

  static String get apiHost {
    final host = _apiHost.trim();
    if (host.isEmpty) {
      throw StateError(
        'API_HOST nao definido. Rode com --dart-define=API_HOST=https://seu-backend.com',
      );
    }

    return host.replaceFirst(RegExp(r'/+$'), '');
  }
}
