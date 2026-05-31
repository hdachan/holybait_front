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
    _pageController = PageController(viewportFraction: 1.0);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<CurrencyProvider>().load();
      await context.read<AdventureProvider>().loadStages();

      final characters = context.read<AdventureProvider>().myCharacters;
      final activeIndex = characters.indexWhere((c) => c.isActive);
      if (activeIndex >= 0 && mounted) {
        setState(() => _currentPage = activeIndex);
        _pageController.jumpToPage(activeIndex);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _theme(String? key) {
    switch (key) {
      case 'char_dragon': return 'dragon';
      case 'char_knight': return 'knight';
      default: return 'bear';
    }
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyProvider>();
    final adventure = context.watch<AdventureProvider>();
    final characters = adventure.myCharacters;
    final currentStat = characters.isNotEmpty && _currentPage < characters.length
        ? characters[_currentPage]
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F7FF),
        elevation: 0,
        title: const Text('캐릭터',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(children: [
              const Text('🪙', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 4),
              Text(_fmt(currency.gold),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFB300),
                      fontSize: 14)),
              const SizedBox(width: 12),
              const Text('👟', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 4),
              Text(_fmt(currency.shoeCoin),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF42A5F5),
                      fontSize: 14)),
            ]),
          ),
        ],
      ),
      body: adventure.isLoading
          ? const Center(child: CircularProgressIndicator())
          : characters.isEmpty
          ? _buildError(adventure)
          : Column(
        children: [
          // 레벨 바
          if (currentStat != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: _LevelBar(stat: currentStat),
            ),

          // 캐릭터 카드 슬라이더
          SizedBox(
            height: 220,
            child: PageView.builder(
              controller: _pageController,
              itemCount: characters.length,
              onPageChanged: (i) =>
                  setState(() => _currentPage = i),
              itemBuilder: (_, i) => _CharacterCard(
                stat: characters[i],
                onSelect: () =>
                    _onSelectCharacter(characters[i].statId),
                theme: _theme(characters[i].imageKey),
              ),
            ),
          ),

          // 인디케이터
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(characters.length, (i) {
              final active = _currentPage == i;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFF6C47FF)
                      : Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),

          // 스탯 + 레벨업 안내
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  if (currentStat != null) ...[
                    _StatCard(stat: currentStat),
                    const SizedBox(height: 12),
                    _NextLevelInfo(stat: currentStat),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),

          // 하단 슬롯
          _CharacterSlots(
            characters: characters,
            currentIndex: _currentPage,
            onTap: (i) => _pageController.animateToPage(i,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut),
          ),
        ],
      ),
    );
  }

  Widget _buildError(AdventureProvider adventure) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.grey, size: 40),
          const SizedBox(height: 12),
          const Text('캐릭터 정보를 불러올 수 없습니다.',
              style: TextStyle(color: Colors.grey)),
          if (adventure.error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(adventure.error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
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
        backgroundColor: const Color(0xFF6C47FF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 2),
      ));
    }
  }
}

// ── 레벨 바 ──
class _LevelBar extends StatelessWidget {
  final CharacterStatModel stat;
  const _LevelBar({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C47FF).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C47FF), Color(0xFF9B79FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text('${stat.level}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Lv.${stat.level}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('${stat.exp} / ${stat.requiredExp} EXP',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: stat.expProgress,
                    minHeight: 10,
                    backgroundColor: Colors.grey.withOpacity(0.15),
                    valueColor: const AlwaysStoppedAnimation(
                        Color(0xFF6C47FF)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 캐릭터 카드 (가로 레이아웃) ──
class _CharacterCard extends StatelessWidget {
  final CharacterStatModel stat;
  final VoidCallback onSelect;
  final String theme;

  const _CharacterCard({
    required this.stat,
    required this.onSelect,
    required this.theme,
  });

  String get _emoji {
    switch (theme) {
      case 'dragon': return '🐉';
      case 'knight': return '⚔️';
      default: return '🐻';
    }
  }

  Color get _color {
    switch (theme) {
      case 'dragon': return const Color(0xFFFF6B35);
      case 'knight': return const Color(0xFF2196F3);
      default: return const Color(0xFF6C47FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _color.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 6),
            )
          ],
          border: Border.all(color: _color.withOpacity(0.2), width: 1.5),
        ),
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            // 캐릭터 이미지
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(_emoji,
                    style: const TextStyle(fontSize: 56)),
              ),
            ),
            const SizedBox(width: 16),

            // 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (stat.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: Colors.green.withOpacity(0.3)),
                      ),
                      child: const Text('✅ 사용 중',
                          style: TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  Text(stat.characterName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Lv.${stat.level}',
                        style: TextStyle(
                            color: _color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    _Mini('⚔️', '${stat.atk}'),
                    const SizedBox(width: 10),
                    _Mini('🛡️', '${stat.def}'),
                    const SizedBox(width: 10),
                    _Mini('❤️', '${stat.maxHp}'),
                  ]),
                  if (!stat.isActive) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onSelect,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: const Text('이 캐릭터 사용',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  final String icon;
  final String value;
  const _Mini(this.icon, this.value);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(icon, style: const TextStyle(fontSize: 12)),
      const SizedBox(width: 2),
      Text(value,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600)),
    ],
  );
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('스탯',
              style:
              TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 16),
          _Bar('⚔️', '공격력', stat.atk, 40, const Color(0xFFFF6B35)),
          const SizedBox(height: 12),
          _Bar('🛡️', '방어력', stat.def, 20, const Color(0xFF2196F3)),
          const SizedBox(height: 12),
          _Bar('❤️', 'HP', stat.maxHp, 200, const Color(0xFFE91E63)),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final String icon;
  final String label;
  final int value;
  final int max;
  final Color color;
  const _Bar(this.icon, this.label, this.value, this.max, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
            ]),
            Text('$value',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (value / max).clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: Colors.grey.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

// ── 레벨업 안내 ──
class _NextLevelInfo extends StatelessWidget {
  final CharacterStatModel stat;
  const _NextLevelInfo({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C47FF).withOpacity(0.08),
            const Color(0xFF9B79FF).withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFF6C47FF).withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6C47FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('⬆️', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Lv.${stat.level + 1} 까지 EXP ${stat.requiredExp - stat.exp} 남음',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text('레벨업 시 ⚔️ +2  🛡️ +1  ❤️ +10',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 하단 캐릭터 슬롯 ──
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: Row(
        children: List.generate(characters.length, (i) {
          final c = characters[i];
          final isSelected = currentIndex == i;
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              height: 60,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF6C47FF).withOpacity(0.1)
                    : Colors.grey.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF6C47FF)
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
                      bottom: 4, right: 4,
                      child: Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border:
                          Border.all(color: Colors.white, width: 1.5),
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