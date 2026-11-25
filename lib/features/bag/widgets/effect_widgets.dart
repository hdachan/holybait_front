import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../data/models/item_model.dart';
import '../../adventure/battle_anim/battle_anim_config.dart';
import '../../adventure/battle_anim/battle_anim_player.dart';

// 가방·상점이 같이 쓰는 이펙트 카드와 상세(미리보기) 창

const effectCardColor = Color(0xFF1C0E04);
const effectAccent = Color(0xFFEF7910);
const _stageBg = Color(0xFF1A2A1A);

String itemPriceText(ItemModel item) {
  final p = item.priceKrw;
  if (p == null) return '판매 안 함';
  final s = p.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  return '$s원';
}

/// 미리보기 재료 (연출 설정 + 상대 몬스터 그림). 화면을 열 때 한 번 읽음
class EffectPreviewData {
  final BattleAnimConfig config;
  final List<ui.Image> monsterFrames;

  const EffectPreviewData(this.config, this.monsterFrames);

  /// 실패하면 null (미리보기만 안 나오고 나머지는 그대로)
  static Future<EffectPreviewData?> load() async {
    try {
      final c = await BattleAnimConfig.load();
      final mon = c.monsters.isEmpty ? null : c.monsters.first; // 상대는 첫 번째 몬스터
      final frames = mon == null
          ? <ui.Image>[]
          : await BattleAnimImages.loadAll(BattleAnimAsset.monsterPaths(mon.key, frames: mon.frames));
      return EffectPreviewData(c, frames);
    } catch (_) {
      return null;
    }
  }
}

/// 이펙트 카드 (그림 + 이름 + 아래 한 줄)
class EffectCard extends StatelessWidget {
  final ItemModel item;
  final BattleAnimConfig? config;
  final String subtitle;
  final bool highlighted;
  final bool locked;
  final VoidCallback onTap;

  const EffectCard({
    super.key,
    required this.item,
    required this.config,
    required this.subtitle,
    required this.onTap,
    this.highlighted = false,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final effect = config?.slashEffect(item.itemKey);
    final thumb = effect == null
        ? null
        : BattleAnimAsset.effectPaths(effect.key, effect.frames)[effect.frames ~/ 2];
    const fallback = Center(child: Icon(Icons.auto_awesome, color: effectAccent, size: 28));
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: effectCardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: highlighted ? effectAccent : Colors.white12,
            width: highlighted ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: thumb == null
                        ? fallback
                        : Image.asset(thumb, fit: BoxFit.contain, errorBuilder: (_, __, ___) => fallback),
                  ),
                ),
                Text(item.name,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(color: highlighted ? effectAccent : Colors.white54, fontSize: 11)),
                const SizedBox(height: 8),
              ],
            ),
            if (locked)
              const Positioned(top: 6, right: 6, child: Icon(Icons.lock, color: Colors.white54, size: 14)),
            if (highlighted)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: effectAccent, borderRadius: BorderRadius.circular(6)),
                  child: const Text('E',
                      style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w800)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 상세 창 띄우기. 버튼: label + onPressed(성공하면 true → 창 닫힘). onPressed가 null이면 버튼 비활성
Future<void> showEffectDetailSheet(
  BuildContext context, {
  required ItemModel item,
  required EffectPreviewData? preview,
  required String buttonLabel,
  Future<bool> Function()? onPressed,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: effectCardColor,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _EffectDetailSheet(
      item: item,
      preview: preview,
      buttonLabel: buttonLabel,
      onPressed: onPressed,
    ),
  );
}

class _EffectDetailSheet extends StatefulWidget {
  final ItemModel item;
  final EffectPreviewData? preview;
  final String buttonLabel;
  final Future<bool> Function()? onPressed;

  const _EffectDetailSheet({
    required this.item,
    required this.preview,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  State<_EffectDetailSheet> createState() => _EffectDetailSheetState();
}

class _EffectDetailSheetState extends State<_EffectDetailSheet> {
  List<ui.Image>? _slash;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadSlash();
  }

  Future<void> _loadSlash() async {
    final e = widget.preview?.config.slashEffect(widget.item.itemKey);
    if (e == null) return;
    final frames = await BattleAnimImages.loadAll(BattleAnimAsset.effectPaths(e.key, e.frames));
    if (mounted) setState(() => _slash = frames);
  }

  Future<void> _press() async {
    final action = widget.onPressed;
    if (action == null) return;
    setState(() => _busy = true);
    final ok = await action();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final p = widget.preview;
    final view = p?.config.views['player'];
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 14),
            // 미리보기 (몬스터에게 쓰는 장면 반복)
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.42,
              child: AspectRatio(
                aspectRatio: p == null ? 9 / 16 : p.config.stageWidth / p.config.stageHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: (p == null || view == null || _slash == null)
                      ? Container(
                          color: _stageBg,
                          child: p == null
                              ? const Center(
                                  child: Text('미리보기를 불러오지 못했어요', style: TextStyle(color: Colors.white54)))
                              : const Center(child: CircularProgressIndicator(color: effectAccent)),
                        )
                      : BattleAnimStage(
                          config: p.config,
                          view: view,
                          frames: {'monster': p.monsterFrames, 'slash': _slash!, 'claw': const []},
                          background: _stageBg,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(item.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            if (item.description != null && item.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(item.description!, style: const TextStyle(color: Colors.white60, fontSize: 13)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (widget.onPressed == null || _busy) ? null : _press,
                style: ElevatedButton.styleFrom(
                  backgroundColor: effectAccent,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.white12,
                  disabledForegroundColor: Colors.white54,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(_busy ? '처리 중…' : widget.buttonLabel,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
