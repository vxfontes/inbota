// export isso aqui como faço

import 'package:flutter/foundation.dart';

class InfosDevice {
  static bool get isMobile => _isMobile();
  static bool get isDesktop => _isDesktop();
  static bool get isIOS =>
      _isMobile() && defaultTargetPlatform == TargetPlatform.iOS;
  static bool get isAndroid =>
      _isMobile() && defaultTargetPlatform == TargetPlatform.android;
  static bool get isMacOS =>
      _isDesktop() && defaultTargetPlatform == TargetPlatform.macOS;
  static bool get isWindows =>
      _isDesktop() && defaultTargetPlatform == TargetPlatform.windows;
  static bool get isLinux =>
      _isDesktop() && defaultTargetPlatform == TargetPlatform.linux;

  static bool _isMobile() {
    try {
      return (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);
    } catch (e) {
      return false;
    }
  }

  static bool _isDesktop() {
    try {
      return (defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux);
    } catch (e) {
      return false;
    }
  }
}
