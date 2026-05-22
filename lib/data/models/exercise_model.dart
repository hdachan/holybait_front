class ExerciseModel {
  final int id;
  final String name;
  final String target;
  final bool isCustom;

  ExerciseModel({
    required this.id,
    required this.name,
    required this.target,
    required this.isCustom,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) => ExerciseModel(
        id: json['id'],
        name: json['name'],
        target: json['target'],
        isCustom: json['isCustom'] ?? false,
      );
}
