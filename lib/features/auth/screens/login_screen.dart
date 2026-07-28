import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';
import '../widgets/google_login_btn.dart';
import '../../../core/widgets/app_background.dart';

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
      // 신규 유저이고 동의 안 했으면 동의 화면으로
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
        title: const Text('탈퇴한 계정',
            style: TextStyle(color: Colors.white)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('이미 탈퇴한 계정입니다.',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white),
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
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 3),
                const Text(
                  'HolyHabit',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '운동하고 레벨업하세요.',
                  style: TextStyle(
                      fontSize: 16, color: Colors.white.withOpacity(0.5)),
                ),
                const Spacer(flex: 4),
                const GoogleLoginButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}