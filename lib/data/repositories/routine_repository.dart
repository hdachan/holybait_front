import '../datasources/routine_remote_ds.dart';
import '../models/routine_model.dart';
import '../models/exercise_model.dart';
import '../models/workout_model.dart';
import '../../features/routine/screens/workout_history_screen.dart';
import '../../features/routine/screens/workout_history_detail_screen.dart';

class RoutineRepository {
  final _remote = RoutineRemoteDataSource();

  Future<List<RoutineModel>> getRoutines() => _remote.getRoutines();
  Future<RoutineModel> getRoutine(int id) => _remote.getRoutine(id);

  Future<RoutineModel> createRoutine(String name, List<int> exerciseIds) =>
      _remote.createRoutine(name, exerciseIds);

  Future<RoutineModel> updateRoutine(
      int id, String name, List<int> exerciseIds) =>
      _remote.updateRoutine(id, name, exerciseIds);

  Future<RoutineModel> saveRoutineDetail(
      int routineId, List<Map<String, dynamic>> exercises) =>
      _remote.saveRoutineDetail(routineId, exercises);

  Future<void> deleteRoutine(int id) => _remote.deleteRoutine(id);

  Future<List<ExerciseModel>> getExercises(
      {String? target, String? keyword}) =>
      _remote.getExercises(target: target, keyword: keyword);

  Future<ExerciseModel> createCustomExercise(String name, String target) =>
      _remote.createCustomExercise(name, target);

  Future<WorkoutSaveResult> saveWorkout(
      int routineExerciseId,
      List<Map<String, dynamic>> sets,
      ) =>
      _remote.saveWorkout(routineExerciseId, sets);

  Future<RecentSetsResponse?> getRecentSets(int routineExerciseId) =>
      _remote.getRecentSets(routineExerciseId);

  // 운동 통계
  Future<WorkoutSummaryModel> getWorkoutSummary() =>
      _remote.getWorkoutSummary();

  // 운동 기록 — 종목 목록
  Future<List<WorkoutHistoryModel>> getExerciseHistory() =>
      _remote.getExerciseHistory();

  // 운동 기록 — 특정 종목 날짜별 상세
  Future<List<WorkoutHistoryDetailModel>> getExerciseDetail(int exerciseId) =>
      _remote.getExerciseDetail(exerciseId);
}