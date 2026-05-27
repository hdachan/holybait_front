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
  int _currentLogIndex = -1; // 현재 재생 중인 턴 인덱스
  bool _isPlaying = false;
  bool _isFinished = false;
  bool _isConfirming = false;

  // 몬스터 흔들기 애니메이션
  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;

  // 데미지 텍스트 표시
  int? _lastDamage;
  bool _isDoubleAttack = false;
  bool _isDamageToPlayer = false;

  @override
  void initState() {
    super.initState();
    _playerHp = widget.battleResult.playerMaxHp;
    _monsterHp = widget.battleResult.monsterHp;

    _shakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _shakeAnim = Tween<double>(begin: 0, end: 10).animate(
        CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn));

    // 잠시 후 자동 재생 시작
    Future.delayed(const Duration(milliseconds: 600), _playNext);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  // 턴 로그 하나씩 재생
  Future<void> _playNext() async {
    final logs = widget.battleResult.logs;
    if (_currentLogIndex >= logs.length - 1) {
      setState(() => _isFinished = true);
      return;
    }

    setState(() {
      _isPlaying = true;
      _currentLogIndex++;
    });

    final log = logs[_currentLogIndex];

    setState(() {
      _lastDamage = log.damage;
      _isDoubleAttack = log.isDoubleAttack;
      _isDamageToPlayer = !log.isPlayer;
      _playerHp = log.playerHpAfter;
      _monsterHp = log.monsterHpAfter;
    });

    // 몬스터 공격 시 플레이어 HP바 흔들기, 플레이어 공격 시 몬스터 흔들기
    _shakeController.forward(from: 0);

    // 다음 턴까지 대기
    await Future.delayed(const Duration(milliseconds: 900));

    if (mounted) {
      setState(() {
        _lastDamage = null;
        _isPlaying = false;
      });
      await Future.delayed(const Duration(milliseconds: 200));
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

    // 재화 갱신
    context.read<CurrencyProvider>().load();

    // 결과 다이얼로그
    await _showResultDialog(result);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _showResultDialog(BattleConfirmResult result) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Row(children: [
          Text(result.isWin ? '🎉 승리!' : '💀 패배',
              style: TextStyle(
                  color: result.isWin ? Colors.amber : Colors.red,
                  fontWeight: FontWeight.bold)),
        ]),
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

  @override
  Widget build(BuildContext context) {
    final battle = widget.battleResult;
    final logs = battle.logs;
    final currentLog =
        _currentLogIndex >= 0 && _currentLogIndex < logs.length
            ? logs[_currentLogIndex]
            : null;

    return PopScope(
      // 배틀 중 뒤로가기 방지 (중간에 나가면 재확인)
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('모험 중단'),
            content: const Text(
                '지금 나가면 보상을 받을 수 없습니다.\n다시 입장할 경우 신발코인이 소모됩니다.\n나가시겠습니까?'),
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
                    // 플레이어 HP
                    Expanded(
                      child: _HpBar(
                        name: '나',
                        currentHp: _playerHp,
                        maxHp: battle.playerMaxHp,
                        atk: battle.playerAtk,
                        def: battle.playerDef,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // VS
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
                      AnimatedBuilder(
                        animation: _shakeAnim,
                        builder: (_, child) => Transform.translate(
                          offset: Offset(_isDamageToPlayer ? 0 : _shakeAnim.value, 0),
                          child: child,
                        ),
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.green.withOpacity(0.3), width: 2),
                          ),
                          child: const Icon(Icons.pest_control,
                              size: 100, color: Colors.green),
                        ),
                      ),

                      // 데미지 텍스트
                      if (_lastDamage != null)
                        Positioned(
                          top: 20,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 400),
                            builder: (_, v, child) => Opacity(
                              opacity: (1 - v * 0.5),
                              child: Transform.translate(
                                  offset: Offset(0, -30 * v), child: child),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _isDamageToPlayer
                                    ? Colors.red
                                    : Colors.orange,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _isDoubleAttack
                                    ? '💥 $_lastDamage!'
                                    : '-$_lastDamage',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22),
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
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Text(
                  _battleMessage(currentLog, battle.monsterName),
                  style: const TextStyle(color: Colors.white, fontSize: 15),
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
                          backgroundColor:
                              battle.result == 'WIN' ? Colors.amber : Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isConfirming
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
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

  String _battleMessage(TurnLog? log, String monsterName) {
    if (log == null) return '어떻게 하시겠습니까?\n몬스터의 능력치를 잘 보고 결정하세요.';
    if (_isFinished) {
      return widget.battleResult.result == 'WIN'
          ? '$monsterName을 처치했습니다!\n보상을 받으세요.'
          : '패배했습니다...\n다음엔 더 강해져서 도전하세요!';
    }
    if (log.isPlayer) {
      return log.isDoubleAttack
          ? '💥 더블어택! $monsterName에게 ${log.damage} 데미지!'
          : '$monsterName에게 ${log.damage} 데미지를 입혔습니다.';
    } else {
      return log.isDoubleAttack
          ? '💥 $monsterName의 더블어택! ${log.damage} 데미지를 받았습니다!'
          : '$monsterName이 ${log.damage} 데미지로 공격했습니다.';
    }
  }
}

class _HpBar extends StatelessWidget {
  final String name;
  final int currentHp;
  final int maxHp;
  final int atk;
  final int def;
  final Color color;
  final bool isMonster;

  const _HpBar({
    required this.name,
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
          Text(name,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text('$currentHp / $maxHp',
              style: TextStyle(color: color, fontSize: 12)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: Colors.grey.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation(
                  ratio > 0.5 ? color : Colors.orange),
            ),
          ),
          const SizedBox(height: 6),
          Row(children: [
            Text('⚔️$atk  🛡️$def',
                style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ]),
        ],
      ),
    );
  }
}
