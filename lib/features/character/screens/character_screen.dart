import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../currency/provider/currency_provider.dart';
import '../../adventure/provider/adventure_provider.dart';
import '../../../data/models/adventure_model.dart';

class CharacterScreen extends StatefulWidget {
  const CharacterScreen({super.key});

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CurrencyProvider>().load();
      context.read<AdventureProvider>().loadStages(); // 캐릭터 스탯 로드
    });
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyProvider>();
    final adventure = context.watch<AdventureProvider>();
    final stat = adventure.characterStat;

    return Scaffold(
      appBar: AppBar(
        title: const Text('캐릭터'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 재화 표시 바 (골드 + 신발코인)
          _CurrencyBar(currency: currency),

          Expanded(
            child: adventure.isLoading
                ? const Center(child: CircularProgressIndicator())
                : stat == null
                ? const Center(
                child: Text('캐릭터 정보를 불러올 수 없습니다.',
                    style: TextStyle(color: Colors.grey)))
                : _CharacterBody(stat: stat),
          ),
        ],
      ),
    );
  }
}

// ── 재화 바 ──
class _CurrencyBar extends StatelessWidget {
  final CurrencyProvider currency;
  const _CurrencyBar({required this.currency});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
            bottom: BorderSide(color: Colors.grey.withOpacity(0.15))),
      ),
      child: Row(
        children: [
          _CurrencyChip('🪙', currency.gold, const Color(0xFFFFB300)),
          const SizedBox(width: 16),
          _CurrencyChip('👟', currency.shoeCoin, const Color(0xFF42A5F5)),
          const Spacer(),
          if (currency.isLoading)
            const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      ),
    );
  }
}

class _CurrencyChip extends StatelessWidget {
  final String icon;
  final int value;
  final Color color;
  const _CurrencyChip(this.icon, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(icon, style: const TextStyle(fontSize: 18)),
      const SizedBox(width: 6),
      Text(_fmt(value),
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: color)),
    ]);
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

// ── 캐릭터 본문 ──
class _CharacterBody extends StatelessWidget {
  final CharacterStatModel stat;
  const _CharacterBody({required this.stat});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 레벨 + 경험치 바
          _LevelBar(stat: stat),
          const SizedBox(height: 24),

          // 캐릭터 이미지 자리 (나중에 실제 캐릭터 이미지로 교체)
          _CharacterImagePlaceholder(level: stat.level),
          const SizedBox(height: 24),

          // 스탯 카드
          _StatCard(stat: stat),
          const SizedBox(height: 16),

          // 다음 레벨업 안내
          _NextLevelInfo(stat: stat),
        ],
      ),
    );
  }
}

// ── 레벨 바 ──
class _LevelBar extends StatelessWidget {
  final CharacterStatModel stat;
  const _LevelBar({required this.stat});

  @override
  Widget build(BuildContext context) {
    final progress = (stat.exp / stat.requiredExp).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // 레벨 뱃지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('LV ${stat.level}',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
          const SizedBox(width: 14),
          // 경험치 바
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 14,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor:
                    const AlwaysStoppedAnimation(Colors.deepPurple),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${stat.exp} / ${stat.requiredExp} EXP',
                  style:
                  const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 캐릭터 이미지 (임시) ──
class _CharacterImagePlaceholder extends StatelessWidget {
  final int level;
  const _CharacterImagePlaceholder({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.06),
        shape: BoxShape.circle,
        border: Border.all(
            color: Colors.deepPurple.withOpacity(0.2), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🐻', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 4),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('Lv.$level',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ── 스탯 카드 ──
class _StatCard extends StatelessWidget {
  final CharacterStatModel stat;
  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('스탯',
              style:
              TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 16),
          _StatRow('⚔️', '공격력', stat.atk, Colors.orange),
          const Divider(height: 20),
          _StatRow('🛡️', '방어력', stat.def, Colors.blue),
          const Divider(height: 20),
          _StatRow('❤️', 'HP', stat.maxHp, Colors.red,
              subText: '${stat.hp} / ${stat.maxHp}'),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String icon;
  final String label;
  final int value;
  final Color color;
  final String? subText;

  const _StatRow(this.icon, this.label, this.value, this.color,
      {this.subText});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Text(label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(
          subText ?? '$value',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color),
        ),
      ],
    );
  }
}

// ── 다음 레벨업 안내 ──
class _NextLevelInfo extends StatelessWidget {
  final CharacterStatModel stat;
  const _NextLevelInfo({required this.stat});

  @override
  Widget build(BuildContext context) {
    final remaining = stat.requiredExp - stat.exp;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('다음 레벨업까지',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.amber,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('EXP $remaining 남음',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(
            'Lv.${stat.level + 1} 달성 시: ⚔️ +2  🛡️ +1  ❤️ +10',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
