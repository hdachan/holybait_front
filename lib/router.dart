import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'features/auth/provider/auth_provider.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/main/main_screen.dart';
import 'features/routine/screens/routine_detail_screen.dart';
import 'features/routine/screens/exercise_pick_screen.dart';
import 'data/models/routine_model.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/',      builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/home',  builder: (_, __) => const MainScreen()),
    GoRoute(
      path: '/routine/:id',
      builder: (context, state) {
        final routine = state.extra as RoutineModel;
        return RoutineDetailScreen(routine: routine);
      },
    ),
    GoRoute(
      path: '/exercise-pick',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ExercisePickScreen(
          alreadyAdded: extra?['alreadyAdded'] as Set<int>? ?? {},
          onComplete: extra?['onComplete'] as void Function(List)?,
        );
      },
    ),
  ],
  redirect: (context, state) {
    if (state.matchedLocation == '/home') {
      final auth = context.read<AuthProvider>();
      if (auth.user == null) return '/';
    }
    return null;
  },
);