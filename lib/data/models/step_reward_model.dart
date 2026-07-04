class StepRewardModel {
  final int grantedCoins;     // 이번에 받은 코인
  final int todayTotalEarned; // 오늘 총 받은 코인
  final int dailyCap;         // 하루 최대치
  final bool success;         // 지급 성공 여부

  StepRewardModel({
    required this.grantedCoins,
    required this.todayTotalEarned,
    required this.dailyCap,
    required this.success,
  });

  factory StepRewardModel.fromJson(Map<String, dynamic> json) => StepRewardModel(
    grantedCoins:     json['grantedCoins']     ?? 0,
    todayTotalEarned: json['todayTotalEarned'] ?? 0,
    dailyCap:         json['dailyCap']         ?? 20,
    success:          json['success']          ?? false,
  );
}