import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/provider/auth_provider.dart';
import '../step_provider.dart';

// ── 걸음수 항해 위젯 (10만보마다 배경 교체, 누적 걸음수 비율로 배 이동) ──
class StepVoyageWidget extends StatefulWidget {
  const StepVoyageWidget({super.key});

  @override
  State<StepVoyageWidget> createState() => _StepVoyageWidgetState();
}

class _StepVoyageWidgetState extends State<StepVoyageWidget> {
  final ScrollController _scrollController = ScrollController();

  static const double _trackWidth = 3000;
  static const double _trackHeight = 260;
  static const double _shipSize = 240;
  static const int _stepsPerChapter = 100000; // 10만보마다 챕터(배경) 전환

  // 챕터별 배경 이미지 (10만보 이상은 마지막 이미지 반복 사용)
  static const List<String> _chapterBgs = [
    'assets/images/home/step_bg.jpg',
    'assets/images/home/step_bg2.jpg',
  ];

  bool _didAutoScroll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final asset in _chapterBgs) {
        precacheImage(AssetImage(asset), context);
      }
    });
  }

  String _formatSteps(int steps) {
    if (steps >= 10000) return '${(steps / 10000).toStringAsFixed(1)}만';
    return steps.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  // 현재 챕터 배경 이미지 (걸음수 기준)
  String _currentBg(int totalSteps) {
    final chapterIndex = totalSteps ~/ _stepsPerChapter;
    final clampedIndex = chapterIndex.clamp(0, _chapterBgs.length - 1);
    return _chapterBgs[clampedIndex];
  }

  // 챕터 내 진행률 (0~1)
  double _chapterRatio(int steps) {
    final withinChapter = steps % _stepsPerChapter;
    return (withinChapter / _stepsPerChapter).clamp(0.0, 1.0);
  }

  double _stepsToX(num steps) {
    final ratio = _chapterRatio(steps.toInt());
    return ratio * (_trackWidth - _shipSize);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final step = context.watch<StepProvider>();
    final confirmedSteps = auth.user?.totalSteps ?? 0;
    final shipX = _stepsToX(confirmedSteps);
    final bgAsset = _currentBg(confirmedSteps);
    final ratio = _chapterRatio(confirmedSteps);

    // 최초 진입 시 맨 왼쪽부터 시작
    if (!_didAutoScroll) {
      _didAutoScroll = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        _scrollController.jumpTo(0);
      });
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          height: _trackHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // ── 가로 스크롤 트랙 (배경 + 배) ──
              SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  width: _trackWidth,
                  height: _trackHeight,
                  child: Stack(
                    children: [
                      // 배경 (현재 챕터 이미지, 트랙 전체를 채움)
                      Positioned.fill(
                        child: Image.asset(
                          bgAsset,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                          errorBuilder: (_, __, ___) =>
                              Container(color: const Color(0xFF0D2A3F)),
                        ),
                      ),

                      // 배 (챕터 내 진행률 위치)
                      Positioned(
                        left: shipX,
                        bottom: 0,
                        child: Image.asset(
                          'assets/images/home/boat_character.png',
                          width: _shipSize,
                          height: _shipSize,
                          fit: BoxFit.contain,
                          alignment: Alignment.bottomCenter,
                          errorBuilder: (_, __, ___) =>
                          const Text('⛵', style: TextStyle(fontSize: 80)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── 상단 딤드 (텍스트 가독성용) ──
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.3],
                    ),
                  ),
                ),
              ),

              // ── 상단: 오늘 걸은 걸음 수 + 총 걸음 수 ──
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text('오늘 걸은 걸음 수',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.85),
                                  shadows: const [
                                    Shadow(color: Colors.black, blurRadius: 4)
                                  ])),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatSteps(step.todaySteps)}보',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(color: Colors.black, blurRadius: 4)
                                ]),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      Column(
                        children: [
                          Text('총 걸음 수',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.85),
                                  shadows: const [
                                    Shadow(color: Colors.black, blurRadius: 4)
                                  ])),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatSteps(confirmedSteps)}보',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(color: Colors.black, blurRadius: 4)
                                ]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── 현재 위치 슬라이더 (조작 불가, 진행 상황 표시 전용) ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              const Text('⛵', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(
                child: IgnorePointer(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 0),
                      activeTrackColor: const Color(0xFFF4A259),
                      inactiveTrackColor: Colors.white.withOpacity(0.15),
                      thumbColor: const Color(0xFFF4A259),
                      disabledActiveTrackColor: const Color(0xFFF4A259),
                      disabledInactiveTrackColor: Colors.white.withOpacity(0.15),
                      disabledThumbColor: const Color(0xFFF4A259),
                    ),
                    child: Slider(
                      value: ratio,
                      min: 0,
                      max: 1,
                      onChanged: (_) {},
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${(ratio * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                      color: Color(0xFFF4A259),
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              const Text('🏝️', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),

        // 안내 문구
        Text('⛵ 오늘 걸은 걸음은 내일 아침 도착해요',
            style: TextStyle(
                fontSize: 11, color: Colors.white.withOpacity(0.35))),
      ],
    );
  }
}