class CurrencyModel {
  final int gold;
  final int shoeCoin;
  final int todayShoeCoin;
  final int dailyCap;

  CurrencyModel({
    required this.gold,
    required this.shoeCoin,
    required this.todayShoeCoin,
    required this.dailyCap,
  });

  factory CurrencyModel.fromJson(Map<String, dynamic> json) => CurrencyModel(
    gold: json['gold'] ?? 0,
    shoeCoin: json['shoeCoin'] ?? 0,
    todayShoeCoin: json['todayShoeCoin'] ?? 0,
    dailyCap: json['dailyCap'] ?? 20,
  );

  int get remainingToday => (dailyCap - todayShoeCoin).clamp(0, dailyCap);
  bool get isCapped => todayShoeCoin >= dailyCap;
}