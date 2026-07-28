import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/planet_provider.dart';
import '../../../data/models/planet_model.dart';
import 'planet_detail_screen.dart';
import '../../currency/provider/currency_provider.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/currency_badge.dart';

class PlanetScreen extends StatefulWidget {
  const PlanetScreen({super.key});

  @override
  State<PlanetScreen> createState() => _PlanetScreenState();
}

class _PlanetScreenState extends State<PlanetScreen> {
  final PageController _pageController =
  PageController(viewportFraction: 0.85);
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

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  String _assetPath(String? imageKey) =>
      'assets/images/space/${imageKey ?? 'planet1'}.png';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlanetProvider>();
    final currency = context.watch<CurrencyProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: const CurrencyBadge(),
        leadingWidth: 140,
        title: const Text('행성 선택',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white)),
        centerTitle: true,
      ),
      body: AppBackground(
        child: provider.isLoading
            ? const Center(
            child: CircularProgressIndicator(color: Colors.white))
            : provider.planets.isEmpty
            ? _buildEmpty()
            : _buildCarousel(provider.planets),
      ),
    );
  }

  Widget _buildCarousel(List<PlanetModel> planets) {
    return Column(
      children: [
        const Spacer(flex: 1),

        // 행성 캐러셀
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: PageView.builder(
            controller: _pageController,
            itemCount: planets.length,
            itemBuilder: (context, i) {
              final planet = planets[i];
              final isActive = i == _currentPage;

              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlanetDetailScreen(planet: planet),
                  ),
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
                        // 행성 이미지
                        Expanded(
                          child: Image.asset(
                            _assetPath(planet.imageKey),
                            fit: BoxFit.contain,
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
                              child: const Center(
                                child: Text('🌍',
                                    style: TextStyle(fontSize: 80)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 행성 이름
                        Text(
                          planet.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // 인터뷰 인물
                        if (planet.interviewPersonName != null)
                          Text(
                            '${planet.interviewPersonName}'
                                '${planet.interviewPersonJob != null ? ' · ${planet.interviewPersonJob}' : ''}',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 13),
                          ),
                        const SizedBox(height: 6),

                        // 탐험 구역 수
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Text(
                            '탐험 구역 ${planet.stages.length}개',
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 탐험하기 버튼 (활성 행성만)
                        if (isActive)
                          ElevatedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PlanetDetailScreen(planet: planet),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF4A259),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24)),
                              elevation: 0,
                            ),
                            child: const Text('탐험하기',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
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

        // 페이지 인디케이터
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
                color: isActive
                    ? const Color(0xFFF4A259)
                    : Colors.white.withOpacity(0.3),
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
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          SizedBox(height: 8),
          Text('곧 새로운 행성이 추가될 예정이에요.',
              style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}