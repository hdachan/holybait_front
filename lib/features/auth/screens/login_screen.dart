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
        context.go('/home');
      case AuthStatus.banned:
        _showSnackBar('계정이 정지되었습니다.');
      case AuthStatus.deleted:
        _showSnackBar('탈퇴한 계정입니다.');
      case AuthStatus.error:
        _showSnackBar(auth.errorMessage ?? '로그인 실패. 다시 시도해주세요.');
      default:
        break;
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
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
      body: SafeArea(
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
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '운동하고 레벨업하세요.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const Spacer(flex: 4),
              const GoogleLoginButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
