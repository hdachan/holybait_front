import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../provider/auth_provider.dart';
import '../../../core/network/api_client.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // 스토어 링크 (출시 후 실제 링크로 교체)
  static const _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.holyhabit.holyhabit';
  static const _appStoreUrl =
      'https://apps.apple.com/app/holyhabit/id000000000';

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    // 1. 버전 체크
    final shouldContinue = await _checkVersion();
    if (!shouldContinue || !mounted) return;

    // 2. JWT 체크
    await context.read<AuthProvider>().checkAuth();
    if (!mounted) return;

    final status = context.read<AuthProvider>().status;
    if (status == AuthStatus.authenticated) {
      context.go('/home');
    } else {
      context.go('/onboarding');
    }
  }

  Future<bool> _checkVersion() async {
    try {
      // 현재 앱 버전
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version; // 예: "1.0.0"

      // 서버에서 버전 정보 가져오기
      final res = await ApiClient.dio.get('/app/version');
      final minVersion = res.data['minVersion'] as String;
      final latestVersion = res.data['latestVersion'] as String;
      final forceUpdate = res.data['forceUpdate'] as bool;

      if (_isOlderVersion(currentVersion, minVersion)) {
        // 강제 업데이트
        if (mounted) _showUpdateDialog(force: true);
        return false;
      }

      if (_isOlderVersion(currentVersion, latestVersion)) {
        // 권장 업데이트
        if (mounted) {
          final skip = await _showUpdateDialog(force: false);
          if (skip) return true; // 나중에 누르면 계속 진행
        }
        return false;
      }

      return true;
    } catch (_) {
      // 버전 체크 실패 시 그냥 진행
      return true;
    }
  }

  // 버전 비교 (1.0.0 형식)
  bool _isOlderVersion(String current, String target) {
    final c = current.split('.').map(int.parse).toList();
    final t = target.split('.').map(int.parse).toList();
    for (int i = 0; i < 3; i++) {
      if (c[i] < t[i]) return true;
      if (c[i] > t[i]) return false;
    }
    return false;
  }

  Future<bool> _showUpdateDialog({required bool force}) async {
    if (!mounted) return true;

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C0E04),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('🚀', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text('업데이트 알림',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          force
              ? '더 나은 서비스를 위해\n업데이트가 필요해요.'
              : '새로운 버전이 출시됐어요!\n업데이트하고 더 즐겨보세요.',
          style: TextStyle(
              color: Colors.white.withOpacity(0.7), fontSize: 14, height: 1.5),
        ),
        actions: [
          if (!force)
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('나중에',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4))),
            ),
          SizedBox(
            width: force ? double.infinity : null,
            child: ElevatedButton(
              onPressed: () async {
                final url = Uri.parse(
                  Theme.of(context).platform == TargetPlatform.iOS
                      ? _appStoreUrl
                      : _playStoreUrl,
                );
                if (await canLaunchUrl(url)) {
                  await launchUrl(url,
                      mode: LaunchMode.externalApplication);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF7910),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('업데이트 하러 가기',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    ) ??
        true;
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
          child: CircularProgressIndicator(color: Color(0xFFEF7910))),
    );
  }
}