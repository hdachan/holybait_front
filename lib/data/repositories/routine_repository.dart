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

  // 편집 모드 전체 저장
  Future<RoutineModel> saveRoutineDetail(
      int routineId, List<Map<String, dynamic>> exercises) =>
      _remote.saveRoutineDetail(routineId, exercises);

  Future<void> deleteRoutine(int id) => _remote.deleteRoutine(id);

  Future<List<ExerciseModel>> getExercises(
      {String? target, String? keyword}) =>
      _remote.getExercises(target: target, keyword: keyword);

  Future<ExerciseModel> createCustomExercise(String name, String target) =>
      _remote.createCustomExercise(name, target);

  Future<void> saveWorkout(
      int routineExerciseId, List<Map<String, dynamic>> sets) =>
      _remote.saveWorkout(routineExerciseId, sets);

  Future<List<WorkoutSetModel>> getRecentSets(int routineExerciseId) =>
      _remote.getRecentSets(routineExerciseId);
}
