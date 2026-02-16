import 'package:inbota/shared/config/app_env.dart';
import 'package:inbota/shared/services/http/app_path.dart';

class AppService {
  static String getBackEndBaseUrl() {
    return '${AppEnv.apiHost}${AppPath.apiPrefix}';
  }
}
