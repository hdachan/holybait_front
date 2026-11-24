import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'battle_anim_config.dart';

/// 그림 파일 → ui.Image (한 번 읽은 건 다시 쓰기)
class BattleAnimImages {
  static final Map<String, Future<ui.Image?>> _cache = {};

  static Future<ui.Image?> load(String path) => _cache.putIfAbsent(path, () async {
        try {
          final data = await rootBundle.load(path);
          final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
          return (await codec.getNextFrame()).image;
        } catch (_) {
          return null; // 파일이 없으면 그 장은 건너뜀
        }
      });

  static Future<List<ui.Image>> loadAll(List<String> paths) async {
    final list = await Future.wait(paths.map(load));
    return list.whereType<ui.Image>().toList();
  }
}

/// 배틀 화면용 조종 장치: 평소엔 대기(idle) 반복, play()로 장면을 한 번 재생한 뒤 대기로 돌아감
class BattleAnimController {
  static const idleView = 'idle';
  static const deathMs = 900.0;

  String _view = idleView;
  String? _damageText;
  double _t = 0;
  double _deathT = -1; // -1 = 살아 있음
  Completer<void>? _done;

  String get view => _view;
  String? get damageText => _damageText;
  double get t => _t;

  /// 0(그대로) ~ 1(완전히 사라짐)
  double get death => _deathT < 0 ? 0 : (_deathT / deathMs).clamp(0.0, 1.0);

  /// 장면 재생. 끝나면 완료되는 Future
  Future<void> play(String view, {String? damageText}) {
    _finish();
    _view = view;
    _damageText = damageText;
    _t = 0;
    final c = Completer<void>();
    _done = c;
    return c.future;
  }

  /// 몬스터가 쓰러짐 (서서히 사라짐)
  void die() => _deathT = 0;

  void _finish() {
    final c = _done;
    _done = null;
    if (c != null && !c.isCompleted) c.complete();
  }

  void _advance(double dt, double totalMs) {
    _t += dt;
    if (_deathT >= 0) _deathT += dt;
    if (_view != idleView && _t >= totalMs) {
      _view = idleView;
      _damageText = null;
      _t = 0;
      _finish();
    }
  }

  void dispose() => _finish();
}

/// 장면 하나를 시간에 맞춰 재생하는 무대 (frame-lab과 같은 계산)
/// frames: 역할(monster / slash / claw)별 그림
class BattleAnimStage extends StatefulWidget {
  final BattleAnimConfig config;
  final BattleAnimView view;
  final Map<String, List<ui.Image>> frames;
  final double speed;
  final bool loop; // true면 끝나고 잠깐 쉬었다가 다시
  final String? damageText; // null이면 JSON 값
  final Color background;
  final VoidCallback? onFinished;

  /// 있으면 장면·데미지 글자는 controller가 정함 (view는 대기 장면 대신 쓰는 기본값)
  final BattleAnimController? controller;

  const BattleAnimStage({
    super.key,
    required this.config,
    required this.view,
    required this.frames,
    this.speed = 1,
    this.loop = true,
    this.damageText,
    this.background = const Color(0xFF1F2A1F),
    this.onFinished,
    this.controller,
  });

  @override
  State<BattleAnimStage> createState() => _BattleAnimStageState();
}

class _BattleAnimStageState extends State<BattleAnimStage> with SingleTickerProviderStateMixin {
  static const _pauseMs = 400.0; // 반복 사이 쉬는 시간
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  double _t = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  double _totalOf(BattleAnimView v) => v.totalMs(widget.frames.map((k, l) => MapEntry(k, l.length)));
  double get _total => _totalOf(widget.view);

  void _onTick(Duration now) {
    final dt = math.min(100.0, (now - _last).inMicroseconds / 1000.0);
    _last = now;
    final c = widget.controller;
    if (c != null) {
      final v = widget.config.views[c.view];
      c._advance(dt * widget.speed, v == null ? 0 : _totalOf(v));
      setState(() {});
      return;
    }
    if (_done) return;
    var t = _t + dt * widget.speed;
    if (widget.loop) {
      if (t > _total + _pauseMs) t = 0;
    } else if (t >= _total) {
      t = _total;
      _done = true;
      widget.onFinished?.call();
    }
    setState(() => _t = t);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return CustomPaint(
      painter: BattleAnimPainter(
        config: widget.config,
        view: c == null ? widget.view : (widget.config.views[c.view] ?? widget.view),
        frames: widget.frames,
        t: c?.t ?? _t,
        damageText: c == null ? widget.damageText : c.damageText,
        background: widget.background,
        monsterDeath: c?.death ?? 0,
      ),
      size: Size.infinite,
    );
  }
}

class BattleAnimPainter extends CustomPainter {
  static const _roleOrder = ['monster', 'slash', 'claw'];

  final BattleAnimConfig config;
  final BattleAnimView view;
  final Map<String, List<ui.Image>> frames;
  final double t;
  final String? damageText;
  final Color background;
  final double monsterDeath; // 0~1

  BattleAnimPainter({
    required this.config,
    required this.view,
    required this.frames,
    required this.t,
    required this.damageText,
    required this.background,
    this.monsterDeath = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final W = config.stageWidth, H = config.stageHeight;
    final k = math.min(size.width / W, size.height / H);
    // 배경·테두리 번쩍임은 무대 밖(위아래 남는 곳)까지 칠함
    final full = Offset.zero & size;
    canvas.save();
    canvas.clipRect(full);
    canvas.saveLayer(full, Paint());
    canvas.drawRect(full, Paint()..color = background);
    canvas.save();
    canvas.translate((size.width - W * k) / 2, (size.height - H * k) / 2);
    canvas.scale(k);

    // 흔들림
    double sx = 0, sy = 0;
    final shake = view.shake;
    final sp = shake?.progress(t);
    if (shake != null && sp != null) {
      final a = shake.value * (1 - sp);
      sx = math.sin(t * 0.9) * a;
      sy = math.cos(t * 1.3) * a * 0.6;
    }
    canvas.save();
    canvas.translate(W / 2 + sx, H / 2 + sy);

    for (final role in _roleOrder) {
      final layer = view.layers[role];
      final imgs = frames[role];
      if (layer == null || imgs == null || imgs.isEmpty) continue;
      final fi = layer.frameAt(imgs.length, t);
      if (fi < 0) continue;
      final im = imgs[fi];
      final w = layer.size, h = layer.size * im.height / im.width;
      canvas.save();
      canvas.translate(layer.x, layer.y);
      canvas.rotate(layer.rotation * math.pi / 180);
      if (layer.flipX) canvas.scale(-1, 1);
      double alpha = layer.opacity.clamp(0.0, 1.0);
      if (role == 'monster' && monsterDeath > 0) {
        // 쓰러짐: 아래로 내려가며 작아지고 사라짐
        final d = Curves.easeIn.transform(monsterDeath);
        canvas.translate(0, d * 30);
        canvas.scale(1 - d * 0.25);
        alpha *= 1 - d;
      }
      if (role == 'monster') {
        // 몬스터가 다가옴: 빠르게 커지고(35%) 천천히 돌아감(65%)
        final lu = view.lunge;
        final p = lu?.progress(t);
        if (lu != null && p != null) {
          final e = p < 0.35 ? 1 - math.pow(1 - p / 0.35, 3).toDouble() : 1 - _smooth((p - 0.35) / 0.65);
          final s = 1 + (lu.value - 1) * e;
          canvas.scale(s, s);
        }
      }
      canvas.drawImageRect(
        im,
        Rect.fromLTWH(0, 0, im.width.toDouble(), im.height.toDouble()),
        Rect.fromLTWH(-w / 2, -h / 2, w, h),
        Paint()
          ..filterQuality = FilterQuality.medium
          ..blendMode = _blend(layer.blend)
          ..color = Color.fromRGBO(255, 255, 255, alpha),
      );
      canvas.restore();
    }

    _paintDamage(canvas);
    canvas.restore(); // 흔들림
    canvas.restore(); // 무대 좌표
    _paintEdgeFlash(canvas, size.width, size.height);
    canvas.restore(); // saveLayer
    canvas.restore();
  }

  void _paintDamage(Canvas canvas) {
    final d = view.damage;
    final p = d?.timed.progress(t);
    if (d == null || p == null) return;
    final text = damageText ?? d.text;
    if (text.isEmpty) return;
    final pop = p < 0.12 ? d.popScale - (d.popScale - 1) * (p / 0.12) : 1.0;
    final ease = 1 - math.pow(1 - p, 3).toDouble();
    final alpha = p < 0.6 ? 1.0 : (1 - (p - 0.6) / 0.4).clamp(0.0, 1.0);
    final fs = d.fontSize;

    TextPainter tp(Paint fg) => TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(fontFamily: 'Paperlogy', fontWeight: FontWeight.w900, fontSize: fs, foreground: fg),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

    canvas.save();
    canvas.translate(d.x, d.y - d.rise * ease);
    canvas.scale(pop, pop);
    final stroke = tp(Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = fs * 0.22
      ..strokeJoin = StrokeJoin.round
      ..color = d.strokeColor.withValues(alpha: alpha));
    final off = Offset(-stroke.width / 2, -stroke.height / 2);
    stroke.paint(canvas, off);
    final fill = tp(Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, off.dy),
        Offset(0, off.dy + stroke.height),
        [
          const Color(0xFFFFF2D6).withValues(alpha: alpha),
          d.color.withValues(alpha: alpha),
          d.color.withValues(alpha: alpha),
        ],
        [0, 0.45, 1],
      ));
    fill.paint(canvas, off);
    canvas.restore();
  }

  void _paintEdgeFlash(Canvas canvas, double W, double H) {
    final f = view.edgeFlash;
    final p = f?.timed.progress(t);
    if (f == null || p == null) return;
    final a = f.timed.value * (p < 0.15 ? p / 0.15 : 1 - (p - 0.15) / 0.85);
    final outer = math.sqrt(W * W + H * H) / 2;
    final inner = math.min(W, H) * 0.25;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, W, H),
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(W / 2, H / 2),
          outer,
          [f.color.withValues(alpha: 0), f.color.withValues(alpha: a.clamp(0.0, 1.0))],
          [inner / outer, 1],
        ),
    );
  }

  static double _smooth(double q) => q * q * (3 - 2 * q);

  static BlendMode _blend(String b) {
    switch (b) {
      case 'screen':
        return BlendMode.screen;
      case 'lighter':
        return BlendMode.plus;
      case 'multiply':
        return BlendMode.multiply;
      case 'overlay':
        return BlendMode.overlay;
      default:
        return BlendMode.srcOver;
    }
  }

  @override
  bool shouldRepaint(covariant BattleAnimPainter oldDelegate) => true; // 매 프레임 시간이 바뀜
}
