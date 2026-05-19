import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/provider/auth_provider.dart';
import 'features/main/provider/main_provider.dart';
import 'router.dart';

void main() {
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
      ],
      child: MaterialApp.router(
        title: 'HolyHabit',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
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
