import 'dart:async';
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
      case 'char_knight': return const Color(0xFF2196F3);
      default: return const Color(0xFFE84545);
    }
  }

  bool _hasSprites(String? key) {
    return key == null ||
        key == 'char_bear' ||
        key == 'char_knight' ||
        key == 'char_dragon';
  }

  bool _hasBackground(String? key) {
    return key == null || key == 'char_bear';
  }

  String _spriteFolder(String? key) {
    switch (key) {
      case 'char_knight': return 'assets/images/characters/knight/';
      case 'char_dragon': return 'assets/images/characters/dragon/';
      default: return 'assets/images/characters/bear/';
    }
  }

  // 캐릭터별 파일명 prefix (bear/knight: sprite, dragon: frame)
  String _spritePrefix(String? key) {
    switch (key) {
      case 'char_dragon': return 'frame';
      default: return 'sprite';
    }
  }

  String _backgroundAsset(String? key) {
    return '${_spriteFolder(key)}background.png';
  }

  String _levelBgAsset(String? key) {
    return '${_spriteFolder(key)}level_background.png';
  }

  // 모든 캐릭터 frame_01-removebg-preview.png 동일
  String _thumbAsset(String? key) {
    if (_hasSprites(key)) {
      final prefix = _spritePrefix(key);
      return '${_spriteFolder(key)}${prefix}_01-removebg-preview.png';
    }
    return '';
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
    final color = _themeColor(currentStat?.imageKey);
    final showBg = _hasBackground(currentStat?.imageKey);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F1FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('캐릭터',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(children: [
              const Text('🪙', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 3),
              Text(_fmt(currency.gold),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFB300),
                      fontSize: 13)),
              const SizedBox(width: 10),
              const Text('👟', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 3),
              Text(_fmt(currency.shoeCoin),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF42A5F5),
                      fontSize: 13)),
            ]),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 전체 화면 배경
          if (showBg)
            Image.asset(
              _backgroundAsset(currentStat?.imageKey),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFFF2F1FA)),
            )
          else
            Container(color: const Color(0xFFF2F1FA)),

          // 컨텐츠
          SafeArea(
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
                      ? const Center(child: CircularProgressIndicator())
                      : characters.isEmpty
                      ? _buildError(adventure)
                      : LayoutBuilder(
                    builder: (context, constraints) {
                      final spriteSize =
                      (constraints.maxHeight * 0.65)
                          .clamp(150.0, 340.0);
                      return Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                        children: [
                          // 캐릭터 영역 (자물쇠 슬롯 제거)
                          Expanded(
                            child: Column(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              crossAxisAlignment:
                              CrossAxisAlignment.center,
                              children: [
                                // 스프라이트
                                _hasSprites(currentStat?.imageKey)
                                    ? _SpriteAnimation(
                                  spriteFolder: _spriteFolder(
                                      currentStat?.imageKey),
                                  spritePrefix: _spritePrefix(
                                      currentStat?.imageKey),
                                  totalFrames: 25,
                                  color: color,
                                  size: spriteSize,
                                )
                                    : _CharacterPlaceholder(
                                  color: color,
                                  size: spriteSize,
                                ),
                                const SizedBox(height: 8),

                                // 스탯
                                if (currentStat != null)
                                  Container(
                                    padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white
                                          .withOpacity(0.75),
                                      borderRadius:
                                      BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        _statChip(
                                            Icons.close,
                                            '공격',
                                            currentStat.atk,
                                            const Color(0xFF9C6FDE)),
                                        const SizedBox(width: 12),
                                        _statChip(
                                            Icons.shield_outlined,
                                            '방어',
                                            currentStat.def,
                                            const Color(0xFF5B9BD5)),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 10),

                                // 착용 버튼
                                if (currentStat != null)
                                  Center(
                                    child: _EquipButton(
                                      stat: currentStat,
                                      color: color,
                                      onTap: () =>
                                          _onSelectCharacter(
                                              currentStat.statId),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

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
          TextButton.icon(
            onPressed: () => adventure.loadStages(),
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, int value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text('$label  ',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        Text('$value',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color)),
      ],
    );
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
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
      width: size,
      height: size,
      child: Center(
        child: Container(
          width: size * 0.8,
          height: size * 0.8,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.2), width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_outline,
                  size: size * 0.3, color: color.withOpacity(0.3)),
              const SizedBox(height: 4),
              Text('준비 중',
                  style: TextStyle(
                      fontSize: 12,
                      color: color.withOpacity(0.4),
                      fontWeight: FontWeight.w500)),
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
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            'LV ${stat.level}',
            style: const TextStyle(
              color: Color(0xFF4CAF50),
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: stat.expProgress,
                minHeight: 12,
                backgroundColor: Colors.grey.withOpacity(0.15),
                valueColor:
                const AlwaysStoppedAnimation(Color(0xFF4CAF50)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${stat.exp}/${stat.requiredExp}',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// ── 자물쇠 슬롯 ──
class _LockSlot extends StatelessWidget {
  final bool hasBg;
  const _LockSlot({this.hasBg = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: hasBg
            ? Colors.white.withOpacity(0.55)
            : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasBg
              ? Colors.white.withOpacity(0.7)
              : Colors.grey.withOpacity(0.25),
          width: 1.2,
        ),
        boxShadow: hasBg
            ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ]
            : null,
      ),
      child: Icon(
        Icons.lock_outline,
        size: 20,
        color: hasBg ? Colors.grey.shade700 : Colors.grey.shade400,
      ),
    );
  }
}

// ── 스탯 ──
class _StatDisplay extends StatelessWidget {
  final CharacterStatModel stat;
  const _StatDisplay({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _row(Icons.close, '공격력', stat.atk, const Color(0xFF9C6FDE)),
        const SizedBox(height: 4),
        _row(Icons.shield_outlined, '방어력', stat.def,
            const Color(0xFF5B9BD5)),
      ],
    );
  }

  Widget _row(IconData icon, String label, int value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text('$label :  ',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
        Text('$value',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color)),
      ],
    );
  }
}

// ── 착용 버튼 ──
class _EquipButton extends StatelessWidget {
  final CharacterStatModel stat;
  final Color color;
  final VoidCallback onTap;

  const _EquipButton({
    required this.stat,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (stat.isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFF4CAF50).withOpacity(0.5)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 15, color: Color(0xFF4CAF50)),
            SizedBox(width: 6),
            Text('착용 중',
                style: TextStyle(
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
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
        const SnackBar(content: Text('슬롯이 이미 최대입니다.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('슬롯 확장'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('슬롯을 ${currentSlot + 1}개로 확장합니다.'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🪙 골드 '),
                Text('$cost개',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber)),
                const Text(' 소모'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await adventure.expandSlot();
              if (!context.mounted) return;
              if (result != null) {
                // 골드 즉시 갱신
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
                // 골드 부족 or 기타 오류 → 팝업
                final errMsg = adventure.error ?? '';
                String msg;
                if (errMsg.contains('골드') || errMsg.contains('403')) {
                  msg = '골드가 부족합니다.\n모험을 통해 골드를 모아보세요!';
                } else if (errMsg.contains('최대')) {
                  msg = '슬롯이 이미 최대입니다.';
                } else {
                  msg = '슬롯 확장에 실패했습니다.';
                }
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('슬롯 확장 실패'),
                    content: Text(msg),
                    actions: [
                      FilledButton(
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
    // 슬롯 수 + 1 (마지막 하나는 구매 버튼, 최대 10개면 추가 안 함)
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
            // i < slotCount → 구매된 빈 슬롯 (그냥 빈 슬롯)
            // i == slotCount → 구매 가능한 다음 슬롯 (골드 구매 버튼)
            final isPurchasable = i == adventure.slotCount;

            return GestureDetector(
              onTap: isPurchasable
                  ? () => _showExpandDialog(context, adventure)
                  : null,
              child: Container(
                width: 68,
                margin: EdgeInsets.only(left: i == 0 ? 0 : 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isPurchasable
                        ? Colors.amber.withOpacity(0.4)
                        : Colors.grey.withOpacity(0.2),
                  ),
                ),
                child: Icon(
                  isPurchasable ? Icons.add_circle_outline : Icons.add,
                  color: isPurchasable
                      ? Colors.amber.shade600
                      : Colors.grey.shade400,
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
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? color : Colors.grey.withOpacity(0.2),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: color.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
                    : [],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: hasSprites(c?.imageKey)
                          ? Image.asset(
                        thumbAsset(c?.imageKey),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.person_outline,
                          color: color.withOpacity(0.4),
                          size: 30,
                        ),
                      )
                          : Icon(
                        Icons.person_outline,
                        color: color.withOpacity(0.4),
                        size: 30,
                      ),
                    ),
                  ),
                  if (c != null && c.isActive)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
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