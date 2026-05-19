import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../home/screens/home_screen.dart';
import '../adventure/screens/adventure_screen.dart';
import '../character/screens/character_screen.dart';
import '../settings/screens/settings_screen.dart';
import 'provider/main_provider.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  static const _screens = [
    HomeScreen(),
    AdventureScreen(),
    CharacterScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final main = context.watch<MainProvider>();

    return Scaffold(
      body: IndexedStack(
        index: main.currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: main.currentIndex,
        onTap: main.setIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1E3A5F),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: '모험'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '캐릭터'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }
}
