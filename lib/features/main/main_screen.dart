import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../home/screens/home_screen.dart';
import '../character/screens/character_screen.dart';
import '../settings/screens/settings_screen.dart';
import '../planet/screens/planet_screen.dart';
import 'provider/main_provider.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  static const _screens = [
    HomeScreen(),
    PlanetScreen(),
    CharacterScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final main = context.watch<MainProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0e0a1a),
      body: IndexedStack(
        index: main.currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _BottomBar(
        currentIndex: main.currentIndex,
        onTap: main.setIndex,
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomBar({
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _BarItem(icon: Icons.home_rounded, label: '홈'),
    _BarItem(icon: Icons.public_rounded, label: '모험'),
    _BarItem(icon: Icons.person_rounded, label: '캐릭터'),
    _BarItem(icon: Icons.settings_rounded, label: '설정'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF160d1f),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final isSelected = i == currentIndex;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          size: 24,
                          color: isSelected
                              ? const Color(0xFFF4A259)
                              : Colors.white.withOpacity(0.4),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFFF4A259)
                                : Colors.white.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _BarItem {
  final IconData icon;
  final String label;
  const _BarItem({required this.icon, required this.label});
}