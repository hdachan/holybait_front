import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../currency/provider/currency_provider.dart';
import '../../adventure/provider/adventure_provider.dart';
import '../../../data/models/adventure_model.dart';
import '../../../core/network/api_client.dart';
import '../../shop/screens/shop_screen.dart';
import '../../../core/widgets/currency_badge.dart';
import '../../quest/screens/quest_sheet.dart';
import '../../quest/provider/quest_provider.dart';

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
      context.read<QuestProvider>().refreshAllBadges();
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

  String _characterImagePath(String? key) {
    switch (key) {
      case 'char_holy':   return 'assets/images/characters/holy/char_holy.png';
      case 'char_knight': return 'assets/images/characters/knight/sprite_01-removebg-preview.png';
      case 'char_dragon': return 'assets/images/characters/dragon/frame_01-removebg-preview.png';
      default:            return 'assets/images/characters/bear/sprite_01-removebg-preview.png';
    }
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
        title: const Text('캐릭터 삭제', style: TextStyle(color: Colors.white)),
        content: Text(
            '${stat.characterName}을(를) 삭제하시겠습니까?\n삭제한 캐릭터는 복구할 수 없습니다.',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소',
                style: TextStyle(color: Colors.white.withOpacity(0.5))),
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

  @override
  Widget build(BuildContext context) {
    final adventure = context.watch<AdventureProvider>();
    final characters = adventure.myCharacters;
    final currentStat = characters.isNotEmpty && _currentPage < characters.length
        ? characters[_currentPage]
        : null;
    final color = _themeColor(currentStat?.imageKey);
    return Scaffold(
      backgroundColor: const Color(0xFF1a0f0a),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: const CurrencyBadge(),
        leadingWidth: 140,
        title: const Text('캐릭터',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
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
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF4A259))),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFF4A259).withOpacity(0.12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, outerConstraints) {
            final width = outerConstraints.maxWidth.clamp(0.0, 500.0);
            final height = width * (1500 / 1300);
            final spriteSize = 200.0;
            final charTop = height * 0.78 - spriteSize;

            return Stack(
              children: [
                // ── 배경 + 캐릭터 ──
                Center(
                  child: SizedBox(
                    width: width,
                    height: height,
                    child: adventure.isLoading
                        ? const Center(
                        child: CircularProgressIndicator(color: Colors.white))
                        : characters.isEmpty
                        ? _buildError(adventure)
                        : Stack(
                      children: [
                        Positioned.fill(
                          child: _BackgroundAnimation(),
                        ),
                        Positioned(
                          top: charTop,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Image.asset(
                              _characterImagePath(currentStat?.imageKey),
                              width: spriteSize,
                              height: spriteSize,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) =>
                                  _CharacterPlaceholder(
                                      color: color, size: spriteSize),
                            ),
                          ),
                        ),

                        // ── 퀘스트 버튼 (우측) ──
                        Positioned(
                          right: 12,
                          top: height * 0.42,
                          child: Consumer<QuestProvider>(
                            builder: (context, questProvider, _) {
                              final hasClaimable = questProvider.hasClaimable;
                              return GestureDetector(
                                onTap: () => showQuestSheet(context),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1C0E04).withOpacity(0.85),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: const Color(0xFFEF7910).withOpacity(0.6)),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFEF7910).withOpacity(0.2),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Text('📜', style: TextStyle(fontSize: 22)),
                                      ),
                                    ),
                                    if (hasClaimable)
                                      Positioned(
                                        top: -4,
                                        right: -4,
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE53935),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: const Color(0xFF1C0E04), width: 2),
                                          ),
                                          child: const Center(
                                            child: Text('!',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── 레벨바 (상단 고정) ──
                if (currentStat != null)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // 레벨 바
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 500),
                              child: _LevelBar(stat: currentStat),
                            ),
                          ),
                        ),
                        // 삭제 버튼 (레벨바 아래 오른쪽)
                        if (!currentStat.isActive)
                          Padding(
                            padding: const EdgeInsets.only(right: 20),
                            child: IconButton(
                              onPressed: () => _onDeleteCharacter(currentStat),
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.redAccent, size: 18),
                              padding: const EdgeInsets.all(2),
                              constraints: const BoxConstraints(),
                            ),
                          ),
                      ],
                    ),
                  ),

                // ── 하단 UI ──
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 착용 버튼
                      if (currentStat != null)
                        _EquipButton(
                          stat: currentStat,
                          color: color,
                          onTap: () => _onSelectCharacter(currentStat.statId),
                        ),

                      const SizedBox(height: 6),

                      // 스탯 판넬 (하단)
                      if (currentStat != null)
                        Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: _StatsPanel(stat: currentStat),
                          ),
                        ),

                      const SizedBox(height: 4),

                      // 하단 슬롯
                      _BottomSlots(
                        characters: characters,
                        currentIndex: _currentPage,
                        totalSlots: adventure.slotCount,
                        thumbAsset: _characterImagePath,
                        themeColor: _themeColor,
                        onTap: (i) => setState(() => _currentPage = i),
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildError(AdventureProvider adventure) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline,
              color: Colors.white.withOpacity(0.3), size: 40),
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
}

// ── 배경 애니메이션 (랜턴 깜빡임) ──
class _BackgroundAnimation extends StatefulWidget {
  @override
  State<_BackgroundAnimation> createState() => _BackgroundAnimationState();
}

class _BackgroundAnimationState extends State<_BackgroundAnimation> {
  static const _totalFrames = 12;
  static const _frameDuration = Duration(milliseconds: 182);
  static const _basePath = 'assets/images/ui/Characte_background/BG_Burrow_Character_';

  int _frame = 2;
  bool _ascending = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_frameDuration, (_) {
      if (!mounted) return;
      setState(() {
        if (_ascending) {
          _frame++;
          if (_frame >= 13) _ascending = false;
        } else {
          _frame--;
          if (_frame <= 2) _ascending = true;
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
    final frameNum = _frame.toString().padLeft(2, '0');
    return Image.asset(
      '${_basePath}$frameNum.png',
      fit: BoxFit.cover,
      alignment: const Alignment(0, 0.5),
      gaplessPlayback: true,
    );
  }
}
class _StatsPanel extends StatelessWidget {
  final CharacterStatModel stat;
  const _StatsPanel({required this.stat});

  static const double _panelHeight = 50.0;
  static const double _cornerWidthLeft = 27.0;
  static const double _cornerWidthRight = 27.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _panelHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/ui/stats_frame_left.png',
              width: _cornerWidthLeft, height: _panelHeight, fit: BoxFit.fill),
          Container(
            height: _panelHeight,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/ui/stats_frame_center.png'),
                fit: BoxFit.fill,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StatItem(
                    iconPath: 'assets/images/ui/icon_hp.png',
                    fallbackIcon: Icons.favorite,
                    iconColor: const Color(0xFFE53935),
                    tooltip: '체력',
                    value: '${stat.hp}',
                    paddingLeft: 0,
                    paddingRight: 20,
                  ),
                  _Divider(),
                  _StatItem(
                    iconPath: 'assets/images/ui/icon_attack.png',
                    fallbackIcon: Icons.sports_martial_arts,
                    iconColor: const Color(0xFFFF6B35),
                    tooltip: '공격력',
                    value: '${stat.atk}',
                    paddingLeft: 20,
                    paddingRight: 20,
                  ),
                  _Divider(),
                  _StatItem(
                    iconPath: 'assets/images/ui/icon_defense.png',
                    fallbackIcon: Icons.shield,
                    iconColor: const Color(0xFF1565C0),
                    tooltip: '방어력',
                    value: '${stat.def}',
                    paddingLeft: 20,
                    paddingRight: 20,
                  ),
                  _Divider(),
                  _StatItem(
                    iconPath: 'assets/images/ui/icon_double.png',
                    fallbackIcon: Icons.flash_on,
                    iconColor: const Color(0xFFFFA000),
                    tooltip: '더블어택',
                    value: '40%',
                    paddingLeft: 20,
                    paddingRight: 0,
                  ),
                ],
              ),
            ),
          ),
          Image.asset('assets/images/ui/stats_frame_right.png',
              width: _cornerWidthRight, height: _panelHeight, fit: BoxFit.fill),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String iconPath;
  final IconData fallbackIcon;
  final Color iconColor;
  final String tooltip;
  final String value;
  final double paddingLeft;
  final double paddingRight;

  const _StatItem({
    required this.iconPath,
    required this.fallbackIcon,
    required this.iconColor,
    required this.tooltip,
    required this.value,
    this.paddingLeft = 6,
    this.paddingRight = 6,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final overlay = Overlay.of(context);
        final renderBox = context.findRenderObject() as RenderBox;
        final offset = renderBox.localToGlobal(Offset.zero);
        late OverlayEntry entry;
        entry = OverlayEntry(
          builder: (_) => Positioned(
            left: offset.dx - 10,
            top: offset.dy - 36,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(tooltip,
                    style: const TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ),
          ),
        );
        overlay.insert(entry);
        Future.delayed(const Duration(seconds: 2), entry.remove);
      },
      child: Padding(
        padding: EdgeInsets.only(left: paddingLeft, right: paddingRight),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              iconPath,
              width: 22,
              height: 22,
              errorBuilder: (_, __, ___) =>
                  Icon(fallbackIcon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(color: Colors.black, blurRadius: 0, offset: const Offset(-1, -1)),
                  Shadow(color: Colors.black, blurRadius: 0, offset: const Offset(1, -1)),
                  Shadow(color: Colors.black, blurRadius: 0, offset: const Offset(-1, 1)),
                  Shadow(color: Colors.black, blurRadius: 0, offset: const Offset(1, 1)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 50,
      color: const Color(0xFF8D6E63).withOpacity(0.4),
    );
  }
}

// ── 착용 버튼 ──
class _EquipButton extends StatefulWidget {
  final CharacterStatModel stat;
  final Color color;
  final VoidCallback onTap;

  const _EquipButton(
      {required this.stat, required this.color, required this.onTap});

  @override
  State<_EquipButton> createState() => _EquipButtonState();
}

class _EquipButtonState extends State<_EquipButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.stat.isActive) {
      return Stack(
        alignment: Alignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/ui/select_ui.svg',
            width: 120,
            height: 30,
          ),
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline,
                  size: 14, color: Color(0xFF4CAF50)),
              SizedBox(width: 6),
              Text('착용 중',
                  style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
          ),
        ],
      );
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/ui/select_ui.svg',
              width: 120,
              height: 30,
            ),
            const Text(
              '착용하기',
              style: TextStyle(
                color: Color(0xFF3E2723),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
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
              width: s,
              height: s,
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
              Icon(Icons.person_outline,
                  size: size * 0.3, color: color.withOpacity(0.4)),
              const SizedBox(height: 4),
              Text('준비 중',
                  style:
                  TextStyle(fontSize: 12, color: color.withOpacity(0.4))),
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
    const double barHeight = 66.0;
    // level_badge 비율: 175:133 = 1.316
    const double badgeW = barHeight * 1.316;

    return SizedBox(
      height: barHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 나무 배경 판넬
          Positioned.fill(
            child: Image.asset(
              'assets/images/ui/level_bar_bg.png',
              fit: BoxFit.fill,
            ),
          ),

          // 경험치 바 (고정 크기)
          Positioned(
            left: badgeW + 12,
            right: 100,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  final overlay = Overlay.of(context);
                  final renderBox = context.findRenderObject() as RenderBox;
                  final offset = renderBox.localToGlobal(Offset.zero);
                  late OverlayEntry entry;
                  entry = OverlayEntry(
                    builder: (_) => Positioned(
                      left: offset.dx,
                      top: offset.dy - 32,
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${stat.exp} / ${stat.requiredExp}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  );
                  overlay.insert(entry);
                  Future.delayed(const Duration(seconds: 2), entry.remove);
                },
                child: SizedBox(
                  width: 240,
                  height: 14,
                  child: Stack(
                    children: [
                      // 배경
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B4C2A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF3D2000),
                              width: 5.0,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xFF3D2000),
                                spreadRadius: 5,
                                blurRadius: 0,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // fill
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: stat.expProgress,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFF6EE060),
                                    Color(0xFF3AAD2E),
                                    Color(0xFF2D8A24),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 하이라이트
                      Positioned(
                        left: 4, right: 4, top: 2,
                        height: 6,
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: stat.expProgress,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 레벨 배지 (왼쪽 밖으로 살짝)
          Positioned(
            left: 0,
            top: -6,
            child: SizedBox(
              width: badgeW,
              height: barHeight + 12,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/images/ui/level_badge.png',
                    fit: BoxFit.contain,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('LV',
                          style: TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              height: 1)),
                      Text('${stat.level}',
                          style: const TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              height: 1)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
  final void Function(int) onTap;

  const _BottomSlots({
    required this.characters,
    required this.currentIndex,
    required this.totalSlots,
    required this.thumbAsset,
    required this.themeColor,
    required this.onTap,
  });

  void _showExpandDialog(BuildContext context, AdventureProvider adventure) {
    final currentSlot = adventure.slotCount;
    final costs = [0, 0, 0, 0, 500, 1000, 1500, 2500, 3500, 5000];
    final cost = currentSlot < 10 ? costs[currentSlot] : -1;

    if (cost == -1) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('슬롯이 이미 최대입니다.')));
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
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
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

    const double panelHeight = 110.0;
    const double cornerWidth = 14.0;
    const double normalSlotH = 76.0;
    const double normalSlotW = normalSlotH * 252 / 390;
    const double selectedSlotH = 90.0;
    const double selectedSlotW = selectedSlotH * 252 / 390;

    return SizedBox(
      height: panelHeight,
      child: Row(
        children: [
          // 왼쪽 프레임
          Image.asset(
            'assets/images/ui/Characte_slot/slot_frame_left.png',
            width: cornerWidth,
            height: panelHeight,
            fit: BoxFit.fill,
          ),
          // 가운데 (슬롯 목록)
          Expanded(
            child: Container(
              height: panelHeight,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage(
                      'assets/images/ui/Characte_slot/slot_frame_center.png'),
                  fit: BoxFit.fill,
                ),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                clipBehavior: Clip.none,
                itemCount: displayCount,
                itemBuilder: (context, i) {
                  final hasChar = i < characters.length;
                  final c = hasChar ? characters[i] : null;
                  final isSelected = currentIndex == i;
                  final color = themeColor(c?.imageKey);

                  // 슬롯 높이/너비
                  final slotH = isSelected ? selectedSlotH : normalSlotH;
                  final slotW = isSelected ? selectedSlotW : normalSlotW;
                  final topPad = ((panelHeight - slotH) / 2).clamp(0.0, double.infinity);
                  final botPad = ((panelHeight - slotH) / 2).clamp(0.0, double.infinity);

                  // 구매 슬롯
                  if (!hasChar) {
                    final isPurchasable = i == adventure.slotCount;
                    return GestureDetector(
                      onTap: isPurchasable
                          ? () => _showExpandDialog(context, adventure)
                          : null,
                      child: Padding(
                        padding: EdgeInsets.only(
                            left: i == 0 ? 0 : 8,
                            top: ((panelHeight - normalSlotH) / 2).clamp(0.0, double.infinity),
                            bottom: ((panelHeight - normalSlotH) / 2).clamp(0.0, double.infinity)),
                        child: isPurchasable
                            ? Image.asset(
                          'assets/images/ui/Characte_slot/slot_locked.png',
                          width: normalSlotW,
                          height: normalSlotH,
                          fit: BoxFit.contain,
                        )
                            : Image.asset(
                          'assets/images/ui/Characte_slot/slot_normal.png',
                          width: normalSlotW,
                          height: normalSlotH,
                          fit: BoxFit.contain,
                          color: Colors.white.withOpacity(0.3),
                          colorBlendMode: BlendMode.modulate,
                        ),
                      ),
                    );
                  }

                  // 캐릭터 슬롯
                  return GestureDetector(
                    onTap: () => onTap(i),
                    child: Padding(
                      padding: EdgeInsets.only(
                          left: i == 0 ? 0 : 8,
                          top: topPad,
                          bottom: botPad),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 슬롯 배경 (착용중이면 selected, 나머지 normal)
                          Image.asset(
                            (c != null && c.isActive)
                                ? 'assets/images/ui/Characte_slot/slot_selected.png'
                                : 'assets/images/ui/Characte_slot/slot_normal.png',
                            width: slotW,
                            height: slotH,
                            fit: BoxFit.contain,
                          ),
                          // 캐릭터 이미지 (상반신, 테두리 안쪽)
                          Positioned.fill(
                            child: ClipRect(
                              child: Align(
                                alignment: const Alignment(0, 0.6),
                                child: Image.asset(
                                  thumbAsset(c?.imageKey),
                                  width: slotW * 0.88,
                                  height: slotH * 0.75,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.topCenter,
                                  errorBuilder: (_, __, ___) => Icon(
                                      Icons.person_outline,
                                      color: color.withOpacity(0.5),
                                      size: 26),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // 오른쪽 프레임
          Image.asset(
            'assets/images/ui/Characte_slot/slot_frame_right.png',
            width: cornerWidth,
            height: panelHeight,
            fit: BoxFit.fill,
          ),
        ],
      ),
    );
  }
}