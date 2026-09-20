import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/planet_model.dart';
import '../../adventure/provider/adventure_provider.dart';
import '../../adventure/screens/battle_screen.dart';
import '../../currency/provider/currency_provider.dart';
import '../../auth/provider/auth_provider.dart';

class PlanetDetailScreen extends StatefulWidget {
  final PlanetModel planet;
  const PlanetDetailScreen({super.key, required this.planet});

  @override
  State<PlanetDetailScreen> createState() => _PlanetDetailScreenState();
}

class _PlanetDetailScreenState extends State<PlanetDetailScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdventureProvider>().loadStages();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdventureProvider>();
    final currency = context.watch<CurrencyProvider>();
    final auth = context.watch<AuthProvider>();
    final characterLevel = provider.activeCharacter?.level ?? 1;
    final totalSteps = auth.user?.totalSteps ?? 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF160d1f),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.planet.name,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white)),
        centerTitle: true,
      ),
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: provider.isLoading
          ? const Center(
          child: CircularProgressIndicator(color: Color(0xFFF4A259)))
          : widget.planet.stages.isEmpty
          ? const Center(
          child: Text('탐험 구역이 없습니다.',
              style: TextStyle(color: Colors.white54)))
          : Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            physics: const PageScrollPhysics(),
            itemCount: widget.planet.stages.length,
            onPageChanged: (i) =>
                setState(() => _currentPage = i),
            itemBuilder: (_, i) {
              final stage = widget.planet.stages[i];
              final isLevelLocked = characterLevel < stage.minLevel;
              final isStepsLocked = totalSteps < stage.requiredSteps;
              final isLocked = isLevelLocked || isStepsLocked;
              final canAfford =
                  currency.shoeCoin >= stage.shoeCoinCost;
              return _StagePage(
                stage: stage,
                isLocked: isLocked,
                isLevelLocked: isLevelLocked,
                isStepsLocked: isStepsLocked,
                currentSteps: totalSteps,
                canAfford: canAfford,
                onTap: () => _onStageTap(
                    stage, isLocked, isLevelLocked, isStepsLocked, canAfford, currency),
              );
            },
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.planet.stages.length, (i) {
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
          ),
        ],
      ),
    );
  }

  void _onStageTap(PlanetStageModel stage, bool isLocked, bool isLevelLocked,
      bool isStepsLocked, bool canAfford, CurrencyProvider currency) async {
    if (isLevelLocked) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lv.${stage.minLevel} 이상부터 입장 가능합니다.'),
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ));
      return;
    }
    if (isStepsLocked) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('누적 걸음수 ${stage.requiredSteps}보 이상부터 입장 가능합니다.'),
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ));
      return;
    }
    if (!canAfford) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('신발코인이 부족합니다. (보유: ${currency.shoeCoin}개)'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1225),
        title: Text(stage.name,
            style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(stage.description,
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            Row(children: [
              const Text('👟 신발코인 ',
                  style: TextStyle(color: Colors.white70)),
              Text('${stage.shoeCoinCost}개',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF4A259))),
              const Text(' 소모',
                  style: TextStyle(color: Colors.white70)),
            ]),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소',
                style:
                TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF4A259),
                foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('탐험하기'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final provider = context.read<AdventureProvider>();
    final result = await provider.startBattle(stage.id);

    if (result == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(provider.error ?? '탐험 시작에 실패했습니다.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ));
      }
      return;
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => BattleScreen(battleResult: result)),
      ).then((_) {
        provider.loadStages();
        context.read<CurrencyProvider>().load();
      });
    }
  }
}

// ── 구역 페이지 ──
class _StagePage extends StatelessWidget {
  final PlanetStageModel stage;
  final bool isLocked;
  final bool isLevelLocked;
  final bool isStepsLocked;
  final int currentSteps;
  final bool canAfford;
  final VoidCallback onTap;

  const _StagePage({
    required this.stage,
    required this.isLocked,
    required this.isLevelLocked,
    required this.isStepsLocked,
    required this.currentSteps,
    required this.canAfford,
    required this.onTap,
  });

  String _lockedReason() {
    if (isLevelLocked) return 'Lv.${stage.minLevel} 이상부터 입장 가능';
    if (isStepsLocked) return '🚶 누적 ${stage.requiredSteps}보 이상부터 입장 가능';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 배경 이미지
        Image.asset(
          'assets/images/adventure/${stage.imageKey}.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFF0D0A1A),
            child: const Center(
              child: Icon(Icons.explore_rounded,
                  color: Colors.white24, size: 80),
            ),
          ),
        ),

        // 딤드 그라디언트
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.2),
                Colors.black.withOpacity(0.75),
              ],
            ),
          ),
        ),

        // 잠금 오버레이
        if (isLocked) Container(color: Colors.black.withOpacity(0.5)),

        // 하단 콘텐츠
        Positioned(
          left: 24,
          right: 24,
          bottom: 80,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 왼쪽: 설명
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF7910).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFFEF7910).withOpacity(0.5)),
                      ),
                      child: Text('구역 ${stage.sortOrder}',
                          style: const TextStyle(
                              color: Color(0xFFEF7910),
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isLocked ? '????' : stage.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isLocked ? _lockedReason() : stage.description,
                      style: TextStyle(
                          color: isLocked
                              ? Colors.redAccent.withOpacity(0.8)
                              : Colors.white.withOpacity(0.7),
                          fontSize: 13,
                          height: 1.4),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                              'Lv.${stage.minLevel}~${stage.maxLevel}',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Text('👟',
                                  style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Text('${stage.shoeCoinCost}',
                                  style: TextStyle(
                                      color: canAfford
                                          ? const Color(0xFFF4A259)
                                          : Colors.red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        if (stage.requiredSteps > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Text('🚶',
                                    style: TextStyle(fontSize: 12)),
                                const SizedBox(width: 4),
                                Text('${stage.requiredSteps}보',
                                    style: TextStyle(
                                        color: isStepsLocked
                                            ? Colors.red
                                            : const Color(0xFF66D4FF),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // 오른쪽: 버튼
              if (!isLocked)
                GestureDetector(
                  onTap: onTap,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/images/ui/select_ui.svg',
                        width: 110,
                        height: 42,
                      ),
                      const Text('탐험하기',
                          style: TextStyle(
                              color: Color(0xFF3E2723),
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                    border:
                    Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: const Icon(Icons.lock,
                      color: Colors.white38, size: 24),
                ),
            ],
          ),
        ),
      ],
    );
  }
}