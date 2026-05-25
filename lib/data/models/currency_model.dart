class CurrencyModel {
  final int gold;
  final int shoeCoin;

  CurrencyModel({required this.gold, required this.shoeCoin});

  factory CurrencyModel.fromJson(Map<String, dynamic> json) => CurrencyModel(
        gold: json['gold'] ?? 0,
        shoeCoin: json['shoeCoin'] ?? 0,
      );

  CurrencyModel copyWith({int? gold, int? shoeCoin}) => CurrencyModel(
        gold: gold ?? this.gold,
        shoeCoin: shoeCoin ?? this.shoeCoin,
      );
}
