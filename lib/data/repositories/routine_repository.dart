import '../datasources/routine_remote_ds.dart';
import '../models/routine_model.dart';
import '../models/exercise_model.dart';
import '../models/workout_model.dart';

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

  // isSuperset, isSupersetFirst 제거
  Future<WorkoutSaveResult> saveWorkout(
      int routineExerciseId,
      List<Map<String, dynamic>> sets,
      ) =>
      _remote.saveWorkout(routineExerciseId, sets);

  // nullable RecentSetsResponse 반환 (기록 없으면 null)
  Future<RecentSetsResponse?> getRecentSets(int routineExerciseId) =>
      _remote.getRecentSets(routineExerciseId);
}
