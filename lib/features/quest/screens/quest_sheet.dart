import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/quest_provider.dart';
import '../../../data/models/quest_model.dart';
import '../../currency/provider/currency_provider.dart';

void showQuestSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _QuestSheet(),
  );
}

class _QuestSheet extends StatefulWidget {
  const _QuestSheet();

  @override
  State<_QuestSheet> createState() => _QuestSheetState();
}

class _QuestSheetState extends State<_QuestSheet> {
  String _selectedType = 'tutorial';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuestProvider>().loadQuests(type: _selectedType);
    });
  }

  void _switchTab(String type) {
    if (_selectedType == type) return;
    setState(() => _selectedType = type);
    context.read<QuestProvider>().loadQuests(type: type);
  }

  @override
  Widget build(BuildContext context) {
    final quest = context.watch<QuestProvider>();

    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75),
      decoration: const BoxDecoration(
        color: Color(0xFF1C0E04),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                const Text('📜', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                const Text('초보자 퀘스트',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                if (quest.totalCount > 0)
                  Text('${quest.claimedCount}/${quest.totalCount}',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 13)),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white12),

          // 탭 (튜토리얼 / 일일 / 주간)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _QuestTab(
                  label: '튜토리얼',
                  isSelected: _selectedType == 'tutorial',
                  onTap: () => _switchTab('tutorial'),
                ),
                const SizedBox(width: 8),
                _QuestTab(
                  label: '일일',
                  isSelected: _selectedType == 'daily',
                  onTap: () => _switchTab('daily'),
                ),
                const SizedBox(width: 8),
                _QuestTab(
                  label: '주간',
                  isSelected: _selectedType == 'weekly',
                  onTap: () => _switchTab('weekly'),
                ),
              ],
            ),
          ),

          Flexible(
            child: quest.isLoading
                ? const Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: Color(0xFFEF7910)),
            )
                : quest.quests.isEmpty
                ? Padding(
              padding: const EdgeInsets.all(40),
              child: Text('아직 준비 중인 퀘스트예요',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 13)),
            )
                : ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: quest.quests.length,
              itemBuilder: (_, i) =>
                  _QuestItem(quest: quest.quests[i], type: _selectedType),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuestTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFEF7910)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white.withOpacity(0.5),
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            )),
      ),
    );
  }
}

class _QuestItem extends StatelessWidget {
  final QuestModel quest;
  final String type;
  const _QuestItem({required this.quest, required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: quest.isClaimed
            ? Colors.white.withOpacity(0.03)
            : const Color(0xFF0D0A1A).withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: quest.isCompleted
              ? const Color(0xFFEF7910).withOpacity(0.6)
              : const Color(0xFF8B5E3C).withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          // 체크 아이콘
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: quest.isClaimed
                  ? const Color(0xFF4CAF50).withOpacity(0.15)
                  : quest.isCompleted
                  ? const Color(0xFFEF7910).withOpacity(0.15)
                  : Colors.white.withOpacity(0.06),
            ),
            child: Icon(
              quest.isClaimed
                  ? Icons.check_circle
                  : quest.isCompleted
                  ? Icons.card_giftcard
                  : Icons.radio_button_unchecked,
              color: quest.isClaimed
                  ? const Color(0xFF4CAF50)
                  : quest.isCompleted
                  ? const Color(0xFFEF7910)
                  : Colors.white.withOpacity(0.3),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // 텍스트
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(quest.title,
                    style: TextStyle(
                        color: quest.isClaimed
                            ? Colors.white.withOpacity(0.4)
                            : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(quest.description,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 11)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: quest.progressRatio,
                          minHeight: 5,
                          backgroundColor: Colors.white.withOpacity(0.08),
                          valueColor: AlwaysStoppedAnimation(
                            quest.isClaimed
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFEF7910),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${quest.progress}/${quest.targetCount}',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // 보상 버튼
          if (quest.isCompleted)
            GestureDetector(
              onTap: () async {
                final result = await context
                    .read<QuestProvider>()
                    .claimReward(quest.questId, type: type);
                if (result != null && context.mounted) {
                  context.read<CurrencyProvider>().load();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('🪙 골드 ${result.rewardGold}개 획득!'),
                    backgroundColor: const Color(0xFF4CAF50),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  ));
                }
              },
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF7910),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('받기',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            )
          else if (quest.isClaimed)
            Icon(Icons.check, color: Colors.white.withOpacity(0.2), size: 20)
          else
            Text('🪙${quest.rewardGold}',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.3), fontSize: 11)),
        ],
      ),
    );
  }
}