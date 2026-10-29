import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/adventure/provider/adventure_provider.dart';
import 'features/auth/provider/auth_provider.dart';
import 'features/main/provider/main_provider.dart';
import 'features/routine/provider/routine_provider.dart';
import 'features/currency/provider/currency_provider.dart';
import 'features/step/step_provider.dart';
import 'features/planet/provider/planet_provider.dart';
import 'features/quest/provider/quest_provider.dart';
import 'router.dart';
import 'core/push/push_service.dart';

// 전역 navigatorKey (auth_interceptor에서 팝업 띄울 때 사용)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 전역 안내(스낵바)용 — 인터넷 연결 안내 등 화면과 관계없이 띄울 때
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushService.init();
  runApp(const HolyHabitApp());
}

class HolyHabitApp extends StatelessWidget {
  const HolyHabitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MainProvider()),
        ChangeNotifierProvider(create: (_) => RoutineProvider()),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
        ChangeNotifierProvider(create: (_) => AdventureProvider()),
        ChangeNotifierProvider(create: (_) => StepProvider()),
        ChangeNotifierProvider(create: (_) => PlanetProvider()),
        ChangeNotifierProvider(create: (_) => QuestProvider()),
      ],
      child: MaterialApp.router(
        title: 'HolyHabit',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: scaffoldMessengerKey,
        theme: ThemeData(
          fontFamily: 'Paperlogy',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E3A5F),
          ),
          useMaterial3: true,
        ),
        routerConfig: router,
      ),
    );
  }
}