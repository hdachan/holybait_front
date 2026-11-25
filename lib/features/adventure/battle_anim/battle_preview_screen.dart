import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../data/models/adventure_model.dart';
import '../screens/battle_screen.dart';
import 'battle_anim_config.dart';
import 'battle_anim_player.dart';

/// 개발용: 로그인 없이 배틀 연출(몬스터 + 이펙트)을 재생해 보는 화면.
/// 로그인 화면의 "연출 미리보기" 버튼으로 들어옴 (출시 빌드에는 버튼이 안 보임).
class BattlePreviewScreen extends StatefulWidget {
  const BattlePreviewScreen({super.key});

  @override
  State<BattlePreviewScreen> createState() => _BattlePreviewScreenState();
}

class _BattlePreviewScreenState extends State<BattlePreviewScreen> {
  static const _views = [('idle', '대기'), ('player', '내 공격'), ('monster', '몬스터 공격')];
  static const _speeds = [1.0, 0.5, 0.25];

  BattleAnimConfig? _config;
  String? _error;
  String _view = 'idle';
  String? _monster, _slash, _claw;
  double _speed = 1;
  Map<String, List<ui.Image>> _frames = const {};
  int _loadId = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final c = await BattleAnimConfig.load();
      if (!mounted) return;
      setState(() {
        _config = c;
        _monster = c.monsters.isNotEmpty ? c.monsters.first.key : null;
        _slash = c.defaultSlash;
        _claw = c.defaultClaw;
      });
      await _loadFrames();
    } catch (e) {
      if (mounted) setState(() => _error = '설정 파일을 읽지 못했어요: $e');
    }
  }

  BattleAnimAsset? _find(List<BattleAnimAsset> list, String? key) {
    for (final a in list) {
      if (a.key == key) return a;
    }
    return null;
  }

  Future<void> _loadFrames() async {
    final c = _config;
    if (c == null) return;
    final id = ++_loadId;
    final mon = _find(c.monsters, _monster);
    final sl = _find(c.slashEffects, _slash);
    final cl = _find(c.clawEffects, _claw);
    final results = await Future.wait([
      mon == null ? Future.value(<ui.Image>[]) : BattleAnimImages.loadAll(BattleAnimAsset.monsterPaths(mon.key, frames: mon.frames)),
      sl == null ? Future.value(<ui.Image>[]) : BattleAnimImages.loadAll(BattleAnimAsset.effectPaths(sl.key, sl.frames)),
      cl == null ? Future.value(<ui.Image>[]) : BattleAnimImages.loadAll(BattleAnimAsset.effectPaths(cl.key, cl.frames)),
    ]);
    if (!mounted || id != _loadId) return; // 그 사이 다른 걸 골랐으면 버림
    setState(() => _frames = {'monster': results[0], 'slash': results[1], 'claw': results[2]});
  }

  /// 실제 배틀 화면을 가짜 기록으로 열기 (서버 요청 없음). 내 공격·몬스터 공격 모두 고른 이펙트
  void _openMockBattle() {
    final name = _find(_config!.monsters, _monster)?.name ?? '몬스터';
    TurnLog log(int turn, bool player, int dmg, int php, int mhp, {bool x2 = false}) => TurnLog(
        turn: turn,
        actor: player ? 'PLAYER' : 'MONSTER',
        damage: dmg,
        isDoubleAttack: x2,
        playerHpAfter: php,
        monsterHpAfter: mhp);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BattleScreen(
        isPreview: true,
        battleResult: BattleStartResult(
          battleId: -1,
          result: 'WIN',
          monsterName: name,
          monsterLevel: 1,
          monsterHp: 100,
          monsterAtk: 12,
          monsterDef: 3,
          monsterImageKey: _monster,
          monsterAttackEffect: _claw, // 고른 몬스터 공격 이펙트로
          playerAttackEffect: _slash, // 고른 내 공격 이펙트로
          playerMaxHp: 80,
          playerAtk: 32,
          playerDef: 5,
          logs: [
            log(1, true, 32, 80, 68),
            log(1, false, 12, 68, 68),
            log(2, true, 32, 68, 36, x2: true),
            log(2, false, 12, 56, 36),
            log(3, true, 36, 56, 0),
          ],
        ),
      ),
    ));
  }

  void _pick(void Function() change) {
    setState(change);
    _loadFrames();
  }

  @override
  Widget build(BuildContext context) {
    final c = _config;
    return Scaffold(
      backgroundColor: const Color(0xFF101410),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101410),
        foregroundColor: Colors.white,
        title: const Text('배틀 연출 미리보기 (개발용)', style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: _monster == null ? null : _openMockBattle,
            child: const Text('모의 배틀 ▶', style: TextStyle(color: Color(0xFFF4A259))),
          ),
        ],
      ),
      body: _error != null
          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.white70)))
          : c == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: c.stageWidth / c.stageHeight,
                          child: _frames.isEmpty
                              ? const Center(child: CircularProgressIndicator())
                              : BattleAnimStage(
                                  // 장면이나 그림이 바뀌면 처음부터 재생
                                  key: ValueKey('$_view|$_monster|$_slash|$_claw'),
                                  config: c,
                                  view: c.views[_view]!,
                                  frames: _frames,
                                  speed: _speed,
                                ),
                        ),
                      ),
                    ),
                    _controls(c),
                  ],
                ),
    );
  }

  Widget _controls(BattleAnimConfig c) {
    return Container(
      color: const Color(0xFF1A1F1A),
      padding: EdgeInsets.fromLTRB(12, 10, 12, MediaQuery.of(context).padding.bottom + 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              for (final (key, label) in _views) ...[
                Expanded(child: _segment(label, _view == key, () => setState(() => _view = key))),
                const SizedBox(width: 6),
              ],
              _segment(_speed == 1 ? '1배' : '$_speed배', false, () {
                setState(() => _speed = _speeds[(_speeds.indexOf(_speed) + 1) % _speeds.length]);
              }),
            ],
          ),
          const SizedBox(height: 10),
          _chipRow('몬스터', c.monsters, _monster, (k) => _pick(() => _monster = k)),
          _chipRow('내 공격 이펙트', c.slashEffects, _slash, (k) => _pick(() {
                _slash = k;
                _view = 'player';
              })),
          _chipRow('몬스터 공격 이펙트', c.clawEffects, _claw, (k) => _pick(() {
                _claw = k;
                _view = 'monster';
              })),
        ],
      ),
    );
  }

  Widget _segment(String label, bool on, VoidCallback onTap) {
    return Material(
      color: on ? const Color(0xFFF4A259) : const Color(0xFF2A322A),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: on ? Colors.black : Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ),
    );
  }

  Widget _chipRow(String title, List<BattleAnimAsset> items, String? selected, ValueChanged<String> onPick) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 4),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final a = items[i];
                final on = a.key == selected;
                return ChoiceChip(
                  label: Text(a.name),
                  selected: on,
                  showCheckmark: false,
                  onSelected: (_) => onPick(a.key),
                  backgroundColor: const Color(0xFF2A322A),
                  selectedColor: const Color(0xFFF4A259),
                  labelStyle: TextStyle(color: on ? Colors.black : Colors.white, fontSize: 12),
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
