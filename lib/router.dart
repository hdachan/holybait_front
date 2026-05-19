import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'features/auth/provider/auth_provider.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/main/main_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/',      builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/home',  builder: (_, __) => const MainScreen()),
  ],
  // 새로고침 시 항상 스플래시부터 시작
  redirect: (context, state) {
    if (state.matchedLocation == '/home') {
      final auth = context.read<AuthProvider>();
      if (auth.user == null) return '/';
    }
    return null;
  },
);