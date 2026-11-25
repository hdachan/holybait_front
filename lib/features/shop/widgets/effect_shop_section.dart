import 'package:flutter/material.dart';

import '../../../data/datasources/item_remote_ds.dart';
import '../../../data/models/item_model.dart';
import '../../bag/widgets/effect_widgets.dart';

/// 상점의 공격 이펙트 판매 칸: 아직 없는 이펙트만. 누르면 미리보기 + 구매 버튼
/// 구매(인앱결제)는 다음 단계 — 지금은 "구매 준비 중"
class EffectShopSection extends StatefulWidget {
  const EffectShopSection({super.key});

  @override
  State<EffectShopSection> createState() => _EffectShopSectionState();
}

class _EffectShopSectionState extends State<EffectShopSection> {
  final _ds = ItemRemoteDataSource();

  List<ItemModel>? _forSale; // null = 불러오는 중
  bool _failed = false;
  EffectPreviewData? _preview;

  @override
  void initState() {
    super.initState();
    _load();
    EffectPreviewData.load().then((p) {
      if (mounted) setState(() => _preview = p);
    });
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final items = await _ds.getMyItems(type: 'EFFECT');
      if (!mounted) return;
      setState(() => _forSale = items.where((i) => !i.owned && i.priceKrw != null).toList());
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _openDetail(ItemModel item) {
    showEffectDetailSheet(
      context,
      item: item,
      preview: _preview,
      buttonLabel: '${itemPriceText(item)} 구매',
      onPressed: () async {
        // TODO 인앱결제 연결 (Play Console 등록 후)
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('구매는 곧 열릴 예정이에요!'), duration: Duration(seconds: 2)));
        return false;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0A1A).withOpacity(0.70),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B5E3C).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: effectAccent, size: 18),
              SizedBox(width: 6),
              Text('공격 이펙트',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('눌러서 미리 볼 수 있어요. 모습만 바뀌고 능력치는 그대로예요.',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 12),
          _body(),
        ],
      ),
    );
  }

  Widget _body() {
    if (_failed) {
      return Center(
        child: TextButton(
          onPressed: _load,
          child: const Text('불러오지 못했어요 · 다시 시도', style: TextStyle(color: effectAccent)),
        ),
      );
    }
    final list = _forSale;
    if (list == null) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator(color: effectAccent)),
      );
    }
    if (list.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: Text('모든 이펙트를 가지고 있어요!', style: TextStyle(color: Colors.white60))),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final item = list[i];
        return EffectCard(
          item: item,
          config: _preview?.config,
          subtitle: itemPriceText(item),
          onTap: () => _openDetail(item),
        );
      },
    );
  }
}
