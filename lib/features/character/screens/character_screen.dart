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
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.78);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CurrencyProvider>().load();
      context.read<AdventureProvider>().loadStages();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyProvider>();
    final adventure = context.watch<AdventureProvider>();
    final characters = adventure.myCharacters;

    final currentStat = characters.isNotEmpty && _currentPage < characters.length
        ? characters[_currentPage]
        : adventure.activeCharacter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('캐릭터'),
        centerTitle: true,
      ),
      body: adventure.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _CurrencyBar(currency: currency),
          Expanded(
            child: characters.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.grey, size: 40),
                  const SizedBox(height: 12),
                  const Text('캐릭터 정보를 불러올 수 없습니다.',
                      style: TextStyle(color: Colors.grey)),
                  if (adventure.error != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(adventure.error!,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 12),
                          textAlign: TextAlign.center),
                    ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => adventure.loadStages(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('다시 시도'),
                  ),
                ],
              ),
            )
                : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // 레벨 바
                  if (currentStat != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20),
                      child: _LevelBar(stat: currentStat),
                    ),
                  const SizedBox(height: 20),

                  // 캐릭터 PageView — 높이 280으로 늘림
                  SizedBox(
                    height: 280,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: characters.length,
                      onPageChanged: (i) =>
                          setState(() => _currentPage = i),
                      itemBuilder: (_, i) => _CharacterCard(
                        stat: characters[i],
                        isSelected: _currentPage == i,
                        onSelect: () => _onSelectCharacter(
                            characters[i].statId),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 페이지 인디케이터
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      characters.length,
                          (i) => AnimatedContainer(
                        duration:
                        const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 3),
                        width: _currentPage == i ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? Colors.deepPurple
                              : Colors.grey.withOpacity(0.3),
                          borderRadius:
                          BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 스탯 카드
                  if (currentStat != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20),
                      child: _StatCard(stat: currentStat),
                    ),
                  const SizedBox(height: 16),

                  // 레벨업 안내
                  if (currentStat != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20),
                      child: _NextLevelInfo(stat: currentStat),
                    ),
                  const SizedBox(height: 24),

                  // 하단 슬롯
                  _CharacterSlots(
                    characters: characters,
                    currentIndex: _currentPage,
                    onTap: (i) {
                      _pageController.animateToPage(i,
                          duration: const Duration(
                              milliseconds: 300),
                          curve: Curves.easeInOut);
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSelectCharacter(int statId) async {
    final adventure = context.read<AdventureProvider>();
    if (adventure.activeCharacter?.statId == statId) return;

    await adventure.selectCharacter(statId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('캐릭터가 변경되었습니다.'),
        ]),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 2),
      ));
    }
  }
}

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
          _Chip('🪙', currency.gold, const Color(0xFFFFB300)),
          const SizedBox(width: 16),
          _Chip('👟', currency.shoeCoin, const Color(0xFF42A5F5)),
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color)),
    ],
  );
}

class _LevelBar extends StatelessWidget {
  final CharacterStatModel stat;
  const _LevelBar({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: stat.expProgress,
                    minHeight: 14,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation(
                        Colors.deepPurple),
                  ),
                ),
                const SizedBox(height: 4),
                Text('${stat.exp} / ${stat.requiredExp} EXP',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 캐릭터 카드 — Stack 대신 Column 으로 겹침 방지
class _CharacterCard extends StatelessWidget {
  final CharacterStatModel stat;
  final bool isSelected;
  final VoidCallback onSelect;

  const _CharacterCard({
    required this.stat,
    required this.isSelected,
    required this.onSelect,
  });

  String get _emoji {
    switch (stat.imageKey) {
      case 'char_dragon': return '🐉';
      case 'char_knight': return '⚔️';
      default: return '🐻';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.symmetric(
          horizontal: 8, vertical: isSelected ? 0 : 20),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.deepPurple.withOpacity(0.08)
            : Colors.grey.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? Colors.deepPurple.withOpacity(0.4)
              : Colors.grey.withOpacity(0.15),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 활성 표시 뱃지
            if (stat.isActive)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('사용 중',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              )
            else
              const SizedBox(height: 22), // 뱃지 높이만큼 공간 유지
            const SizedBox(height: 8),

            // 캐릭터 이모지
            Text(_emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 8),

            // 이름
            Text(stat.characterName,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),

            // 레벨 뱃지
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Lv.${stat.level}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),

            // 선택 버튼 (활성 아닐 때만, 선택된 카드일 때만)
            if (!stat.isActive && isSelected)
              FilledButton(
                onPressed: onSelect,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  minimumSize: const Size(120, 36),
                ),
                child: const Text('이 캐릭터 사용',
                    style: TextStyle(fontSize: 13)),
              )
            else
              const SizedBox(height: 36), // 버튼 높이만큼 공간 유지
          ],
        ),
      ),
    );
  }
}

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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('스탯',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 16),
          _StatRow('⚔️', '공격력', stat.atk, Colors.orange),
          const Divider(height: 20),
          _StatRow('🛡️', '방어력', stat.def, Colors.blue),
          const Divider(height: 20),
          _StatRow('❤️', 'HP', stat.maxHp, Colors.red),
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
  const _StatRow(this.icon, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(icon, style: const TextStyle(fontSize: 20)),
      const SizedBox(width: 12),
      Text(label,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w500)),
      const Spacer(),
      Text('$value',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color)),
    ],
  );
}

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
          Text('Lv.${stat.level + 1} 달성 시: ⚔️ +2  🛡️ +1  ❤️ +10',
              style: const TextStyle(
                  fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _CharacterSlots extends StatelessWidget {
  final List<CharacterStatModel> characters;
  final int currentIndex;
  final void Function(int) onTap;

  const _CharacterSlots({
    required this.characters,
    required this.currentIndex,
    required this.onTap,
  });

  String _emoji(String? key) {
    switch (key) {
      case 'char_dragon': return '🐉';
      case 'char_knight': return '⚔️';
      default: return '🐻';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
            top: BorderSide(color: Colors.grey.withOpacity(0.15))),
      ),
      child: Row(
        children: List.generate(characters.length, (i) {
          final c = characters[i];
          final isSelected = currentIndex == i;
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              height: 56,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.deepPurple.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? Colors.deepPurple
                      : Colors.grey.withOpacity(0.2),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(_emoji(c.imageKey),
                        style: const TextStyle(fontSize: 28)),
                  ),
                  if (c.isActive)
                    Positioned(
                      bottom: 2, right: 2,
                      child: Container(
                        width: 10, height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
