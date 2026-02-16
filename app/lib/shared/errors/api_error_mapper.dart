class ApiErrorMapper {
  ApiErrorMapper._();

  static const Map<String, String> _defaultCodeMessages = {
    'connection_refused': 'Sem conexao com o servidor.',
    'timeout': 'Tempo de conexao esgotado.',
    'invalid_payload': 'Dados invalidos. Verifique os campos.',
  };

  static String fromResponseData(
    dynamic data, {
    required String fallbackMessage,
    Map<String, String> codeOverrides = const {},
  }) {
    if (data is Map) {
      final map = data.map((key, value) => MapEntry(key.toString(), value));
      final errorCode = map['error']?.toString();
      if (errorCode != null && errorCode.isNotEmpty) {
        return mapCode(errorCode, overrides: codeOverrides);
      }

      final message = map['message']?.toString();
      if (message != null && message.isNotEmpty) {
        return message;
      }
    }

    return fallbackMessage;
  }

  static String mapCode(
    String code, {
    Map<String, String> overrides = const {},
  }) {
    if (overrides.containsKey(code)) {
      return overrides[code]!;
    }
    return _defaultCodeMessages[code] ?? code;
  }
}
