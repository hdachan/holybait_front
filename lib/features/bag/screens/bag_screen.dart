import 'package:flutter/material.dart';

import '../../../core/error/server_error.dart';
import '../../../data/datasources/item_remote_ds.dart';
import '../../../data/models/item_model.dart';
import '../../shop/screens/shop_screen.dart';
import '../widgets/effect_widgets.dart';

const _bg = Color(0xFF140A03);

/// 가방: 내가 가진 아이템만. 카드를 누르면 상세(미리보기·착용) 창
/// 없는 이펙트는 상점에서 봄 (아래 "상점에서 더 보기")
/// (나중에 재료를 넣을 때는 type 'MATERIAL' 목록을 같은 방식으로 추가)
class BagScreen extends StatefulWidget {
  const BagScreen({super.key});

  @override
  State<BagScreen> createState() => _BagScreenState();
}

class _BagScreenState extends State<BagScreen> {
  final _ds = ItemRemoteDataSource();

  List<ItemModel> _items = const [];
  bool _loading = true;
  String? _error;
  EffectPreviewData? _preview;

  List<ItemModel> get _owned => _items.where((i) => i.owned).toList();

  @override
  void initState() {
    super.initState();
    _loadItems();
    EffectPreviewData.load().then((p) {
      if (mounted) setState(() => _preview = p);
    });
  }

  Future<void> _loadItems() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _ds.getMyItems(type: 'EFFECT');
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = serverErrorMessage(e) ?? '가방을 불러오지 못했어요.';
      });
    }
  }

  Future<bool> _equip(ItemModel item) async {
    try {
      final items = await _ds.equip(item.id);
      if (!mounted) return false;
      setState(() => _items = items);
      _snack('${item.name} 착용!');
      return true;
    } catch (e) {
      if (mounted) _snack(serverErrorMessage(e) ?? '착용에 실패했어요. 잠시 후 다시 시도해 주세요.', error: true);
      return false;
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: error ? const Color(0xFFC62828) : null,
        duration: const Duration(seconds: 2),
      ));
  }

  void _openDetail(ItemModel item) {
    showEffectDetailSheet(
      context,
      item: item,
      preview: _preview,
      buttonLabel: item.equipped ? '착용 중' : '착용하기',
      onPressed: item.equipped ? null : () => _equip(item),
    );
  }

  Future<void> _goShop() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShopScreen()));
    if (mounted) _loadItems(); // 상점에서 산 게 있으면 반영
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        title: const Text('가방', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: effectAccent))
          : _error != null
              ? _errorView()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text('공격 이펙트',
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                    Expanded(child: _grid()),
                    _shopButton(),
                  ],
                ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error!, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          TextButton(onPressed: _loadItems, child: const Text('다시 시도', style: TextStyle(color: effectAccent))),
        ],
      ),
    );
  }

  Widget _grid() {
    final owned = _owned;
    if (owned.isEmpty) {
      return const Center(child: Text('아직 가방이 비어 있어요.', style: TextStyle(color: Colors.white54)));
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemCount: owned.length,
      itemBuilder: (_, i) {
        final item = owned[i];
        return EffectCard(
          item: item,
          config: _preview?.config,
          subtitle: item.equipped ? '착용 중' : '보유',
          highlighted: item.equipped,
          onTap: () => _openDetail(item),
        );
      },
    );
  }

  Widget _shopButton() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _goShop,
            icon: const Icon(Icons.storefront, size: 20),
            label: const Text('상점에서 더 보기', style: TextStyle(fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: effectAccent,
              side: const BorderSide(color: effectAccent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ),
    );
  }
}
