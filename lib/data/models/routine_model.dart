class RoutineModel {
  final int id;
  final String name;
  final int exerciseCount;
  final List<RoutineExerciseModel> exercises;

  RoutineModel({
    required this.id,
    required this.name,
    required this.exerciseCount,
    required this.exercises,
  });

  factory RoutineModel.fromJson(Map<String, dynamic> json) => RoutineModel(
        id: json['id'],
        name: json['name'],
        exerciseCount: json['exerciseCount'] ?? 0,
        exercises: (json['exercises'] as List? ?? [])
            .map((e) => RoutineExerciseModel.fromJson(e))
            .toList(),
      );
}

class RoutineExerciseModel {
  final int id;
  final int exerciseId;
  final String exerciseName;
  final String target;
  final int orderIndex;
  final int? supersetGroup;

  RoutineExerciseModel({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.target,
    required this.orderIndex,
    this.supersetGroup,
  });

  factory RoutineExerciseModel.fromJson(Map<String, dynamic> json) =>
      RoutineExerciseModel(
        id: json['id'],
        exerciseId: json['exerciseId'],
        exerciseName: json['exerciseName'],
        target: json['target'],
        orderIndex: json['orderIndex'],
        supersetGroup: json['supersetGroup'],
      );
}
