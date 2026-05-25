import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../currency/provider/currency_provider.dart';

class CharacterScreen extends StatefulWidget {
  const CharacterScreen({super.key});

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CurrencyProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('캐릭터'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 재화 표시 바
          _CurrencyBar(currency: currency),
          // 나머지 캐릭터 화면 (추후 구현)
          const Expanded(
            child: Center(
              child: Text('캐릭터 화면 - 추후 구현',
                  style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyBar extends StatelessWidget {
  final CurrencyProvider currency;
  const _CurrencyBar({required this.currency});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.15)),
        ),
      ),
      child: Row(
        children: [
          // 골드
          _CurrencyChip(
            icon: '🪙',
            value: currency.gold,
            color: const Color(0xFFFFB300),
          ),
          const SizedBox(width: 16),
          // 신발 코인
          _CurrencyChip(
            icon: '👟',
            value: currency.shoeCoin,
            color: const Color(0xFF42A5F5),
          ),
          const Spacer(),
          // 로딩 중이면 스피너
          if (currency.isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}

class _CurrencyChip extends StatelessWidget {
  final String icon;
  final int value;
  final Color color;

  const _CurrencyChip({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 6),
        Text(
          _formatNumber(value),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}
