import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/adventure_provider.dart';
import '../../../data/models/adventure_model.dart';
import '../../currency/provider/currency_provider.dart';
import 'battle_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<AdventureProvider>();
      await provider.loadStages();
      // 미수령 배틀 체크
      await _checkPendingBattle();
    });
  }

  // 미수령 배틀 체크 — 있으면 팝업
  Future<void> _checkPendingBattle() async {
    final provider = context.read<AdventureProvider>();
    final pending = await provider.checkPendingBattle();

    if (pending == null || !mounted) return;

    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('이전 배틀이 있습니다'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${pending.monsterName} 와의 배틀이 완료되지 않았습니다.'),
            const SizedBox(height: 12),
            const Text('이어서 하시겠습니까?',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'abandon'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('포기하기'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'resume'),
            child: const Text('이어서 하기'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (action == 'resume') {
      // 배틀 화면으로 이동 (처음부터 재생)
      provider.currentBattle = pending;
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => BattleScreen(battleResult: pending)),
      ).then((_) {
        provider.loadStages();
        context.read<CurrencyProvider>().load();
      });
    } else if (action == 'abandon') {
      // 포기
      await provider.abandonBattle(pending.battleId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('배틀을 포기했습니다.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdventureProvider>();
    final currency = context.watch<CurrencyProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('맵 선택'),
        centerTitle: true,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _CoinBar(currency: currency),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '다양한 지역으로 모험을 떠나보세요.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              itemCount: provider.stages.length,
              itemBuilder: (_, i) => _StageCard(
                stage: provider.stages[i],
                characterLevel:
                provider.activeCharacter?.level ?? 1,
                shoeCoin: currency.shoeCoin,
                onTap: () =>
                    _onStageTap(provider.stages[i], currency),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onStageTap(StageModel stage, CurrencyProvider currency) async {
    final provider = context.read<AdventureProvider>();
    final level = provider.activeCharacter?.level ?? 1;

    if (level < stage.minLevel) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lv.${stage.minLevel} 이상부터 입장 가능합니다.'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ));
      return;
    }

    if (currency.shoeCoin < stage.shoeCoinCost) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
        Text('신발코인이 부족합니다. (보유: ${currency.shoeCoin}개)'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
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
            const SizedBox(height: 4),
            const Text('입장 후 신발코인은 즉시 차감됩니다.',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('시작하기'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await provider.startBattle(stage.id);
    if (result == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(provider.error ?? '모험 시작에 실패했습니다.'),
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

class _CoinBar extends StatelessWidget {
  final CurrencyProvider currency;
  const _CoinBar({required this.currency});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
            bottom:
            BorderSide(color: Colors.grey.withOpacity(0.15))),
      ),
      child: Row(
        children: [
          _Chip('🪙', currency.gold, const Color(0xFFFFB300)),
          const SizedBox(width: 20),
          _Chip('👟', currency.shoeCoin, const Color(0xFF42A5F5)),
          const Spacer(),
          if (currency.isLoading)
            const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String icon;
  final int value;
  final Color color;
  const _Chip(this.icon, this.value, this.color);

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(icon, style: const TextStyle(fontSize: 18)),
      const SizedBox(width: 6),
      Text(_fmt(value),
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color)),
    ],
  );
}

class _StageCard extends StatelessWidget {
  final StageModel stage;
  final int characterLevel;
  final int shoeCoin;
  final VoidCallback onTap;

  const _StageCard({
    required this.stage,
    required this.characterLevel,
    required this.shoeCoin,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = characterLevel < stage.minLevel;
    final canAfford = shoeCoin >= stage.shoeCoinCost;

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
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: isLocked
                      ? Colors.grey.withOpacity(0.1)
                      : Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isLocked
                    ? const Icon(Icons.lock,
                    color: Colors.grey, size: 28)
                    : const Icon(Icons.forest_rounded,
                    color: Colors.deepPurple, size: 32),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stage ${stage.id}',
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
                            color: isLocked ? Colors.grey : null)),
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
                              color: canAfford ? null : Colors.red)),
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
