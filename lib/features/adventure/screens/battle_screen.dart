import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/adventure_provider.dart';
import '../../../data/models/adventure_model.dart';
import '../../currency/provider/currency_provider.dart';

class BattleScreen extends StatefulWidget {
  final BattleStartResult battleResult;
  const BattleScreen({super.key, required this.battleResult});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen>
    with TickerProviderStateMixin {

  late int _playerHp;
  late int _monsterHp;
  int _currentLogIndex = -1;
  bool _isFinished = false;
  bool _isConfirming = false;
  bool _monsterIsAttacking = false;

  late AnimationController _monsterShakeCtrl;
  late Animation<double> _monsterShakeAnim;
  late AnimationController _playerShakeCtrl;
  late Animation<double> _playerShakeAnim;
  late AnimationController _monsterFlashCtrl;
  late AnimationController _playerFlashCtrl;
  late AnimationController _monsterJumpCtrl;
  late Animation<double> _monsterJumpAnim;

  // 공격 이펙트 (플레이어 공격 / 몬스터 공격 각각 별도)
  late AnimationController _playerAttackEffectCtrl;
  late AnimationController _monsterAttackEffectCtrl;
  bool _showPlayerEffect = false;
  bool _showMonsterEffect = false;

  int? _lastDamage;
  bool _isDoubleAttack = false;
  bool _isDamageToPlayer = false;
  int _damageKey = 0;
  TurnLog? _currentLog;

  static const int _monsterTotalFrames = 12; // 프레임 수
  static const int _frameMs = 80;            // 프레임 속도 (ms)

  // 몬스터별 스프라이트 폴더 (imageKey 기반, 없으면 기본값)
  String get _monsterSpriteFolder {
    final key = widget.battleResult.monsterImageKey ?? 'monster1';
    return 'assets/images/monsters/$key/';
  }

  @override
  void initState() {
    super.initState();
    _playerHp = widget.battleResult.playerMaxHp;
    _monsterHp = widget.battleResult.monsterHp;

    _monsterShakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _monsterShakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -6.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 0.0), weight: 20),
    ]).animate(CurvedAnimation(
        parent: _monsterShakeCtrl, curve: Curves.easeInOut));

    _playerShakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _playerShakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -6.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 0.0), weight: 20),
    ]).animate(CurvedAnimation(
        parent: _playerShakeCtrl, curve: Curves.easeInOut));

    _monsterFlashCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _playerFlashCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));

    _monsterJumpCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _monsterJumpAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -18.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: -18.0, end: 0.0), weight: 50),
    ]).animate(CurvedAnimation(
        parent: _monsterJumpCtrl, curve: Curves.easeInOut));

    _playerAttackEffectCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _monsterAttackEffectCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));

    // 스프라이트 미리 캐시 후 배틀 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (int i = 1; i <= _monsterTotalFrames; i++) {
        final frameNum = i.toString().padLeft(2, '0');
        precacheImage(
          AssetImage(
              '${_monsterSpriteFolder}frame_$frameNum-removebg-preview.png'),
          context,
        );
      }
      Future.delayed(const Duration(milliseconds: 700), _playNext);
    });
  }

  @override
  void dispose() {
    _monsterShakeCtrl.dispose();
    _playerShakeCtrl.dispose();
    _monsterFlashCtrl.dispose();
    _playerFlashCtrl.dispose();
    _monsterJumpCtrl.dispose();
    _playerAttackEffectCtrl.dispose();
    _monsterAttackEffectCtrl.dispose();
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
      _lastDamage = log.damage;
      _isDoubleAttack = log.isDoubleAttack;
      _isDamageToPlayer = !log.isPlayer;
      _damageKey++;
    });

    if (log.isPlayer) {
      // 플레이어 공격 이펙트 (몬스터 위치에 표시)
      setState(() => _showPlayerEffect = true);
      _playerAttackEffectCtrl.forward(from: 0).then((_) {
        if (mounted) setState(() => _showPlayerEffect = false);
      });

      _monsterShakeCtrl.forward(from: 0);
      _monsterFlashCtrl.forward(from: 0).then((_) {
        if (mounted) _monsterFlashCtrl.reverse();
      });
    } else {
      setState(() => _monsterIsAttacking = true);
      _monsterJumpCtrl.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 150));

      // 몬스터 공격 이펙트 (플레이어 위치에 표시)
      setState(() => _showMonsterEffect = true);
      _monsterAttackEffectCtrl.forward(from: 0).then((_) {
        if (mounted) setState(() => _showMonsterEffect = false);
      });

      _playerShakeCtrl.forward(from: 0);
      _playerFlashCtrl.forward(from: 0).then((_) {
        if (mounted) _playerFlashCtrl.reverse();
      });

      // 프레임 수 * 속도만큼 정확히 대기
      await Future.delayed(
          Duration(milliseconds: _frameMs * _monsterTotalFrames));
      if (mounted) setState(() => _monsterIsAttacking = false);
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() {
        _playerHp = log.playerHpAfter;
        _monsterHp = log.monsterHpAfter;
      });
    }

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _lastDamage = null);
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) _playNext();
    }
  }

  Future<void> _confirm() async {
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
        title: Text(result.isWin ? '🎉 승리!' : '💀 패배',
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
              const Text('다음엔 더 강해져서 도전하세요!',
                  style: TextStyle(color: Colors.grey)),
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

  String _battleMessage() {
    if (_currentLog == null) return '몬스터가 나타났다!\n어떻게 하시겠습니까?';
    if (_isFinished) {
      return widget.battleResult.result == 'WIN'
          ? '${widget.battleResult.monsterName}을 처치했습니다!\n보상을 받으세요.'
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
                '지금 나가면 보상을 받을 수 없습니다.\n나갔다 들어오면 다시 볼 수 있습니다.\n나가시겠습니까?'),
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
        if (leave == true && mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A2A1A),
        body: SafeArea(
          child: Column(
            children: [
              // HP 바
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          AnimatedBuilder(
                            animation: _playerShakeAnim,
                            builder: (_, child) => Transform.translate(
                              offset: Offset(_playerShakeAnim.value, 0),
                              child: AnimatedBuilder(
                                animation: _playerFlashCtrl,
                                builder: (_, child) => ColorFiltered(
                                  colorFilter: ColorFilter.mode(
                                    Colors.white.withOpacity(
                                        _playerFlashCtrl.value * 0.4),
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
                          // 몬스터 공격 이펙트 (플레이어 위에 표시)
                          if (_showMonsterEffect)
                            _AttackEffect(
                              controller: _monsterAttackEffectCtrl,
                              color: const Color(0xFFE53935),
                              isDouble: _isDoubleAttack && _lastDamage != null,
                            ),
                        ],
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

              // 몬스터 이미지
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: Listenable.merge(
                            [_monsterShakeAnim, _monsterJumpAnim]),
                        builder: (_, child) => Transform.translate(
                          offset: Offset(
                            _monsterShakeAnim.value,
                            _monsterJumpAnim.value,
                          ),
                          child: child,
                        ),
                        child: AnimatedBuilder(
                          animation: _monsterFlashCtrl,
                          builder: (_, child) => ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              Colors.red.withOpacity(
                                  _monsterFlashCtrl.value * 0.6),
                              BlendMode.srcATop,
                            ),
                            child: child,
                          ),
                          child: _MonsterSprite(
                            spriteFolder: _monsterSpriteFolder,
                            totalFrames: _monsterTotalFrames,
                            frameMs: _frameMs,
                            isAttacking: _monsterIsAttacking,
                          ),
                        ),
                      ),

                      // 플레이어 공격 이펙트 (몬스터 위에 표시)
                      if (_showPlayerEffect)
                        _AttackEffect(
                          controller: _playerAttackEffectCtrl,
                          color: const Color(0xFF66D4FF),
                          isDouble: _isDoubleAttack && _lastDamage != null,
                        ),

                      // 데미지 숫자
                      if (_lastDamage != null)
                        TweenAnimationBuilder<double>(
                          key: ValueKey(_damageKey),
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 600),
                          builder: (_, v, __) => Opacity(
                            opacity: v < 0.6 ? 1.0 : (1.0 - v) / 0.4,
                            child: Transform.translate(
                              offset: Offset(
                                _isDamageToPlayer ? -60 : 60,
                                -60 * v,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: _isDamageToPlayer
                                      ? Colors.red.shade700
                                      : Colors.orange.shade700,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_isDamageToPlayer
                                          ? Colors.red
                                          : Colors.orange)
                                          .withOpacity(0.6),
                                      blurRadius: 14,
                                      spreadRadius: 1,
                                    )
                                  ],
                                ),
                                child: Text(
                                  _isDoubleAttack
                                      ? '💥 x2  $_lastDamage!'
                                      : '-$_lastDamage',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 배틀 메시지
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.1)),
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
      ),
    );
  }
}

// ── 몬스터 스프라이트 ──
class _MonsterSprite extends StatefulWidget {
  final String spriteFolder;
  final int totalFrames;
  final int frameMs;
  final bool isAttacking;

  const _MonsterSprite({
    required this.spriteFolder,
    required this.totalFrames,
    required this.frameMs,
    required this.isAttacking,
  });

  @override
  State<_MonsterSprite> createState() => _MonsterSpriteState();
}

class _MonsterSpriteState extends State<_MonsterSprite> {
  int _frame = 0;
  Timer? _timer;

  @override
  void didUpdateWidget(_MonsterSprite oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isAttacking && !oldWidget.isAttacking) {
      _frame = 0;
      _timer?.cancel();
      _timer = Timer.periodic(
          Duration(milliseconds: widget.frameMs), (_) {
        if (!mounted) return;
        setState(() {
          if (_frame < widget.totalFrames - 1) {
            _frame++; // 마지막 프레임에서 멈춤
          }
        });
      });
    } else if (!widget.isAttacking && oldWidget.isAttacking) {
      _timer?.cancel();
      _timer = null;
      if (mounted) setState(() => _frame = 0); // frame_01 복귀
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 바닥 그림자
          Positioned(
            bottom: 0,
            child: Container(
              width: 140,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(70),
              ),
            ),
          ),
          // IndexedStack — 25장 전부 올려두고 현재 프레임만 표시 (깜빡임 없음)
          IndexedStack(
            index: _frame,
            children: List.generate(widget.totalFrames, (i) {
              final frameNum = (i + 1).toString().padLeft(2, '0');
              final path =
                  '${widget.spriteFolder}frame_$frameNum-removebg-preview.png';
              return Image.asset(
                path,
                width: 240,
                height: 240,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => i == 0
                    ? Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.green.withOpacity(0.3),
                        width: 2),
                  ),
                  child: const Center(
                    child:
                    Text('👾', style: TextStyle(fontSize: 90)),
                  ),
                )
                    : const SizedBox(width: 240, height: 240),
              );
            }),
          ),
        ],
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
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: Colors.grey.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation(barColor),
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
// ── 공격 이펙트 (플레이어/몬스터 공격 시 표시되는 임팩트) ──
class _AttackEffect extends StatelessWidget {
  final AnimationController controller;
  final Color color;
  final bool isDouble;

  const _AttackEffect({
    required this.controller,
    required this.color,
    required this.isDouble,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value; // 0.0 ~ 1.0

        // 타이밍: 확산 후 서서히 사라짐
        final scale = 0.3 + (t * 1.2);
        final opacity = (1.0 - t).clamp(0.0, 1.0);

        return IgnorePointer(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 원형 충격파
              Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 4),
                    ),
                  ),
                ),
              ),

              // 십자 슬래시 라인
              Opacity(
                opacity: opacity,
                child: Transform.rotate(
                  angle: 0.4,
                  child: Container(
                    width: 140 * (0.5 + t * 0.6),
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(color: color.withOpacity(0.6), blurRadius: 8),
                      ],
                    ),
                  ),
                ),
              ),
              Opacity(
                opacity: opacity,
                child: Transform.rotate(
                  angle: -0.4,
                  child: Container(
                    width: 140 * (0.5 + t * 0.6),
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(color: color.withOpacity(0.6), blurRadius: 8),
                      ],
                    ),
                  ),
                ),
              ),

              // 스파크 파티클 (더블어택일 때 추가 강조)
              if (isDouble)
                Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale * 1.3,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFFFFD700), width: 3),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}