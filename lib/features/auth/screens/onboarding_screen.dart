import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  static const _totalPages = 4;

  static const _titles = [
    '환영해요, 탐험가님!',
    '운동하면 코인이 쌓여요!',
    '코인으로 탐험을 떠나요!',
    '탐험에서 성장해요!',
  ];

  static const _subtitles = [
    '운동하고, 탐험하고,\n캐릭터를 키우는 특별한 모험을 시작해요',
    '운동을 완료할 때마다 코인을\n획득할 수 있어요',
    '모은 코인으로 탐험을 떠나면\n다양한 아이템과 경험치를 얻을 수 있어요',
    '탐험을 통해 경험치를 모으면\n캐릭터가 더 강해져요!',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _complete() {
    if (mounted) context.go('/login');
  }

  void _next() {
    if (_currentPage < _totalPages - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // 메인 컬럼
            Column(
              children: [
                // 이미지 영역
                Expanded(
                  flex: 7,
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _totalPages,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (context, i) {
                      final pageNum = (i + 1).toString().padLeft(2, '0');
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Center(
                          child: Image.asset(
                            'assets/images/onboarding/onboarding_$pageNum.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 텍스트 + 하단 UI
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 제목
                      Text(
                        _titles[_currentPage],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      // 소제목
                      Text(
                        _subtitles[_currentPage],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      // 인디케이터
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            (_currentPage + 1).toString().padLeft(2, '0'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF4A259),
                            ),
                          ),
                          Text(
                            ' / ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          Text(
                            _totalPages.toString().padLeft(2, '0'),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // 다음/시작하기 버튼
                      Center(
                        child: _OnboardingButton(
                          label: _currentPage < _totalPages - 1 ? '다음' : '시작하기',
                          onTap: _next,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),

            // 오른쪽 상단 건너뛰기
            if (_currentPage < _totalPages - 1)
              Positioned(
                top: 8,
                right: 8,
                child: TextButton(
                  onPressed: _complete,
                  child: Text('건너뛰기',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── 온보딩 버튼 ──
class _OnboardingButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _OnboardingButton({required this.label, required this.onTap});

  @override
  State<_OnboardingButton> createState() => _OnboardingButtonState();
}

class _OnboardingButtonState extends State<_OnboardingButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    const double btnH = 50.0;
    const double leftW = 80 * (btnH / 221);
    const double rightW = 160 * (btnH / 221);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(
            0,
            _pressed ? 2 : (_hovered ? -4 : 0),
            0,
          ),
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: SizedBox(
              height: btnH,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 골드 글로우
                  AnimatedOpacity(
                    opacity: _hovered && !_pressed ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xAAFFD700),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 3조각 버튼
                  Positioned.fill(
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/onboarding/onboring_bt_normal_left.png',
                          width: leftW,
                          height: btnH,
                          fit: BoxFit.fill,
                        ),
                        Expanded(
                          child: Image.asset(
                            'assets/images/onboarding/onboring_bt_normal_mid.png',
                            height: btnH,
                            fit: BoxFit.fill,
                          ),
                        ),
                        Image.asset(
                          'assets/images/onboarding/onboring_bt_normal_right.png',
                          width: rightW,
                          height: btnH,
                          fit: BoxFit.fill,
                        ),
                      ],
                    ),
                  ),
                  // 클릭 시 테두리 플래시
                  if (_pressed)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFFD700).withOpacity(0.8),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  // 텍스트
                  Center(
                    child: Text(
                      widget.label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E2723),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}