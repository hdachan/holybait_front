import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../battle_anim/battle_anim_config.dart';
import '../battle_anim/battle_anim_player.dart';
import '../provider/adventure_provider.dart';
import '../../../data/models/adventure_model.dart';
import '../../currency/provider/currency_provider.dart';

class BattleScreen extends StatefulWidget {
  final BattleStartResult battleResult;
  /// 개발용 모의 배틀: 서버에 포기·보상 요청을 보내지 않음
  final bool isPreview;
  const BattleScreen({super.key, required this.battleResult, this.isPreview = false});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen>
    with TickerProviderStateMixin {

  // 내 공격 이펙트: 서버가 준 가방 착용 이펙트, 없거나 모르는 이름이면 불꽃 베기
  static const _playerEffectKey = 'fire_slash'; // 불꽃 베기
  // 몬스터 공격 이펙트: 서버가 준 몬스터별 값, 없거나 모르는 이름이면 발톱 3줄
  static const _defaultMonsterEffectKey = 'claw';
  static const _background = Color(0xFF1A2A1A);

  late int _playerHp;
  late int _monsterHp;
  int _currentLogIndex = -1;
  bool _isFinished = false;
  bool _isConfirming = false;
  TurnLog? _currentLog;

  // 내가 맞을 때 내 HP 칸 흔들림·번쩍임
  late AnimationController _playerShakeCtrl;
  late Animation<double> _playerShakeAnim;
  late AnimationController _playerFlashCtrl;

  // 배틀 연출 (frame-lab 설정 그대로 재생)
  final _anim = BattleAnimController();
  BattleAnimConfig? _animConfig;
  Map<String, List<ui.Image>>? _animFrames;
  bool _animLoading = true;

  @override
  void initState() {
    super.initState();
    _playerHp = widget.battleResult.playerMaxHp;
    _monsterHp = widget.battleResult.monsterHp;

    _playerShakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _playerShakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -6.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 0.0), weight: 20),
    ]).animate(CurvedAnimation(
        parent: _playerShakeCtrl, curve: Curves.easeInOut));

    _playerFlashCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));

    // 그림을 모두 읽은 뒤 배틀 시작
    _loadAnim().then((_) {
      if (mounted) Future.delayed(const Duration(milliseconds: 700), _playNext);
    });
  }

  Future<void> _loadAnim() async {
    try {
      final config = await BattleAnimConfig.load();
      final monster = config.resolveMonster(widget.battleResult.monsterImageKey);
      final slash = config.slashEffect(widget.battleResult.playerAttackEffect) ??
          config.effect(_playerEffectKey);
      final claw = config.clawEffect(widget.battleResult.monsterAttackEffect) ??
          config.effect(_defaultMonsterEffectKey);
      Future<List<ui.Image>> effect(BattleAnimAsset? e) => e == null
          ? Future.value(<ui.Image>[])
          : BattleAnimImages.loadAll(BattleAnimAsset.effectPaths(e.key, e.frames));
      final frames = await Future.wait([
        monster == null
            ? Future.value(<ui.Image>[])
            : BattleAnimImages.loadAll(
                BattleAnimAsset.monsterPaths(monster.key, frames: monster.frames)),
        effect(slash),
        effect(claw),
      ]);
      if (!mounted) return;
      setState(() {
        _animConfig = config;
        _animFrames = {'monster': frames[0], 'slash': frames[1], 'claw': frames[2]};
        _animLoading = false;
      });
    } catch (_) {
      // 설정을 못 읽으면 연출 없이 진행 (몬스터는 👾로 표시)
      if (mounted) setState(() => _animLoading = false);
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    _playerShakeCtrl.dispose();
    _playerFlashCtrl.dispose();
    super.dispose();
  }

  Future<void> _playNext() async {
    final logs = widget.battleResult.logs;
    if (_currentLogIndex >= logs.length - 1) {
      if (mounted) setState(() => _isFinished = true);
      return;
    }

    final nextIndex = _currentLogIndex + 1;
    final log = logs[nextIndex];

    if (!mounted) return;
    setState(() {
      _currentLogIndex = nextIndex;
      _currentLog = log;
    });

    // 내 공격 = 'player' 장면, 몬스터 공격 = 'monster' 장면 (1인칭)
    final viewName = log.isPlayer ? 'player' : 'monster';
    final damageText =
        log.isDoubleAttack ? 'x2 -${log.damage}' : '-${log.damage}';
    final config = _animConfig;
    final played = config != null
        ? _anim.play(viewName, damageText: damageText)
        : Future<void>.delayed(const Duration(milliseconds: 900));

    // 데미지 숫자가 뜨는 순간에 HP 반영
    final hitMs =
        config?.views[viewName]?.damage?.timed.startMs.round() ?? 200;
    await Future.delayed(Duration(milliseconds: hitMs));
    if (!mounted) return;
    setState(() {
      _playerHp = log.playerHpAfter;
      _monsterHp = log.monsterHpAfter;
    });
    if (!log.isPlayer) {
      _playerShakeCtrl.forward(from: 0);
      _playerFlashCtrl.forward(from: 0).then((_) {
        if (mounted) _playerFlashCtrl.reverse();
      });
    }

    // 몬스터 HP 0 → 서서히 사라짐
    final monsterDead = log.isPlayer && log.monsterHpAfter <= 0;
    if (monsterDead) _anim.die();

    await played;
    if (!mounted) return;
    // 쓰러졌으면 사라지는 연출을 기다렸다가 결과로
    await Future.delayed(Duration(milliseconds: monsterDead ? 500 : 250));
    if (mounted) _playNext();
  }

  Future<void> _confirm() async {
    if (widget.isPreview) {
      Navigator.pop(context);
      return;
    }
    setState(() => _isConfirming = true);
    final provider = context.read<AdventureProvider>();
    final result = await provider.confirmRewards();
    if (!mounted) return;
    setState(() => _isConfirming = false);
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('보상 수령에 실패했습니다.'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    context.read<CurrencyProvider>().load();

    // 1. 결과 다이얼로그
    await _showResultDialog(result);
    if (!mounted) return;

    // 2. 레벨업 연출 (레벨업 했을 때만)
    if (result.levelsGained > 0) {
      await _showLevelUpDialog(result);
      if (!mounted) return;
    }

    // 3. 캐릭터 드롭 팝업 (드롭 됐을 때만)
    if (result.hasDroppedCharacter) {
      await _showDropDialog(result);
      if (!mounted) return;
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _showResultDialog(BattleConfirmResult result) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(result.isWin ? '🎉 승리!' : (_isTimeoutLose ? '⏱ 시간 초과' : '💀 패배'),
            style: TextStyle(
                color: result.isWin ? Colors.amber : Colors.red,
                fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.isWin) ...[
              _rewardRow('✨ 경험치', '+${result.expGained} EXP'),
              _rewardRow('💰 골드', '+${result.goldGained} G'),
              if (result.levelsGained > 0)
                _rewardRow('⬆️ 레벨업', '${result.levelsGained}번!',
                    highlight: true),
              if (result.hasDroppedCharacter)
                _rewardRow('🎁 캐릭터 획득', result.droppedCharacterName!,
                    highlight: true),
            ] else
              Text(
                  _isTimeoutLose
                      ? '50턴 안에 쓰러뜨리지 못했어요.\n공격력을 더 키워서 도전하세요!'
                      : '다음엔 더 강해져서 도전하세요!',
                  style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            const Divider(),
            Text('현재 Lv.${result.newLevel}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (result.newExp / result.requiredExp).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.grey.withOpacity(0.2),
                valueColor:
                const AlwaysStoppedAnimation(Colors.deepPurple),
              ),
            ),
            const SizedBox(height: 4),
            Text('${result.newExp} / ${result.requiredExp} EXP',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // 레벨업 연출 다이얼로그
  Future<void> _showLevelUpDialog(BattleConfirmResult result) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2C1654), Color(0xFF1A2A4A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: Colors.amber.withOpacity(0.6), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⬆️', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 12),
              const Text('LEVEL UP!',
                  style: TextStyle(
                      color: Colors.amber,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
              const SizedBox(height: 16),
              Text(
                'Lv.${result.newLevel - result.levelsGained} → Lv.${result.newLevel}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _statRow('⚔️ 공격력', result.newAtk),
                    const SizedBox(height: 6),
                    _statRow('🛡️ 방어력', result.newDef),
                    const SizedBox(height: 6),
                    _statRow('❤️ 최대 HP', result.newMaxHp),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('계속하기',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statRow(String label, int value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
        Text('$value',
            style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ],
    );
  }

  // 캐릭터 드롭 팝업
  Future<void> _showDropDialog(BattleConfirmResult result) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A3A2A), Color(0xFF0D1F0D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: Colors.greenAccent.withOpacity(0.6), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.greenAccent.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎁', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 12),
              const Text('캐릭터 획득!',
                  style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('새로운 캐릭터를 획득했어요!',
                  style:
                  TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  result.droppedCharacterName ?? '',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              const Text('캐릭터 화면에서 확인해보세요',
                  style:
                  TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('확인',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rewardRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: highlight ? Colors.amber : Colors.deepPurple)),
        ],
      ),
    );
  }

  // 서버 턴 상한(50턴)에 걸려 패배 — 내 체력이 남아 있는데 패배인 경우
  bool get _isTimeoutLose {
    final logs = widget.battleResult.logs;
    return widget.battleResult.result != 'WIN' &&
        logs.isNotEmpty &&
        logs.last.playerHpAfter > 0;
  }

  String _battleMessage() {
    if (_currentLog == null) return '몬스터가 나타났다!\n어떻게 하시겠습니까?';
    if (_isFinished) {
      if (widget.battleResult.result == 'WIN') {
        return '${widget.battleResult.monsterName}을 처치했습니다!\n보상을 받으세요.';
      }
      return _isTimeoutLose
          ? '⏱ 시간 초과! 50턴 안에 쓰러뜨리지 못했어요.\n공격력을 더 키워서 도전하세요!'
          : '패배했습니다...\n다음엔 더 강해져서 도전하세요!';
    }
    final log = _currentLog!;
    if (log.isPlayer) {
      return log.isDoubleAttack
          ? '💥 더블어택! ${widget.battleResult.monsterName}에게 ${log.damage} 데미지!'
          : '${widget.battleResult.monsterName}에게 ${log.damage} 데미지를 입혔습니다.';
    } else {
      return log.isDoubleAttack
          ? '💥 ${widget.battleResult.monsterName}의 더블어택!\n${log.damage} 데미지를 받았습니다!'
          : '${widget.battleResult.monsterName}이 ${log.damage} 데미지로 공격했습니다.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final battle = widget.battleResult;
    final activeChar = context.watch<AdventureProvider>().activeCharacter;

    final charEmoji = () {
      switch (activeChar?.imageKey) {
        case 'char_dragon': return '🐉';
        case 'char_knight': return '⚔️';
        default: return '🐻';
      }
    }();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('모험 중단'),
            content: const Text(
                '지금 나가면 이 모험은 끝나고\n보상을 받을 수 없습니다.\n나가시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('계속하기'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('나가기'),
              ),
            ],
          ),
        );
        if (leave != true || !context.mounted) return;
        if (widget.isPreview) {
          Navigator.pop(context);
          return;
        }
        // 직접 나가면 서버에서 배틀 포기 처리 (튕긴 경우만 다음에 이어서 하기)
        // 전송이 실패하면 배틀이 남아 다음 행성 진입 때 "이전 배틀" 팝업으로 처리됨
        context
            .read<AdventureProvider>()
            .abandonBattle(widget.battleResult.battleId);
        Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: _background,
        body: Stack(
          children: [
            // 배틀 연출 (화면 전체, 몬스터는 가운데)
            Positioned.fill(
              child: _animConfig != null && _animFrames != null
                  ? BattleAnimStage(
                      config: _animConfig!,
                      view: _animConfig!.views[BattleAnimController.idleView]!,
                      frames: _animFrames!,
                      controller: _anim,
                      background: _background,
                    )
                  : Center(
                      child: _animLoading
                          ? const CircularProgressIndicator()
                          : const Text('👾', style: TextStyle(fontSize: 90)),
                    ),
            ),
            SafeArea(
              child: Column(
                children: [
                  // HP 바
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: AnimatedBuilder(
                            animation: _playerShakeAnim,
                            builder: (_, child) => Transform.translate(
                              offset: Offset(_playerShakeAnim.value, 0),
                              child: AnimatedBuilder(
                                animation: _playerFlashCtrl,
                                builder: (_, child) => ColorFiltered(
                                  colorFilter: ColorFilter.mode(
                                    Colors.white.withValues(
                                        alpha: _playerFlashCtrl.value * 0.4),
                                    BlendMode.srcATop,
                                  ),
                                  child: child,
                                ),
                                child: _HpBar(
                                  name: activeChar?.characterName ?? '나',
                                  emoji: charEmoji,
                                  currentHp: _playerHp,
                                  maxHp: battle.playerMaxHp,
                                  atk: battle.playerAtk,
                                  def: battle.playerDef,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('VS',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _HpBar(
                            name: battle.monsterName,
                            emoji: '👾',
                            currentHp: _monsterHp,
                            maxHp: battle.monsterHp,
                            atk: battle.monsterAtk,
                            def: battle.monsterDef,
                            color: Colors.red,
                            isMonster: true,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // 배틀 메시지
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Text(
                      _battleMessage(),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 15),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 하단 버튼
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _isFinished
                        ? ElevatedButton(
                      onPressed: _isConfirming ? null : _confirm,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        backgroundColor: battle.result == 'WIN'
                            ? Colors.amber
                            : Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isConfirming
                          ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white))
                          : Text(
                          battle.result == 'WIN'
                              ? '🎉 보상 받기'
                              : '💀 결과 확인',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    )
                        : OutlinedButton(
                      onPressed: null,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        backgroundColor: Colors.black.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('배틀 진행 중...',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── HP 바 ──
class _HpBar extends StatelessWidget {
  final String name;
  final String emoji;
  final int currentHp;
  final int maxHp;
  final int atk;
  final int def;
  final Color color;
  final bool isMonster;

  const _HpBar({
    required this.name,
    required this.emoji,
    required this.currentHp,
    required this.maxHp,
    required this.atk,
    required this.def,
    required this.color,
    this.isMonster = false,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (currentHp / maxHp).clamp(0.0, 1.0);
    final barColor = ratio > 0.5
        ? color
        : ratio > 0.25
        ? Colors.orange
        : Colors.red;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('$currentHp / $maxHp',
              style: TextStyle(color: color, fontSize: 11)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: ratio),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: Colors.grey.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text('⚔️$atk  🛡️$def',
              style:
              const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }
}
