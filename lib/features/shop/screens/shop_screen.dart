import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../currency/provider/currency_provider.dart';
import '../../adventure/provider/adventure_provider.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  static const int gachaCost = 1400;

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('상점',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white)),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/shop/shop_bg.png',
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withOpacity(0.35)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                children: [
                  // 보유 골드
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D0A1A).withOpacity(0.70),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF8B5E3C).withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF4A259).withOpacity(0.08),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text('보유 골드',
                            style: TextStyle(
                                fontSize: 14, color: Colors.white.withOpacity(0.6))),
                        const SizedBox(width: 8),
                        Text('${currency.gold}',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFB300))),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 캐릭터 뽑기 카드 (이미지 + 버튼 겹침)
                  AspectRatio(
                    aspectRatio: 608 / 553,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            'assets/images/shop/shop_popup.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        Positioned(
                          left: 24,
                          right: 24,
                          bottom: 24,
                          child: ElevatedButton(
                            onPressed: () => _onGacha(context, currency),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF7910),
                              foregroundColor: Colors.black,
                              minimumSize: const Size(double.infinity, 52),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('🪙 ', style: TextStyle(fontSize: 16)),
                                Text('$gachaCost 골드로 뽑기',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onGacha(
      BuildContext context, CurrencyProvider currency) async {
    final adventure = context.read<AdventureProvider>();

    // 골드 부족 체크
    if (currency.gold < gachaCost) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1C0E04),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('골드 부족', style: TextStyle(color: Colors.white)),
          content: const Text('골드가 부족합니다.\n모험을 통해 골드를 모아보세요!',
              style: TextStyle(color: Colors.white70)),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFEF7910),
                  foregroundColor: Colors.black),
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      return;
    }

    // 슬롯 꽉 찬 경우 체크
    if (adventure.myCharacters.length >= adventure.slotCount) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1C0E04),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('슬롯 부족', style: TextStyle(color: Colors.white)),
          content: const Text('슬롯이 꽉 찼습니다.\n캐릭터 화면에서 슬롯을 확장해주세요!',
              style: TextStyle(color: Colors.white70)),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFEF7910),
                  foregroundColor: Colors.black),
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      return;
    }

    try {
      final dio = ApiClient.dio;
      final res = await dio.post('/shop/gacha');
      final data = res.data as Map<String, dynamic>;

      if (!context.mounted) return;

      // 골드 즉시 갱신
      currency.load();
      // 캐릭터 목록 갱신
      await adventure.loadStages();

      // 결과 팝업
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF1C0E04),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: const Color(0xFFEF7910).withOpacity(0.5), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 52)),
                const SizedBox(height: 12),
                const Text('캐릭터 획득!',
                    style: TextStyle(
                        color: Color(0xFFEF7910),
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    data['characterName'] ?? '',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '남은 골드: ${data['remainingGold']}',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF7910),
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
    } on DioException catch (e) {
      if (!context.mounted) return;
      final msg = e.response?.data is Map
          ? e.response?.data['message'] ?? '뽑기에 실패했습니다.'
          : '뽑기에 실패했습니다.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ));
    }
  }
}