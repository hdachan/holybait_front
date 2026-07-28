import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/currency/provider/currency_provider.dart';

/// 앱바 왼쪽 골드 + 신발코인 표시 위젯
/// 사용법:
/// AppBar(
///   leading: const CurrencyBadge(),
///   leadingWidth: 140,
/// )
class CurrencyBadge extends StatelessWidget {
  const CurrencyBadge({super.key});

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<CurrencyProvider>();

    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        children: [
          const Icon(Icons.monetization_on, size: 15, color: Color(0xFFFFB300)),
          const SizedBox(width: 3),
          Text(
            _fmt(currency.gold),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFB300),
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.directions_run, size: 15, color: Color(0xFF42A5F5)),
          const SizedBox(width: 3),
          Text(
            _fmt(currency.shoeCoin),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF42A5F5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}