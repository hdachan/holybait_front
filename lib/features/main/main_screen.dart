import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../home/screens/home_screen.dart';
import '../character/screens/character_screen.dart';
import '../settings/screens/settings_screen.dart';
import '../planet/screens/planet_screen.dart';
import '../adventure/widgets/pending_battle_dialog.dart';
import 'provider/main_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const _screens = [
    HomeScreen(),
    PlanetScreen(),
    CharacterScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // 앱을 켰을 때(로그인 직후 포함) 끝까지 보지 않고 나간 배틀이 있으면 이어하기 팝업
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) checkPendingBattleAndPrompt(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final main = context.watch<MainProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF0e0a1a),
      // 안 보이는 탭도 살아 있으므로, 지금 보는 탭만 애니메이션을 켬 (배터리 절약)
      body: IndexedStack(
        index: main.currentIndex,
        children: [
          for (var i = 0; i < _screens.length; i++)
            TickerMode(enabled: i == main.currentIndex, child: _screens[i]),
        ],
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
    _BarItem(iconN: 'assets/images/onboarding/icon/icon_home_n.png',
        iconS: 'assets/images/onboarding/icon/icon_home_s.png',
        label: '홈'),
    _BarItem(iconN: 'assets/images/onboarding/icon/icon_map_n.png',
        iconS: 'assets/images/onboarding/icon/icon_map_s.png',
        label: '모험'),
    _BarItem(iconN: 'assets/images/onboarding/icon/icon_c_n.png',
        iconS: 'assets/images/onboarding/icon/icon_c_s.png',
        label: '캐릭터'),
    _BarItem(iconN: 'assets/images/onboarding/icon/icon_setting_n.png',
        iconS: 'assets/images/onboarding/icon/icon_setting_s.png',
        label: '설정'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF000000),
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
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // 글로우 효과 (아이콘 바로 뒤, 크게)
                      if (isSelected)
                        Positioned(
                          top: 4,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Opacity(
                              opacity: 0.6,
                              child: Image.asset(
                                'assets/images/onboarding/Bottom_Glow_Effect.png',
                                width: 48,
                                height: 48,
                                fit: BoxFit.fill,
                              ),
                            ),
                          ),
                        ),

                      // 아이콘 + 텍스트
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              isSelected ? item.iconS : item.iconN,
                              width: 24,
                              height: 24,
                              fit: BoxFit.contain,
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

                      // 하단 인디케이터
                      if (isSelected)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Image.asset(
                              'assets/images/onboarding/Bottom_Indicator_Light.png',
                              width: 36,
                              fit: BoxFit.fitWidth,
                            ),
                          ),
                        ),
                    ],
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
  final String iconN;
  final String iconS;
  final String label;
  const _BarItem({required this.iconN, required this.iconS, required this.label});
}