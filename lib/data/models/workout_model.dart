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

  factory WorkoutSetModel.fromJson(Map<String, dynamic> json) =>
      WorkoutSetModel(
        setNumber: json['setNumber'] ?? 1,
        weightKg: json['weightKg'] != null
            ? double.tryParse(json['weightKg'].toString())
            : null,
        reps: json['reps'] != null
            ? int.tryParse(json['reps'].toString())
            : null,
        isDropset: json['isDropset'] ?? false,
      );
}

class RecentSetsResponse {
  final String? loggedDate; // "2026-05-26" 형식
  final List<WorkoutSetModel> sets;

  RecentSetsResponse({required this.loggedDate, required this.sets});

  factory RecentSetsResponse.fromJson(Map<String, dynamic> json) {
    return RecentSetsResponse(
      loggedDate: json['loggedDate']?.toString(),
      sets: (json['sets'] as List? ?? [])
          .map((s) => WorkoutSetModel.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  // Flutter 현재 날짜와 문자열 비교 — "2026-05-26" == "2026-05-26"
  bool get isToday {
    if (loggedDate == null) return false;
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return loggedDate == todayStr;
  }
}

class WorkoutSaveResult {
  final int grantedShoeCoin;

  WorkoutSaveResult({required this.grantedShoeCoin});

  factory WorkoutSaveResult.fromJson(Map<String, dynamic> json) =>
      WorkoutSaveResult(
        grantedShoeCoin: json['grantedShoeCoin'] ?? 0,
      );
}
