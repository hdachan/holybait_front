import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../provider/planet_provider.dart';
import '../../../data/models/planet_model.dart';
import 'planet_detail_screen.dart';
import '../../currency/provider/currency_provider.dart';
import '../../../core/widgets/currency_badge.dart';

class PlanetScreen extends StatefulWidget {
  const PlanetScreen({super.key});

  @override
  State<PlanetScreen> createState() => _PlanetScreenState();
}

class _PlanetScreenState extends State<PlanetScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlanetProvider>().loadPlanets();
      context.read<CurrencyProvider>().load();
    });
    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentPage) setState(() => _currentPage = page);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlanetProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: const CurrencyBadge(),
        leadingWidth: 140,
        title: const Text('행성 선택',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/space/space_bg.png', fit: BoxFit.cover),
          provider.isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : provider.planets.isEmpty
              ? _buildEmpty()
              : _buildCarousel(provider.planets),
        ],
      ),
    );
  }

  Widget _buildCarousel(List<PlanetModel> planets) {
    return Column(
      children: [
        const SizedBox(height: 100),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.62,
          child: PageView.builder(
            controller: _pageController,
            itemCount: planets.length,
            itemBuilder: (context, i) {
              final planet = planets[i];
              final isActive = i == _currentPage;

              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PlanetDetailScreen(planet: planet)),
                ),
                child: AnimatedScale(
                  scale: isActive ? 1.0 : 0.85,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  child: AnimatedOpacity(
                    opacity: isActive ? 1.0 : 0.5,
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(flex: 3, child: _PlanetAnimation(imageKey: planet.imageKey, isActive: isActive)),
                        const SizedBox(height: 20),
                        // 행성 이름 (판넬 배경)
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              'assets/images/ui/island/island_name_UI.png',
                              height: 56,
                              fit: BoxFit.fitHeight,
                            ),
                            Text(planet.name,
                                style: const TextStyle(
                                    color: Color(0xFF3E2723),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (planet.interviewPersonName != null)
                          Text(
                            '${planet.interviewPersonName}'
                                '${planet.interviewPersonJob != null ? ' · ${planet.interviewPersonJob}' : ''}',
                            style: const TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Text('탐험 구역 ${planet.stages.length}개',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                        ),
                        const SizedBox(height: 16),
                        if (isActive)
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => PlanetDetailScreen(planet: planet)),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SvgPicture.asset(
                                  'assets/images/ui/select_ui.svg',
                                  width: 160,
                                  height: 44,
                                ),
                                const Text('탐험하기',
                                    style: TextStyle(
                                        color: Color(0xFF3E2723),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const Spacer(flex: 1),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(planets.length, (i) {
            final isActive = i == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFF4A259) : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🌍', style: TextStyle(fontSize: 64)),
          SizedBox(height: 16),
          Text('아직 행성이 없습니다.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          SizedBox(height: 8),
          Text('곧 새로운 행성이 추가될 예정이에요.',
              style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}

// ── 행성 애니메이션 ──
class _PlanetAnimation extends StatefulWidget {
  final String? imageKey;
  final bool isActive;
  const _PlanetAnimation({this.imageKey, this.isActive = false});

  @override
  State<_PlanetAnimation> createState() => _PlanetAnimationState();
}

class _PlanetAnimationState extends State<_PlanetAnimation> {
  static const _totalFrames = 13;
  static const _frameDuration = Duration(milliseconds: 150);

  int _frame = 1;
  bool _ascending = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _startTimer();
  }

  @override
  void didUpdateWidget(_PlanetAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _startTimer();
    } else if (!widget.isActive && oldWidget.isActive) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_frameDuration, (_) {
      if (!mounted) return;
      setState(() {
        if (_ascending) {
          _frame++;
          if (_frame >= _totalFrames) _ascending = false;
        } else {
          _frame--;
          if (_frame <= 1) _ascending = true;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final key = widget.imageKey ?? 'planet1';
    final frameNum = _frame.toString().padLeft(2, '0');
    return Image.asset(
      'assets/images/space/$key/${key}_$frameNum.png',
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              const Color(0xFFF4A259).withOpacity(0.6),
              const Color(0xFF2a1840).withOpacity(0.3),
            ],
          ),
        ),
        child: const Center(child: Text('🌍', style: TextStyle(fontSize: 80))),
      ),
    );
  }
}