import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../currency/provider/currency_provider.dart';
import '../provider/adventure_provider.dart';
import '../screens/battle_screen.dart';

// 끝까지 보지 않고 나간 배틀(보상 미수령)이 있으면 이어서 보기 / 포기 선택
// 앱을 켰을 때(MainScreen)와 행성에 들어갈 때(PlanetDetailScreen) 호출
Future<void> checkPendingBattleAndPrompt(BuildContext context) async {
  final provider = context.read<AdventureProvider>();
  final pending = await provider.checkPendingBattle();
  if (pending == null || !context.mounted) return;

  final action = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: const Color(0xFF1E1225),
      title: const Text('이전 배틀이 있습니다',
          style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${pending.monsterName}와(과)의 배틀을 끝까지 보지 않고 나갔어요.\n이어서 보고 보상을 받을까요?',
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          Text('포기하면 사용한 신발코인은 돌아오지 않아요.',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 12)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, 'abandon'),
          child: const Text('포기하기',
              style: TextStyle(color: Colors.redAccent)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF4A259),
              foregroundColor: Colors.black),
          onPressed: () => Navigator.pop(dialogContext, 'resume'),
          child: const Text('이어서 하기'),
        ),
      ],
    ),
  );

  if (!context.mounted) return;

  if (action == 'resume') {
    provider.currentBattle = pending;
    final currency = context.read<CurrencyProvider>();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BattleScreen(battleResult: pending)),
    );
    provider.loadStages();
    currency.load();
  } else if (action == 'abandon') {
    await provider.abandonBattle(pending.battleId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('배틀을 포기했습니다.'),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ));
  }
}
