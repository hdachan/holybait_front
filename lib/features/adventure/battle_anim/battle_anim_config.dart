import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';

/// frame-lab에서 내보낸 `assets/battle/battle_anim.json`을 읽는 모델.
/// 무대는 360×640, 가운데가 (0, 0).
class BattleAnimConfig {
  final double stageWidth;
  final double stageHeight;
  final Map<String, BattleAnimView> views; // idle / player / monster
  final List<BattleAnimAsset> monsters;
  final List<BattleAnimAsset> slashEffects; // 내 공격 (몬스터 위)
  final List<BattleAnimAsset> clawEffects; // 몬스터 공격 (화면 가운데)
  final String defaultSlash;
  final String defaultClaw;

  const BattleAnimConfig({
    required this.stageWidth,
    required this.stageHeight,
    required this.views,
    required this.monsters,
    required this.slashEffects,
    required this.clawEffects,
    required this.defaultSlash,
    required this.defaultClaw,
  });

  static const assetPath = 'assets/battle/battle_anim.json';

  /// 예전 몬스터 그림 이름 → 새 몬스터 (예전 그림 폴더는 뺌).
  /// 운영 DB의 image_key를 바꾸기 전(2단계)에도 새 몬스터가 나오게 하려는 것
  static const legacyMonsterKeys = {
    'monster_gorilla': 'monster_leaf', // 1 숲 고릴라 → 나뭇잎 몬스터
    'monster_Shadow_black': 'monster_black_blob', // 2 흑화 검정이 → 검은 몬스터
    'monster_black': 'monster_pink_snake', // 3 나무 정령 → 분홍 뱀
    'monster_werewolf': 'monster_fire_blob', // 4 늑대인간 → 불덩이 몬스터
    'monster_dragon': 'monster_flame_black', // 5 용암 드래곤 → 불꽃 검은 몬스터
    'monster_giant': 'monster_flame_ghost', // 6 어둠의 거인 → 불꽃 유령
  };

  /// 서버가 준 image_key → 앱에 있는 몬스터. 모르는 이름이면 첫 번째 몬스터
  BattleAnimAsset? resolveMonster(String? imageKey) {
    final key = legacyMonsterKeys[imageKey] ?? imageKey;
    for (final m in monsters) {
      if (m.key == key) return m;
    }
    return monsters.isEmpty ? null : monsters.first;
  }

  /// 내 공격 이펙트 목록에 있는 이름일 때만 (없으면 null)
  BattleAnimAsset? slashEffect(String? key) {
    for (final e in slashEffects) {
      if (e.key == key) return e;
    }
    return null;
  }

  /// 몬스터 공격 이펙트 목록에 있는 이름일 때만 (없으면 null)
  BattleAnimAsset? clawEffect(String? key) {
    for (final e in clawEffects) {
      if (e.key == key) return e;
    }
    return null;
  }

  BattleAnimAsset? effect(String key) {
    for (final e in [...slashEffects, ...clawEffects]) {
      if (e.key == key) return e;
    }
    return null;
  }

  static Future<BattleAnimConfig> load() async {
    final raw = await rootBundle.loadString(assetPath);
    return BattleAnimConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  factory BattleAnimConfig.fromJson(Map<String, dynamic> j) {
    final stage = (j['stage'] as Map<String, dynamic>?) ?? const {};
    final views = <String, BattleAnimView>{};
    ((j['views'] as Map<String, dynamic>?) ?? const {}).forEach((k, v) {
      views[k] = BattleAnimView.fromJson(v as Map<String, dynamic>);
    });
    List<BattleAnimAsset> list(String key) => ((j[key] as List?) ?? const [])
        .map((e) => BattleAnimAsset.fromJson(e as Map<String, dynamic>))
        .toList();
    final defaults = (j['defaults'] as Map<String, dynamic>?) ?? const {};
    return BattleAnimConfig(
      stageWidth: _d(stage['width'], 360),
      stageHeight: _d(stage['height'], 640),
      views: views,
      monsters: list('monsters'),
      slashEffects: list('slashEffects'),
      clawEffects: list('clawEffects'),
      defaultSlash: (defaults['slash'] as String?) ?? 'fire_slash',
      defaultClaw: (defaults['claw'] as String?) ?? 'claw',
    );
  }
}

/// 그림 묶음 하나 (몬스터 1종 또는 이펙트 1종)
class BattleAnimAsset {
  final String key;
  final String name;
  final int frames;

  const BattleAnimAsset({required this.key, required this.name, required this.frames});

  factory BattleAnimAsset.fromJson(Map<String, dynamic> j) => BattleAnimAsset(
        key: j['key'] as String,
        name: (j['name'] as String?) ?? j['key'] as String,
        frames: (j['frames'] as num?)?.toInt() ?? 12,
      );

  /// 몬스터 그림 경로 (기존 파일 이름 규칙 유지)
  static List<String> monsterPaths(String key, {int frames = 12}) => List.generate(
      frames,
      (i) => 'assets/images/monsters/$key/frame_${_two(i + 1)}-removebg-preview.png');

  /// 이펙트 그림 경로
  static List<String> effectPaths(String key, int frames) =>
      List.generate(frames, (i) => 'assets/images/effects/$key/${key}_${_two(i + 1)}.png');
}

/// 장면 하나 (대기 / 내 공격 / 몬스터 공격)
class BattleAnimView {
  final Map<String, BattleAnimLayer> layers; // monster, slash, claw
  final BattleAnimDamage? damage;
  final BattleAnimTimed? shake; // value = 세기 px
  final BattleAnimTimed? lunge; // value = 최대 크기 배수
  final BattleAnimEdgeFlash? edgeFlash;

  const BattleAnimView({
    required this.layers,
    this.damage,
    this.shake,
    this.lunge,
    this.edgeFlash,
  });

  factory BattleAnimView.fromJson(Map<String, dynamic> j) {
    final layers = <String, BattleAnimLayer>{};
    ((j['layers'] as Map<String, dynamic>?) ?? const {}).forEach((k, v) {
      layers[k] = BattleAnimLayer.fromJson(v as Map<String, dynamic>);
    });
    final sh = j['shake'] as Map<String, dynamic>?;
    final lu = j['monsterLunge'] as Map<String, dynamic>?;
    final dm = j['damage'] as Map<String, dynamic>?;
    final ef = j['edgeFlash'] as Map<String, dynamic>?;
    return BattleAnimView(
      layers: layers,
      damage: dm == null ? null : BattleAnimDamage.fromJson(dm),
      shake: sh == null
          ? null
          : BattleAnimTimed(_d(sh['startMs'], 0), _d(sh['durationMs'], 200), _d(sh['power'], 6)),
      lunge: lu == null
          ? null
          : BattleAnimTimed(_d(lu['startMs'], 0), _d(lu['durationMs'], 300), _d(lu['maxScale'], 1.3)),
      edgeFlash: ef == null ? null : BattleAnimEdgeFlash.fromJson(ef),
    );
  }

  /// 장면 전체 길이(ms). frameCounts = 레이어별 그림 장 수
  double totalMs(Map<String, int> frameCounts) {
    double m = 300;
    layers.forEach((role, l) {
      m = math.max(m, l.delayMs + l.durationMs(frameCounts[role] ?? 0));
    });
    for (final t in [damage?.timed, shake, lunge, edgeFlash?.timed]) {
      if (t != null) m = math.max(m, t.startMs + t.durationMs);
    }
    return (m / 10).ceilToDouble() * 10;
  }
}

class BattleAnimTimed {
  final double startMs;
  final double durationMs;
  final double value;
  const BattleAnimTimed(this.startMs, this.durationMs, this.value);

  /// 0~1 진행도, 범위 밖이면 null
  double? progress(double t) {
    final p = (t - startMs) / durationMs;
    return (p < 0 || p > 1) ? null : p;
  }
}

class BattleAnimLayer {
  final double x, y, size, rotation, opacity, frameMs, delayMs;
  final String afterEnd; // hold / hide / loop
  final String blend;
  final bool flipX;
  final List<SeqStep>? sequence;

  const BattleAnimLayer({
    required this.x,
    required this.y,
    required this.size,
    required this.rotation,
    required this.opacity,
    required this.frameMs,
    required this.delayMs,
    required this.afterEnd,
    required this.blend,
    required this.flipX,
    required this.sequence,
  });

  factory BattleAnimLayer.fromJson(Map<String, dynamic> j) {
    final frameMs = _d(j['frameMs'], 80);
    return BattleAnimLayer(
      x: _d(j['x'], 0),
      y: _d(j['y'], 0),
      size: _d(j['size'], 240),
      rotation: _d(j['rotation'], 0),
      opacity: _d(j['opacity'], 1),
      frameMs: frameMs,
      delayMs: _d(j['delayMs'], 0),
      afterEnd: (j['afterEnd'] as String?) ?? 'hold',
      blend: (j['blend'] as String?) ?? 'source-over',
      flipX: (j['flipX'] as bool?) ?? false,
      sequence: _parseSeq(j['sequence'] as String?, frameMs),
    );
  }

  /// "04:80 05:120" → [(3, 80), (4, 120)]. 비어 있으면 null (1번부터 끝까지 frameMs 간격)
  static List<SeqStep>? _parseSeq(String? s, double frameMs) {
    if (s == null || s.trim().isEmpty) return null;
    final out = <SeqStep>[];
    for (final tok in s.trim().split(RegExp(r'[\s,]+'))) {
      final m = RegExp(r'^(\d+)(?::(\d+))?$').firstMatch(tok);
      if (m == null) continue;
      final i = int.parse(m.group(1)!) - 1;
      if (i < 0) continue;
      final ms = m.group(2) == null ? frameMs : math.max(10, int.parse(m.group(2)!)).toDouble();
      out.add(SeqStep(i, ms));
    }
    return out.isEmpty ? null : out;
  }

  List<SeqStep>? _seqFor(int n) => sequence?.where((e) => e.index < n).toList();

  double durationMs(int n) {
    final s = _seqFor(n);
    if (s != null && s.isNotEmpty) return s.fold(0.0, (a, e) => a + e.ms);
    return n * frameMs;
  }

  /// t(ms)에 보여줄 그림 번호 (0부터). 안 보이면 -1
  int frameAt(int n, double t) {
    if (n == 0) return -1;
    var local = t - delayMs;
    if (local < 0) return -1;
    final s = _seqFor(n);
    final hasSeq = s != null && s.isNotEmpty;
    final dur = durationMs(n);
    if (local >= dur) {
      if (afterEnd == 'loop') {
        local %= dur;
      } else if (afterEnd == 'hide') {
        return -1;
      } else {
        return hasSeq ? s.last.index : n - 1;
      }
    }
    if (!hasSeq) return math.min(n - 1, (local / frameMs).floor());
    double acc = 0;
    for (final e in s) {
      if (local < acc + e.ms) return e.index;
      acc += e.ms;
    }
    return s.last.index;
  }
}

class SeqStep {
  final int index;
  final double ms;
  const SeqStep(this.index, this.ms);
}

class BattleAnimDamage {
  final String text;
  final BattleAnimTimed timed;
  final double x, y, fontSize, rise, popScale;
  final Color color, strokeColor;

  const BattleAnimDamage({
    required this.text,
    required this.timed,
    required this.x,
    required this.y,
    required this.fontSize,
    required this.rise,
    required this.popScale,
    required this.color,
    required this.strokeColor,
  });

  factory BattleAnimDamage.fromJson(Map<String, dynamic> j) => BattleAnimDamage(
        text: (j['text'] as String?) ?? '',
        timed: BattleAnimTimed(_d(j['startMs'], 0), _d(j['durationMs'], 700), 0),
        x: _d(j['x'], 0),
        y: _d(j['y'], 0),
        fontSize: _d(j['fontSize'], 64),
        rise: _d(j['rise'], 60),
        popScale: _d(j['popScale'], 1.5),
        color: parseHexColor(j['color'] as String?, const Color(0xFFFFB02E)),
        strokeColor: parseHexColor(j['strokeColor'] as String?, const Color(0xFF4A1C00)),
      );
}

class BattleAnimEdgeFlash {
  final BattleAnimTimed timed; // value = 진하기 0~1
  final Color color;
  const BattleAnimEdgeFlash(this.timed, this.color);

  factory BattleAnimEdgeFlash.fromJson(Map<String, dynamic> j) => BattleAnimEdgeFlash(
        BattleAnimTimed(_d(j['startMs'], 0), _d(j['durationMs'], 500), _d(j['strength'], 0.7)),
        parseHexColor(j['color'] as String?, const Color(0xFFFF1A2E)),
      );
}

Color parseHexColor(String? hex, Color fallback) {
  if (hex == null) return fallback;
  final h = hex.replaceFirst('#', '');
  final v = int.tryParse(h.length == 6 ? 'FF$h' : h, radix: 16);
  return v == null ? fallback : Color(v);
}

double _d(dynamic v, double fallback) => v is num ? v.toDouble() : fallback;
String _two(int n) => n.toString().padLeft(2, '0');
