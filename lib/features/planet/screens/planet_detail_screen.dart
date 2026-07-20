import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/planet_model.dart';
import '../../../data/models/adventure_model.dart';
import '../../adventure/provider/adventure_provider.dart';
import '../../adventure/screens/battle_screen.dart';
import '../../currency/provider/currency_provider.dart';

class PlanetDetailScreen extends StatefulWidget {
  final PlanetModel planet;
  const PlanetDetailScreen({super.key, required this.planet});

  @override
  State<PlanetDetailScreen> createState() => _PlanetDetailScreenState();
}

class _PlanetDetailScreenState extends State<PlanetDetailScreen> {
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
    final characterLevel = provider.activeCharacter?.level ?? 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F1FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.planet.name,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 행성 헤더
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2C1654), Color(0xFF1A2A4A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Text('🌍', style: TextStyle(fontSize: 40)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.planet.interviewPersonName != null)
                        Text(
                          '${widget.planet.interviewPersonName}'
                              '${widget.planet.interviewPersonJob != null ? ' · ${widget.planet.interviewPersonJob}' : ''}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      if (widget.planet.description != null)
                        Text(
                          widget.planet.description!,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 탐험 구역 목록
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('탐험 구역',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text('신발코인으로 입장',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : widget.planet.stages.isEmpty
                ? const Center(
                child: Text('탐험 구역이 없습니다.',
                    style: TextStyle(color: Colors.grey)))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 4),
              itemCount: widget.planet.stages.length,
              itemBuilder: (_, i) {
                final stage = widget.planet.stages[i];
                final isLocked =
                    characterLevel < stage.minLevel;
                final canAfford =
                    currency.shoeCoin >= stage.shoeCoinCost;

                return _StageCard(
                  stage: stage,
                  isLocked: isLocked,
                  canAfford: canAfford,
                  onTap: () => _onStageTap(
                      stage, isLocked, canAfford, currency),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onStageTap(PlanetStageModel stage, bool isLocked, bool canAfford,
      CurrencyProvider currency) async {
    if (isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lv.${stage.minLevel} 이상부터 입장 가능합니다.'),
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
        title: Text(stage.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(stage.description),
            const SizedBox(height: 12),
            Row(children: [
              const Text('👟 신발코인 '),
              Text('${stage.shoeCoinCost}개',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange)),
              const Text(' 소모'),
            ]),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
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

class _StageCard extends StatelessWidget {
  final PlanetStageModel stage;
  final bool isLocked;
  final bool canAfford;
  final VoidCallback onTap;

  const _StageCard({
    required this.stage,
    required this.isLocked,
    required this.canAfford,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isLocked
              ? Colors.grey.withOpacity(0.2)
              : Colors.deepPurple.withOpacity(0.3),
        ),
      ),
      child: InkWell(
        onTap: isLocked ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: isLocked
                      ? Colors.grey.withOpacity(0.1)
                      : Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isLocked
                    ? const Icon(Icons.lock, color: Colors.grey, size: 26)
                    : const Icon(Icons.explore_rounded,
                    color: Colors.deepPurple, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('구역 ${stage.sortOrder}',
                        style: TextStyle(
                            fontSize: 11,
                            color: isLocked
                                ? Colors.grey
                                : Colors.deepPurple,
                            fontWeight: FontWeight.w600)),
                    Text(stage.name,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:
                            isLocked ? Colors.grey : null)),
                    const SizedBox(height: 2),
                    Text(
                      isLocked
                          ? 'Lv.${stage.minLevel} 이상 필요'
                          : stage.description,
                      style: TextStyle(
                          fontSize: 12,
                          color: isLocked
                              ? Colors.red.shade300
                              : Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(children: [
                      Text('👟 ',
                          style: TextStyle(
                              fontSize: 13,
                              color: canAfford
                                  ? null
                                  : Colors.red)),
                      Text('${stage.shoeCoinCost}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: canAfford
                                  ? Colors.orange
                                  : Colors.red,
                              fontSize: 13)),
                      Text(
                          '  Lv.${stage.minLevel}~${stage.maxLevel}',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ]),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}