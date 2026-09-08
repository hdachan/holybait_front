import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';
import '../widgets/google_login_btn.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().addListener(_onAuthChange);
    });
  }

  void _onAuthChange() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.authenticated:
        if (auth.needsConsent) {
          context.go('/consent');
        } else {
          context.go('/home');
        }
      case AuthStatus.banned:
        _showSnackBar('계정이 정지되었습니다. 고객센터에 문의해주세요.');
      case AuthStatus.deleted:
        _showDeletedDialog();
      case AuthStatus.error:
        _showSnackBar(auth.errorMessage ?? '로그인 실패. 다시 시도해주세요.');
      default:
        break;
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  void _showDeletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1225),
        title: const Text('탈퇴한 계정', style: TextStyle(color: Colors.white)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('이미 탈퇴한 계정입니다.',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                textAlign: TextAlign.center),
            SizedBox(height: 8),
            Text('다른 Google 계정으로 로그인하거나\n새로 가입해주세요.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF4A259),
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    context.read<AuthProvider>().removeListener(_onAuthChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 이미지 (고정 높이)
          Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: MediaQuery.of(context).size.width.clamp(0.0, 400.0),
                child: Image.asset(
                  'assets/images/onboarding/login_bg.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
              // 온보딩 다시보기 버튼
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 8,
                child: TextButton(
                  onPressed: () => context.go('/onboarding'),
                  child: Text('둘러보기',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 13)),
                ),
              ),
            ],
          ),

          // 하단 텍스트 + 버튼
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    '이제, 당신의 모험을\n시작해보세요!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '운동하고, 탐험하고, 성장하며\n나만의 이야기를 만들어가요!',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.5),
                      height: 1.5,
                    ),
                  ),
                  const Spacer(),
                  // 구글 로그인 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const GoogleLoginButton(),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}