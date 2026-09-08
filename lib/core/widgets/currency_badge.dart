import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/currency/provider/currency_provider.dart';

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
          Image.asset('assets/images/ui/main_coin.png', width: 18, height: 18),
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
          Image.asset('assets/images/ui/blue_coin.png', width: 18, height: 18),
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