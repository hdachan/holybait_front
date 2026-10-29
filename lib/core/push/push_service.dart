import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';

// 푸시 알림 (Firebase Cloud Messaging) — 지금은 공지·이벤트만
// Firebase 콘솔 > Messaging 에서 토픽으로 보냄
//   notice : 알림 받기 ON 인 기기
//   event  : 알림 받기 ON + 마케팅 정보 수신 동의 (광고성 정보라 동의 필요)
// 웹은 사용하지 않음 (모든 함수가 아무것도 안 함)
class PushService {
  static const _enabledKey = 'push_enabled';
  static const _noticeTopic = 'notice';
  static const _eventTopic = 'event';

  static bool _ready = false;

  // main()에서 runApp 전에 호출. 실패해도 앱은 그대로 실행
  static Future<void> init() async {
    if (kIsWeb) return;
    try {
      await Firebase.initializeApp();
      _ready = true;
      // 앱을 보고 있을 때 온 알림은 시스템 알림이 안 뜨므로 화면 아래 안내로 보여줌
      FirebaseMessaging.onMessage.listen(_showForeground);
    } catch (e) {
      debugPrint('Firebase 초기화 실패: $e');
    }
  }

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  // 로그인 후 홈에 들어왔을 때: 알림 권한 요청(Android 13+, 처음 한 번만 창이 뜸) + 토픽 맞추기
  static Future<void> onLoggedIn({required bool marketingAgreed}) async {
    if (!_ready) return;
    try {
      await FirebaseMessaging.instance.requestPermission();
    } catch (e) {
      debugPrint('알림 권한 요청 실패: $e');
    }
    await syncTopics(marketingAgreed: marketingAgreed);
  }

  // 설정의 '알림 받기' 스위치
  static Future<void> setEnabled(bool value, {required bool marketingAgreed}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
    await syncTopics(marketingAgreed: marketingAgreed);
  }

  // 스위치·마케팅 동의 상태에 맞게 토픽 구독/해제
  // 실패(인터넷 끊김 등)하면 다음 앱 실행 때 다시 맞춰짐
  static Future<void> syncTopics({required bool marketingAgreed}) async {
    if (!_ready) return;
    final enabled = await isEnabled();
    await _setTopic(_noticeTopic, enabled);
    await _setTopic(_eventTopic, enabled && marketingAgreed);
  }

  // 로그아웃·탈퇴·세션 종료: 이 기기는 알림을 받지 않음 (다음 로그인 때 다시 구독)
  static Future<void> clear() async {
    if (!_ready) return;
    await _setTopic(_noticeTopic, false);
    await _setTopic(_eventTopic, false);
  }

  static Future<void> _setTopic(String topic, bool subscribe) async {
    try {
      if (subscribe) {
        await FirebaseMessaging.instance.subscribeToTopic(topic);
      } else {
        await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      }
    } catch (e) {
      debugPrint('토픽 $topic ${subscribe ? '구독' : '해제'} 실패: $e');
    }
  }

  static void _showForeground(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    final text = [n.title, n.body].where((s) => s != null && s.isNotEmpty).join('\n');
    if (text.isEmpty) return;
    scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
      content: Text(text),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 5),
    ));
  }
}
