import 'package:flutter/foundation.dart';

// 서버 로그인 기록(login_history.device_info)에 남길 기기 종류
String get deviceInfoLabel {
  if (kIsWeb) return 'flutter_web';
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => 'flutter_android',
    TargetPlatform.iOS => 'flutter_ios',
    _ => 'flutter_${defaultTargetPlatform.name}',
  };
}
