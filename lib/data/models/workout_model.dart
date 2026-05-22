class WorkoutSetModel {
  final int setNumber;
  final double? weightKg;
  final int? reps;
  final bool isDropset;

  WorkoutSetModel({
    required this.setNumber,
    this.weightKg,
    this.reps,
    this.isDropset = false,
  });

  factory WorkoutSetModel.fromJson(Map<String, dynamic> json) => WorkoutSetModel(
        setNumber: json['setNumber'],
        weightKg: json['weightKg'] != null
            ? double.parse(json['weightKg'].toString())
            : null,
        reps: json['reps'],
        isDropset: json['isDropset'] ?? false,
      );
}
