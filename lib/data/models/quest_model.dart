class QuestModel {
  final int questId;
  final String title;
  final String description;
  final String actionType;
  final int progress;
  final int targetCount;
  final String status; // in_progress / completed / claimed
  final int rewardGold;
  final int rewardExp;

  QuestModel({
    required this.questId,
    required this.title,
    required this.description,
    required this.actionType,
    required this.progress,
    required this.targetCount,
    required this.status,
    required this.rewardGold,
    required this.rewardExp,
  });

  bool get isCompleted => status == 'completed';
  bool get isClaimed => status == 'claimed';
  bool get isInProgress => status == 'in_progress';
  double get progressRatio =>
      targetCount == 0 ? 0 : (progress / targetCount).clamp(0.0, 1.0);

  factory QuestModel.fromJson(Map<String, dynamic> json) => QuestModel(
    questId: json['questId'],
    title: json['title'],
    description: json['description'] ?? '',
    actionType: json['actionType'],
    progress: json['progress'] ?? 0,
    targetCount: json['targetCount'] ?? 1,
    status: json['status'] ?? 'in_progress',
    rewardGold: json['rewardGold'] ?? 0,
    rewardExp: json['rewardExp'] ?? 0,
  );
}

class QuestClaimResult {
  final int rewardGold;
  final int remainingGold;

  QuestClaimResult({required this.rewardGold, required this.remainingGold});

  factory QuestClaimResult.fromJson(Map<String, dynamic> json) =>
      QuestClaimResult(
        rewardGold: json['rewardGold'] ?? 0,
        remainingGold: json['remainingGold'] ?? 0,
      );
}