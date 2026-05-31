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

  // 몬스터 흔들기
  late AnimationController _monsterShakeCtrl;
  late Animation<double> _monsterShakeAnim;

  // 플레이어 피격 흔들기
  late AnimationController _playerShakeCtrl;
  late Animation<double> _playerShakeAnim;

  // 몬스터 피격 플래시 (빨간색)
  late AnimationController _monsterFlashCtrl;

  // 플레이어 피격 플래시 (흰색)
  late AnimationController _playerFlashCtrl;

  // 몬스터 점프 (공격 시)
  late AnimationController _monsterJumpCtrl;
  late Animation<double> _monsterJumpAnim;

  int? _lastDamage;
  bool _isDoubleAttack = false;
  bool _isDamageToPlayer = false;
  int _damageKey = 0;

  TurnLog? _currentLog;

  @override
  void initState() {
    super.initState();
    _playerHp = widget.battleResult.playerMaxHp;
    _monsterHp = widget.battleResult.monsterHp;

    // 몬스터 흔들기 (피격)
    _monsterShakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _monsterShakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -6.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 0.0), weight: 20),
    ]).animate(CurvedAnimation(
        parent: _monsterShakeCtrl, curve: Curves.easeInOut));

    // 플레이어 흔들기 (피격)
    _playerShakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _playerShakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -6.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 0.0), weight: 20),
    ]).animate(CurvedAnimation(
        parent: _playerShakeCtrl, curve: Curves.easeInOut));

    // 몬스터 피격 플래시
    _monsterFlashCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));

    // 플레이어 피격 플래시
    _playerFlashCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));

    // 몬스터 공격 점프 (위아래)
    _monsterJumpCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _monsterJumpAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -18.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: -18.0, end: 0.0), weight: 50),
    ]).animate(
        CurvedAnimation(parent: _monsterJumpCtrl, curve: Curves.easeInOut));

    Future.delayed(const Duration(milliseconds: 700), _playNext);
  }

  @override
  void dispose() {
    _monsterShakeCtrl.dispose();
    _playerShakeCtrl.dispose();
    _monsterFlashCtrl.dispose();
    _playerFlashCtrl.dispose();
    _monsterJumpCtrl.dispose();
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
      // 플레이어 공격 → 몬스터 흔들기 + 빨간 플래시
      _monsterShakeCtrl.forward(from: 0);
      _monsterFlashCtrl.forward(from: 0).then((_) {
        if (mounted) _monsterFlashCtrl.reverse();
      });
    } else {
      // 몬스터 공격 → 몬스터 점프 + 플레이어 흔들기 + 흰 플래시
      _monsterJumpCtrl.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 150));
      _playerShakeCtrl.forward(from: 0);
      _playerFlashCtrl.forward(from: 0).then((_) {
        if (mounted) _playerFlashCtrl.reverse();
      });
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
    await _showResultDialog(result);
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
                _rewardRow('⬆️ 레벨업',
                    'Lv.${result.newLevel - result.levelsGained} → Lv.${result.newLevel}',
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
    final activeChar =
        context.watch<AdventureProvider>().activeCharacter;

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
              // ── HP 바 영역 ──
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // 플레이어 HP (캐릭터 이름 표시)
                    Expanded(
                      child: AnimatedBuilder(
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
                    ),
                    const SizedBox(width: 12),
                    const Text('VS',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    const SizedBox(width: 12),
                    // 몬스터 HP
                    Expanded(
                      child: _HpBar(
                        name: battle.monsterName,
                        emoji: '👹',
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

              // ── 몬스터 이미지 영역 ──
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 몬스터
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
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                  width: 2),
                            ),
                            child: const Center(
                              child: Text('👹',
                                  style: TextStyle(fontSize: 90)),
                            ),
                          ),
                        ),
                      ),

                      // 데미지 숫자 (공중으로 떠오름)
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

              // ── 배틀 메시지 ──
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border:
                  Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Text(
                  _battleMessage(),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),

              // ── 하단 버튼 ──
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
              style: const TextStyle(
                  color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }
}