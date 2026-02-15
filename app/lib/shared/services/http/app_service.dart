import 'package:inbota/shared/services/http/app_path.dart';

class AppService {
  static const String _host = 'http://192.168.0.122:8080';

  static String getBackEndBaseUrl() {
    return '$_host${AppPath.apiPrefix}';
  }
}
