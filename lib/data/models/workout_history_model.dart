// 운동 기록 화면(workout_history_screen, workout_history_detail_screen)에서 쓰는 모델

class WorkoutSummaryModel {
  final int thisWeekCount;
  final int streakDays;
  final int totalExercises;

  WorkoutSummaryModel({
    required this.thisWeekCount,
    required this.streakDays,
    required this.totalExercises,
  });

  factory WorkoutSummaryModel.fromJson(Map<String, dynamic> json) =>
      WorkoutSummaryModel(
        thisWeekCount: json['thisWeekCount'] ?? 0,
        streakDays: json['streakDays'] ?? 0,
        totalExercises: json['totalExercises'] ?? 0,
      );
}

class WorkoutHistoryModel {
  final int exerciseId;
  final String exerciseName;
  final String target;
  final String lastLoggedDate;
  final int totalSessions;

  WorkoutHistoryModel({
    required this.exerciseId,
    required this.exerciseName,
    required this.target,
    required this.lastLoggedDate,
    required this.totalSessions,
  });

  factory WorkoutHistoryModel.fromJson(Map<String, dynamic> json) =>
      WorkoutHistoryModel(
        exerciseId: json['exerciseId'],
        exerciseName: json['exerciseName'],
        target: json['target'] ?? '',
        lastLoggedDate: json['lastLoggedDate'] ?? '',
        totalSessions: json['totalSessions'] ?? 0,
      );
}
class WorkoutHistoryDetailModel {
  final String loggedDate;
  final int totalSets;
  final List<SetDetailModel> sets;

  WorkoutHistoryDetailModel({
    required this.loggedDate,
    required this.totalSets,
    required this.sets,
  });

  factory WorkoutHistoryDetailModel.fromJson(Map<String, dynamic> json) =>
      WorkoutHistoryDetailModel(
        loggedDate: json['loggedDate'] ?? '',
        totalSets: json['totalSets'] ?? 0,
        sets: (json['sets'] as List? ?? [])
            .map((s) => SetDetailModel.fromJson(s))
            .toList(),
      );
}

class SetDetailModel {
  final int setNumber;
  final double? weightKg;
  final int? reps;
  final bool isDropset;

  SetDetailModel({
    required this.setNumber,
    this.weightKg,
    this.reps,
    required this.isDropset,
  });

  factory SetDetailModel.fromJson(Map<String, dynamic> json) =>
      SetDetailModel(
        setNumber: json['setNumber'] ?? 0,
        weightKg: json['weightKg'] != null
            ? double.tryParse(json['weightKg'].toString())
            : null,
        reps: json['reps'],
        isDropset: json['isDropset'] ?? false,
      );
}