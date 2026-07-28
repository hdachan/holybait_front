import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../currency/provider/currency_provider.dart';
import '../../adventure/provider/adventure_provider.dart';
import '../../../data/models/adventure_model.dart';
import '../../../core/network/api_client.dart';
import '../../shop/screens/shop_screen.dart';
import '../../../core/widgets/character_background.dart';
import '../../../core/widgets/currency_badge.dart';

class CharacterScreen extends StatefulWidget {
  const CharacterScreen({super.key});

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> {
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<CurrencyProvider>().load();
      await context.read<AdventureProvider>().loadStages();
      final characters = context.read<AdventureProvider>().myCharacters;
      final activeIndex = characters.indexWhere((c) => c.isActive);
      if (activeIndex >= 0 && mounted) {
        setState(() => _currentPage = activeIndex);
      }
    });
  }

  Color _themeColor(String? key) {
    switch (key) {
      case 'char_dragon': return const Color(0xFFFF6B35);
      case 'char_knight': return const Color(0xFF42A5F5);
      default:            return const Color(0xFFE84545);
    }
  }

  bool _hasSprites(String? key) =>
      key == null || key == 'char_bear' || key == 'char_knight' || key == 'char_dragon';

  String _spriteFolder(String? key) {
    switch (key) {
      case 'char_knight': return 'assets/images/characters/knight/';
      case 'char_dragon': return 'assets/images/characters/dragon/';
      default:            return 'assets/images/characters/bear/';
    }
  }

  String _spritePrefix(String? key) {
    switch (key) {
      case 'char_dragon': return 'frame';
      default:            return 'sprite';
    }
  }

  String _thumbAsset(String? key) {
    if (_hasSprites(key)) {
      final prefix = _spritePrefix(key);
      return '${_spriteFolder(key)}${prefix}_01-removebg-preview.png';
    }
    return '';
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final currency  = context.watch<CurrencyProvider>();
    final adventure = context.watch<AdventureProvider>();
    final characters = adventure.myCharacters;
    final currentStat = characters.isNotEmpty && _currentPage < characters.length
        ? characters[_currentPage]
        : null;
    final color = _themeColor(currentStat?.imageKey);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: const CurrencyBadge(),
        leadingWidth: 140,
        title: const Text('캐릭터',
            style: TextStyle(fontWeight: FontWeight.bold,
                fontSize: 18, color: Colors.white)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ShopScreen()))
                  .then((_) {
                context.read<CurrencyProvider>().load();
                context.read<AdventureProvider>().loadStages();
              }),
              icon: const Text('🛒', style: TextStyle(fontSize: 16)),
              label: const Text('상점',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                      color: Color(0xFFF4A259))),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFF4A259).withOpacity(0.12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
            ),
          ),
        ],
      ),
      body: CharacterBackground(
        child: SafeArea(
          child: Column(
            children: [
              // 레벨 바
              if (currentStat != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: _LevelBar(stat: currentStat),
                ),

              // 메인 영역
              Expanded(
                child: adventure.isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : characters.isEmpty
                    ? _buildError(adventure)
                    : LayoutBuilder(
                  builder: (context, constraints) {
                    final spriteSize =
                    (constraints.maxHeight * 0.65).clamp(150.0, 340.0);
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 스프라이트
                        _hasSprites(currentStat?.imageKey)
                            ? _SpriteAnimation(
                          spriteFolder: _spriteFolder(currentStat?.imageKey),
                          spritePrefix: _spritePrefix(currentStat?.imageKey),
                          totalFrames: 25,
                          color: color,
                          size: spriteSize,
                        )
                            : _CharacterPlaceholder(color: color, size: spriteSize),

                        const SizedBox(height: 12),

                        // 스탯 칩
                        if (currentStat != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.12)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _statChip(Icons.close, '공격',
                                    currentStat.atk, const Color(0xFFFF6B6B)),
                                const SizedBox(width: 16),
                                _statChip(Icons.shield_outlined, '방어',
                                    currentStat.def, const Color(0xFF42A5F5)),
                              ],
                            ),
                          ),

                        const SizedBox(height: 12),

                        // 착용 버튼
                        if (currentStat != null)
                          _EquipButton(
                            stat: currentStat,
                            color: color,
                            onTap: () => _onSelectCharacter(currentStat.statId),
                          ),

                        // 삭제 버튼
                        if (currentStat != null && !currentStat.isActive)
                          TextButton.icon(
                            onPressed: () => _onDeleteCharacter(currentStat),
                            icon: const Icon(Icons.delete_outline,
                                size: 14, color: Colors.redAccent),
                            label: const Text('캐릭터 삭제',
                                style: TextStyle(
                                    color: Colors.redAccent, fontSize: 12)),
                          ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // 하단 슬롯
              _BottomSlots(
                characters: characters,
                currentIndex: _currentPage,
                totalSlots: adventure.slotCount,
                thumbAsset: _thumbAsset,
                themeColor: _themeColor,
                hasSprites: _hasSprites,
                onTap: (i) => setState(() => _currentPage = i),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(AdventureProvider adventure) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.white.withOpacity(0.3), size: 40),
          const SizedBox(height: 12),
          Text('캐릭터 정보를 불러올 수 없습니다.',
              style: TextStyle(color: Colors.white.withOpacity(0.4))),
          TextButton.icon(
            onPressed: () => adventure.loadStages(),
            icon: Icon(Icons.refresh, color: Colors.white.withOpacity(0.5)),
            label: Text('다시 시도',
                style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, int value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text('$label  ',
            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
        Text('$value',
            style: TextStyle(fontSize: 13,
                fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Future<void> _onDeleteCharacter(CharacterStatModel stat) async {
    final adventure = context.read<AdventureProvider>();
    if (adventure.myCharacters.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('마지막 캐릭터는 삭제할 수 없습니다.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1225),
        title: const Text('캐릭터 삭제',
            style: TextStyle(color: Colors.white)),
        content: Text('${stat.characterName}을(를) 삭제하시겠습니까?\n삭제한 캐릭터는 복구할 수 없습니다.',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소', style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await ApiClient.dio.delete('/adventures/character/${stat.statId}');
      await adventure.loadStages();
      setState(() => _currentPage = 0);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('캐릭터가 삭제되었습니다.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('캐릭터 삭제에 실패했습니다.'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _onSelectCharacter(int statId) async {
    final adventure = context.read<AdventureProvider>();
    if (adventure.activeCharacter?.statId == statId) return;
    await adventure.selectCharacter(statId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('캐릭터가 변경되었습니다.'),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 2),
      ));
    }
  }
}

// ── 스프라이트 애니메이션 ──
class _SpriteAnimation extends StatefulWidget {
  final String spriteFolder;
  final String spritePrefix;
  final int totalFrames;
  final Color color;
  final double size;

  const _SpriteAnimation({
    required this.spriteFolder,
    required this.spritePrefix,
    required this.totalFrames,
    required this.color,
    required this.size,
  });

  @override
  State<_SpriteAnimation> createState() => _SpriteAnimationState();
}

class _SpriteAnimationState extends State<_SpriteAnimation> {
  int _frame = 0;
  Timer? _timer;

  void _play() {
    _timer?.cancel();
    setState(() => _frame = 0);
    _timer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted) return;
      setState(() {
        _frame++;
        if (_frame >= widget.totalFrames) {
          _frame = 0;
          _timer?.cancel();
          _timer = null;
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
    final s = widget.size;
    return GestureDetector(
      onTap: _play,
      child: SizedBox(
        width: s,
        height: s,
        child: IndexedStack(
          index: _frame,
          children: List.generate(widget.totalFrames, (i) {
            final frameNum = (i + 1).toString().padLeft(2, '0');
            final path =
                '${widget.spriteFolder}${widget.spritePrefix}_$frameNum-removebg-preview.png';
            return Image.asset(
              path,
              width: s * 0.92,
              height: s * 0.92,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => i == 0
                  ? _CharacterPlaceholder(color: widget.color, size: s)
                  : SizedBox(width: s, height: s),
            );
          }),
        ),
      ),
    );
  }
}

// ── 플레이스홀더 ──
class _CharacterPlaceholder extends StatelessWidget {
  final Color color;
  final double size;
  const _CharacterPlaceholder({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size, height: size,
      child: Center(
        child: Container(
          width: size * 0.7,
          height: size * 0.7,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.2), width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_outline, size: size * 0.3,
                  color: color.withOpacity(0.4)),
              const SizedBox(height: 4),
              Text('준비 중',
                  style: TextStyle(fontSize: 12, color: color.withOpacity(0.4))),
            ],
          ),
        ),
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
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text('LV ${stat.level}',
              style: const TextStyle(
                  color: Color(0xFF4CAF50),
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: stat.expProgress,
                minHeight: 10,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF4CAF50)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('${stat.exp}/${stat.requiredExp}',
              style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4))),
        ],
      ),
    );
  }
}

// ── 착용 버튼 ──
class _EquipButton extends StatelessWidget {
  final CharacterStatModel stat;
  final Color color;
  final VoidCallback onTap;

  const _EquipButton({required this.stat, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (stat.isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.4)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 15, color: Color(0xFF4CAF50)),
            SizedBox(width: 6),
            Text('착용 중',
                style: TextStyle(color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      );
    }

    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
      child: const Text('착용하기',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }
}

// ── 하단 슬롯 ──
class _BottomSlots extends StatelessWidget {
  final List<CharacterStatModel> characters;
  final int currentIndex;
  final int totalSlots;
  final String Function(String?) thumbAsset;
  final Color Function(String?) themeColor;
  final bool Function(String?) hasSprites;
  final void Function(int) onTap;

  const _BottomSlots({
    required this.characters,
    required this.currentIndex,
    required this.totalSlots,
    required this.thumbAsset,
    required this.themeColor,
    required this.hasSprites,
    required this.onTap,
  });

  void _showExpandDialog(BuildContext context, AdventureProvider adventure) {
    final currentSlot = adventure.slotCount;
    final costs = [0, 0, 0, 0, 500, 1000, 1500, 2500, 3500, 5000];
    final cost = currentSlot < 10 ? costs[currentSlot] : -1;

    if (cost == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('슬롯이 이미 최대입니다.')));
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1225),
        title: const Text('슬롯 확장', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('슬롯을 ${currentSlot + 1}개로 확장합니다.',
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🪙 골드 ', style: TextStyle(color: Colors.white70)),
                Text('$cost개',
                    style: const TextStyle(fontWeight: FontWeight.bold,
                        color: Color(0xFFF4A259))),
                const Text(' 소모', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소',
                style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF4A259),
                foregroundColor: Colors.black),
            onPressed: () async {
              Navigator.pop(context);
              final result = await adventure.expandSlot();
              if (!context.mounted) return;
              if (result != null) {
                context.read<CurrencyProvider>().load();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('슬롯이 ${result.slotCount}개로 확장되었습니다!'),
                  backgroundColor: const Color(0xFF4CAF50),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                ));
              } else {
                final errMsg = adventure.error ?? '';
                final msg = errMsg.contains('골드') || errMsg.contains('403')
                    ? '골드가 부족합니다.\n모험을 통해 골드를 모아보세요!'
                    : errMsg.contains('최대')
                    ? '슬롯이 이미 최대입니다.'
                    : '슬롯 확장에 실패했습니다.';
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: const Color(0xFF1E1225),
                    title: const Text('슬롯 확장 실패',
                        style: TextStyle(color: Colors.white)),
                    content: Text(msg,
                        style: const TextStyle(color: Colors.white70)),
                    actions: [
                      FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFF4A259),
                            foregroundColor: Colors.black),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('확인'),
                      ),
                    ],
                  ),
                );
              }
            },
            child: const Text('구매'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adventure = context.watch<AdventureProvider>();
    final displayCount = adventure.slotCount < 10
        ? adventure.slotCount + 1
        : adventure.slotCount;

    return SizedBox(
      height: 68,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: displayCount,
        itemBuilder: (context, i) {
          final hasChar = i < characters.length;
          final c = hasChar ? characters[i] : null;
          final isSelected = currentIndex == i;
          final color = themeColor(c?.imageKey);

          if (!hasChar) {
            final isPurchasable = i == adventure.slotCount;
            return GestureDetector(
              onTap: isPurchasable
                  ? () => _showExpandDialog(context, adventure)
                  : null,
              child: Container(
                width: 68,
                margin: EdgeInsets.only(left: i == 0 ? 0 : 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isPurchasable
                        ? const Color(0xFFF4A259).withOpacity(0.4)
                        : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Icon(
                  isPurchasable ? Icons.add_circle_outline : Icons.add,
                  color: isPurchasable
                      ? const Color(0xFFF4A259)
                      : Colors.white.withOpacity(0.2),
                  size: 26,
                ),
              ),
            );
          }

          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 68,
              margin: EdgeInsets.only(left: i == 0 ? 0 : 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.15)
                    : Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? color : Colors.white.withOpacity(0.1),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: color.withOpacity(0.25),
                    blurRadius: 10, offset: const Offset(0, 2))]
                    : [],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: hasSprites(c?.imageKey)
                          ? Image.asset(thumbAsset(c?.imageKey),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                              Icons.person_outline,
                              color: color.withOpacity(0.5), size: 30))
                          : Icon(Icons.person_outline,
                          color: color.withOpacity(0.5), size: 30),
                    ),
                  ),
                  if (c != null && c.isActive)
                    Positioned(
                      top: 4, right: 4,
                      child: Container(
                        width: 16, height: 16,
                        decoration: const BoxDecoration(
                            color: Color(0xFF4CAF50), shape: BoxShape.circle),
                        child: const Icon(Icons.check,
                            color: Colors.white, size: 11),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}